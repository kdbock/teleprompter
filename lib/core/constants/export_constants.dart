class ExportConstants {
  // Switch export backend without changing service code.
  // Valid values: OverlayExportService.backendFfmpegKit / backendNative
  // Use fallback-stable backend for current TestFlight prep.
  static const String exportBackend = 'ffmpeg_kit';
}
