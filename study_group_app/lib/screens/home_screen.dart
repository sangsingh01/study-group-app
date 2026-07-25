import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
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
 
/// Next-Generation Dark Theme Palette
class _ModernPalette {
  static const background = Color(0xFF0D0F17);
  static const surface = Color(0xFF161926);
  static const surfaceLight = Color(0xFF202538);
  static const stroke = Color(0xFF2D334B);
 
  static const primary = Color(0xFF6366F1); // Modern Electric Indigo
  static const primaryGradientEnd = Color(0xFF8B5CF6); // Vibrant Purple
  static const accentNeon = Color(0xFF06B6D4); // Cyan Glow
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFEF4444);
 
  static const textMain = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
}
 
class HomeScreen extends StatefulWidget {
  final dynamic user;
  const HomeScreen({super.key, required this.user});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;
 
  // Focus Timer & Daily Progress State
  double _focusHoursCompleted = 2.5; // Hours focused today
  final double _dailyFocusGoal = 4.0; // Goal in hours
  bool _isTimerActive = false;
 
  // Integrated Tasks (Connected to Study Section)
  final List<Map<String, dynamic>> _remainingTasks = [
    {
      'id': '1',
      'title': 'Solve Calculus Chapter 4 Exercises',
      'group': 'Mathematics',
      'dueDate': 'Today, 5:00 PM',
      'isCompleted': false,
      'priority': 'High',
    },
    {
      'id': '2',
      'title': 'Review Quantum Mechanics Notes',
      'group': 'Physics',
      'dueDate': 'Tomorrow',
      'isCompleted': false,
      'priority': 'Medium',
    },
    {
      'id': '3',
      'title': 'Complete Data Structures Quiz',
      'group': 'Computer Science',
      'dueDate': 'In 2 days',
      'isCompleted': false,
      'priority': 'Normal',
    },
  ];
 
  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
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
 
