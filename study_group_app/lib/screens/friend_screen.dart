import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../screens/search_users_screen.dart';
import '../screens/direct_message_screen.dart';
import '../services/database_service.dart';

// Palette matching the home tab UI style
class _Palette {
  static const paper = Color(0xFFF6F5F2);
  static const ink = Color(0xFF232338);
  static const inkSoft = Color(0xFF74748C);
  static const card = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFE7E6EF);

  static const indigo = Color(0xFF4E4AC7);
  static const amber = Color(0xFFF2A33D);
  static const teal = Color(0xFF1FA98C);
  static const coral = Color(0xFFEB6F5C);
  static const plum = Color(0xFFB4519C);

  static const accents = [indigo, teal, coral, plum, amber];
}

class FriendScreen extends StatefulWidget {
  final User user;
  const FriendScreen({super.key, required this.user});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest(AppUser requester) async {
    try {
      await _databaseService.acceptFriendRequest(
        widget.user.uid,
        requester.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${requester.username} is now your friend.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: _Palette.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to accept request from ${requester.username}.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: _Palette.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(AppUser requester) async {
    try {
      await _databaseService.declineFriendRequest(
        widget.user.uid,
        requester.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Declined request from ${requester.username}.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: _Palette.inkSoft,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to decline request from ${requester.username}.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: _Palette.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildAvatar(AppUser member, Color accentColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: accentColor.withValues(alpha: 0.15),
          foregroundImage: member.profileImage != null ? NetworkImage(member.profileImage!) : null,
          child: member.profileImage == null
              ? Text(
                  member.initials,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                )
              : null,
        ),
        if (member.isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.teal,
                border: Border.all(color: _Palette.card, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.paper,
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: _databaseService.userStream(widget.user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _Palette.indigo),
              );
            }
            final currentUser = snapshot.data;
            if (currentUser == null) {
              return Center(
                child: Text(
                  'Unable to load profile information.',
                  style: GoogleFonts.poppins(color: _Palette.inkSoft),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Friends',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _Palette.ink,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with classmates and manage requests.',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: _Palette.inkSoft,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchUsersScreen(currentUid: widget.user.uid),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.indigo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                    style: GoogleFonts.poppins(fontSize: 13.5, color: _Palette.ink),
                    decoration: InputDecoration(
                      hintText: 'Search friends',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: _Palette.inkSoft.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: _Palette.indigo, size: 20),
                      filled: true,
                      fillColor: _Palette.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _Palette.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _Palette.indigo, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Friend Requests',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _Palette.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (currentUser.friendRequests.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _Palette.card,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _Palette.hairline),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _Palette.indigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_unread_rounded,
                                      color: _Palette.indigo,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'No pending requests — invite classmates to connect.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        color: _Palette.inkSoft,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            StreamBuilder<List<AppUser>>(
                              stream: _databaseService.usersByIdsStream(currentUser.friendRequests),
                              builder: (context, requestSnapshot) {
                                if (requestSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(color: _Palette.indigo),
                                  );
                                }
                                final requesters = requestSnapshot.data ?? [];
                                return Column(
                                  children: requesters.map((requester) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: _Palette.card,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: _Palette.hairline),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            _buildAvatar(requester, _Palette.indigo),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    requester.username,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: _Palette.ink,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    requester.email,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12.5,
                                                      color: _Palette.inkSoft,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: _Palette.teal,
                                                    size: 26,
                                                  ),
                                                  onPressed: () => _acceptRequest(requester),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel_rounded,
                                                    color: _Palette.coral,
                                                    size: 26,
                                                  ),
                                                  onPressed: () => _declineRequest(requester),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'My Friends',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _Palette.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<AppUser>>(
                            stream: _databaseService.usersByIdsStream(currentUser.friends),
                            builder: (context, friendSnapshot) {
                              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(color: _Palette.indigo),
                                );
                              }
                              final friends = friendSnapshot.data ?? [];
                              final filteredFriends = _searchQuery.isEmpty
                                  ? friends
                                  : friends.where((friend) {
                                      return friend.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                          friend.email.toLowerCase().contains(_searchQuery.toLowerCase());
                                    }).toList();

                              if (filteredFriends.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: _Palette.card,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: _Palette.hairline),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'Your friend list is empty.'
                                          : 'No friends match your search.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        color: _Palette.inkSoft,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredFriends.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final friend = filteredFriends[index];
                                  final accentColor = _Palette.accents[index % _Palette.accents.length];

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _Palette.card,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: _Palette.hairline),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(22),
                                        onTap: () {
                                          final conversationChatId = _databaseService.getChatId(widget.user.uid, friend.uid);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DirectMessageScreen(
                                                currentUser: currentUser,
                                                currentUserAuthData: widget.user,
                                                friend: friend,
                                                chatId: conversationChatId,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              _buildAvatar(friend, accentColor),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      friend.username,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: _Palette.ink,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      friend.email,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12.5,
                                                        color: _Palette.inkSoft,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: _Palette.indigo.withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.chat_bubble_rounded,
                                                  color: _Palette.indigo,
                                                  size: 18,
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
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}