import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'package:file_explorer_apk/models/document_models.dart';

/// Handles loading and lightweight parsing of local documents so that
/// presentation layers can render appropriate viewers or gracefully fall back
/// to external handlers when necessary.
class DocumentService {
  const DocumentService();

  /// Attempts to load a document from [path], returning rich text whenever
  /// possible and signalling when a fallback viewer (e.g. open_filex) is
  /// required.
  Future<DocumentLoadResult> loadDocument(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return DocumentLoadResult(
        kind: DocumentKind.unsupported,
        path: path,
        fallbackRequired: true,
        errorMessage: 'File not found',
      );
    }

    final extension = p.extension(path).toLowerCase();

    if (_pdfExtensions.contains(extension)) {
      // PDFs are rendered via PdfView widgets using the file path. We simply
      // signal that the document is supported without eagerly decoding bytes.
      return DocumentLoadResult(kind: DocumentKind.pdf, path: path);
    }

    if (_textExtensions.contains(extension)) {
      try {
        final text = await file.readAsString();
        return DocumentLoadResult(
          kind: DocumentKind.text,
          path: path,
          text: text,
        );
      } catch (e) {
        return DocumentLoadResult(
          kind: DocumentKind.text,
          path: path,
          fallbackRequired: true,
          errorMessage: 'Unable to read text file: $e',
        );
      }
    }

    if (_docxExtensions.contains(extension)) {
      try {
        final text = await _extractDocxText(file);
        if (text.isEmpty) {
          return DocumentLoadResult(
            kind: DocumentKind.docx,
            path: path,
            fallbackRequired: true,
            errorMessage: 'Empty DOCX document',
          );
        }
        return DocumentLoadResult(
          kind: DocumentKind.docx,
          path: path,
          text: text,
        );
      } catch (e) {
        return DocumentLoadResult(
          kind: DocumentKind.docx,
          path: path,
          fallbackRequired: true,
          errorMessage: 'DOCX parse error: $e',
        );
      }
    }

    if (_docExtensions.contains(extension)) {
      // Legacy .doc format is not natively supported.
      return DocumentLoadResult(
        kind: DocumentKind.doc,
        path: path,
        fallbackRequired: true,
        errorMessage: 'DOC format requires external viewer',
      );
    }

    return DocumentLoadResult(
      kind: DocumentKind.unsupported,
      path: path,
      fallbackRequired: true,
      errorMessage: 'Unsupported document type ($extension)',
    );
  }

  Future<String> _extractDocxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final documentEntry = archive.files.firstWhere(
      (item) => item.name == 'word/document.xml',
      orElse: () => throw StateError('DOCX missing document.xml'),
    );

    final documentXml = documentEntry.content as List<int>;
    final xmlString = String.fromCharCodes(documentXml);
    final document = XmlDocument.parse(xmlString);

    final buffer = StringBuffer();
    for (final node in document.findAllElements('w:p')) {
      final textNodes = node.findAllElements('w:t');
      final paragraph = textNodes.map((n) => n.innerText).join();
      if (paragraph.isNotEmpty) {
        buffer.writeln(paragraph);
      }
    }

    return buffer.toString().trim();
  }
}

const Set<String> _pdfExtensions = {'.pdf'};
const Set<String> _textExtensions = {'.txt', '.md', '.csv', '.log'};
const Set<String> _docxExtensions = {'.docx'};
const Set<String> _docExtensions = {'.doc'};
