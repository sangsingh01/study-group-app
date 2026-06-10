import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../screens/search_users_screen.dart';
import '../screens/direct_message_screen.dart';
import '../services/database_service.dart';

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
            content: Text('${requester.username} is now your friend.'),
            backgroundColor: const Color(0xFF43E97B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to accept request from ${requester.username}.'),
            backgroundColor: const Color(0xFFFF6584),
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
            content: Text('Declined request from ${requester.username}.'),
            backgroundColor: const Color(0xFF6B7280),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to decline request from ${requester.username}.'),
            backgroundColor: const Color(0xFFFF6584),
          ),
        );
      }
    }
  }

  Widget _buildAvatar(AppUser member) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.18),
          foregroundImage: member.profileImage != null ? NetworkImage(member.profileImage!) : null,
          child: member.profileImage == null
              ? Text(
                  member.initials,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                )
              : null,
        ),
        if (member.isActive)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF43E97B),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: _databaseService.userStream(widget.user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            final currentUser = snapshot.data;
            if (currentUser == null) {
              return const Center(child: Text('Unable to load profile information.'));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Friends',
                              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Connect with classmates and manage requests.',
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280)),
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
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                        label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search friends',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C63FF)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Friend Requests',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          if (currentUser.friendRequests.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 10))],
                              ),
                              child: Row(
                                children: [
                                  const Text('📭', style: TextStyle(fontSize: 32)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'No pending requests — invite classmates to connect.',
                                      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280)),
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
                                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                                }
                                final requesters = requestSnapshot.data ?? [];
                                return Column(
                                  children: requesters.map((requester) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      elevation: 0,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                              foregroundImage: requester.profileImage != null ? NetworkImage(requester.profileImage!) : null,
                                              child: requester.profileImage == null
                                                  ? Text(
                                                      requester.initials,
                                                      style: GoogleFonts.poppins(color: const Color(0xFF1A1A2E), fontWeight: FontWeight.w700),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(requester.username, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                                                  const SizedBox(height: 4),
                                                  Text(requester.email, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280))),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B), size: 28),
                                                  onPressed: () => _acceptRequest(requester),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFFFF6584), size: 28),
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
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          StreamBuilder<List<AppUser>>(
                            stream: _databaseService.usersByIdsStream(currentUser.friends),
                            builder: (context, friendSnapshot) {
                              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                              }
                              final friends = friendSnapshot.data ?? [];
                              final filteredFriends = _searchQuery.isEmpty
                                  ? friends
                                  : friends.where((friend) {
                                      return friend.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                          friend.email.toLowerCase().contains(_searchQuery.toLowerCase());
                                    }).toList();

                              if (filteredFriends.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Center(
                                    child: Text(
                                      _searchQuery.isEmpty ? 'Your friend list is empty.' : 'No friends match your search.',
                                      style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
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
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 10))],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      leading: _buildAvatar(friend),
                                      title: Text(friend.username, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                      subtitle: Text(friend.email, style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 13)),
                                      trailing: Container(
                                        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), shape: BoxShape.circle),
                                        child: IconButton(
                                          icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF6C63FF), size: 20),
                                          onPressed: () {
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
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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
