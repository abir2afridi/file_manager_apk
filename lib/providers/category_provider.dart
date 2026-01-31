import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/services/file_service.dart';

final categoryFilesProvider = FutureProvider.family<List<FileModel>, String>((
  ref,
  type,
) async {
  final basePath = await FileService.getPrimaryStoragePath();
  final candidateDirs = _resolveCandidateDirectories(basePath, type);
  final extensions = _resolveExtensions(type);
  final results = <FileModel>[];
  final seenPaths = <String>{};

  for (final dirPath in candidateDirs) {
    final directory = Directory(dirPath);
    if (!await directory.exists()) continue;

    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          if (name.startsWith('.') || name == 'Android') {
            continue;
          }
        }

        if (entity is File) {
          if (extensions != null) {
            final pathLower = entity.path.toLowerCase();
            if (!extensions.any((ext) => pathLower.endsWith(ext))) {
              continue;
            }
          }

          if (seenPaths.add(entity.path)) {
            try {
              results.add(FileModel.fromFileSystemEntity(entity));
            } catch (_) {
              continue;
            }
          }
        }
      }
    } catch (_) {
      // Skip directories we cannot access
      continue;
    }
  }

  return results;
});

List<String> _resolveCandidateDirectories(String basePath, String type) {
  final dirs = <String>[];
  String join(String name) => p.join(basePath, name);

  switch (type) {
    case 'images':
      dirs.addAll({
        join('DCIM'),
        join('Pictures'),
        join('Download'),
        join('Screenshots'),
      });
      break;
    case 'videos':
      dirs.addAll({join('DCIM'), join('Movies'), join('Download')});
      break;
    case 'audio':
      dirs.addAll({join('Music'), join('Audio'), join('Download')});
      break;
    case 'documents':
      dirs.addAll({join('Documents'), join('Download'), join('Notes')});
      break;
    case 'apks':
      dirs.addAll({join('Download'), join('APKs')});
      break;
    case 'downloads':
      dirs.add(join('Download'));
      break;
    case 'archives':
      dirs.addAll({join('Download'), join('Documents')});
      break;
  }

  if (dirs.isEmpty) {
    dirs.add(basePath);
  }

  return dirs.toSet().toList();
}

List<String>? _resolveExtensions(String type) {
  switch (type) {
    case 'images':
      return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'];
    case 'videos':
      return ['.mp4', '.mkv', '.avi', '.mov', '.webm'];
    case 'audio':
      return ['.mp3', '.wav', '.m4a', '.flac', '.aac'];
    case 'documents':
      return [
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.txt',
      ];
    case 'apks':
      return ['.apk'];
    case 'downloads':
      return null;
    case 'archives':
      return ['.zip', '.rar', '.7z', '.tar', '.gz'];
    default:
      return null;
  }
}
