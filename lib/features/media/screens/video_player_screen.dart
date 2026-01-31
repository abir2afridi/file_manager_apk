import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:file_explorer_apk/models/media_asset.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  final List<MediaAsset> playlist;
  final int initialIndex;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showControls = true;
  late int _currentIndex;

  MediaAsset get _currentAsset => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, widget.playlist.length - 1);
    _loadVideo(_currentIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_handleControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    }
  }

  Future<void> _loadVideo(int index) async {
    final asset = widget.playlist[index];
    final file = File(asset.path);
    if (!file.existsSync()) {
      setState(() {
        _errorMessage = 'File not found on device.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final previous = _controller;
    previous?.removeListener(_handleControllerUpdate);

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      controller.addListener(_handleControllerUpdate);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
        _currentIndex = index;
      });
      await previous?.dispose();
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to play video: $e';
      });
    }
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;
    if (value.position >= value.duration && !_isLoading) {
      _playNext();
    }
  }

  void _playNext() {
    if (_currentIndex >= widget.playlist.length - 1) {
      _controller?.seekTo(Duration.zero);
      _controller?.pause();
      return;
    }
    _loadVideo(_currentIndex + 1);
  }

  void _playPrevious() {
    if (_currentIndex == 0) {
      _controller?.seekTo(Duration.zero);
      return;
    }
    _loadVideo(_currentIndex - 1);
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(position);
  }

  Future<void> _shareCurrent() async {
    await Share.shareXFiles([XFile(_currentAsset.path)], text: _currentAsset.name);
  }

  Future<void> _openExternally() async {
    await OpenFilex.open(_currentAsset.path);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _currentAsset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open with another app',
            onPressed: _openExternally,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareCurrent,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller?.value.isInitialized == true
                    ? controller!.value.aspectRatio
                    : 16 / 9,
                child: controller != null && controller.value.isInitialized
                    ? VideoPlayer(controller)
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? _ErrorPlaceholder(
                                message: _errorMessage!,
                                onOpenExternally: _openExternally,
                              )
                            : const SizedBox.shrink(),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: _ControlsOverlay(
                  controller: controller,
                  isLoading: _isLoading,
                  onPlayPause: _togglePlayPause,
                  onSeek: _seekTo,
                  onNext: _currentIndex < widget.playlist.length - 1
                      ? _playNext
                      : null,
                  onPrevious: _currentIndex > 0 ? _playPrevious : null,
                  theme: theme,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.isLoading,
    required this.onPlayPause,
    required this.onSeek,
    required this.onNext,
    required this.onPrevious,
    required this.theme,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final Future<void> Function() onPlayPause;
  final Future<void> Function(Duration position) onSeek;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final value = controller?.value;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 24),
          if (value != null && value.isInitialized)
            Expanded(
              child: Center(
                child: IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  onPressed: onPlayPause,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                ),
              ),
            )
          else if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const Spacer(),
          if (value != null && value.isInitialized)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(value.duration),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  Slider(
                    min: 0,
                    max: value.duration.inMilliseconds.toDouble(),
                    value: value.position.inMilliseconds.clamp(
                      0,
                      value.duration.inMilliseconds,
                    ).toDouble(),
                    onChanged: (newValue) => onSeek(
                      Duration(milliseconds: newValue.round()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: onPrevious,
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: Colors.white),
                      ),
                      IconButton(
                        onPressed: onNext,
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({
    required this.message,
    required this.onOpenExternally,
  });

  final String message;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Playback error',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onOpenExternally,
              child: const Text('Open with another app'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
