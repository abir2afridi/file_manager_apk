import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/media_asset.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  final List<MediaAsset> assets;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _chromeVisible = true;

  MediaAsset get _currentAsset => widget.assets[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.assets.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: Colors.black45,
              elevation: 0,
              title: Text(
                _currentAsset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: _shareCurrent,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: _showDetails,
                  tooltip: 'Details',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleChrome,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              itemCount: widget.assets.length,
              builder: (context, index) {
                final asset = widget.assets[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(asset.path)),
                  heroAttributes: PhotoViewHeroAttributes(tag: asset.path),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                );
              },
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              loadingBuilder: (context, event) {
                final progress = event == null
                    ? null
                    : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1);
                return Center(
                  child: CircularProgressIndicator(value: progress),
                );
              },
            ),
            if (_chromeVisible)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentIndex + 1} / ${widget.assets.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentAsset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCurrent() async {
    await Share.shareXFiles([
      XFile(_currentAsset.path),
    ], text: _currentAsset.name);
  }

  void _showDetails() {
    final asset = _currentAsset;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              _detailRow('File', asset.name),
              const SizedBox(height: 8),
              _detailRow('Path', asset.path),
              if (asset.sizeBytes > 0) ...[
                const SizedBox(height: 8),
                _detailRow('Size', _formatBytes(asset.sizeBytes)),
              ],
              if (asset.lastModified != null) ...[
                const SizedBox(height: 8),
                _detailRow('Modified', asset.lastModified.toString()),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final digitGroups = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, digitGroups);
    return '${size.toStringAsFixed(1)} ${units[digitGroups]}';
  }
}
