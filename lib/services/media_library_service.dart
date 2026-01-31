import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/services/file_service.dart';

/// Service responsible for discovering media files (images, videos, audio)
/// across device storage without blocking the UI thread.
class MediaLibraryService {
  MediaLibraryService({this.includeHidden = false, this.followLinks = false});

  /// Whether hidden files (those whose name starts with '.') should be included.
  final bool includeHidden;

  /// Whether symbolic links should be followed while scanning.
  final bool followLinks;

  /// Discovers media assets for the given [mediaType]. Optionally restrict the
  /// scan to specific [directories].
  Future<List<MediaAsset>> loadMedia({
    required MediaType mediaType,
    List<String>? directories,
    bool recursive = true,
  }) async {
    final roots = directories ?? await _resolveDefaultDirectories(mediaType);
    if (roots.isEmpty) {
      return const [];
    }

    final config = _MediaScanConfig(
      roots: roots,
      mediaType: mediaType,
      recursive: recursive,
      includeHidden: includeHidden,
      followLinks: followLinks,
    );

    final results = await Isolate.run(
      () => _scanMedia(config.toMap()),
    );

    return results.map(MediaAsset.fromMap).toList(growable: false);
  }

  /// Streams media assets as they are discovered. Suitable for progressively
  /// populating galleries while a background scan continues.
  Stream<MediaAsset> watchMedia({
    required MediaType mediaType,
    List<String>? directories,
    bool recursive = true,
  }) async* {
    final roots = directories ?? await _resolveDefaultDirectories(mediaType);
    if (roots.isEmpty) {
      return;
    }

    final config = _MediaScanConfig(
      roots: roots,
      mediaType: mediaType,
      recursive: recursive,
      includeHidden: includeHidden,
      followLinks: followLinks,
    );

    final controller = StreamController<MediaAsset>();
    final receivePort = ReceivePort();

    Isolate? isolate;
    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        controller.add(MediaAsset.fromMap(message));
      } else if (message == _kIsolateCompleteToken) {
        controller.close();
        receivePort.close();
        isolate?.kill(priority: Isolate.immediate);
      }
    }, onError: controller.addError, onDone: controller.close);

    isolate = await Isolate.spawn<_MediaScanStreamConfig>(
      _scanMediaStream,
      _MediaScanStreamConfig(
        sendPort: receivePort.sendPort,
        config: config,
      ),
    );

    yield* controller.stream;
  }

  Future<List<String>> _resolveDefaultDirectories(MediaType type) async {
    final root = await FileService.getPrimaryStoragePath();
    final subDirs = _defaultMediaSubDirectories[type] ?? const [];
    final directories = <String>{root};
    for (final subDir in subDirs) {
      directories.add(p.join(root, subDir));
    }
    return directories.where((path) => Directory(path).existsSync()).toList();
  }
}

const _kIsolateCompleteToken = '__MEDIA_SCAN_DONE__';

class _MediaScanConfig {
  _MediaScanConfig({
    required this.roots,
    required this.mediaType,
    required this.recursive,
    required this.includeHidden,
    required this.followLinks,
  });

  final List<String> roots;
  final MediaType mediaType;
  final bool recursive;
  final bool includeHidden;
  final bool followLinks;

  Map<String, dynamic> toMap() => {
        'roots': roots,
        'mediaType': mediaType.index,
        'recursive': recursive,
        'includeHidden': includeHidden,
        'followLinks': followLinks,
      };
}

class _MediaScanStreamConfig {
  const _MediaScanStreamConfig({
    required this.sendPort,
    required this.config,
  });

  final SendPort sendPort;
  final _MediaScanConfig config;
}

Future<List<Map<String, dynamic>>> _scanMedia(Map<String, dynamic> configMap) async {
  final config = _parseConfig(configMap);
  final results = <Map<String, dynamic>>[];

  for (final root in config.roots) {
    final directory = Directory(root);
    if (!await directory.exists()) continue;

    await for (final entity in directory.list(
      recursive: config.recursive,
      followLinks: config.followLinks,
    )) {
      if (entity is! File) continue;
      final asset = await _buildMediaAsset(entity, config.mediaType,
          includeHidden: config.includeHidden);
      if (asset != null) {
        results.add(asset);
      }
    }
  }

  results.sort((a, b) {
    final aModified = a['lastModified'] as int? ?? 0;
    final bModified = b['lastModified'] as int? ?? 0;
    return bModified.compareTo(aModified);
  });

  return results;
}

Future<void> _scanMediaStream(_MediaScanStreamConfig request) async {
  final sendPort = request.sendPort;
  final configMap = request.config.toMap();
  final config = _parseConfig(configMap);

  try {
    for (final root in config.roots) {
      final directory = Directory(root);
      if (!await directory.exists()) continue;

      await for (final entity in directory.list(
        recursive: config.recursive,
        followLinks: config.followLinks,
      )) {
        if (entity is! File) continue;
        final asset = await _buildMediaAsset(
          entity,
          config.mediaType,
          includeHidden: config.includeHidden,
        );
        if (asset != null) {
          sendPort.send(asset);
        }
      }
    }
  } catch (e, stack) {
    sendPort.send({'error': e.toString(), 'stack': stack.toString()});
  } finally {
    sendPort.send(_kIsolateCompleteToken);
  }
}

_MediaScanConfig _parseConfig(Map<String, dynamic> map) {
  return _MediaScanConfig(
    roots: (map['roots'] as List).cast<String>(),
    mediaType: MediaType.values[map['mediaType'] as int],
    recursive: map['recursive'] as bool? ?? true,
    includeHidden: map['includeHidden'] as bool? ?? false,
    followLinks: map['followLinks'] as bool? ?? false,
  );
}

Future<Map<String, dynamic>?> _buildMediaAsset(
  File file,
  MediaType type, {
  required bool includeHidden,
}) async {
  final extension = p.extension(file.path).toLowerCase();
  if (!includeHidden && p.basename(file.path).startsWith('.')) {
    return null;
  }

  if (!_matchesType(extension, type, file.path)) {
    return null;
  }

  try {
    final stat = await file.stat();
    return {
      'path': file.path,
      'name': p.basename(file.path),
      'type': type.index,
      'sizeBytes': stat.size,
      'lastModified': stat.modified.millisecondsSinceEpoch,
      'durationMs': null,
      'parentDirectory': p.dirname(file.path),
      'mimeType': lookupMimeType(file.path),
    };
  } catch (_) {
    return null;
  }
}

bool _matchesType(String extension, MediaType type, String fullPath) {
  switch (type) {
    case MediaType.image:
      return _imageExtensions.contains(extension);
    case MediaType.video:
      return _videoExtensions.contains(extension);
    case MediaType.audio:
      return _audioExtensions.contains(extension);
  }
}

const Set<String> _imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.heic',
};

const Set<String> _videoExtensions = {
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.webm',
  '.flv',
};

const Set<String> _audioExtensions = {
  '.mp3',
  '.aac',
  '.wav',
  '.ogg',
  '.flac',
  '.m4a',
};

const Map<MediaType, List<String>> _defaultMediaSubDirectories = {
  MediaType.image: ['Pictures', 'DCIM', 'WhatsApp/Media/WhatsApp Images'],
  MediaType.video: ['Movies', 'DCIM', 'WhatsApp/Media/WhatsApp Video'],
  MediaType.audio: ['Music', 'Audio', 'WhatsApp/Media/WhatsApp Audio'],
};
