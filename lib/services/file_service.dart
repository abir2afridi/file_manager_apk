import 'dart:io';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:path/path.dart' as p;

class FileService {
  static Future<List<FileModel>> getFilesInDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist');
      }

      final entities = await directory.list().toList();
      final files = <FileModel>[];

      for (final entity in entities) {
        try {
          final fileModel = FileModel.fromFileSystemEntity(entity);
          
          // Add item count for directories
          if (fileModel.isDirectory) {
            try {
              final dir = Directory(entity.path);
              final items = await dir.list().length;
              files.add(FileModel(
                path: fileModel.path,
                name: fileModel.name,
                isDirectory: fileModel.isDirectory,
                size: fileModel.size,
                lastModified: fileModel.lastModified,
                extension: fileModel.extension,
                itemCount: items,
              ));
            } catch (e) {
              // If we can't count items, add without count
              files.add(fileModel);
            }
          } else {
            files.add(fileModel);
          }
        } catch (e) {
          // Skip files that can't be accessed
          continue;
        }
      }

      // Sort: directories first, then files
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return files;
    } catch (e) {
      throw Exception('Failed to load directory: $e');
    }
  }

  static Future<bool> deleteFile(String path) async {
    try {
      final entity = File(path);
      if (await entity.exists()) {
        await entity.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  static Future<bool> deleteDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete directory: $e');
    }
  }

  static Future<List<FileModel>> searchFiles(String query, {String? basePath}) async {
    try {
      final searchPath = basePath ?? '/storage/emulated/0';
      final directory = Directory(searchPath);
      final results = <FileModel>[];

      await for (final entity in directory.list(recursive: true)) {
        try {
          final fileName = p.basename(entity.path).toLowerCase();
          if (fileName.contains(query.toLowerCase())) {
            final fileModel = FileModel.fromFileSystemEntity(entity);
            results.add(fileModel);
          }
        } catch (e) {
          // Skip files that can't be accessed
          continue;
        }
      }

      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  static Future<int> getDirectorySize(String path) async {
    try {
      final directory = Directory(path);
      int totalSize = 0;

      await for (final entity in directory.list(recursive: true)) {
        try {
          if (entity is File) {
            totalSize += await entity.length();
          }
        } catch (e) {
          // Skip files that can't be accessed
          continue;
        }
      }

      return totalSize;
    } catch (e) {
      throw Exception('Failed to calculate directory size: $e');
    }
  }
}
