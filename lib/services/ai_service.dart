import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    assert(key.isNotEmpty && key != 'your-openai-api-key-here',
        'OPENAI_API_KEY is not set in .env');
    return key;
  }

  /// Send a chat completion request. Returns the assistant message content.
  /// [model] defaults to gpt-4o. Pass 'o3-mini' for escalation paths.
  /// Throws on network error or non-200 response.
  static Future<String> chat({
    required List<Map<String, String>> messages,
    String model = 'gpt-4o',
    int maxTokens = 1024,
    double temperature = 0.4,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer ${_apiKey}',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      debugPrint('[AiService] HTTP ${response.statusCode}: ${response.body}');
      throw Exception('OpenAI API error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['choices'][0]['message']['content'] as String;
    return content.trim();
  }

  /// Vet diagnosis: returns a map with keys: diagnosis, confidence (0-100), advice.
  /// Automatically escalates to o3-mini when confidence < 60.
  static Future<Map<String, dynamic>> vetDiagnosis({
    required String species,
    required String symptoms,
    String locale = 'uz',
  }) async {
    final lang = locale == 'ru' ? 'Russian' : 'Uzbek';
    final systemPrompt = '''You are Sonya, an expert AI veterinarian for Central Asian livestock farms.
Respond ONLY in $lang.
Given the animal species and symptoms, provide:
1. A concise diagnosis (1-2 sentences)
2. Recommended treatment / action steps (2-4 bullet points)
3. Confidence score (0-100)

Return your response as valid JSON with keys: "diagnosis", "advice", "confidence".
Example: {"diagnosis": "...", "advice": "...", "confidence": 75}''';

    final userPrompt = 'Species: $species\nSymptoms: $symptoms';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    String raw = await chat(messages: messages, model: 'gpt-4o', maxTokens: 512);

    // Strip markdown code fences if present
    raw = raw.replaceAll(RegExp(r'```json|```'), '').trim();

    Map<String, dynamic> result;
    try {
      result = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      result = {'diagnosis': raw, 'advice': '', 'confidence': 50};
    }

    final confidence = (result['confidence'] as num?)?.toInt() ?? 50;

    // Escalate to o3-mini when confidence is low
    if (confidence < 60) {
      debugPrint('[AiService] confidence=$confidence < 60, escalating to o3-mini');
      final escalatedRaw = await chat(
        messages: messages,
        model: 'o3-mini',
        maxTokens: 1024,
        temperature: 1.0,
      );
      final cleaned = escalatedRaw.replaceAll(RegExp(r'```json|```'), '').trim();
      try {
        result = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (_) {
        result['diagnosis'] = escalatedRaw;
      }
    }

    return result;
  }
}
