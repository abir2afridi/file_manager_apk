import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_explorer_apk/models/file_model.dart';

final categoryFilesProvider = FutureProvider.family<List<FileModel>, String>((
  ref,
  type,
) async {
  final dir = Directory('/storage/emulated/0');
  List<FileModel> results = [];

  List<String> extensions = [];
  switch (type) {
    case 'images':
      extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      break;
    case 'videos':
      extensions = ['.mp4', '.mkv', '.avi', '.mov'];
      break;
    case 'audio':
      extensions = ['.mp3', '.wav', '.m4a', '.flac'];
      break;
    case 'documents':
      extensions = [
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.txt',
      ];
      break;
    case 'apks':
      extensions = ['.apk'];
      break;
    case 'downloads':
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final entities = await downloadsDir.list().toList();
        for (var entity in entities) {
          if (entity is File) {
            results.add(FileModel.fromFileSystemEntity(entity));
          }
        }
        return results;
      }
      return [];
    default:
      return [];
  }

  try {
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || name == 'Android') {
          // Skip these folders to speed up scanning
          continue;
        }
      }
      if (entity is File) {
        final path = entity.path.toLowerCase();
        if (extensions.any((ext) => path.endsWith(ext))) {
          results.add(FileModel.fromFileSystemEntity(entity));
        }
      }
    }
  } catch (e) {
    // Handle or ignore
  }

  return results;
});
