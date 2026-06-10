import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class DirectMessageScreen extends StatefulWidget {
  final AppUser? currentUser;
  final User currentUserAuthData;
  final AppUser friend;
  final String chatId;

  const DirectMessageScreen({
    super.key,
    required this.currentUser,
    required this.currentUserAuthData,
    required this.friend,
    required this.chatId,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTextNotEmpty = false;
  bool _showEmojiTray = false;
  Timer? _typingTimer;
  bool _amITyping = false;

  // Cache stream instance so Flutter doesn't recreate the connection on every build frame
  late Stream<List<MessageModel>> _messageStream;

  final List<String> _quickEmojis = ['😀', '😂', '😍', '👋', '👍', '🙏', '🔥', '✨', '📚', '🎯'];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageTextChanged);
    _markChatAsRead();
    
    // FIX 1: Establish stream once on init to prevent stream recycling stutters
    _messageStream = _databaseService.getDirectMessages(widget.chatId);
  }

  void _markChatAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseService.markMessagesAsRead(widget.chatId, widget.currentUserAuthData.uid);
    });
  }

  void _onMessageTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTextNotEmpty) {
      setState(() => _isTextNotEmpty = hasText);
    }

    if (hasText && !_amITyping) {
      _amITyping = true;
      _databaseService.updateTypingStatus(widget.chatId, widget.currentUserAuthData.uid, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_amITyping) {
        _amITyping = false;
        _databaseService.updateTypingStatus(widget.chatId, widget.currentUserAuthData.uid, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _typingTimer?.cancel();
    if (_amITyping) {
      _amITyping = false;
      _databaseService.updateTypingStatus(widget.chatId, widget.currentUserAuthData.uid, false);
    }

    final messageNode = MessageModel(
      senderId: widget.currentUserAuthData.uid,
      senderName: widget.currentUser?.username ?? 'User',
      receiverId: widget.friend.uid,
      message: text,
      timestamp: DateTime.now(),
    );

    try {
      await _databaseService.sendDirectMessage(widget.chatId, messageNode, widget.friend.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery error: $e'), backgroundColor: const Color(0xFFFF6584)),
      );
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatGroupDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMMM yyyy').format(dateTime);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_amITyping) {
      _databaseService.updateTypingStatus(widget.chatId, widget.currentUserAuthData.uid, false);
    }
    _messageController.removeListener(_onMessageTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C86FF), Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friend.profileImage != null ? NetworkImage(widget.friend.profileImage!) : null,
              backgroundColor: Colors.white30,
              child: widget.friend.profileImage == null
                  ? Text(
                      widget.friend.initials,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.friend.username,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    widget.friend.isActive ? 'Online' : 'Last seen today',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.friend.isActive ? const Color(0xFF43E97B) : Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call coming soon!'), backgroundColor: Color(0xFF6C63FF)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call coming soon!'), backgroundColor: Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              // Pass the cached reference instead of calling database functions natively inside build block
              stream: _messageStream, 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final currentMsg = messages[messages.length - 1 - index];
                    final isMine = currentMsg.senderId == widget.currentUserAuthData.uid;

                    Widget dateBarElement = const SizedBox.shrink();
                    
                    if (index == messages.length - 1) {
                      dateBarElement = _buildDateDivider(currentMsg.timestamp);
                    } else {
                      final nextOlderMsg = messages[messages.length - 1 - (index + 1)];
                      if (!_isSameDay(currentMsg.timestamp, nextOlderMsg.timestamp)) {
                        dateBarElement = _buildDateDivider(currentMsg.timestamp);
                      }
                    }

                    return Column(
                      // FIX 2: Added explicit structural ValueKeys to avoid bubble item blinking
                      key: ValueKey(currentMsg.id ?? index.toString()), 
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dateBarElement,
                        _buildMessageBubble(currentMsg, isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          StreamBuilder<bool>(
            stream: _databaseService.getFriendTypingStatus(widget.chatId, widget.friend.uid),
            builder: (context, snapshot) {
              if (snapshot.data == true) return _buildTypingIndicator();
              return const SizedBox.shrink();
            },
          ),
          
          _buildMessageInputBar(context),
          if (_showEmojiTray) _buildEmojiTrayWidget(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.friend.profileImage != null ? NetworkImage(widget.friend.profileImage!) : null,
            backgroundColor: Colors.grey[300],
            child: widget.friend.profileImage == null
                ? Text(widget.friend.initials, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 12),
          Text(widget.friend.username, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Say hi to ${widget.friend.username}!', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          const Text('👋', style: TextStyle(fontSize: 44)),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
          child: Text(
            _formatGroupDate(date),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: isMine ? const EdgeInsets.only(left: 60, bottom: 8) : const EdgeInsets.only(right: 60, bottom: 8),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isMine
                  ? const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                        bottomLeft: Radius.circular(18),
                      ),
                    )
                  : BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
              child: Text(
                msg.message,
                style: GoogleFonts.poppins(fontSize: 14, color: isMine ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMessageTime(msg.timestamp),
                    style: GoogleFonts.poppins(fontSize: 10, color: isMine ? Colors.grey[600] : Colors.grey[500]),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 13,
                      color: msg.isRead ? const Color(0xFF6C63FF) : Colors.grey[400],
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputBar(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -3))],
      ),
      padding: EdgeInsets.only(
        left: 12, 
        right: 12, 
        top: 8,
        bottom: isKeyboardOpen ? 8 : 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_showEmojiTray ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined, color: Colors.grey[600]),
            onPressed: () {
              setState(() {
                _showEmojiTray = !_showEmojiTray;
                if (_showEmojiTray) FocusScope.of(context).unfocus();
              });
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                ),
                onTap: () => setState(() => _showEmojiTray = false),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isTextNotEmpty
                ? GestureDetector(
                    key: const ValueKey('sendBtn'),
                    onTap: _sendMessage,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('micBtn'),
                    icon: const Icon(Icons.mic_none_rounded, color: Colors.grey),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice coming soon'), backgroundColor: Color(0xFF6C63FF)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTrayWidget() {
    return Container(
      height: 64,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _quickEmojis.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              final val = _messageController.text;
              _messageController.text = val + _quickEmojis[index];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 24))),
            ),
          );
        },
      ),
    );
  }
}