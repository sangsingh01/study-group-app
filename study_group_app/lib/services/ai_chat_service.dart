import 'package:firebase_ai/firebase_ai.dart';
 
/// Handles all communication with the Gemini model via Firebase AI Logic.
/// Keeps a running chat session so the AI remembers conversation context.
class AiChatService {
  late final GenerativeModel _model;
  late ChatSession _chat;
 
  AiChatService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.0-flash',
      systemInstruction: Content.system(
        'You are a helpful study assistant inside a study-group app. '
        'Help students with study tips, explaining concepts clearly, '
        'summarizing notes, and answering academic questions concisely. '
        'Keep answers focused and easy to read on a mobile screen.',
      ),
    );
    _chat = _model.startChat();
  }
 
  /// Sends a message to the AI and returns its text response.
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      return 'Something went wrong talking to the AI assistant: $e';
    }
  }
 
  /// Clears the conversation and starts a fresh chat session.
  void resetChat() {
    _chat = _model.startChat();
  }
}
 