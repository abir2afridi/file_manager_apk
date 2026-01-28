import 'dart:io';
import 'package:path/path.dart' as p;

class FileModel {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;
  final String extension;
  final int? itemCount;

  FileModel({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    required this.extension,
    this.itemCount,
  });

  factory FileModel.fromFileSystemEntity(FileSystemEntity entity) {
    final stats = entity.statSync();
    return FileModel(
      path: entity.path,
      name: p.basename(entity.path),
      isDirectory: entity is Directory,
      size: stats.size,
      lastModified: stats.modified,
      extension: p.extension(entity.path).toLowerCase(),
    );
  }
}
