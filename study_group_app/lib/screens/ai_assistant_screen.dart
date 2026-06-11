// lib/screens/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:study_group_app/constants/design_system.dart'; 
import '../services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  final String currentUid;
  const AiAssistantScreen({super.key, required this.currentUid});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> chatHistory = [];
  bool isAiThinking = false;
  String activeAiResponseStream = "";

  void _dispatchPrompt(String msg) async {
    if (msg.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      chatHistory.add({"role": "user", "text": msg});
      isAiThinking = true;
      activeAiResponseStream = "";
    });

    try {
      final responseStream = AiService.streamAIResponse(msg);
      await for (var token in responseStream) {
        setState(() {
          isAiThinking = false;
          activeAiResponseStream += token;
        });
      }
      setState(() {
        chatHistory.add({"role": "ai", "text": activeAiResponseStream});
        activeAiResponseStream = "";
      });
    } catch (e) {
      setState(() {
        isAiThinking = false;
        chatHistory.add({"role": "ai", "text": "Failed to handle inbound stream parse metrics."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text(
          'Cipher AI Lab', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatHistory.length + (isAiThinking || activeAiResponseStream.isNotEmpty ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx == chatHistory.length) {
                  return _buildMessageCard(activeAiResponseStream.isEmpty ? "Thinking..." : activeAiResponseStream, "ai");
                }
                final item = chatHistory[idx];
                return _buildMessageCard(item['text']!, item['role']!);
              },
            ),
          ),
          _buildInputPanel(),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String txt, String role) {
    bool isUser = role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          txt, 
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController, 
              decoration: const InputDecoration(hintText: "Ask anything..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple), 
            onPressed: () => _dispatchPrompt(_textController.text),
          ),
        ],
      ),
    );
  }
}