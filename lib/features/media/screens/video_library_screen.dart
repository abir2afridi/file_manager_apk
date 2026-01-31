import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/providers/media_library_providers.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/features/media/screens/video_player_screen.dart';
import 'package:file_explorer_apk/features/media/widgets/media_thumbnail.dart';

class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen> {
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
          : 'Media access is required to browse your videos. Grant access to continue.';
    });
    if (granted) {
      await ref
          .read(mediaLibraryControllerProvider(MediaType.video).notifier)
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
        title: const Text('Videos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
            onPressed: _permissionChecked && _permissionError == null
                ? () => ref
                      .read(
                        mediaLibraryControllerProvider(
                          MediaType.video,
                        ).notifier,
                      )
                      .refresh()
                : null,
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
                  mediaLibraryControllerProvider(MediaType.video),
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
                              MediaType.video,
                            ).notifier,
                          )
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: assets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return _VideoTile(
                            asset: asset,
                            onTap: () => _openPlayer(context, assets, index),
                            onLongPress: () => _shareAsset(asset),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorState(
                    message: 'Unable to load videos: $error',
                    onRetry: () => ref
                        .read(
                          mediaLibraryControllerProvider(
                            MediaType.video,
                          ).notifier,
                        )
                        .refresh(),
                  ),
                );
              },
            ),
    );
  }

  void _openPlayer(BuildContext context, List<MediaAsset> assets, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerScreen(playlist: assets, initialIndex: index),
      ),
    );
  }

  Future<void> _shareAsset(MediaAsset asset) async {
    await Share.shareXFiles([XFile(asset.path)], text: asset.name);
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.asset,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaAsset asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 70,
                child: MediaThumbnail(asset: asset, heroTag: asset.path),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      asset.parentDirectory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.play_circle_fill_rounded, size: 32),
            ],
          ),
        ),
      ),
    );
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
            Icons.video_library_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('No videos found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add media to your device storage and pull to refresh.',
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
