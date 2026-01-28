import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/services/file_service.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileListScreen extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const FileListScreen({super.key, required this.title, required this.path});

  @override
  ConsumerState<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends ConsumerState<FileListScreen> {
  String _currentPath = '';
  List<FileModel> _files = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, size, date
  final Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await FileService.getFilesInDirectory(_currentPath);
      _sortFiles(files);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
      }
    }
  }

  void _sortFiles(List<FileModel> files) {
    switch (_sortBy) {
      case 'name':
        files.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'size':
        files.sort((a, b) => b.size.compareTo(a.size));
        break;
      case 'date':
        files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
    }
  }

  void _navigateToDirectory(FileModel file) {
    setState(() {
      _currentPath = file.path;
      _selectedFiles.clear();
      _isSelectionMode = false;
    });
    _loadFiles();
  }

  void _navigateBack() {
    final parent = File(_currentPath).parent;
    if (parent.path != _currentPath) {
      setState(() {
        _currentPath = parent.path;
        _selectedFiles.clear();
        _isSelectionMode = false;
      });
      _loadFiles();
    }
  }

  Future<void> _openFile(FileModel file) async {
    try {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  void _toggleSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(filePath);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedFiles.clear();
      _selectedFiles.addAll(_files.map((file) => file.path));
      _isSelectionMode = true;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFiles.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _shareSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;
    await _sharePaths(_selectedFiles.toList());
  }

  Future<void> _sharePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    final existingPaths = paths
        .where((path) => File(path).existsSync())
        .toList();
    if (existingPaths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected items are no longer available.'),
        ),
      );
      return;
    }
    final missingCount = paths.length - existingPaths.length;
    if (missingCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$missingCount item(s) could not be found.')),
      );
    }
    try {
      final files = existingPaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(files, text: 'Sharing ${files.length} item(s)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing items: $e')));
    }
  }

  void _showActionPending(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
  }

  Future<void> _handleFolderAction(String action, FileModel file) async {
    switch (action) {
      case 'select':
        _toggleSelection(file.path);
        break;
      case 'quick_share':
        await _quickShareFolder(file);
        break;
      case 'move_to':
        _showActionPending('Move to');
        break;
      case 'copy_to':
        _showActionPending('Copy to');
        break;
      case 'rename':
        _showActionPending('Rename');
        break;
      case 'compress':
        _showActionPending('Compress');
        break;
      case 'delete':
        await _deleteEntry(file);
        break;
      case 'info':
        _showFolderInfo(file);
        break;
      default:
        _showActionPending(action);
    }
  }

  void _handleFileAction(String action, FileModel file) async {
    switch (action) {
      case 'select':
        _toggleSelection(file.path);
        break;
      case 'share':
        await _sharePaths([file.path]);
        break;
      case 'move_to':
        _showActionPending('Move to');
        break;
      case 'copy_to':
        _showActionPending('Copy to');
        break;
      case 'add_starred':
        _showActionPending('Add to Starred');
        break;
      case 'move_trash':
        _showActionPending('Move to trash');
        break;
      case 'move_safe':
        _showActionPending('Move to safe folder');
        break;
      case 'backup_drive':
        _showActionPending('Back up to Google Drive');
        break;
      case 'rename':
        _showActionPending('Rename');
        break;
      case 'compress':
        _showActionPending('Compress');
        break;
      case 'delete':
        await _deleteEntry(file);
        break;
      case 'info':
        _showFileInfo(file);
        break;
      default:
        _showActionPending(action);
    }
  }

  Future<void> _deleteEntry(FileModel file) async {
    final shouldDelete = await _confirmDeletion(file);
    if (!shouldDelete) return;
    try {
      bool success = false;
      if (file.isDirectory) {
        success = await FileService.deleteDirectory(file.path);
      } else {
        success = await FileService.deleteFile(file.path);
      }
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete ${file.name}')),
        );
        return;
      }
      _selectedFiles.remove(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${file.name} deleted')));
      await _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ${file.name}: $e')),
      );
    }
  }

  Future<bool> _confirmDeletion(FileModel file) async {
    if (!mounted) return false;
    final descriptor = file.isDirectory ? 'folder' : 'file';
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete permanently'),
            content: Text(
              'Are you sure you want to delete the $descriptor "${file.name}" permanently?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showFolderInfo(FileModel file) {
    if (!mounted) return;
    final sizeFuture = FileService.getDirectorySize(file.path);
    showDialog<void>(
      context: context,
      builder: (_) => FutureBuilder<int>(
        future: sizeFuture,
        builder: (context, snapshot) {
          Widget sizeWidget;
          if (snapshot.hasError) {
            sizeWidget = Text(
              'Size: Unable to calculate',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          } else if (!snapshot.hasData) {
            sizeWidget = const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Size: '),
                SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            );
          } else {
            sizeWidget = Text('Size: ${_formatFileSize(snapshot.data ?? 0)}');
          }

          return AlertDialog(
            title: const Text('Folder info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${file.name}'),
                const SizedBox(height: 8),
                Text('Path: ${file.path}'),
                const SizedBox(height: 8),
                Text('Items: ${file.itemCount ?? 'Unknown'}'),
                const SizedBox(height: 8),
                sizeWidget,
                const SizedBox(height: 8),
                Text(
                  'Last modified: ${DateFormat('dd MMM yyyy, HH:mm').format(file.lastModified)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _quickShareFolder(FileModel folder) async {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogVisible = false;

    try {
      dialogVisible = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _ProgressDialog(message: 'Preparing folder...'),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = _sanitizeFileName(folder.name);
      final zipTarget = p.join(
        tempDir.path,
        '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.zip',
      );

      final zipPath = await compute(_zipFolder, {
        'source': folder.path,
        'zip': zipTarget,
      });

      if (dialogVisible && navigator.mounted) {
        navigator.pop();
        dialogVisible = false;
      }

      await Share.shareXFiles([
        XFile(zipPath),
      ], text: 'Sharing folder "${folder.name}"');

      await File(zipPath).delete().catchError((_) {});
    } catch (e) {
      if (dialogVisible && navigator.mounted) {
        navigator.pop();
        dialogVisible = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Quick share failed: $e')));
    }
  }

  String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'folder' : sanitized;
  }

  void _showFileInfo(FileModel file) {
    if (!mounted) return;
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
            Text('Size: ${_formatFileSize(file.size)}'),
            const SizedBox(height: 8),
            Text(
              'Modified: ${DateFormat('dd MMM yyyy, HH:mm').format(file.lastModified)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${file.extension.isEmpty ? 'Unknown' : file.extension}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _folderMenuItems() => const [
    PopupMenuItem(value: 'select', child: Text('Select')),
    PopupMenuItem(value: 'quick_share', child: Text('Quick share')),
    PopupMenuItem(value: 'move_to', child: Text('Move to')),
    PopupMenuItem(value: 'copy_to', child: Text('Copy to')),
    PopupMenuItem(value: 'rename', child: Text('Rename')),
    PopupMenuItem(value: 'compress', child: Text('Compress')),
    PopupMenuItem(value: 'delete', child: Text('Delete permanently')),
    PopupMenuItem(value: 'info', child: Text('Folder info')),
  ];

  List<PopupMenuEntry<String>> _fileMenuItems() => const [
    PopupMenuItem(value: 'select', child: Text('Select')),
    PopupMenuItem(value: 'share', child: Text('Share')),
    PopupMenuItem(value: 'move_to', child: Text('Move to')),
    PopupMenuItem(value: 'copy_to', child: Text('Copy to')),
    PopupMenuItem(value: 'add_starred', child: Text('Add to Starred')),
    PopupMenuItem(value: 'move_trash', child: Text('Move to trash')),
    PopupMenuItem(value: 'move_safe', child: Text('Move to safe folder')),
    PopupMenuItem(
      value: 'backup_drive',
      child: Text('Back up to Google Drive'),
    ),
    PopupMenuItem(value: 'rename', child: Text('Rename')),
    PopupMenuItem(value: 'compress', child: Text('Compress')),
    PopupMenuItem(value: 'delete', child: Text('Delete permanently')),
    PopupMenuItem(value: 'info', child: Text('File info')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedFiles.length} selected' : widget.title,
        ),
        leading: _currentPath != widget.path
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
              )
            : _isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _deselectAll)
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectedFiles.length < _files.length
                  ? _selectAll
                  : _deselectAll,
              tooltip: 'Select all',
            ),
            if (_selectedFiles.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareSelectedFiles,
                tooltip: 'Share selected',
              ),
          ] else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
                _sortFiles(_files);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'name', child: Text('Sort by name')),
                const PopupMenuItem(value: 'size', child: Text('Sort by size')),
                const PopupMenuItem(value: 'date', child: Text('Sort by date')),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'This folder is empty',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : _isGridView
          ? _buildGridView()
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFiles.contains(file.path);
        return _buildFileTile(file, isSelected);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFiles.contains(file.path);
        return _buildGridItem(file, isSelected);
      },
    );
  }

  Widget _buildGridItem(FileModel file, bool isSelected) {
    return Card(
      elevation: isSelected ? 6 : 2,
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(file.path);
          } else {
            if (file.isDirectory) {
              _navigateToDirectory(file);
            } else {
              _openFile(file);
            }
          }
        },
        onLongPress: () {
          _toggleSelection(file.path);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) => file.isDirectory
                      ? _handleFolderAction(value, file)
                      : _handleFileAction(value, file),
                  itemBuilder: (_) =>
                      file.isDirectory ? _folderMenuItems() : _fileMenuItems(),
                ),
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: file.isDirectory
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      file.isDirectory
                          ? Icons.folder
                          : _getFileIcon(file.extension),
                      color: file.isDirectory ? Colors.blue : Colors.grey[700],
                      size: 32,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  file.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.blue : null,
                  ),
                ),
              ),
              if (!file.isDirectory)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatFileSize(file.size),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTile(FileModel file, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: file.isDirectory ? Colors.blue : Colors.grey[300],
          child: Stack(
            children: [
              Center(
                child: Icon(
                  file.isDirectory
                      ? Icons.folder
                      : _getFileIcon(file.extension),
                  color: file.isDirectory ? Colors.white : Colors.grey[700],
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          file.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: file.isDirectory
            ? Text('${file.itemCount ?? 0} items')
            : Text(_formatFileSize(file.size)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!file.isDirectory)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  DateFormat('dd MMM yyyy').format(file.lastModified),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => file.isDirectory
                  ? _handleFolderAction(value, file)
                  : _handleFileAction(value, file),
              itemBuilder: (_) =>
                  file.isDirectory ? _folderMenuItems() : _fileMenuItems(),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(file.path);
          } else {
            if (file.isDirectory) {
              _navigateToDirectory(file);
            } else {
              _openFile(file);
            }
          }
        },
        onLongPress: () {
          _toggleSelection(file.path);
        },
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mkv':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
        return Icons.audio_file;
      case '.apk':
        return Icons.android;
      case '.zip':
      case '.rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ProgressDialog extends StatelessWidget {
  final String message;

  const _ProgressDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _zipFolder(Map<String, String> params) {
  final source = params['source']!;
  final zipPath = params['zip']!;

  final encoder = ZipFileEncoder();
  if (File(zipPath).existsSync()) {
    File(zipPath).deleteSync();
  }
  encoder.create(zipPath);
  encoder.addDirectory(Directory(source), includeDirName: true);
  encoder.close();

  return zipPath;
}