  // NEW: opens the search screen so the user can find people and send friend requests.
  // Assumption: SearchUsersScreen takes a `currentUid` param, matching the pattern
  // used by FriendRequestsScreen/AiAssistantScreen below. Adjust if its constructor differs.
  void _navigateToSearchUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchUsersScreen(
          currentUid: widget.user.uid,
        ),
      ),
    );
  }
 
  void _navigateToNotes(BuildContext context) {
    // Navigate to Study Screen with Notes View selected
    setState(() {
      _selectedIndex = 3; // Index for StudyScreen
    });
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
            backgroundColor: _ModernPalette.background,
            body: Center(
              child: CircularProgressIndicator(color: _ModernPalette.primary),
            ),
          );
        }
 
        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: _ModernPalette.background,
            body: Center(
              child: CircularProgressIndicator(color: _ModernPalette.primary),
            ),
          );
        }
 
        return Scaffold(
          backgroundColor: _ModernPalette.background,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: _ModernPalette.background.withOpacity(0.85),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_ModernPalette.primary, _ModernPalette.accentNeon],
                  ).createShader(bounds),
                  child: Text(
                    'Cipher',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _ModernPalette.accentNeon,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            actions: [
              // NEW: Add Friends button — opens SearchUsersScreen to find & send requests
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _navigateToSearchUsers(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _ModernPalette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _ModernPalette.stroke),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: _ModernPalette.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              StreamBuilder<AppUser?>(
                stream: _databaseService.userStream(widget.user.uid),
                builder: (context, snapshot) {
                  final userProfile = snapshot.data;
                  final int requestCount = userProfile?.friendRequests.length ?? 0;
 
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _navigateToRequests(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _ModernPalette.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _ModernPalette.stroke),
                              ),
                              child: Icon(
                                requestCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                color: requestCount > 0
                                    ? _ModernPalette.accentNeon
                                    : _ModernPalette.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (requestCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _ModernPalette.rose,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _ModernPalette.background, width: 2),
                              ),
                              child: Text(
                                requestCount > 9 ? '9+' : '$requestCount',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: IndexedStack(
              key: ValueKey<int>(_selectedIndex),
              index: _selectedIndex,
              children: [
                _buildHomeTab(currentUser),
                GroupsScreen(currentUser: currentUser, user: widget.user),
                ChatsScreen(user: widget.user, currentUser: currentUser),
                StudyScreen(currentUser: currentUser),
                ProfileScreen(currentUser: currentUser),
              ],
            ),
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
                  backgroundColor: _ModernPalette.primary,
                  elevation: 8,
                  // shadowColor: _ModernPalette.primary.withOpacity(0.5),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'New Group',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: _buildModernBottomNav(context),
        );
      },
    );
  }
 
  Widget _buildHomeTab(AppUser? currentUser) {
    return RefreshIndicator(
      color: _ModernPalette.primary,
      backgroundColor: _ModernPalette.surface,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingHeader(currentUser),
            const SizedBox(height: 20),
            _buildInspirationalQuoteCard(),
            const SizedBox(height: 24),
            _buildSectionLabel('Focus & Daily Progress'),
            const SizedBox(height: 14),
            _buildProgressAndTimerCard(),
            const SizedBox(height: 28),
            _buildSectionLabel('Study Features'),
            const SizedBox(height: 14),
            _buildStudyFeaturesList(context),
            const SizedBox(height: 28),
            _buildRemainingTasksSection(),
            const SizedBox(height: 28),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ModernPalette.textMain,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
 
  Widget _buildGreetingHeader(AppUser? currentUser) {
    final hour = DateTime.now().hour;
    String greetingTime = 'Good Morning';
    IconData greetingIcon = Icons.wb_twilight_rounded;
    if (hour >= 12 && hour < 17) {
      greetingTime = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 17) {
      greetingTime = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
    }
 
    final firstName = currentUser?.username.split(' ').first ?? 'there';
 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ModernPalette.primary,
            _ModernPalette.primaryGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _ModernPalette.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(greetingIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        greetingTime,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Welcome back, $firstName 👋",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Ready to smash your focus goals today?",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildInspirationalQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ModernPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ModernPalette.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _ModernPalette.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.format_quote_rounded, color: _ModernPalette.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "\"Small daily improvements over time lead to stunning results.\"",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: _ModernPalette.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "— Robin Sharma",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _ModernPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildProgressAndTimerCard() {
    final double progressPercentage = (_focusHoursCompleted / _dailyFocusGoal).clamp(0.0, 1.0);
 
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ModernPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ModernPalette.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: progressPercentage,
                      strokeWidth: 8,
                      backgroundColor: _ModernPalette.surfaceLight,
                      color: _ModernPalette.accentNeon,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    "${(progressPercentage * 100).toInt()}%",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ModernPalette.textMain,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Focus Target",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ModernPalette.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_focusHoursCompleted hrs focused of $_dailyFocusGoal hrs goal",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _ModernPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: _ModernPalette.surfaceLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.transparent,
                        color: _ModernPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _ModernPalette.stroke, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _ModernPalette.accentNeon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isTimerActive ? "Focus Session Running..." : "Focus Timer Ready",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ModernPalette.textMain,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isTimerActive = !_isTimerActive;
                    if (_isTimerActive) {
                      _focusHoursCompleted += 0.5; // Demo increments focus hours
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimerActive ? _ModernPalette.rose : _ModernPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  _isTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  _isTimerActive ? "Pause" : "Start Focus",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildStudyFeaturesList(BuildContext context) {
    return Column(
      children: [
        // 1. Uploaded Notes Feature
        GestureDetector(
          onTap: () => _navigateToNotes(context),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _ModernPalette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ModernPalette.stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _ModernPalette.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.folder_shared_rounded,
                    color: _ModernPalette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Uploaded Notes Hub",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ModernPalette.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Access class notes, PDFs & study guides",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _ModernPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _ModernPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 2. Video Meeting Feature (Placeholder)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _ModernPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ModernPalette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ModernPalette.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.video_call_rounded,
                  color: _ModernPalette.emerald,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Video Study Room",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _ModernPalette.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _ModernPalette.emerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Upcoming",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _ModernPalette.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Join live group video sessions & discussions",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _ModernPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _ModernPalette.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildRemainingTasksSection() {
    final pendingCount = _remainingTasks.where((t) => !t['isCompleted']).length;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          "Remaining Tasks",
          trailing: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 3; // Navigate to StudyScreen tasks
              });
            },
            child: Row(
              children: [
                Text(
                  "$pendingCount Pending",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _ModernPalette.accentNeon,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: _ModernPalette.accentNeon,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_remainingTasks.isEmpty)
          _buildEmptyTasksState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _remainingTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = _remainingTasks[index];
              final isDone = task['isCompleted'] as bool;
 
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _ModernPalette.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ModernPalette.stroke),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          task['isCompleted'] = !isDone;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? _ModernPalette.emerald : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDone ? _ModernPalette.emerald : _ModernPalette.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDone ? _ModernPalette.textMuted : _ModernPalette.textMain,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                task['group'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: _ModernPalette.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: _ModernPalette.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time_rounded, size: 12, color: _ModernPalette.amber),
                              const SizedBox(width: 4),
                              Text(
                                task['dueDate'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: _ModernPalette.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
 
  Widget _buildEmptyTasksState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ModernPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ModernPalette.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: _ModernPalette.emerald, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "All tasks completed!",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ModernPalette.textMain,
                ),
              ),
              Text(
                "You're all caught up for today.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _ModernPalette.textMuted,
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _ModernPalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _ModernPalette.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_ModernPalette.accentNeon, _ModernPalette.primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ask AI Assistant",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ModernPalette.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Get instant help with your studies & tasks",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _ModernPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _ModernPalette.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: _ModernPalette.textMain,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildModernBottomNav(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _databaseService.getChatList(widget.user.uid),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (var chat in snapshot.data!) {
            unreadCount += (chat['unread_${widget.user.uid}'] ?? 0) as int;
          }
        }
 
        final items = [
          _NavItemData(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
          _NavItemData(Icons.groups_outlined, Icons.groups_rounded, 'Groups'),
          _NavItemData(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat', badge: unreadCount),
          _NavItemData(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Study'),
          _NavItemData(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
        ];
 
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            height: 68,
            decoration: BoxDecoration(
              color: _ModernPalette.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _ModernPalette.stroke),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = _selectedIndex == index;
 
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected
                                      ? _ModernPalette.accentNeon
                                      : _ModernPalette.textMuted,
                                  size: 22,
                                ),
                              ),
                              if (item.badge != null && item.badge! > 0)
                                Positioned(
                                  right: -8,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC4899),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Text(
                                      item.badge! > 99 ? '99+' : '${item.badge}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? _ModernPalette.textMain
                                  : _ModernPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
 
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
 
  _NavItemData(this.icon, this.activeIcon, this.label, {this.badge});
}