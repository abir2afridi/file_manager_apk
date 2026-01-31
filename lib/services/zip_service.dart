import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Represents a ZIP operation type.
enum ZipOperation { compress, extract }

/// Status of the ongoing ZIP task.
enum ZipProgressStatus { running, success, error }

/// Progress information emitted during compression or extraction.
class ZipProgress {
  final ZipOperation operation;
  final ZipProgressStatus status;
  final double progress;
  final String message;
  final String? error;
  final String? outputPath;

  const ZipProgress({
    required this.operation,
    required this.status,
    required this.progress,
    required this.message,
    this.error,
    this.outputPath,
  });

  bool get isCompleted => status == ZipProgressStatus.success;
  bool get isError => status == ZipProgressStatus.error;
}

/// A high-level service responsible for compressing and extracting ZIP archives
/// in an isolate to keep the UI responsive.
class ZipService {
  const ZipService._();

  /// Compresses the provided [sources] into a single archive at [destination].
  ///
  /// Emits [ZipProgress] updates with percentage, messages, and completion
  /// state. Any errors are surfaced as progress events with
  /// [ZipProgressStatus.error].
  static Stream<ZipProgress> compress({
    required List<String> sources,
    required String destination,
    int compressionLevel = ZipFileEncoder.gzip,
  }) {
    return _startZipOperation(
      operation: ZipOperation.compress,
      requestBuilder: (sendPort) => _CompressRequest(
        sendPort: sendPort,
        sources: sources,
        destination: destination,
        level: compressionLevel,
      ),
      entryPoint: _compressIsolate,
    );
  }

  /// Extracts the [zipPath] archive into [destinationDirectory].
  static Stream<ZipProgress> extract({
    required String zipPath,
    required String destinationDirectory,
  }) {
    return _startZipOperation(
      operation: ZipOperation.extract,
      requestBuilder: (sendPort) => _ExtractRequest(
        sendPort: sendPort,
        zipPath: zipPath,
        destination: destinationDirectory,
      ),
      entryPoint: _extractIsolate,
    );
  }

  static Stream<ZipProgress> _startZipOperation<T>({
    required ZipOperation operation,
    required T Function(SendPort sendPort) requestBuilder,
    required Future<void> Function(T request) entryPoint,
  }) {
    final controller = StreamController<ZipProgress>();

    final progressPort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    Isolate? isolate;
    var isClosed = false;

    void closeAll() {
      if (isClosed) return;
      isClosed = true;
      progressPort.close();
      errorPort.close();
      exitPort.close();
      controller.close();
      isolate?.kill(priority: Isolate.immediate);
      isolate = null;
    }

    void emitProgress({
      required ZipProgressStatus status,
      required double progress,
      required String message,
      String? error,
      String? outputPath,
    }) {
      if (isClosed) return;
      controller.add(
        ZipProgress(
          operation: operation,
          status: status,
          progress: progress,
          message: message,
          error: error,
          outputPath: outputPath,
        ),
      );
      if (status == ZipProgressStatus.success ||
          status == ZipProgressStatus.error) {
        closeAll();
      }
    }

    progressPort.listen((dynamic message) {
      if (message is! Map) return;
      final map = Map<String, dynamic>.from(message);
      final statusString = map['status'] as String? ?? 'progress';
      final progressValue = (map['progress'] as num?)?.toDouble() ?? 0;
      final messageText = map['message'] as String? ?? '';
      final error = map['error'] as String?;
      final outputPath = map['outputPath'] as String?;

      switch (statusString) {
        case 'progress':
          emitProgress(
            status: ZipProgressStatus.running,
            progress: progressValue,
            message: messageText,
            error: error,
            outputPath: outputPath,
          );
          break;
        case 'complete':
          emitProgress(
            status: ZipProgressStatus.success,
            progress: 1.0,
            message: messageText,
            outputPath: outputPath,
          );
          break;
        case 'error':
          emitProgress(
            status: ZipProgressStatus.error,
            progress: progressValue,
            message: messageText,
            error: error ?? messageText,
          );
          break;
        default:
          emitProgress(
            status: ZipProgressStatus.running,
            progress: progressValue,
            message: messageText,
            error: error,
            outputPath: outputPath,
          );
      }
    });

    errorPort.listen((dynamic errorData) {
      final description = _describeIsolateError(errorData);
      emitProgress(
        status: ZipProgressStatus.error,
        progress: 0,
        message: 'Operation failed',
        error: description,
      );
    });

    exitPort.listen((_) => closeAll());

    Future<void>(() async {
      try {
        isolate = await Isolate.spawn<T>(
          entryPoint,
          requestBuilder(progressPort.sendPort),
          onError: errorPort.sendPort,
          onExit: exitPort.sendPort,
          errorsAreFatal: true,
        );
      } catch (e, stackTrace) {
        debugPrint('Failed to spawn ZIP isolate: $e\n$stackTrace');
        emitProgress(
          status: ZipProgressStatus.error,
          progress: 0,
          message: 'Unable to start operation',
          error: e.toString(),
        );
      }
    });

    controller.onCancel = closeAll;

    return controller.stream;
  }

