import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import 'package:file_explorer_apk/models/media_asset.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.asset,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.heroTag,
  });

  final MediaAsset asset;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primaryContainer;
    final borderColor = selected
        ? theme.colorScheme.primary
        : Colors.transparent;

    return Semantics(
      label: 'Media item ${asset.name}',
      button: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 3 : 1),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (heroTag != null)
                  Hero(tag: heroTag!, child: _buildPreview())
                else
                  _buildPreview(),
                if (asset.type != MediaType.image)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Icon(_iconForType(asset.type), size: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final file = File(asset.path);
    if (asset.type == MediaType.image && file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    final mime = asset.mimeType ?? lookupMimeType(asset.path) ?? '';
    if (mime.startsWith('video/')) {
      return _overlayIcon(Icons.play_arrow_rounded);
    }
    if (mime.startsWith('audio/')) {
      return _overlayIcon(Icons.audiotrack_rounded);
    }

    return _fallbackIcon();
  }

  Widget _overlayIcon(IconData icon) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(child: Icon(icon, size: 36, color: Colors.white)),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Icon(_iconForType(asset.type), size: 32, color: Colors.white70),
      ),
    );
  }

  IconData _iconForType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.photo_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.audio:
        return Icons.audiotrack_rounded;
    }
  }
}
