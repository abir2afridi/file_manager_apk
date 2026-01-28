import 'dart:io';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:path/path.dart' as p;

class StorageAnalysis {
  final List<File> largeFiles;
  final List<File> duplicateFiles;
  final List<File> oldApks;
  final List<Directory> cacheFolders;
  final int totalJunkSize;

  StorageAnalysis({
    required this.largeFiles,
    required this.duplicateFiles,
    required this.oldApks,
    required this.cacheFolders,
    required this.totalJunkSize,
  });
}

class StorageService {
  static Future<double> getTotalSpace() async {
    return await DiskSpace.getTotalDiskSpace ?? 0;
  }

  static Future<double> getFreeSpace() async {
    return await DiskSpace.getFreeDiskSpace ?? 0;
  }

  static Future<StorageAnalysis> analyzeStorage() async {
    final dir = Directory('/storage/emulated/0');
    List<File> largeFiles = [];
    List<File> oldApks = [];
    List<Directory> cacheFolders = [];
    Map<String, List<File>> fileMap = {};
    int totalJunkSize = 0;

    const int largeFileThreshold = 50 * 1024 * 1024; // 50MB

    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        final name = p.basename(entity.path);

        // Skip hidden folders and Android system folder to save time
        if (entity is Directory) {
          if (name.startsWith('.') || name == 'Android') continue;
          if (name.toLowerCase() == 'cache' || name.toLowerCase() == '.cache') {
            cacheFolders.add(entity);
            // We could calculate size here but it's slow
          }
        }

        if (entity is File) {
          final size = await entity.length();
          final ext = p.extension(entity.path).toLowerCase();

          // Large files
          if (size > largeFileThreshold) {
            largeFiles.add(entity);
          }

          // APKs
          if (ext == '.apk') {
            oldApks.add(entity);
          }

          // Duplicate detection (simple name+size check)
          final key = '${name}_$size';
          if (fileMap.containsKey(key)) {
            fileMap[key]!.add(entity);
          } else {
            fileMap[key] = [entity];
          }
        }
      }
    } catch (_) {}

    List<File> duplicateFiles = [];
    fileMap.forEach((key, files) {
      if (files.length > 1) {
        // Add all except the first one as duplicates
        duplicateFiles.addAll(files.skip(1));
      }
    });

    return StorageAnalysis(
      largeFiles: largeFiles,
      duplicateFiles: duplicateFiles,
      oldApks: oldApks,
      cacheFolders: cacheFolders,
      totalJunkSize: totalJunkSize,
    );
  }
}
