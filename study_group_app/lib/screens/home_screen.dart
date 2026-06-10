import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/group_model.dart';
import '../models/user_model.dart';
import '../providers/profile_provider.dart';
import '../screens/create_group_screen.dart';
import '../screens/group_details_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_users_screen.dart';
import '../services/database_service.dart';
import 'chats_screen.dart'; 
import 'study_screen.dart';
import 'friend_requests_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendRequestsScreen(
          currentUid: widget.user.uid,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).initialize(widget.user);
    });
    _databaseService.setUserActive(widget.user.uid, true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _databaseService.userStream(widget.user.uid),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        final colorScheme = Theme.of(context).colorScheme;

        if (userSnapshot.connectionState == ConnectionState.waiting &&
            currentUser == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            title: Text(
              'StudyGroup',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF6C63FF),
            elevation: 0,
            actions: [
              StreamBuilder<AppUser?>(
                stream: _databaseService.userStream(widget.user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () => _navigateToRequests(context),
                    );
                  }

                  final userProfile = snapshot.data!;
                  final int requestCount = userProfile.friendRequests.length;

                  if (requestCount == 0) {
                    return IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () => _navigateToRequests(context),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () => _navigateToRequests(context),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$requestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(currentUser), 
              GroupsScreen(currentUser: currentUser, user: widget.user),
              ChatsScreen(user: widget.user, currentUser: currentUser),
              const StudyScreen(),
              ProfileScreen(currentUser: currentUser),
            ],
          ),
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateGroupScreen(user: widget.user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Group'),
                )
              : null,
          bottomNavigationBar: _buildCustomBottomNav(context),
        );
      },
    );
  }

  Widget _buildCustomBottomNav(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final slateGray = colorScheme.onSurface.withValues(alpha: 0.6);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _databaseService.getChatList(widget.user.uid),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (var chat in snapshot.data!) {
            unreadCount += (chat['unread_${widget.user.uid}'] ?? 0) as int;
          }
        }

        return Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: primary, inactiveColor: slateGray),
              _navItem(icon: Icons.group_rounded, label: 'Groups', index: 1, activeColor: primary, inactiveColor: slateGray),
              _navItem(icon: Icons.chat_bubble_rounded, label: 'Chat', index: 2, activeColor: primary, inactiveColor: slateGray, badgeCount: unreadCount),
              _navItem(icon: Icons.menu_book_rounded, label: 'Study', index: 3, activeColor: primary, inactiveColor: slateGray),
              _navItem(icon: Icons.person_rounded, label: 'Profile', index: 4, activeColor: primary, inactiveColor: slateGray),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
    int? badgeCount,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: 12,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(AppUser? currentUser) {
    return StreamBuilder<List<GroupModel>>(
      stream: currentUser != null
          ? _databaseService.getMyGroups(currentUser.uid)
          : const Stream.empty(),
      builder: (context, myGroupsSnapshot) {
        final myGroups = myGroupsSnapshot.data ?? [];
        final greeting = _getGreeting();

        return RefreshIndicator(
          onRefresh: () async {
            if (currentUser != null) {
              await _databaseService.getMyGroups(currentUser.uid).first;
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 18),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8E7DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
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
                                  '$greeting, ${currentUser?.username.split(' ').first ?? 'Learner'}! 👋',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your study space is ready.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withValues(alpha: 0.24),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHomeActionButton(
                      context: context,
                      icon: Icons.group_rounded,
                      label: 'My Groups',
                      color: const Color(0xFF6C63FF),
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _buildHomeActionButton(
                      context: context,
                      icon: Icons.explore_rounded,
                      label: 'Find Groups',
                      color: const Color(0xFF43E97B),
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _buildHomeActionButton(
                      context: context,
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Add Friend',
                      color: const Color(0xFFFF6584),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchUsersScreen(currentUid: widget.user.uid),
                          ),
                        );
                      },
                    ),
                    _buildHomeActionButton(
                      context: context,
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      color: const Color(0xFF4C8DFF),
                      onTap: () => setState(() => _selectedIndex = 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Groups',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: Text(
                        'See All',
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (myGroups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No groups yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(
                          'Join a group to start collaborating with classmates.',
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _selectedIndex = 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(
                              'Find a Group',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: myGroups.map((group) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildCompactGroupCard(group, currentUser),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 26),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final buttonWidth = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;
    return SizedBox(
      width: buttonWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGroupCard(GroupModel group, AppUser? currentUser) {
    final bool isMember = currentUser != null && group.members.contains(currentUser.uid);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('${group.members.length} members', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: currentUser == null || isMember
                      ? null
                      : () async {
                          await _databaseService.joinGroup(group.id, widget.user.uid);
                        },
                  child: Text(isMember ? 'Joined' : 'Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}