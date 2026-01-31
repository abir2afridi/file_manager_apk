import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

enum FileViewerKind {
  image,
  video,
  audio,
  pdf,
  text,
  docx,
  doc,
  unsupported,
}

class FileTypeResolver {
  const FileTypeResolver._();

  static FileViewerKind resolve(String path) {
    final extension = p.extension(path).toLowerCase();
    final normalized = extension.isEmpty ? '' : extension;
    final mime = lookupMimeType(path) ?? '';

    if (_imageExtensions.contains(normalized) || mime.startsWith('image/')) {
      return FileViewerKind.image;
    }

    if (_videoExtensions.contains(normalized) || mime.startsWith('video/')) {
      return FileViewerKind.video;
    }

    if (_audioExtensions.contains(normalized) || mime.startsWith('audio/')) {
      return FileViewerKind.audio;
    }

    if (_pdfExtensions.contains(normalized) || mime == 'application/pdf') {
      return FileViewerKind.pdf;
    }

    if (_textExtensions.contains(normalized) || mime.startsWith('text/')) {
      return FileViewerKind.text;
    }

    if (_docxExtensions.contains(normalized)) {
      return FileViewerKind.docx;
    }

    if (_docExtensions.contains(normalized)) {
      return FileViewerKind.doc;
    }

    return FileViewerKind.unsupported;
  }

  static bool isImage(String path) =>
      resolve(path) == FileViewerKind.image;

  static bool isVideo(String path) =>
      resolve(path) == FileViewerKind.video;

  static bool isAudio(String path) =>
      resolve(path) == FileViewerKind.audio;

  static bool isDocument(String path) {
    final kind = resolve(path);
    return kind == FileViewerKind.pdf ||
        kind == FileViewerKind.text ||
        kind == FileViewerKind.docx ||
        kind == FileViewerKind.doc;
  }
}

const Set<String> _imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.heic',
  '.heif',
};

const Set<String> _videoExtensions = {
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.webm',
  '.flv',
};

const Set<String> _audioExtensions = {
  '.mp3',
  '.aac',
  '.wav',
  '.ogg',
  '.flac',
  '.m4a',
  '.opus',
};

const Set<String> _pdfExtensions = {'.pdf'};

const Set<String> _textExtensions = {
  '.txt',
  '.md',
  '.csv',
  '.log',
  '.json',
  '.xml',
};

const Set<String> _docxExtensions = {'.docx'};
const Set<String> _docExtensions = {'.doc'};
