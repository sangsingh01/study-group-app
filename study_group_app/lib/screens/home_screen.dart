// lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/design_system.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_users_screen.dart';
import '../services/database_service.dart';
import 'chats_screen.dart';
import 'friend_requests_screen.dart';
import 'study_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;

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
    _databaseService.setUserActive(widget.user.uid, true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _databaseService.userStream(widget.user.uid),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;

        if (userSnapshot.connectionState == ConnectionState.waiting && currentUser == null) {
          return const Scaffold(
            backgroundColor: CipherColors.background,
            body: Center(
              child: CircularProgressIndicator(color: CipherColors.primary),
            ),
          );
        }

        // Guard: some tabs (StudyScreen, GroupsScreen, ProfileScreen, ChatsScreen)
        // need a non-null AppUser. If the stream hasn't delivered one yet
        // (e.g. right after this branch on a slow connection), show a loader
        // instead of passing a nullable value into a non-nullable parameter.
        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: CipherColors.background,
            body: Center(
              child: CircularProgressIndicator(color: CipherColors.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: CipherColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Cipher',
              style: CipherTextStyles.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CipherColors.primary,
              ),
            ),
            actions: [
              StreamBuilder<AppUser?>(
                stream: _databaseService.userStream(widget.user.uid),
                builder: (context, snapshot) {
                  final userProfile = snapshot.data;
                  final int requestCount = userProfile?.friendRequests.length ?? 0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          requestCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                          color: CipherColors.primary,
                          size: 26,
                        ),
                        onPressed: () => _navigateToRequests(context),
                      ),
                      if (requestCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(currentUser),
              GroupsScreen(currentUser: currentUser, user: widget.user),
              ChatsScreen(user: widget.user, currentUser: currentUser),
              StudyScreen(currentUser: currentUser),
              ProfileScreen(currentUser: currentUser),
            ],
          ),
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateGroupScreen(user: widget.user),
                      ),
                    );
                  },
                  backgroundColor: CipherColors.primary,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'Create Group',
                    style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          bottomNavigationBar: _buildCustomBottomNav(context),
        );
      },
    );
  }

  Widget _buildCustomBottomNav(BuildContext context) {
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
          height: 65,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: CipherColors.border, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(iconOutline: Icons.home_outlined, iconFilled: Icons.home_rounded, label: 'Home', index: 0),
              _navItem(iconOutline: Icons.groups_outlined, iconFilled: Icons.groups_rounded, label: 'Groups', index: 1),
              _navItem(iconOutline: Icons.chat_bubble_outline_rounded, iconFilled: Icons.chat_bubble_rounded, label: 'Chat', index: 2, badgeCount: unreadCount),
              _navItem(iconOutline: Icons.menu_book_outlined, iconFilled: Icons.menu_book_rounded, label: 'Study', index: 3),
              _navItem(iconOutline: Icons.person_outline_rounded, iconFilled: Icons.person_rounded, label: 'Profile', index: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem({
    required IconData iconOutline,
    required IconData iconFilled,
    required String label,
    required int index,
    int? badgeCount,
  }) {
    final isSelected = _selectedIndex == index;
    final activeColor = CipherColors.primary;
    final inactiveColor = CipherColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? activeColor : Colors.transparent,
                  ),
                ),
                Icon(
                  isSelected ? iconFilled : iconOutline,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: CipherTextStyles.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: 16,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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
    return RefreshIndicator(
      color: CipherColors.primary,
      onRefresh: () async {
        if (currentUser != null) {
          await _databaseService.getMyGroups(currentUser.uid).first;
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingBanner(currentUser),
            const SizedBox(height: 16),
            _buildStatsRow(currentUser),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 16),
            _buildMyGroupsSection(currentUser),
            const SizedBox(height: 16),
            _buildAIAssistantBanner(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingBanner(AppUser? currentUser) {
    final hour = DateTime.now().hour;
    String greetingTime = 'Good Morning';
    if (hour >= 12 && hour < 17) greetingTime = 'Good Afternoon';
    if (hour >= 17) greetingTime = 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: CipherColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CipherColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greetingTime,",
                      style: CipherTextStyles.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${currentUser?.username.split(' ').first ?? 'Learner'}! ",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your learning dashboard is ready",
                      style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.waving_hand_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "3 Day Streak!",
                    style: CipherTextStyles.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Text(
                "Keep it up ✨",
                style: CipherTextStyles.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppUser? currentUser) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        int groupCount = 0;
        int friendCount = currentUser?.friends.length ?? 0;
        int xpCount = 800;
        String studyTime = "2.1h";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          groupCount = (data?['groups'] as List?)?.length ?? 0;
          xpCount = data?['xp'] ?? 800;
          studyTime = data?['studyTime'] ?? "2.1h";
        }

        return Row(
          children: [
            Expanded(child: _buildStatItem(Icons.groups_rounded, "$groupCount", "Groups", CipherColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.people_rounded, "$friendCount", "Friends", CipherColors.secondary)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.bolt_rounded, "$xpCount", "XP Points", CipherColors.pink)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem(Icons.timer_rounded, studyTime, "Studied", CipherColors.blue)),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color accentColor) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
          ),
          Text(
            label,
            style: CipherTextStyles.poppins(fontSize: 11, color: CipherColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final itemWidth = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildCompactActionCard(Icons.grid_view_rounded, "My Groups", CipherColors.primaryLight, CipherColors.primary, itemWidth, () => setState(() => _selectedIndex = 1)),
        _buildCompactActionCard(Icons.search_rounded, "Find Groups", CipherColors.secondaryLight, CipherColors.secondary, itemWidth, () => setState(() => _selectedIndex = 1)),
        _buildCompactActionCard(Icons.person_add_alt_1_rounded, "Add Friend", CipherColors.pinkLight, CipherColors.pink, itemWidth, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SearchUsersScreen(currentUid: widget.user.uid)));
        }),
        _buildCompactActionCard(Icons.account_circle_rounded, "My Profile", CipherColors.blueLight, CipherColors.blue, itemWidth, () => setState(() => _selectedIndex = 4)),
      ],
    );
  }

  Widget _buildCompactActionCard(IconData icon, String label, Color bg, Color tint, double width, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: bg,
              child: Icon(icon, color: tint, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: CipherColors.textPrimary),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsSection(AppUser? currentUser) {
    const List<LinearGradient> gradients = [
      CipherColors.primaryGradient,
      CipherColors.secondaryGradient,
      CipherColors.pinkGradient,
      CipherColors.blueGradient,
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("My Groups", style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: Text("See All", style: CipherTextStyles.poppins(fontSize: 13, color: CipherColors.primary, fontWeight: FontWeight.w600)),
            )
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: StreamBuilder<List<GroupModel>>(
            stream: currentUser != null ? _databaseService.getMyGroups(currentUser.uid) : const Stream.empty(),
            builder: (context, snapshot) {
              final myGroups = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: CipherColors.primary));
              }
              if (myGroups.isEmpty) {
                return _buildEmptyGroupsState();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: myGroups.length,
                itemBuilder: (context, index) {
                  final group = myGroups[index];
                  final gradient = gradients[index % gradients.length];

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Subject Group",
                                style: CipherTextStyles.poppins(fontSize: 10, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${group.members.length} members",
                              style: CipherTextStyles.poppins(fontSize: 12, color: Colors.white70),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "Active",
                                style: CipherTextStyles.poppins(fontSize: 10, color: CipherColors.primary, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
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

  Widget _buildEmptyGroupsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("No groups yet", style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("Create or join a group", style: CipherTextStyles.poppins(fontSize: 11, color: CipherColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => _selectedIndex = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: CipherColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Get Started", style: CipherTextStyles.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildAIAssistantBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiAssistantScreen(currentUid: widget.user.uid),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CipherColors.orangeGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ask AI Study Assistant", style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Get instant help with your studies", style: CipherTextStyles.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}