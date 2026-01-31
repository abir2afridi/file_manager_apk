import 'package:meta/meta.dart';

enum DocumentKind { pdf, text, docx, doc, unsupported }

@immutable
class DocumentLoadResult {
  final DocumentKind kind;
  final String path;
  final String? text;
  final bool fallbackRequired;
  final String? errorMessage;

  const DocumentLoadResult({
    required this.kind,
    required this.path,
    this.text,
    this.fallbackRequired = false,
    this.errorMessage,
  });

  DocumentLoadResult copyWith({
    DocumentKind? kind,
    String? path,
    String? text,
    bool? fallbackRequired,
    String? errorMessage,
  }) {
    return DocumentLoadResult(
      kind: kind ?? this.kind,
      path: path ?? this.path,
      text: text ?? this.text,
      fallbackRequired: fallbackRequired ?? this.fallbackRequired,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
