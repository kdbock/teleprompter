import 'dart:io';

import 'export_backend.dart';

class FallbackCopyBackend implements ExportBackend {
  @override
  Future<ExportBackendResult> run(ExportBackendRequest request) async {
    await File(request.inputPath).copy(request.outputPath);
    return const ExportBackendResult(
      success: true,
      renderMode: 'pass_through_copy',
    );
  }
}
