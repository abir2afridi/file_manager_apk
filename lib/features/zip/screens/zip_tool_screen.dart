import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'package:file_explorer_apk/providers/theme_provider.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/services/zip_service.dart';

class ZipToolScreen extends ConsumerStatefulWidget {
  const ZipToolScreen({super.key});

  @override
  ConsumerState<ZipToolScreen> createState() => _ZipToolScreenState();
}

class _ZipToolScreenState extends ConsumerState<ZipToolScreen> {
  final List<_SelectedItem> _selectedSources = [];
  final TextEditingController _archiveNameController = TextEditingController(
    text: 'archive',
  );

  String? _compressionTargetDir;
  String? _zipFileForExtraction;
  String? _extractionTargetDir;

  ZipOperation? _activeOperation;
  ZipOperation? _lastOperation;
  ZipProgressStatus? _progressStatus;
  double _progressValue = 0;
  String _progressMessage = 'Idle';
  String? _outputPath;
  String? _errorMessage;

  StreamSubscription<ZipProgress>? _subscription;

  bool get _isRunning =>
      _activeOperation != null && _progressStatus == ZipProgressStatus.running;

  @override
  void dispose() {
    _subscription?.cancel();
    _archiveNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP toolkit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            'Compression',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildCompressionCard(accentColor, theme),
          const SizedBox(height: 32),
          Text(
            'Extraction',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildExtractionCard(accentColor, theme),
          const SizedBox(height: 32),
          _buildProgressSection(theme),
        ],
      ),
    );
  }

  Widget _buildCompressionCard(Color accentColor, ThemeData theme) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.colorScheme.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? null : _pickFilesForCompression,
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Add files'),
                ),
                FilledButton.icon(
                  onPressed: _isRunning ? null : _pickFolderForCompression,
                  icon: const Icon(Icons.folder_zip_rounded),
                  label: const Text('Add folder'),
                ),
                FilledButton.icon(
                  onPressed: _isRunning
                      ? null
                      : _pickCompressionTargetDirectory,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Target folder'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedSources.isEmpty)
              Text(
                'No sources selected yet. Add files or a folder to compress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected sources', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in _selectedSources)
                        Chip(
                          avatar: Icon(
                            item.isDirectory
                                ? Icons.folder_rounded
                                : Icons.insert_drive_file_rounded,
                            size: 18,
                          ),
                          label: Text(p.basename(item.path)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: _isRunning
                              ? null
                              : () => setState(() {
                                  _selectedSources.remove(item);
                                }),
                        ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _archiveNameController,
              enabled: !_isRunning,
              decoration: const InputDecoration(
                labelText: 'Archive name',
                helperText: 'Saved as <name>.zip in the target folder',
              ),
            ),
            const SizedBox(height: 12),
            if (_compressionTargetDir != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _compressionTargetDir!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear target',
                    onPressed: _isRunning
                        ? null
                        : () => setState(() {
                            _compressionTargetDir = null;
                          }),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.compress_rounded),
                label: const Text('Start compression'),
                onPressed: _isRunning ? null : _startCompression,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionCard(Color accentColor, ThemeData theme) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.colorScheme.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? null : _pickZipFile,
                  icon: const Icon(Icons.archive_rounded),
                  label: const Text('Select ZIP'),
                ),
                FilledButton.icon(
                  onPressed: _isRunning ? null : _pickExtractionTargetDirectory,
                  icon: const Icon(Icons.outbox_rounded),
                  label: const Text('Destination'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_zipFileForExtraction != null)
              ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: accentColor.withValues(alpha: 0.9),
                ),
                title: Text(p.basename(_zipFileForExtraction!)),
                subtitle: Text(_zipFileForExtraction!),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isRunning
                      ? null
                      : () => setState(() => _zipFileForExtraction = null),
                ),
              )
            else
              Text(
                'Choose a ZIP archive to extract.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            if (_extractionTargetDir != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _extractionTargetDir!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isRunning
                        ? null
                        : () => setState(() => _extractionTargetDir = null),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.unarchive_rounded),
                label: const Text('Start extraction'),
                onPressed: _isRunning ? null : _startExtraction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final status = _progressStatus;
    if (status == null) {
      return const SizedBox.shrink();
    }

    final operation = _activeOperation ?? _lastOperation;
    final bool isRunning = status == ZipProgressStatus.running;

    IconData leadingIcon;
    Color iconColor;

    if (status == ZipProgressStatus.success) {
      leadingIcon = Icons.check_circle_rounded;
      iconColor = theme.colorScheme.primary;
    } else if (status == ZipProgressStatus.error) {
      leadingIcon = Icons.error_outline_rounded;
      iconColor = theme.colorScheme.error;
    } else {
      leadingIcon = operation == ZipOperation.extract
          ? Icons.unarchive_rounded
          : Icons.compress_rounded;
      iconColor = theme.colorScheme.primary;
    }

    final title = () {
      if (isRunning) {
        return operation == ZipOperation.extract ? 'Extracting' : 'Compressing';
      }
      if (status == ZipProgressStatus.success) {
        return 'Completed';
      }
      if (status == ZipProgressStatus.error) {
        return 'Failed';
      }
      return 'Processing';
    }();

    final progressValue =
        status == ZipProgressStatus.success || status == ZipProgressStatus.error
        ? 1.0
        : _progressValue.clamp(0.0, 1.0);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.colorScheme.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(leadingIcon, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isRunning)
                  TextButton.icon(
                    onPressed: _cancelCurrentOperation,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Cancel'),
                  )
                else
                  TextButton.icon(
                    onPressed: _clearProgress,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Dismiss'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 12),
            Text(_progressMessage, style: theme.textTheme.bodyMedium),
            if (status == ZipProgressStatus.error && _errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (status == ZipProgressStatus.success && _outputPath != null) ...[
              const SizedBox(height: 12),
              SelectableText(_outputPath!, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy path'),
                    onPressed: _copyOutputPath,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilesForCompression() async {
    try {
      final files = await openFiles(
        acceptedTypeGroups: const [XTypeGroup(label: 'Any')],
      );
      if (files.isEmpty) return;
      setState(() {
        for (final file in files) {
          if (_selectedSources.any((item) => item.path == file.path)) {
            continue;
          }
          _selectedSources.add(_SelectedItem(file.path, false));
        }
      });
    } catch (e) {
      _notify('Unable to pick files: $e');
    }
  }

  Future<void> _pickFolderForCompression() async {
    try {
      final directoryPath = await getDirectoryPath();
      if (directoryPath == null) return;
      if (_selectedSources.any((item) => item.path == directoryPath)) {
        _notify('Folder already selected.');
        return;
      }
      setState(() {
        _selectedSources.add(_SelectedItem(directoryPath, true));
      });
    } catch (e) {
      _notify('Unable to pick folder: $e');
    }
  }

  Future<void> _pickCompressionTargetDirectory() async {
    try {
      final directoryPath = await getDirectoryPath();
      if (directoryPath == null) return;
      setState(() {
        _compressionTargetDir = directoryPath;
      });
    } catch (e) {
      _notify('Unable to select destination: $e');
    }
  }

  Future<void> _pickZipFile() async {
    try {
      final zip = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'ZIP archives', extensions: ['zip']),
        ],
      );
      if (zip == null) return;
      setState(() {
        _zipFileForExtraction = zip.path;
      });
    } catch (e) {
      _notify('Unable to pick ZIP file: $e');
    }
  }

  Future<void> _pickExtractionTargetDirectory() async {
    try {
      final directory = await getDirectoryPath();
      if (directory == null) return;
      setState(() {
        _extractionTargetDir = directory;
      });
    } catch (e) {
      _notify('Unable to select destination: $e');
    }
  }

  Future<void> _startCompression() async {
    if (_selectedSources.isEmpty) {
      _notify('Select at least one file or folder to compress.');
      return;
    }
    if (_compressionTargetDir == null) {
      _notify('Select a target folder to save the archive.');
      return;
    }
    final archiveName = _archiveNameController.text.trim();
    if (archiveName.isEmpty) {
      _notify('Provide a name for the archive.');
      return;
    }

    final granted = await _ensureStoragePermission();
    if (!granted) {
      _notify('Storage permission is required.');
      return;
    }

    final sanitizedName = archiveName.endsWith('.zip')
        ? archiveName
        : '$archiveName.zip';
    final destination = p.join(_compressionTargetDir!, sanitizedName);

    _beginOperation(ZipOperation.compress);

    final stream = ZipService.compress(
      sources: _selectedSources.map((item) => item.path).toList(),
      destination: destination,
    );

    _subscription = stream.listen(
      (progress) {
        setState(() {
          _progressStatus = progress.status;
          _progressValue = progress.progress;
          _progressMessage = progress.message;
          _outputPath = progress.outputPath;
          _errorMessage = progress.error;
        });
        if (progress.status == ZipProgressStatus.success) {
          _notify('Archive created at ${progress.outputPath}');
        }
        if (progress.status != ZipProgressStatus.running) {
          _onOperationFinished();
        }
      },
      onError: (error, stackTrace) {
        setState(() {
          _progressStatus = ZipProgressStatus.error;
          _progressMessage = 'Compression failed';
          _errorMessage = error.toString();
        });
        _onOperationFinished();
        _notify('Compression failed: $error');
      },
    );
  }

  Future<void> _startExtraction() async {
    if (_zipFileForExtraction == null) {
      _notify('Select a ZIP archive first.');
      return;
    }
    if (_extractionTargetDir == null) {
      _notify('Select a destination folder.');
      return;
    }

    final granted = await _ensureStoragePermission();
    if (!granted) {
      _notify('Storage permission is required.');
      return;
    }

    _beginOperation(ZipOperation.extract);

    final stream = ZipService.extract(
      zipPath: _zipFileForExtraction!,
      destinationDirectory: _extractionTargetDir!,
    );

    _subscription = stream.listen(
      (progress) {
        setState(() {
          _progressStatus = progress.status;
          _progressValue = progress.progress;
          _progressMessage = progress.message;
          _outputPath = progress.outputPath;
          _errorMessage = progress.error;
        });
        if (progress.status == ZipProgressStatus.success) {
          _notify('Archive extracted to ${progress.outputPath}');
        }
        if (progress.status != ZipProgressStatus.running) {
          _onOperationFinished();
        }
      },
      onError: (error, stackTrace) {
        setState(() {
          _progressStatus = ZipProgressStatus.error;
          _progressMessage = 'Extraction failed';
          _errorMessage = error.toString();
        });
        _onOperationFinished();
        _notify('Extraction failed: $error');
      },
    );
  }

  void _beginOperation(ZipOperation operation) {
    _subscription?.cancel();
    setState(() {
      _activeOperation = operation;
      _lastOperation = operation;
      _progressStatus = ZipProgressStatus.running;
      _progressValue = 0;
      _progressMessage = operation == ZipOperation.compress
          ? 'Starting...'
          : 'Starting...';
      _errorMessage = null;
      _outputPath = null;
    });
  }

  void _onOperationFinished() {
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _activeOperation = null;
    });
  }

  Future<void> _cancelCurrentOperation() async {
    await _subscription?.cancel();
    _subscription = null;
    setState(() {
      _activeOperation = null;
      _progressStatus = ZipProgressStatus.error;
      _progressMessage = 'Cancelled by user';
      _errorMessage = null;
    });
  }

  void _clearProgress() {
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _activeOperation = null;
      _progressStatus = null;
      _progressValue = 0;
      _progressMessage = 'Idle';
      _outputPath = null;
      _errorMessage = null;
    });
  }

  Future<bool> _ensureStoragePermission() async {
    return PermissionService.requestStoragePermission();
  }

  Future<void> _copyOutputPath() async {
    final path = _outputPath;
    if (path == null) return;
    await Clipboard.setData(ClipboardData(text: path));
    _notify('Path copied to clipboard');
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedItem {
  final String path;
  final bool isDirectory;

  _SelectedItem(this.path, this.isDirectory);
}
