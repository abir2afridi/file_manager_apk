import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/features/file_explorer/screens/file_list_screen.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/providers/category_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/widgets/folder_icon.dart';
import 'package:file_explorer_apk/widgets/file_icon.dart';
import 'package:file_explorer_apk/services/viewer_launcher.dart';

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
    final visual = _visualForType(type);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: filesAsync.when(
        data: (files) => _buildFileList(context, files, visual),
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

  Widget _buildFileList(
    BuildContext context,
    List<FileModel> files,
    _CategoryVisual visual,
  ) {
    if (files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    final totalSize = files
        .where((file) => !file.isDirectory)
        .fold<int>(0, (sum, file) => sum + file.size);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      itemCount: files.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CategorySummaryCard(
            title: title,
            itemCount: files.length,
            totalSize: totalSize,
            accentColor: visual.color,
            icon: visual.icon,
          );
        }

        final file = files[index - 1];
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _CategoryFileTile(
            file: file,
            accentColor: visual.color,
            onTap: () => _openEntry(context, file),
            onAction: (action) => _handleAction(context, file, action),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    FileModel file,
    _CategoryFileAction action,
  ) async {
    switch (action) {
      case _CategoryFileAction.open:
        await _openEntry(context, file);
        break;
      case _CategoryFileAction.share:
        await _shareFile(context, file);
        break;
      case _CategoryFileAction.info:
        _showInfoDialog(context, file);
        break;
      case _CategoryFileAction.location:
        await _openLocation(context, file);
        break;
    }
  }

  Future<void> _openEntry(BuildContext context, FileModel file) async {
    if (file.isDirectory) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileListScreen(title: file.name, path: file.path),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await ViewerLauncher.openFile(context, file);
  }

  Future<void> _openLocation(BuildContext context, FileModel file) async {
    final parentPath = File(file.path).parent.path;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FileListScreen(title: p.basename(parentPath), path: parentPath),
      ),
    );
  }

  Future<void> _shareFile(BuildContext context, FileModel file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Sharing ${file.name}');
    } catch (err) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share ${file.name}: $err')),
      );
    }
  }

  void _showInfoDialog(BuildContext context, FileModel file) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('File info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file.name}'),
            const SizedBox(height: 8),
            Text('Path: ${file.path}'),
            const SizedBox(height: 8),
            if (!file.isDirectory) Text('Size: ${_formatSize(file.size)}'),
            if (!file.isDirectory) const SizedBox(height: 8),
            Text(
              'Modified: ${DateFormat('dd MMM yyyy, HH:mm').format(file.lastModified)}',
            ),
            if (file.isDirectory) ...[
              const SizedBox(height: 8),
              Text('Items: ${file.itemCount ?? 'Unknown'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: theme.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

enum _CategoryFileAction { open, share, info, location }

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual(this.icon, this.color);
}

_CategoryVisual _visualForType(String type) {
  switch (type) {
    case 'images':
      return const _CategoryVisual(Icons.image, Colors.purple);
    case 'videos':
      return const _CategoryVisual(Icons.videocam, Colors.orange);
    case 'audio':
      return const _CategoryVisual(Icons.audiotrack, Colors.teal);
    case 'documents':
      return const _CategoryVisual(Icons.description, Colors.indigo);
    case 'apks':
      return const _CategoryVisual(Icons.android, Colors.green);
    case 'downloads':
      return const _CategoryVisual(Icons.download, Colors.blue);
    default:
      return const _CategoryVisual(Icons.insert_drive_file, Colors.pink);
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final int totalSize;
  final Color accentColor;
  final IconData icon;

  const _CategorySummaryCard({
    required this.title,
    required this.itemCount,
    required this.totalSize,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: onAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: onAccent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onAccent.withValues(alpha: 0.85),
                  ),
                ),
                if (totalSize > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total size • ${_formatSize(totalSize)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onAccent.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFileTile extends StatelessWidget {
  final FileModel file;
  final Color accentColor;
  final VoidCallback onTap;
  final Future<void> Function(_CategoryFileAction action) onAction;

  const _CategoryFileTile({
    required this.file,
    required this.accentColor,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDir = file.isDirectory;
    final icon = isDir ? Icons.folder_rounded : _iconForFile(file.extension);
    final iconColor = isDir ? accentColor : _getFileColor(file.extension);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              isDir
                  ? FolderIcon(baseColor: iconColor, glyph: icon, size: 40)
                  : FileIcon(baseColor: iconColor, glyph: icon, size: 40),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isDir
                          ? '${file.itemCount ?? 0} items'
                          : '${_formatSize(file.size)} • ${DateFormat('dd MMM yyyy').format(file.lastModified)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_CategoryFileAction>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _CategoryFileAction.open,
                    child: Text('Open'),
                  ),
                  if (!isDir)
                    const PopupMenuItem(
                      value: _CategoryFileAction.share,
                      child: Text('Share'),
                    ),
                  if (!isDir)
                    const PopupMenuItem(
                      value: _CategoryFileAction.location,
                      child: Text('Open location'),
                    ),
                  const PopupMenuItem(
                    value: _CategoryFileAction.info,
                    child: Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getFileColor(String ext) {
  switch (ext.toLowerCase()) {
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.webp':
      return Colors.purple;
    case '.mp4':
    case '.mkv':
    case '.avi':
    case '.mov':
      return Colors.red;
    case '.mp3':
    case '.wav':
    case '.m4a':
    case '.flac':
      return Colors.teal;
    case '.pdf':
      return Colors.orange;
    case '.apk':
      return Colors.green;
    case '.zip':
    case '.rar':
    case '.7z':
    case '.tar':
      return Colors.indigo;
    case '.txt':
    case '.doc':
    case '.docx':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

IconData _iconForFile(String extension) {
  switch (extension.toLowerCase()) {
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.webp':
      return Icons.image_rounded;
    case '.mp4':
    case '.mkv':
    case '.avi':
    case '.mov':
      return Icons.movie_rounded;
    case '.mp3':
    case '.wav':
    case '.m4a':
    case '.flac':
      return Icons.music_note_rounded;
    case '.pdf':
      return Icons.picture_as_pdf_rounded;
    case '.apk':
      return Icons.android_rounded;
    case '.zip':
    case '.rar':
    case '.7z':
    case '.tar':
      return Icons.inventory_2_rounded;
    case '.txt':
    case '.doc':
    case '.docx':
      return Icons.description_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(1024)).floor();
  final value = bytes / math.pow(1024, i);
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${suffixes[i]}';
}
