import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/providers/audio_playback_provider.dart';
import 'package:file_explorer_apk/services/audio_playback_service.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  final List<MediaAsset> playlist;
  final int initialIndex;

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen>
    with WidgetsBindingObserver {
  AudioPlaybackService? _service;
  PlayerState? _playerState;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _positionSub;
  StreamSubscription<Duration?>? _bufferedSub;
  StreamSubscription<Duration?>? _durationSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isLoading = false;
  String? _errorMessage;

  late int _currentIndex;

  MediaAsset get _currentTrack => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, widget.playlist.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initService());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _bufferedSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _service?.pause();
    }
  }

  Future<void> _initService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = await ref.read(audioPlaybackControllerProvider.future);
      if (!mounted) return;
      _attachService(service);
      await _loadTrack(_currentIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize audio playback: $e';
      });
    }
  }

  void _attachService(AudioPlaybackService service) {
    _service = service;
    _playerStateSub = service.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
    _positionSub = service.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position ?? Duration.zero);
    });
    _bufferedSub = service.bufferedPositionStream.listen((buffered) {
      if (!mounted) return;
      // Buffering handled implicitly by just_audio; could be surfaced in UI later.
    });
    _durationSub = service.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
  }

  Future<void> _loadTrack(int index) async {
    final service = _service;
    if (service == null) return;

    final track = widget.playlist[index];
    final file = File(track.path);
    if (!file.existsSync()) {
      setState(() {
        _errorMessage = 'File not found: ${track.name}';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await service.stop();
      await service.loadFile(file);
      await service.play();
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
        _isLoading = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to play ${track.name}: $e';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    final service = _service;
    final state = _playerState;
    if (service == null || state == null) return;
    if (state.playing) {
      await service.pause();
    } else {
      await service.play();
    }
  }

  Future<void> _seekTo(Duration position) async {
    final service = _service;
    if (service == null) return;
    await service.seek(position);
  }

  void _playNext() {
    if (_currentIndex >= widget.playlist.length - 1) return;
    unawaited(_loadTrack(_currentIndex + 1));
  }

  void _playPrevious() {
    if (_currentIndex == 0) {
      unawaited(_seekTo(Duration.zero));
      return;
    }
    unawaited(_loadTrack(_currentIndex - 1));
  }

  Future<void> _shareCurrent() async {
    await Share.shareXFiles([
      XFile(_currentTrack.path),
    ], text: _currentTrack.name);
  }

  Future<void> _openExternally() => OpenFilex.open(_currentTrack.path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerState = _playerState;
    final isPlaying = playerState?.playing ?? false;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _currentTrack.name,
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
      body: _errorMessage != null
          ? _ErrorView(
              message: _errorMessage!,
              onOpenExternally: _openExternally,
            )
          : Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        _currentTrack.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTrack.parentDirectory,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: math.max(_duration.inMilliseconds.toDouble(), 1),
                          value: math.min(
                            _position.inMilliseconds.toDouble(),
                            _duration.inMilliseconds.toDouble(),
                          ),
                          onChanged: (value) =>
                              _seekTo(Duration(milliseconds: value.round())),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        onPressed: _currentIndex > 0 ? _playPrevious : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(isPlaying ? 'Pause' : 'Play'),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 40,
                        onPressed: _currentIndex < widget.playlist.length - 1
                            ? _playNext
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Divider(color: theme.dividerColor.withOpacity(0.3)),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.playlist.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final track = widget.playlist[index];
                      final isCurrent = index == _currentIndex;
                      return ListTile(
                        leading: Icon(
                          isCurrent
                              ? Icons.play_arrow_rounded
                              : Icons.music_note,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.parentDirectory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isCurrent
                            ? Text(
                                _formatDuration(_duration),
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        onTap: () => _loadTrack(index),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onOpenExternally});

  final String message;
  final Future<void> Function() onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Playback error',
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
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    final mins = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$seconds';
  }
  return '$minutes:$seconds';
}
