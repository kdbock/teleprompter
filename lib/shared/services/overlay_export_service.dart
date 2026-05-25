import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'export/backends/export_backend.dart';
import 'export/backends/fallback_copy_backend.dart';
import 'export/backends/native_ffmpeg_backend.dart';

class OverlayExportResult {
  const OverlayExportResult({
    required this.outputPath,
    required this.renderMode,
  });

  final String outputPath;
  final String renderMode;
}

class OverlayExportService {
  static const String backendFfmpegKit = 'ffmpeg_kit';
  static const String backendNative = 'native';

  OverlayExportService({
    String? backend,
    ExportBackend? primaryBackend,
    ExportBackend? fallbackBackend,
  }) : _primaryBackend = primaryBackend ?? _resolvePrimaryBackend(backend),
       _fallbackBackend = fallbackBackend ?? FallbackCopyBackend();

  final ExportBackend _primaryBackend;
  final ExportBackend _fallbackBackend;

  static ExportBackend _resolvePrimaryBackend(String? backend) {
    switch (backend) {
      case backendNative:
        return NativeFfmpegBackend();
      case backendFfmpegKit:
        // FFmpegKit backend was removed due package discontinuation.
        // Route this value to safe fallback behavior.
        return FallbackCopyBackend();
      default:
        return NativeFfmpegBackend();
    }
  }

  Map<String, dynamic> buildRenderPlan(Map<String, dynamic> exportProfile) {
    final trimStartMs = (exportProfile['trimStartMs'] as num?)?.toInt() ?? 0;
    final trimEndMs = (exportProfile['trimEndMs'] as num?)?.toInt();
    final lowerThird =
        (exportProfile['lowerThird'] as Map?)?.cast<String, dynamic>() ?? {};
    final captions =
        (exportProfile['captions'] as Map?)?.cast<String, dynamic>() ?? {};
    final imageOverlay =
        (exportProfile['imageOverlay'] as Map?)?.cast<String, dynamic>() ?? {};
    final filterResult = _buildFilterComplex(
      lowerThird: lowerThird,
      captions: captions,
      imageOverlay: imageOverlay,
    );
    return {
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'lowerThirdEnabled': lowerThird['enabled'] == true,
      'captionsEnabled': captions['enabled'] == true,
      'imageOverlayEnabled': (imageOverlay['path'] as String?)?.isNotEmpty == true,
      'ffmpegFilterComplex': filterResult.filter,
      'ffmpegOutputLabel': filterResult.outputLabel,
      'ffmpegCommand': '',
    };
  }

  ({String filter, String? outputLabel}) _buildFilterComplex({
    required Map<String, dynamic> lowerThird,
    required Map<String, dynamic> captions,
    required Map<String, dynamic> imageOverlay,
  }) {
    final parts = <String>[];
    var current = '[0:v]';
    if (lowerThird['enabled'] == true &&
        (lowerThird['text'] as String?)?.trim().isNotEmpty == true) {
      final text = (lowerThird['text'] as String).replaceAll("'", r"\'");
      parts.add(
        "$current drawtext=text='$text':x=(w-text_w)/2:y=h*0.82:fontsize=32:fontcolor=white:box=1:boxcolor=black@0.5 [v1]",
      );
      current = '[v1]';
    }
    if (captions['enabled'] == true &&
        (captions['text'] as String?)?.trim().isNotEmpty == true) {
      final text = (captions['text'] as String).split('\n').first.replaceAll("'", r"\'");
      parts.add(
        "$current drawtext=text='$text':x=(w-text_w)/2:y=h*0.92:fontsize=28:fontcolor=white:box=1:boxcolor=black@0.45 [v2]",
      );
      current = '[v2]';
    }
    if ((imageOverlay['path'] as String?)?.isNotEmpty == true) {
      final x = (imageOverlay['x'] as num?)?.toDouble() ?? 24;
      final y = (imageOverlay['y'] as num?)?.toDouble() ?? 24;
      parts.add("$current [1:v] overlay=${x.round()}:${y.round()} [v3]");
      current = '[v3]';
    }
    if (parts.isEmpty) return (filter: '', outputLabel: null);
    return (filter: parts.join(';'), outputLabel: current);
  }

  Future<OverlayExportResult> exportStyledVideo({
    required String inputPath,
    required Map<String, dynamic> exportProfile,
  }) async {
    final input = File(inputPath);
    if (!await input.exists()) {
      throw Exception('Input recording not found');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final id = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${exportDir.path}/styled_$id.${inputPath.split('.').last}';
    final renderPlan = buildRenderPlan(exportProfile);
    final command = _buildFfmpegCommand(
      inputPath: input.path,
      outputPath: outputPath,
      exportProfile: exportProfile,
      renderPlan: renderPlan,
    );
    renderPlan['ffmpegCommand'] = command;

    final primary = await _primaryBackend.run(
      ExportBackendRequest(
        inputPath: input.path,
        outputPath: outputPath,
        exportProfile: exportProfile,
        renderPlan: renderPlan,
      ),
    );
    var mode = primary.renderMode;
    if (!primary.success) {
      final fallback = await _fallbackBackend.run(
        ExportBackendRequest(
          inputPath: input.path,
          outputPath: outputPath,
          exportProfile: exportProfile,
          renderPlan: renderPlan,
        ),
      );
      mode = '${primary.renderMode}->${fallback.renderMode}';
    }

    return OverlayExportResult(
      outputPath: outputPath,
      renderMode: mode,
    );
  }

  String _buildFfmpegCommand({
    required String inputPath,
    required String outputPath,
    required Map<String, dynamic> exportProfile,
    required Map<String, dynamic> renderPlan,
  }) {
    final trimStartMs = renderPlan['trimStartMs'] as int;
    final trimEndMs = renderPlan['trimEndMs'] as int?;
    final filter = renderPlan['ffmpegFilterComplex'] as String;
    final outputLabel = renderPlan['ffmpegOutputLabel'] as String?;
    final startSec = (trimStartMs / 1000).toStringAsFixed(3);
    final durationSec = trimEndMs == null
        ? null
        : (((trimEndMs - trimStartMs).clamp(0, 1 << 30)) / 1000).toStringAsFixed(3);
    final imagePath = ((exportProfile['imageOverlay'] as Map?)?['path'] as String?);

    final cmd = StringBuffer()
      ..write('-y -ss $startSec ')
      ..write('-i "$inputPath" ');
    if (imagePath != null && imagePath.isNotEmpty) {
      cmd.write('-i "$imagePath" ');
    }
    if (durationSec != null) {
      cmd.write('-t $durationSec ');
    }
    if (filter.isNotEmpty) {
      cmd.write('-filter_complex "$filter" ');
      cmd.write('-map "$outputLabel" -map 0:a? ');
    } else {
      cmd.write('-map 0:v -map 0:a? ');
    }
    cmd.write('-c:v libx264 -c:a aac -movflags +faststart "$outputPath"');
    return cmd.toString();
  }
}
