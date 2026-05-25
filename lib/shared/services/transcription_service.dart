import 'dart:io';

import 'package:http/http.dart' as http;

abstract class TranscriptionService {
  Future<String> transcribeVideoFile(String videoPath);
}

class OpenAIWhisperTranscriptionService implements TranscriptionService {
  OpenAIWhisperTranscriptionService({required this.apiKey});

  final String apiKey;

  @override
  Future<String> transcribeVideoFile(String videoPath) async {
    if (apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }

    final file = File(videoPath);
    if (!await file.exists()) {
      throw Exception('Video file not found for transcription');
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', videoPath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('OpenAI transcription failed (${streamed.statusCode}): $body');
    }

    return body.trim();
  }
}
