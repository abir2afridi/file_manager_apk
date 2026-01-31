import 'package:meta/meta.dart';

enum MediaType { image, video, audio }

@immutable
class MediaAsset {
  final String path;
  final String name;
  final MediaType type;
  final int sizeBytes;
  final DateTime? lastModified;
  final Duration? duration;
  final String parentDirectory;
  final String? mimeType;

  const MediaAsset({
    required this.path,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.parentDirectory,
    this.lastModified,
    this.duration,
    this.mimeType,
  });

  MediaAsset copyWith({
    String? path,
    String? name,
    MediaType? type,
    int? sizeBytes,
    DateTime? lastModified,
    Duration? duration,
    String? parentDirectory,
    String? mimeType,
  }) {
    return MediaAsset(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastModified: lastModified ?? this.lastModified,
      duration: duration ?? this.duration,
      parentDirectory: parentDirectory ?? this.parentDirectory,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  Map<String, dynamic> toMap() => {
        'path': path,
        'name': name,
        'type': type.index,
        'sizeBytes': sizeBytes,
        'lastModified': lastModified?.millisecondsSinceEpoch,
        'durationMs': duration?.inMilliseconds,
        'parentDirectory': parentDirectory,
        'mimeType': mimeType,
      };

  factory MediaAsset.fromMap(Map<String, dynamic> map) {
    return MediaAsset(
      path: map['path'] as String,
      name: map['name'] as String,
      type: MediaType.values[map['type'] as int],
      sizeBytes: map['sizeBytes'] as int,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
      duration: map['durationMs'] != null
          ? Duration(milliseconds: map['durationMs'] as int)
          : null,
      parentDirectory: map['parentDirectory'] as String,
      mimeType: map['mimeType'] as String?,
    );
  }
}