  static String _describeIsolateError(dynamic errorData) {
    if (errorData is List && errorData.isNotEmpty) {
      return errorData.join('\n');
    }
    return errorData?.toString() ?? 'Unknown error';
  }
}

class _CompressRequest {
  final SendPort sendPort;
  final List<String> sources;
  final String destination;
  final int level;

  const _CompressRequest({
    required this.sendPort,
    required this.sources,
    required this.destination,
    required this.level,
  });
}

class _ExtractRequest {
  final SendPort sendPort;
  final String zipPath;
  final String destination;

  const _ExtractRequest({
    required this.sendPort,
    required this.zipPath,
    required this.destination,
  });
}

class _ZipEntry {
  final String absolutePath;
  final String relativePath;
  final bool isDirectory;
  final int size;
  final int mode;
  final int lastModifiedSeconds;

  const _ZipEntry({
    required this.absolutePath,
    required this.relativePath,
    required this.isDirectory,
    required this.size,
    required this.mode,
    required this.lastModifiedSeconds,
  });
}

Future<void> _compressIsolate(_CompressRequest request) async {
  final sendPort = request.sendPort;
  try {
    final entries = await _collectEntries(request.sources);
    if (entries.isEmpty) {
      throw Exception('No files or folders to compress');
    }

    final totalBytes = entries
        .where((entry) => !entry.isDirectory)
        .fold<int>(0, (sum, entry) => sum + entry.size);
    final hasByteBudget = totalBytes > 0;

    _sendProgress(
      sendPort,
      status: 'progress',
      progress: 0,
      message: 'Preparing files...',
    );

    final output = OutputFileStream(request.destination);
    final encoder = ZipEncoder();
    encoder.startEncode(output, level: request.level);

    var processedBytes = 0;
    var processedEntries = 0;

    for (final entry in entries) {
      if (entry.isDirectory) {
        final archiveDir = ArchiveFile.directory(entry.relativePath);
        archiveDir.mode = entry.mode;
        archiveDir.lastModTime = entry.lastModifiedSeconds;
        encoder.add(archiveDir);

        if (!hasByteBudget) {
          processedEntries++;
          final progress = (processedEntries / entries.length).clamp(0.0, 1.0);
          _sendProgress(
            sendPort,
            status: 'progress',
            progress: progress,
            message: 'Adding folder ${entry.relativePath}',
          );
        }
        continue;
      }

      final inputStream = InputFileStream(entry.absolutePath);
      final archiveFile = ArchiveFile.stream(entry.relativePath, inputStream);
      archiveFile.lastModTime = entry.lastModifiedSeconds;
      archiveFile.mode = entry.mode;

      encoder.add(archiveFile, level: request.level);
      await inputStream.close();

      processedBytes += entry.size;
      if (!hasByteBudget) {
        processedEntries++;
      }
      final progress = hasByteBudget
          ? (processedBytes / totalBytes).clamp(0.0, 1.0)
          : (processedEntries / entries.length).clamp(0.0, 1.0);

      _sendProgress(
        sendPort,
        status: 'progress',
        progress: progress,
        message: 'Compressing ${p.basename(entry.absolutePath)}',
      );
    }

    encoder.endEncode();
    await output.close();

    _sendProgress(
      sendPort,
      status: 'complete',
      progress: 1.0,
      message: 'Archive created successfully',
      outputPath: request.destination,
    );
  } catch (e, stackTrace) {
    debugPrint('ZIP compression error: $e\n$stackTrace');
    _sendProgress(
      sendPort,
      status: 'error',
      progress: 0,
      message: 'Compression failed',
      error: e.toString(),
    );
  }
}

