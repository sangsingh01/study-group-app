// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
  static const String _apiKey = "YOUR_GEMINI_API_KEY_HERE";

  static const String systemPrompt = '''
You are Cipher AI, a helpful study assistant for university students. You help with:
- Explaining concepts clearly
- Solving academic problems
- Summarizing study materials
- Creating practice questions
Keep responses highly concise, precise, and educational. Use clear Markdown format structure.
''';

  static Stream<String> streamAIResponse(String userMessage) async* {
    try {
      final response = await http.post(
        Uri.parse("$_endpoint?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {"role": "user", "parts": [{"text": "$systemPrompt\n\nUser Question: $userMessage"}]}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String content = data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        
        // Emulating chunk token generation streaming patterns word-by-word
        List<String> tokens = content.split(' ');
        for (var token in tokens) {
          await Future.delayed(const Duration(milliseconds: 40));
          yield "$token ";
        }
      } else {
        yield "Error resolving stream execution engine metrics.";
      }
    } catch (e) {
      yield "Exception: Unable to maintain live gateway sync pipeline.";
    }
  }
}