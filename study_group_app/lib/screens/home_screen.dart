// lib/screens/home_screen.dart
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
 
// A small local palette for the home tab, styled after the sticky-note /
// highlighter colors people actually use in study planners — warm paper
// background, ink text, and a set of muted (not neon) accent colors used
// consistently per meaning. Kept local to this file so it doesn't fight
// with CipherColors used elsewhere in the app.
class _Palette {
  static const paper = Color(0xFFFAF5EC);
  static const ink = Color(0xFF2C2A26);
  static const inkSoft = Color(0xFF6F6A61);
  static const card = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFEDE4D3);
 
  static const terracotta = Color(0xFF4E4AC7);      // was 0xFF5B57E0 — a touch darker
static const terracottaDeep = Color(0xFF3A3798);  // was 0xFF4541B8 — noticeably darker
  static const amber = Color(0xFFE0A339);
  static const amberSoft = Color(0xFFF7E6C4);
  static const sage = Color(0xFF6F8F6A);
  static const sageSoft = Color(0xFFDCE6D6);
  static const dustyBlue = Color(0xFF4E7C94);
  static const dustyBlueSoft = Color(0xFFD7E4E8);
  static const plum = Color(0xFF8C5B7C);
  static const plumSoft = Color(0xFFE9DAE5);
}
 
