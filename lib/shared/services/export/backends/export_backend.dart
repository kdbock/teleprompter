abstract class ExportBackend {
  Future<ExportBackendResult> run(ExportBackendRequest request);
}

class ExportBackendRequest {
  const ExportBackendRequest({
    required this.inputPath,
    required this.outputPath,
    required this.exportProfile,
    required this.renderPlan,
  });

  final String inputPath;
  final String outputPath;
  final Map<String, dynamic> exportProfile;
  final Map<String, dynamic> renderPlan;
}

class ExportBackendResult {
  const ExportBackendResult({
    required this.success,
    required this.renderMode,
  });

  final bool success;
  final String renderMode;
}
