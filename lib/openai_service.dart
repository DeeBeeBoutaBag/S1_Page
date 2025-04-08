// openai_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final _fineTunedModel = dotenv.env['FINE_TUNED_MODEL']!;

  Future<String> generateResponse(List<Map<String, String>> messages, {int tokens = 150}) async {
    final userMessage = messages.last['content']!.toLowerCase();

    // Conditions to handle specific requests.
    if (userMessage.contains('who created you') || userMessage.contains('who made you')) {
      return 'Oh, my creator goes by the name Bunny. Real cool folks, ya feel me?';
    }

    final prompt = [
      {
        'role': 'system',
        'content':
            'You are S.E.V.A, an AI assistant created by Bunny to exclusively answer questions about The Hidden Genius Project. '
            'Respond like a modern African-American Southerner from Mississippi using respectful slang, informal tones, '
            'and a friendly conversational style. If a question is outside the topic of The Hidden Genius Project, or too general, '
            'you must politely say exactly: "I do not have the capacity to answer that you feel me?" Keep responses short, clear, and precise.'
      },
      ...messages
    ];

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({'model': _fineTunedModel, 'messages': prompt, 'max_tokens': tokens, 'temperature': 0.7}),
      );

      if (response.statusCode == 200) {
        final reply = jsonDecode(response.body)['choices'][0]['message']['content'].trim();

        // Additional safeguard if AI response goes off topic
        if (_isOffTopic(reply)) {
          return 'I do not have the capacity to answer that you feel me?';
        }
        return reply;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return "Sorry, something's up with the server. Hit me up a lil' later, aight?";
    }
  }

  // Optional extra verification (basic level)
  bool _isOffTopic(String reply) {
    final rejectionPhrase = 'I do not have the capacity to answer that you feel me?';
    List<String> bannedKeywords = ['politics', 'religion', 'weather', 'sports', 'general knowledge', 'finance', 'healthcare', 'dating'];
    return bannedKeywords.any(reply.toLowerCase().contains) || reply.contains(rejectionPhrase);
  }
}