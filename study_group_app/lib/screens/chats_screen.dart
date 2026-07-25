import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import 'direct_message_screen.dart';
import 'search_users_screen.dart';

class _ModernPalette {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color primary = Color(0xFF6366F1);
  static const Color accentNeon = Color(0xFF38BDF8);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color stroke = Color(0xFF334155);
}

class ChatsScreen extends StatefulWidget {
  final AppUser? currentUser;
  final User user;

  const ChatsScreen({
    super.key,
    required this.currentUser,
    required this.user,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _ModernPalette.primary;
    final colors = [
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
    ];
    return colors[name.trim().length % colors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSearchUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchUsersScreen(currentUid: widget.user.uid),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (now.difference(dateTime).inMinutes < 1) {
      return 'Just now';
    } else if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  Stream<List<Map<String, dynamic>>> _getChatListWithIds(String userId) {
    return _databaseService.getChatList(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ModernPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: _ModernPalette.surface,
                border: Border(
                  bottom: BorderSide(color: _ModernPalette.stroke),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Messages',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _ModernPalette.textMain,
                            ),
                          ),
                          Text(
                            'Private chats with friends',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _ModernPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _navigateToSearchUsers(context),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ModernPalette.surfaceLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _ModernPalette.stroke),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: _ModernPalette.accentNeon,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add Friends',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _ModernPalette.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _ModernPalette.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _ModernPalette.textMuted,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: _ModernPalette.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _ModernPalette.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      color: _ModernPalette.textMain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getChatListWithIds(widget.user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final chats = snapshot.data!;

                  // Sort conversations dynamically in real time by latest message times
                  chats.sort((a, b) {
                    final dynamic timeA = a['lastMessageTime'];
                    final dynamic timeB = b['lastMessageTime'];

                    int msA = 0;
                    int msB = 0;

                    if (timeA is Timestamp) msA = timeA.millisecondsSinceEpoch;
                    if (timeA is int) msA = timeA;

                    if (timeB is Timestamp) msB = timeB.millisecondsSinceEpoch;
                    if (timeB is int) msB = timeB;

                    return msB.compareTo(msA);
                  });

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: _ModernPalette.stroke,
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _buildChatTile(context, chat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _ModernPalette.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    color: _ModernPalette.surface,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 10,
                    color: _ModernPalette.surface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: _ModernPalette.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: _ModernPalette.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Friends and start a conversation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _ModernPalette.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _ModernPalette.primary,
              foregroundColor: _ModernPalette.textMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchUsersScreen(currentUid: widget.user.uid),
                ),
              );
            },
            icon: const Icon(Icons.group_rounded),
            label: Text(
              'Find Friends',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    final participants = List<String>.from(chat['participants'] ?? []);
    final friendUid = participants.firstWhere((uid) => uid != widget.user.uid,
        orElse: () => '');

    final originalMessage = (chat['lastMessage'] ?? '').toString();
    final lastMessageLower = originalMessage.toLowerCase();
    final lastMessageTime = chat['lastMessageTime'];
    final unreadCount = chat['unread_${widget.user.uid}'] ?? 0;
    final chatId = chat['chatId'] ?? '';
    final String messageType = chat['messageType'] ?? 'text';

    if (friendUid.isEmpty) return const SizedBox.shrink();

    DateTime messageDateTime;
    if (lastMessageTime != null) {
      if (lastMessageTime is Timestamp) {
        messageDateTime = lastMessageTime.toDate();
      } else if (lastMessageTime is int) {
        messageDateTime = DateTime.fromMillisecondsSinceEpoch(lastMessageTime);
      } else {
        messageDateTime = DateTime.now();
      }
    } else {
      messageDateTime = DateTime.now();
    }

    return FutureBuilder<AppUser?>(
      future: _databaseService.getUserByUid(friendUid),
      builder: (context, friendSnapshot) {
        if (!friendSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final friend = friendSnapshot.data!;
        final username = friend.username.toLowerCase();

        // INTENTIONAL FILTER CHECK: If query doesn't match name AND doesn't match text message, shrink item entirely
        if (_searchQuery.isNotEmpty &&
            !username.contains(_searchQuery) &&
            !lastMessageLower.contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        // Handle file type specific rendering checks dynamically
        String displayMessageText = originalMessage;
        bool isItalic = false;

        if (messageType == 'file') {
          displayMessageText = 'Sent a file: $originalMessage';
        } else if (originalMessage.isEmpty) {
          displayMessageText = 'Say hi!';
          isItalic = true;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DirectMessageScreen(
                    currentUser: widget.currentUser,
                    currentUserAuthData: widget.user,
                    friend: friend,
                    chatId: chatId,
                  ),
                ),
              );
              _databaseService.markMessagesAsRead(chatId, widget.user.uid);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: friend.profileImage != null
                              ? NetworkImage(friend.profileImage!)
                              : null,
                          backgroundColor: _getAvatarColor(friend.username),
                          child: friend.profileImage == null
                              ? Text(
                                  friend.initials,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                )
                              : null,
                        ),
                        if (friend.isActive)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _ModernPalette.background,
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                friend.username,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _ModernPalette.textMain,
                                ),
                              ),
                              Text(
                                _formatTime(messageDateTime),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _ModernPalette.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  displayMessageText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontStyle: isItalic
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: isItalic
                                        ? _ModernPalette.textMuted
                                        : _ModernPalette.textMuted,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _ModernPalette.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}