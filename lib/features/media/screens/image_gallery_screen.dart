import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/providers/media_library_providers.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/features/media/screens/image_viewer_screen.dart';
import 'package:file_explorer_apk/features/media/widgets/media_thumbnail.dart';

class ImageGalleryScreen extends ConsumerStatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  ConsumerState<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends ConsumerState<ImageGalleryScreen> {
  bool _permissionChecked = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    final granted = await PermissionService.ensureMediaLibraryPermissions();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionError = granted
          ? null
          : 'Media access is required to display your images. Grant access to continue.';
    });
    if (granted) {
      await ref
          .read(mediaLibraryControllerProvider(MediaType.image).notifier)
          .refresh();
    }
  }

  Future<void> _openSettings() async {
    await PermissionService.requestMediaLibraryPermissions();
    await _ensurePermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Images'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _permissionChecked && _permissionError == null
                ? () => ref
                      .read(
                        mediaLibraryControllerProvider(
                          MediaType.image,
                        ).notifier,
                      )
                      .refresh()
                : null,
            tooltip: 'Rescan',
          ),
        ],
      ),
      body: !_permissionChecked
          ? const Center(child: CircularProgressIndicator())
          : _permissionError != null
          ? _PermissionErrorView(
              message: _permissionError!,
              onRetry: _openSettings,
            )
          : Consumer(
              builder: (context, ref, _) {
                final assetsAsync = ref.watch(
                  mediaLibraryControllerProvider(MediaType.image),
                );
                return assetsAsync.when(
                  data: (assets) {
                    if (assets.isEmpty) {
                      return const _EmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(
                            mediaLibraryControllerProvider(
                              MediaType.image,
                            ).notifier,
                          )
                          .refresh(),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: assets.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return MediaThumbnail(
                            asset: asset,
                            heroTag: asset.path,
                            onTap: () => _openViewer(context, assets, index),
                            onLongPress: () => _shareAsset(asset),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorState(
                    message: 'Unable to load images: $error',
                    onRetry: () => ref
                        .read(
                          mediaLibraryControllerProvider(
                            MediaType.image,
                          ).notifier,
                        )
                        .refresh(),
                  ),
                );
              },
            ),
    );
  }

  void _openViewer(
    BuildContext context,
    List<MediaAsset> assets,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImageViewerScreen(assets: assets, initialIndex: initialIndex),
      ),
    );
  }

  Future<void> _shareAsset(MediaAsset asset) async {
    final filePath = asset.path;
    await Share.shareXFiles([XFile(filePath)], text: asset.name);
  }
}

class _PermissionErrorView extends StatelessWidget {
  const _PermissionErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              Icons.lock_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Permission needed',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Grant access'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('No images found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add photos to your device storage and pull to refresh.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
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
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
