import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/category_provider.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'dart:math' as math;

class CategoryFileListScreen extends ConsumerWidget {
  final String title;
  final String type;

  const CategoryFileListScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(categoryFilesProvider(type));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: filesAsync.when(
        data: (files) => _buildFileList(context, files),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning files...'),
            ],
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<FileModel> files) {
    if (files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: _getCategoryIcon(type),
          title: Text(file.name),
          subtitle: Text(
            '${_formatSize(file.size)} • ${DateFormat('dd MMM yyyy').format(file.lastModified)}',
          ),
          onTap: () => OpenFile.open(file.path),
        );
      },
    );
  }

  Widget _getCategoryIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'images':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case 'videos':
        icon = Icons.videocam;
        color = Colors.orange;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        color = Colors.teal;
        break;
      case 'documents':
        icon = Icons.description;
        color = Colors.indigo;
        break;
      case 'apks':
        icon = Icons.android;
        color = Colors.green;
        break;
      case 'downloads':
        icon = Icons.download;
        color = Colors.blue;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Icon(icon, color: color);
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
