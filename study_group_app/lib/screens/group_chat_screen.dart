import 'dart:async';

import 'package:flutter/material.dart';

import '../models/group_message.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (_isTyping == isTyping) return;
    _isTyping = isTyping;
    await _databaseService.updateGroupTypingStatus(
      groupId: widget.group.id,
      uid: widget.currentUser.uid,
      username: widget.currentUser.username,
      isTyping: isTyping,
    );
  }

  void _onMessageChanged(String text) {
    _typingTimer?.cancel();
    final shouldType = text.trim().isNotEmpty;
    _updateTypingStatus(shouldType);

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = GroupMessage(
      id: _databaseService.generateGroupMessageId(widget.group.id),
      senderUid: widget.currentUser.uid,
      senderName: widget.currentUser.username,
      senderImage: widget.currentUser.profileImage,
      text: text,
      createdAt: DateTime.now(),
    );

    _messageController.clear();
    await _databaseService.sendGroupMessage(widget.group.id, message);
    await _updateTypingStatus(false);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildChatBubble(GroupMessage message) {
    final isOwnMessage = message.senderUid == widget.currentUser.uid;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
            bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(184),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isOwnMessage
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.group.name} Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: _databaseService.groupMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation with your group.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildChatBubble(message);
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: _databaseService.groupTypingUsers(
              widget.group.id,
              widget.currentUser.uid,
            ),
            builder: (context, snapshot) {
              final typers = snapshot.data ?? [];
              if (typers.isEmpty) return const SizedBox.shrink();
              final typingText = typers.length == 1
                  ? '${typers.first} is typing...'
                  : 'Several people are typing...';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    typingText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _onMessageChanged,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
