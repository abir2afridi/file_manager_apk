import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/document_models.dart';
import 'package:file_explorer_apk/providers/document_providers.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key, required this.path, this.displayName});

  final String path;
  final String? displayName;

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  PdfControllerPinch? _pdfController;
  String? _pdfPath;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _ensurePdfController(DocumentLoadResult result) {
    if (result.kind != DocumentKind.pdf) {
      if (_pdfController != null) {
        _pdfController?.dispose();
        _pdfController = null;
        _pdfPath = null;
      }
      return;
    }

    if (_pdfPath == result.path && _pdfController != null) {
      return;
    }

    _pdfController?.dispose();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(result.path),
    );
    _pdfPath = result.path;
  }

  Future<void> _openExternally() async {
    await OpenFilex.open(widget.path);
  }

  Future<void> _share() async {
    await Share.shareXFiles([
      XFile(widget.path),
    ], text: widget.displayName ?? widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final asyncResult = ref.watch(documentControllerProvider(widget.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.displayName ?? File(widget.path).uri.pathSegments.last,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open with another app',
            onPressed: _openExternally,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _share,
          ),
        ],
      ),
      body: asyncResult.when(
        data: (result) {
          _ensurePdfController(result);
          if (result.fallbackRequired) {
            return _FallbackView(
              message:
                  result.errorMessage ??
                  'This document cannot be rendered in-app.',
              onOpenExternally: _openExternally,
            );
          }

          switch (result.kind) {
            case DocumentKind.pdf:
              final controller = _pdfController;
              if (controller == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return PdfViewPinch(
                controller: controller,
                onDocumentError: (error) =>
                    _showError(context, 'PDF render error: $error'),
              );
            case DocumentKind.text:
            case DocumentKind.docx:
              return _TextDocumentView(text: result.text ?? '');
            case DocumentKind.doc:
            case DocumentKind.unsupported:
              return _FallbackView(
                message:
                    result.errorMessage ??
                    'This document requires an external viewer.',
                onOpenExternally: _openExternally,
              );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _FallbackView(
          message: 'Unable to load document: $error',
          onOpenExternally: _openExternally,
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TextDocumentView extends StatelessWidget {
  const _TextDocumentView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n').length;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: SelectableText(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            fontFamily: 'monospace',
          ),
          maxLines: lines + 10,
        ),
      ),
    );
  }
}

class _FallbackView extends StatelessWidget {
  const _FallbackView({required this.message, required this.onOpenExternally});

  final String message;
  final Future<void> Function() onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Use external viewer',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onOpenExternally,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open with another app'),
            ),
          ],
        ),
      ),
    );
  }
}
