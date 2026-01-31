import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/providers/media_library_providers.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/features/media/screens/audio_player_screen.dart';

class AudioLibraryScreen extends ConsumerStatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  ConsumerState<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends ConsumerState<AudioLibraryScreen> {
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
          : 'Media access is required to browse your audio library. Grant access to continue.';
    });
    if (granted) {
      await ref
          .read(mediaLibraryControllerProvider(MediaType.audio).notifier)
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
        title: const Text('Audio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
            onPressed: _permissionChecked && _permissionError == null
                ? () => ref
                    .read(
                      mediaLibraryControllerProvider(MediaType.audio).notifier,
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
                    final assetsAsync =
                        ref.watch(mediaLibraryControllerProvider(MediaType.audio));
                    return assetsAsync.when(
                      data: (assets) {
                        if (assets.isEmpty) {
                          return const _EmptyState();
                        }
                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(mediaLibraryControllerProvider(MediaType.audio)
                                  .notifier)
                              .refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: assets.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final asset = assets[index];
                              return _AudioTile(
                                asset: asset,
                                onTap: () => _openPlayer(context, assets, index),
                                onLongPress: () => _shareAsset(asset),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => _ErrorState(
                        message: 'Unable to load audio files: $error',
                        onRetry: () => ref
                            .read(mediaLibraryControllerProvider(MediaType.audio)
                                .notifier)
                            .refresh(),
                      ),
                    );
                  },
                ),
    );
  }

  void _openPlayer(
    BuildContext context,
    List<MediaAsset> assets,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerScreen(
          playlist: assets,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _shareAsset(MediaAsset asset) async {
    await Share.shareXFiles([XFile(asset.path)], text: asset.name);
  }
}

class _AudioTile extends StatelessWidget {
  const _AudioTile({
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
    final stat = File(asset.path).statSync();
    return ListTile(      
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: const Icon(Icons.music_note_rounded),
      ),
      title: Text(
        asset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${asset.parentDirectory}\n${_formatDate(stat.modified)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_arrow_rounded),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PermissionErrorView extends StatelessWidget {
  const _PermissionErrorView({
    required this.message,
    required this.onRetry,
  });

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
            Icon(Icons.lock_rounded, size: 56, color: theme.colorScheme.primary),
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
          Icon(Icons.library_music_outlined,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'No audio files found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add music to your device storage and pull to refresh.',
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
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            Icon(Icons.error_outline_rounded,
                size: 56, color: theme.colorScheme.error),
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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
