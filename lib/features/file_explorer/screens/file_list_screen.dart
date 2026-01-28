import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/file_provider.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/providers/clipboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class FileListScreen extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const FileListScreen({super.key, required this.title, required this.path});

  @override
  ConsumerState<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends ConsumerState<FileListScreen> {
  bool _isGridView = false;
  bool _hasPermission = false;
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionService.requestStoragePermission();
    setState(() {
      _hasPermission = granted;
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPaths.add(path);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPaths.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Storage permission is required'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    final filesAsync = ref.watch(fileListProvider(widget.path));
    final clipboard = ref.watch(clipboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: Text(
          _isSelectionMode ? '${_selectedPaths.length} selected' : widget.title,
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    final paths = _selectedPaths.toList();
                    Share.shareXFiles(paths.map((p) => XFile(p)).toList());
                    _clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _bulkDelete,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
      ),
      body: filesAsync.when(
        data: (files) => _buildFileList(files),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: clipboard != null && !_isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _pasteFile(clipboard),
              label: Text(
                clipboard.action == ClipboardAction.copy
                    ? 'Paste'
                    : 'Move here',
              ),
              icon: const Icon(Icons.paste),
            )
          : null,
    );
  }

  Widget _buildFileList(List<FileModel> files) {
    if (files.isEmpty) {
      return const Center(child: Text('Empty folder'));
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) => _buildFileItem(files[index], true),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) => _buildFileItem(files[index], false),
    );
  }

  Widget _buildFileItem(FileModel file, bool isGrid) {
    final isSelected = _selectedPaths.contains(file.path);
    final icon = file.isDirectory ? Icons.folder : _getFileIcon(file.extension);
    final color = file.isDirectory ? Colors.amber : Colors.blue;

    if (isGrid) {
      return InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(file.path);
          } else {
            _onFileTap(file);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelection(file.path);
          } else {
            _onFileLongPress(file);
          }
        },
        child: Container(
          color: isSelected
              ? Colors.blue.withAlpha(51)
              : null, // 0.2 * 255 = 51
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 48, color: color),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                file.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      selected: isSelected,
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          if (isSelected)
            const Icon(Icons.check_circle, color: Colors.blue, size: 20),
        ],
      ),
      title: Text(file.name),
      subtitle: Text(
        '${file.isDirectory ? '' : _formatSize(file.size)} • ${DateFormat('dd MMM yyyy').format(file.lastModified)}',
      ),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(file.path);
        } else {
          _onFileTap(file);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelection(file.path);
        } else {
          _onFileLongPress(file);
        }
      },
      trailing: _isSelectionMode
          ? null
          : IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _onFileLongPress(file),
            ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.mp4':
      case '.mkv':
      case '.avi':
        return Icons.videocam;
      case '.mp3':
      case '.wav':
      case '.m4a':
        return Icons.audiotrack;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.apk':
        return Icons.android;
      case '.zip':
      case '.rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _onFileTap(FileModel file) {
    if (file.isDirectory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FileListScreen(title: file.name, path: file.path),
        ),
      );
    } else {
      OpenFile.open(file.path);
    }
  }

  void _onFileLongPress(FileModel file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(file.path)]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Navigator.pop(context);
              ref.read(clipboardProvider.notifier).copy(file);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File copied to clipboard')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: const Text('Move'),
            onTap: () {
              Navigator.pop(context);
              ref.read(clipboardProvider.notifier).move(file);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File marked for move')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _renameFile(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Details'),
            onTap: () {
              Navigator.pop(context);
              _showDetails(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteFile(file);
            },
          ),
        ],
      ),
    );
  }

  void _showDetails(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file.name}'),
            Text('Path: ${file.path}'),
            Text('Size: ${_formatSize(file.size)}'),
            Text(
              'Modified: ${DateFormat('dd MMM yyyy HH:mm').format(file.lastModified)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _renameFile(FileModel file) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == file.name) {
                Navigator.pop(context);
                return;
              }

              final newPath = p.join(p.dirname(file.path), newName);
              try {
                if (file.isDirectory) {
                  await Directory(file.path).rename(newPath);
                } else {
                  await File(file.path).rename(newPath);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                final _ = ref.refresh(fileListProvider(widget.path));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error renaming: $e')));
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteFile(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (file.isDirectory) {
                  await Directory(file.path).delete(recursive: true);
                } else {
                  await File(file.path).delete();
                }
                if (!context.mounted) return;
                final _ = ref.refresh(fileListProvider(widget.path));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _bulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete ${_selectedPaths.length} items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final paths = _selectedPaths.toList();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                for (final path in paths) {
                  final type = await FileSystemEntity.type(path);
                  if (type == FileSystemEntityType.directory) {
                    await Directory(path).delete(recursive: true);
                  } else if (type == FileSystemEntityType.file) {
                    await File(path).delete();
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error during bulk delete: $e')),
                  );
                }
              }

              if (!context.mounted) return;
              Navigator.pop(context); // Close loading dialog
              _clearSelection();
              final _ = ref.refresh(fileListProvider(widget.path));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _pasteFile(ClipboardData data) async {
    final sourcePath = data.file.path;
    final destPath = p.join(widget.path, data.file.name);

    if (sourcePath == destPath) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination are same')),
      );
      return;
    }

    try {
      if (data.action == ClipboardAction.copy) {
        if (data.file.isDirectory) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder copy not yet supported')),
          );
          return;
        } else {
          await File(sourcePath).copy(destPath);
        }
      } else {
        if (data.file.isDirectory) {
          await Directory(sourcePath).rename(destPath);
        } else {
          await File(sourcePath).rename(destPath);
        }
      }

      ref.read(clipboardProvider.notifier).clear();
      final _ = ref.refresh(fileListProvider(widget.path));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data.action == ClipboardAction.copy ? 'File copied' : 'File moved',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
