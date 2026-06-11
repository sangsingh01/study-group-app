import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class SearchTab extends StatefulWidget {
  final AppUser currentUser;
  const SearchTab({super.key, required this.currentUser});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  final Map<String, String> _buttonStateCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getDeterministicColor(String name) {
    final int hash = name.hashCode;
    final List<Color> palette = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF2563EB),
      const Color(0xFFF59E0B),
    ];
    return palette[hash.abs() % palette.length];
  }

  String _calculateInitialState(AppUser targetedUser) {
    if (widget.currentUser.friends.contains(targetedUser.uid)) return 'FRIENDS';
    if (targetedUser.friendRequests.contains(widget.currentUser.uid)) return 'REQUESTED';
    return 'NOT_FRIENDS';
  }

  Future<void> _triggerAddFriend(AppUser targetUser, String displayName) async {
    setState(() => _buttonStateCache[targetUser.uid] = 'LOADING');

    try {
      await _databaseService.sendFriendRequest(widget.currentUser.uid, targetUser.uid);
      setState(() => _buttonStateCache[targetUser.uid] = 'REQUESTED');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF43E97B),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Friend request sent!', 
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _buttonStateCache[targetUser.uid] = 'NOT_FRIENDS');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF6584),
          content: Text('Failed to send request. Try again.', style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10), 
                  blurRadius: 10, 
                  offset: const Offset(0, 4)
                )
              ]
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search by name or email...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),

        Expanded(
          child: _searchQuery.trim().length < 2
              ? _buildFeedbackPrompt("Type at least 2 characters to search for peers.", Icons.manage_search)
              : StreamBuilder<List<AppUser>>(
                  stream: _databaseService.cipherSearchUsers(_searchQuery, widget.currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                    }
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return _buildFeedbackPrompt("No matching users found.", Icons.person_search_outlined);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final String state = _buttonStateCache[user.uid] ??= _calculateInitialState(user);

                        // Safe map extraction avoids using direct getters on AppUser
                        final Map<String, dynamic> dataMap = user.toMap();
                        final String userName = (dataMap['name'] ?? dataMap['displayName'] ?? 'Cipher User').toString();
                        final String userEmail = (dataMap['email'] ?? '').toString();
                        final String? userPhoto = dataMap['photoURL'] ?? dataMap['photoUrl'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white,
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: _getDeterministicColor(userName),
                                  backgroundImage: userPhoto != null && userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                                  child: userPhoto == null || userPhoto.isEmpty
                                      ? Text(userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : "?",
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E), fontSize: 15)),
                                      Text(userEmail, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text("Mutual: 2 groups", style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _buildStatefulButton(state, user, userName),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildStatefulButton(String state, AppUser targetUser, String displayName) {
    switch (state) {
      case 'LOADING':
        return const SizedBox(
          width: 24, 
          height: 24, 
          child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2)
        );
      case 'FRIENDS':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFE8FFF4), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF43E97B), size: 16),
              const SizedBox(width: 4),
              Text("Friends", style: GoogleFonts.poppins(color: const Color(0xFF43E97B), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      case 'REQUESTED':
        return Tooltip(
          message: "Request pending",
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Color(0xFF6B7280), size: 16),
                const SizedBox(width: 4),
                Text("Requested", style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        );
      default:
        return TextButton.icon(
          onPressed: () => _triggerAddFriend(targetUser, displayName),
          icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
          label: Text("Add Friend", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
    }
  }

  Widget _buildFeedbackPrompt(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.grey.withAlpha(80)),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}