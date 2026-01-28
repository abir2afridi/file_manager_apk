import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/models/file_model.dart';

final fileListProvider = FutureProvider.family<List<FileModel>, String>((
  ref,
  path,
) async {
  final directory = Directory(path);
  if (!await directory.exists()) {
    return [];
  }

  final List<FileSystemEntity> entities = await directory.list().toList();
  final List<FileModel> files = [];

  for (var entity in entities) {
    try {
      files.add(FileModel.fromFileSystemEntity(entity));
    } catch (e) {
      // Skip files that can't be accessed
    }
  }

  // Sort: Directories first, then alphabetically
  files.sort((a, b) {
    if (a.isDirectory && !b.isDirectory) return -1;
    if (!a.isDirectory && b.isDirectory) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return files;
});