class HomeScreen extends StatefulWidget {
  final  user;
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
            backgroundColor: _Palette.paper,
            body: Center(
              child: CircularProgressIndicator(color: _Palette.terracotta),
            ),
          );
        }
 
        // Guard: some tabs (StudyScreen, GroupsScreen, ProfileScreen, ChatsScreen)
        // need a non-null AppUser. If the stream hasn't delivered one yet
        // (e.g. right after this branch on a slow connection), show a loader
        // instead of passing a nullable value into a non-nullable parameter.
        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: _Palette.paper,
            body: Center(
              child: CircularProgressIndicator(color: _Palette.terracotta),
            ),
          );
        }
 
        return Scaffold(
          backgroundColor: _Palette.paper,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Cipher',
                  style: CipherTextStyles.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _Palette.ink,
                  ).copyWith(letterSpacing: -0.5),
                ),
                const SizedBox(width: 6),
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _Palette.terracotta,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            actions: [
              StreamBuilder<AppUser?>(
                stream: _databaseService.userStream(widget.user.uid),
                builder: (context, snapshot) {
                  final userProfile = snapshot.data;
                  final int requestCount = userProfile?.friendRequests.length ?? 0;
 
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _Palette.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: _Palette.hairline),
                          ),
                          child: IconButton(
                            icon: Icon(
                              requestCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                              color: _Palette.ink,
                              size: 21,
                            ),
                            onPressed: () => _navigateToRequests(context),
                          ),
                        ),
                        if (requestCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              decoration: BoxDecoration(
                                color: _Palette.terracotta,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _Palette.paper, width: 1.5),
                              ),
                              child: Text(
                                requestCount > 9 ? '9+' : '$requestCount',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
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
                  backgroundColor: _Palette.terracotta,
                  elevation: 2,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'New group',
                    style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _Palette.card,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, -4)),
            ],
            border: const Border(top: BorderSide(color: _Palette.hairline, width: 1)),
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
    const activeColor = _Palette.terracotta;
    const inactiveColor = _Palette.inkSoft;
 
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _Palette.terracotta.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? iconFilled : iconOutline,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 21,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: CipherTextStyles.poppins(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: 22,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: _Palette.plum,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
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
      ),
    );
  }
 
  Widget _buildHomeTab(AppUser? currentUser) {
    return RefreshIndicator(
      color: _Palette.terracotta,
      onRefresh: () async {
        if (currentUser != null) {
          await _databaseService.getMyGroups(currentUser.uid).first;
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingHeader(currentUser),
            const SizedBox(height: 26),
            _buildSectionLabel('Quick actions'),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 30),
            _buildMyGroupsSection(currentUser),
            const SizedBox(height: 26),
            _buildAIAssistantCard(context),
          ],
        ),
      ),
    );
  }
 
  Widget _buildSectionLabel(String text, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: CipherTextStyles.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _Palette.ink,
          ).copyWith(letterSpacing: -0.2),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
 
  Widget _buildGreetingHeader(AppUser? currentUser) {
    final hour = DateTime.now().hour;
    String greetingTime = 'Good morning';
    IconData greetingIcon = Icons.wb_twilight_rounded;
    if (hour >= 12 && hour < 17) {
      greetingTime = 'Good afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
    }
    if (hour >= 17) {
      greetingTime = 'Good evening';
      greetingIcon = Icons.nightlight_round;
    }
 
    final firstName = currentUser?.username.split(' ').first ?? 'there';
 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _Palette.terracotta.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_Palette.terracotta, _Palette.terracottaDeep],
                ),
              ),
            ),
            // A quiet decorative motif — a single oversized outline glyph
            // bleeding off the edge — instead of a busy icon-in-a-circle,
            // so the card has depth without extra chrome.
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 118,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(greetingIcon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        greetingTime,
                        style: CipherTextStyles.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 17, 8, 8).withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CipherTextStyles.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 45, 117, 242),
                    ).copyWith(letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Let's make today count.",
                    style: CipherTextStyles.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(255, 18, 42, 80).withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildQuickActions(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(Icons.grid_view_rounded, "My groups", _Palette.dustyBlue, _Palette.dustyBlueSoft, () => setState(() => _selectedIndex = 1)),
      _QuickAction(Icons.search_rounded, "Find groups", _Palette.sage, _Palette.sageSoft, () => setState(() => _selectedIndex = 1)),
      _QuickAction(Icons.person_add_alt_1_rounded, "Add friend", _Palette.plum, _Palette.plumSoft, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SearchUsersScreen(currentUid: widget.user.uid)));
      }),
      _QuickAction(Icons.account_circle_rounded, "Profile", _Palette.amber, _Palette.amberSoft, () => setState(() => _selectedIndex = 4)),
    ];
 
    return Row(
      children: actions
          .map((a) => Expanded(child: _buildActionChip(a)))
          .expand((w) => [w, const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }
 
  Widget _buildActionChip(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.hairline),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: action.tintSoft, borderRadius: BorderRadius.circular(11)),
              child: Icon(action.icon, color: action.tint, size: 17),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CipherTextStyles.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: _Palette.ink).copyWith(height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildMyGroupsSection(AppUser? currentUser) {
    // Sticky-note palette: solid, saturated (not pastel-washed-out, not
    // neon-gradient) tints that rotate per card the way color-coded
    // folders or highlighters would in an actual student's planner.
    const List<Color> tints = [_Palette.dustyBlue, _Palette.sage, _Palette.plum, _Palette.amber];
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          "My groups",
          trailing: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("See all", style: CipherTextStyles.poppins(fontSize: 12.5, color: _Palette.terracotta, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _Palette.terracotta),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 138,
          child: StreamBuilder<List<GroupModel>>(
            stream: currentUser != null ? _databaseService.getMyGroups(currentUser.uid) : const Stream.empty(),
            builder: (context, snapshot) {
              final myGroups = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _Palette.terracotta));
              }
              if (myGroups.isEmpty) {
                return _buildEmptyGroupsState();
              }
 
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: myGroups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final group = myGroups[index];
                  final tint = tints[index % tints.length];
 
                  return Container(
                    width: 188,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Palette.hairline),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tint,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: _Palette.sage, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CipherTextStyles.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: _Palette.ink),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 13, color: _Palette.inkSoft),
                                const SizedBox(width: 4),
                                Text(
                                  "${group.members.length} members",
                                  style: CipherTextStyles.poppins(fontSize: 11.5, color: _Palette.inkSoft, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: _Palette.dustyBlueSoft, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.groups_rounded, size: 16, color: _Palette.dustyBlue),
                    ),
                    const SizedBox(width: 10),
                    Text("No groups yet", style: CipherTextStyles.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: _Palette.ink)),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Create one or join a friend's to get started", style: CipherTextStyles.poppins(fontSize: 11.5, color: _Palette.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => setState(() => _selectedIndex = 1),
            style: TextButton.styleFrom(
              backgroundColor: _Palette.terracotta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Get started", style: CipherTextStyles.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          )
        ],
      ),
    );
  }
 
  Widget _buildAIAssistantCard(BuildContext context) {
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _Palette.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _Palette.ink.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _Palette.amber,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ask the study assistant", style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text("Stuck on something? Get help fast", style: CipherTextStyles.poppins(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _QuickAction {
  final IconData icon;
  final String label;
  final Color tint;
  final Color tintSoft;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.tint, this.tintSoft, this.onTap);
}
 
