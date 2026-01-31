import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/services/viewer_launcher.dart';

class FileSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _search(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _search(context);
  }

  Widget _search(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters to search'));
    }

    return FutureBuilder<List<FileModel>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return const Center(child: Text('No files found'));
        }

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              leading: Icon(
                file.isDirectory ? Icons.folder : Icons.insert_drive_file,
              ),
              title: Text(file.name),
              subtitle: Text(file.path),
              onTap: () async {
                if (!context.mounted) return;
                if (file.isDirectory) {
                  // TODO: consider navigating to directory view.
                } else {
                  await ViewerLauncher.openFile(context, file);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<FileModel>> _performSearch(String query) async {
    final dir = Directory('/storage/emulated/0');
    List<FileModel> results = [];
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity.path.toLowerCase().contains(query.toLowerCase())) {
          results.add(FileModel.fromFileSystemEntity(entity));
        }
        if (results.length > 50) break; // Limit results for performance
      }
    } catch (_) {}
    return results;
  }
}
