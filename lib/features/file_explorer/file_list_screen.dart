import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/models/file_model.dart';
import 'package:file_explorer_apk/services/file_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

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

    try {
      final files = _selectedFiles.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        files,
        text: 'Sharing ${_selectedFiles.length} file(s)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing files: $e')));
      }
    }
  }

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
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: file.isDirectory
                        ? Colors.blue.withOpacity(0.1)
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
        trailing: file.isDirectory
            ? const Icon(Icons.chevron_right)
            : Text(
                DateFormat('dd MMM yyyy').format(file.lastModified),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
