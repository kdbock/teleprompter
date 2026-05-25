import 'package:flutter/services.dart';

import 'export_backend.dart';

class NativeFfmpegBackend implements ExportBackend {
  NativeFfmpegBackend({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'teleprompter/export_native_ffmpeg';
  final MethodChannel _channel;

  @override
  Future<ExportBackendResult> run(ExportBackendRequest request) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('render', {
        'inputPath': request.inputPath,
        'outputPath': request.outputPath,
        'exportProfile': request.exportProfile,
        'renderPlan': request.renderPlan,
      });
      final success = result?['success'] == true;
      final mode = (result?['renderMode'] as String?) ?? 'native_ffmpeg_unknown';
      return ExportBackendResult(success: success, renderMode: mode);
    } on PlatformException {
      return const ExportBackendResult(
        success: false,
        renderMode: 'native_ffmpeg_unavailable',
      );
    } catch (_) {
      return const ExportBackendResult(
        success: false,
        renderMode: 'native_ffmpeg_failed',
      );
    }
  }
}
