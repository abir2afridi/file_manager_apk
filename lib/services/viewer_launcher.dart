import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/services/file_type_resolver.dart';
import 'package:file_explorer_apk/features/media/screens/image_viewer_screen.dart';
import 'package:file_explorer_apk/features/media/screens/video_player_screen.dart';
import 'package:file_explorer_apk/features/media/screens/audio_player_screen.dart';
import 'package:file_explorer_apk/features/documents/screens/document_viewer_screen.dart';

class ViewerLauncher {
  const ViewerLauncher._();

  static Future<void> openFile(
    BuildContext context,
    FileModel file, {
    List<FileModel>? scope,
  }) async {
    final kind = FileTypeResolver.resolve(file.path);
    switch (kind) {
      case FileViewerKind.image:
        await _openImage(context, file, scope);
        return;
      case FileViewerKind.video:
        await _openVideo(context, file, scope);
        return;
      case FileViewerKind.audio:
        await _openAudio(context, file, scope);
        return;
      case FileViewerKind.pdf:
      case FileViewerKind.text:
      case FileViewerKind.docx:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DocumentViewerScreen(path: file.path, displayName: file.name),
          ),
        );
        return;
      case FileViewerKind.doc:
      case FileViewerKind.unsupported:
        await _openWithExternal(context, file.path, file.name);
        return;
    }
  }

  static Future<void> _openImage(
    BuildContext context,
    FileModel file,
    List<FileModel>? scope,
  ) async {
    final scopeFiles = _filterScope(scope, FileViewerKind.image, file);
    final assets = scopeFiles.map(_toMediaAsset).toList(growable: false);
    final initialIndex = assets.indexWhere((asset) => asset.path == file.path);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          assets: assets,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  static Future<void> _openVideo(
    BuildContext context,
    FileModel file,
    List<FileModel>? scope,
  ) async {
    final scopeFiles = _filterScope(scope, FileViewerKind.video, file);
    final playlist = scopeFiles.map(_toMediaAsset).toList(growable: false);
    final initialIndex = playlist.indexWhere(
      (asset) => asset.path == file.path,
    );
    if (playlist.isEmpty) {
      await _openWithExternal(
        context,
        file.path,
        file.name,
        reason: 'Unsupported video format',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          playlist: playlist,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  static Future<void> _openAudio(
    BuildContext context,
    FileModel file,
    List<FileModel>? scope,
  ) async {
    final scopeFiles = _filterScope(scope, FileViewerKind.audio, file);
    final playlist = scopeFiles.map(_toMediaAsset).toList(growable: false);
    final initialIndex = playlist.indexWhere(
      (asset) => asset.path == file.path,
    );
    if (playlist.isEmpty) {
      await _openWithExternal(
        context,
        file.path,
        file.name,
        reason: 'Unsupported audio format',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerScreen(
          playlist: playlist,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  static List<FileModel> _filterScope(
    List<FileModel>? scope,
    FileViewerKind kind,
    FileModel fallback,
  ) {
    final candidates = scope ?? [fallback];
    final parentDir = p.dirname(fallback.path);
    final filtered =
        candidates.where((entry) {
          if (entry.isDirectory) return false;
          if (p.dirname(entry.path) != parentDir) return false;
          return FileTypeResolver.resolve(entry.path) == kind;
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    if (filtered.isEmpty) {
      filtered.add(fallback);
    }
    return filtered;
  }

  static MediaAsset _toMediaAsset(FileModel file) {
    return MediaAsset(
      path: file.path,
      name: file.name,
      type: _mediaTypeFromKind(FileTypeResolver.resolve(file.path)),
      sizeBytes: file.size,
      parentDirectory: p.dirname(file.path),
      lastModified: file.lastModified,
      mimeType: lookupMimeType(file.path),
    );
  }

  static MediaType _mediaTypeFromKind(FileViewerKind kind) {
    switch (kind) {
      case FileViewerKind.image:
        return MediaType.image;
      case FileViewerKind.video:
        return MediaType.video;
      case FileViewerKind.audio:
        return MediaType.audio;
      default:
        return MediaType.image;
    }
  }

  static Future<void> _openWithExternal(
    BuildContext context,
    String path,
    String name, {
    String? reason,
  }) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      final message = result.message;
      final error = message.isNotEmpty
          ? message
          : 'Unable to open "$name" externally.';
      final extra = reason != null ? ' ($reason)' : '';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error$extra')));
    }
  }
}
