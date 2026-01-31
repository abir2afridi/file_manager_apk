import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_explorer_apk/models/document_models.dart';
import 'package:file_explorer_apk/services/document_service.dart';

final documentServiceProvider = Provider<DocumentService>((ref) {
  return const DocumentService();
});

final documentControllerProvider = AsyncNotifierProviderFamily<
    DocumentController, DocumentLoadResult, String>(DocumentController.new);

class DocumentController
    extends FamilyAsyncNotifier<DocumentLoadResult, String> {
  @override
  Future<DocumentLoadResult> build(String path) async {
    final service = ref.watch(documentServiceProvider);
    return service.loadDocument(path);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(documentServiceProvider);
      return service.loadDocument(arg);
    });
  }
}
