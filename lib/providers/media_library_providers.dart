import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_explorer_apk/models/media_asset.dart';
import 'package:file_explorer_apk/services/media_library_service.dart';

final mediaLibraryServiceProvider = Provider<MediaLibraryService>((ref) {
  return MediaLibraryService();
});

final mediaLibraryControllerProvider = AsyncNotifierProviderFamily<
    MediaLibraryController, List<MediaAsset>, MediaType>(
  MediaLibraryController.new,
);

class MediaLibraryController
    extends FamilyAsyncNotifier<List<MediaAsset>, MediaType> {
  @override
  Future<List<MediaAsset>> build(MediaType arg) async {
    final service = ref.watch(mediaLibraryServiceProvider);
    final assets = await service.loadMedia(mediaType: arg);
    return assets;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(mediaLibraryServiceProvider);
      return service.loadMedia(mediaType: arg);
    });
  }
}