Future<void> _extractIsolate(_ExtractRequest request) async {
  final sendPort = request.sendPort;
  try {
    final zipFile = File(request.zipPath);
    if (!zipFile.existsSync()) {
      throw Exception('ZIP file not found: ${request.zipPath}');
    }

    final destination = Directory(request.destination);
    destination.createSync(recursive: true);

    _sendProgress(
      sendPort,
      status: 'progress',
      progress: 0,
      message: 'Opening archive...',
    );

    final input = InputFileStream(zipFile.path);
    final archive = ZipDecoder().decodeStream(input);
    await input.close();

    final files = archive.files;
    final totalBytes = files
        .where((file) => file.isFile)
        .fold<int>(0, (sum, file) => sum + file.size);
    final hasByteBudget = totalBytes > 0;

    var processedBytes = 0;
    var processedEntries = 0;

    for (final file in files) {
      final sanitizedName = _sanitizeArchivePath(file.name);
      if (sanitizedName.isEmpty) {
        continue;
      }

      final outputPath = p.join(destination.path, sanitizedName);
      final normalizedOutput = p.normalize(outputPath);

      if (!p.isWithin(destination.path, normalizedOutput)) {
        throw Exception('Archive entry escapes destination: ${file.name}');
      }

      if (file.isFile) {
        final outputFile = File(normalizedOutput);
        outputFile.parent.createSync(recursive: true);
        final output = OutputFileStream(outputFile.path);
        file.writeContent(output);
        await output.close();

        processedBytes += file.size;
        if (!hasByteBudget) {
          processedEntries++;
        }
        final progress = hasByteBudget
            ? (processedBytes / totalBytes).clamp(0.0, 1.0)
            : (processedEntries / files.length).clamp(0.0, 1.0);

        _sendProgress(
          sendPort,
          status: 'progress',
          progress: progress,
          message: 'Extracting ${p.basename(file.name)}',
        );
      } else {
        Directory(normalizedOutput).createSync(recursive: true);
        if (!hasByteBudget) {
          processedEntries++;
          final progress = (processedEntries / files.length).clamp(0.0, 1.0);
          _sendProgress(
            sendPort,
            status: 'progress',
            progress: progress,
            message: 'Creating folder ${file.name}',
          );
        }
      }
    }

    _sendProgress(
      sendPort,
      status: 'complete',
      progress: 1.0,
      message: 'Archive extracted successfully',
      outputPath: destination.path,
    );
  } catch (e, stackTrace) {
    debugPrint('ZIP extraction error: $e\n$stackTrace');
    _sendProgress(
      sendPort,
      status: 'error',
      progress: 0,
      message: 'Extraction failed',
      error: e.toString(),
    );
  }
}

Future<List<_ZipEntry>> _collectEntries(List<String> sources) async {
  final entries = <_ZipEntry>[];

  for (final rawSource in sources) {
    final entityType = FileSystemEntity.typeSync(rawSource, followLinks: false);

    switch (entityType) {
      case FileSystemEntityType.file:
        final file = File(rawSource);
        if (!file.existsSync()) {
          throw Exception('File not found: $rawSource');
        }
        final stat = await file.stat();
        entries.add(
          _ZipEntry(
            absolutePath: file.path,
            relativePath: _toPosixPath(p.basename(file.path)),
            isDirectory: false,
            size: await file.length(),
            mode: stat.mode,
            lastModifiedSeconds: stat.modified.millisecondsSinceEpoch ~/ 1000,
          ),
        );
        break;

      case FileSystemEntityType.directory:
        final directory = Directory(rawSource);
        if (!directory.existsSync()) {
          throw Exception('Directory not found: $rawSource');
        }
        final dirStat = await directory.stat();
        final rootName = p.basename(directory.path);
        final rootRelative = _toPosixPath(rootName);

        entries.add(
          _ZipEntry(
            absolutePath: directory.path,
            relativePath: '$rootRelative/',
            isDirectory: true,
            size: 0,
            mode: dirStat.mode,
            lastModifiedSeconds:
                dirStat.modified.millisecondsSinceEpoch ~/ 1000,
          ),
        );

        await for (final entity in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          try {
            if (entity is File) {
              final stat = await entity.stat();
              final relative = p.join(
                rootName,
                p.relative(entity.path, from: directory.path),
              );
              entries.add(
                _ZipEntry(
                  absolutePath: entity.path,
                  relativePath: _toPosixPath(relative),
                  isDirectory: false,
                  size: await entity.length(),
                  mode: stat.mode,
                  lastModifiedSeconds:
                      stat.modified.millisecondsSinceEpoch ~/ 1000,
                ),
              );
            } else if (entity is Directory) {
              final stat = await entity.stat();
              final relative = p.join(
                rootName,
                p.relative(entity.path, from: directory.path),
              );
              final relativePath = _toPosixPath(relative);
              entries.add(
                _ZipEntry(
                  absolutePath: entity.path,
                  relativePath: relativePath.endsWith('/')
                      ? relativePath
                      : '$relativePath/',
                  isDirectory: true,
                  size: 0,
                  mode: stat.mode,
                  lastModifiedSeconds:
                      stat.modified.millisecondsSinceEpoch ~/ 1000,
                ),
              );
            }
          } catch (_) {
            // Skip entities that cannot be accessed.
            continue;
          }
        }
        break;

      case FileSystemEntityType.link:
      case FileSystemEntityType.notFound:
        throw Exception('Unsupported source path: $rawSource');
    }
  }

  return entries;
}

void _sendProgress(
  SendPort port, {
  required String status,
  required String message,
  required double progress,
  String? error,
  String? outputPath,
}) {
  port.send({
    'status': status,
    'message': message,
    'progress': progress,
    'error': error,
    'outputPath': outputPath,
  });
}

String _sanitizeArchivePath(String path) {
  var sanitized = path.replaceAll('\\', '/').replaceAll('\u0000', '');
  while (sanitized.startsWith('/')) {
    sanitized = sanitized.substring(1);
  }

  final parts = <String>[];
  for (final segment in sanitized.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
      continue;
    }
    parts.add(segment);
  }

  return parts.join('/');
}

String _toPosixPath(String value) => value.replaceAll('\\', '/');
