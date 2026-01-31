import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_explorer_apk/services/audio_playback_service.dart';

final audioPlaybackControllerProvider = AutoDisposeAsyncNotifierProvider<
    AudioPlaybackController, AudioPlaybackService>(AudioPlaybackController.new);

class AudioPlaybackController
    extends AutoDisposeAsyncNotifier<AudioPlaybackService> {
  @override
  Future<AudioPlaybackService> build() async {
    final service = await AudioPlaybackService.create();
    ref.onDispose(service.dispose);
    return service;
  }
}
