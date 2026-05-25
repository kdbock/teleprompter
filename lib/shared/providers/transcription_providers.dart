import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/transcription_service.dart';

const String _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return OpenAIWhisperTranscriptionService(apiKey: _openAiApiKey);
});
