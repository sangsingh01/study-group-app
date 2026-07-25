//Here is the updated code for `lib/screens/study_screen.dart`.

//The navigation in `_buildQuickAiAccessCard()` and the 2x2 grid tile for **AI Assistant** have both been updated to navigate to `AiChatScreen()` as requested.

//```dart
// lib/screens/study_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'notes_screen.dart';
import 'tasks_ui.dart';
import 'quiz_screen.dart';
import 'ai_assistant_screen.dart';
import 'study_timer_screen.dart';
import 'ai_chat_screen.dart';
class StudyScreen extends StatefulWidget {
  final AppUser currentUser; // Updated to pass full AppUser object

  const StudyScreen({super.key, required this.currentUser});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  bool isWeeklySelected = true; // Tracks the state of the analytics switcher toggle

  /// Opens a modal sheet allowing the user to select a study group
  /// before navigating to the GroupQuizListScreen.
  void _openGroupSelectorForQuiz(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Group for Quizzes',
                style: CipherTextStyles.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a study group to view or create quizzes.',
                style: CipherTextStyles.poppins(
                  fontSize: 12,
                  color: Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .where('members', arrayContains: widget.currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: CipherColors.greenPrimary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading groups.',
                          style: CipherTextStyles.poppins(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'You are not a member of any study groups yet.',
                          style: CipherTextStyles.poppins(color: Colors.grey),
                        ),
                      );
                    }

                    final groups = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return GroupModel.fromMap({
                        ...data,
                        'id': doc.id,
                      });
                    }).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: CipherColors.quizBg,
                            child: Icon(
                              Icons.groups_rounded,
                              color: CipherColors.greenPrimary,
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: CipherTextStyles.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${group.members.length} members',
                            style: CipherTextStyles.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(ctx); // Close modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupQuizListScreen(
                                  group: group,
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Opens the per-group Study Timer
  void _openGroupSelectorForTimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Group to Study',
                style: CipherTextStyles.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose which group this study session counts toward.',
                style: CipherTextStyles.poppins(
                  fontSize: 12,
                  color: Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .where('members', arrayContains: widget.currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: CipherColors.greenPrimary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading groups.',
                          style: CipherTextStyles.poppins(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'You are not a member of any study groups yet.',
                          style: CipherTextStyles.poppins(color: Colors.grey),
                        ),
                      );
                    }

                    final groups = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return GroupModel.fromMap({
                        ...data,
                        'id': doc.id,
                      });
                    }).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: CipherColors.tasksBg,
                            child: Icon(
                              Icons.timer_rounded,
                              color: CipherColors.pinkPrimary,
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: CipherTextStyles.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${group.members.length} members',
                            style: CipherTextStyles.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(ctx); // Close modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyTimerScreen(
                                  groupId: group.id,
                                  userId: widget.currentUser.uid,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  _buildQuickAiAccessCard(),
                  const SizedBox(height: 14),
                  _buildStudyTimerCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEADER COMPONENT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, left: 20, right: 20, bottom: 32),
      decoration: const BoxDecoration(
        gradient: CipherColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Hub',
            style: CipherTextStyles.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All your learning in one place',
            style: CipherTextStyles.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2x2 FEATURE GRID CARDS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildFeatureGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: [
        _buildGridCard(
          bg: CipherColors.notesBg,
          iconBg: Colors.white,
          iconColor: CipherColors.purplePrimary,
          icon: Icons.folder_copy_rounded,
          title: "Notes",
          sub: " share files",
          titleColor: CipherColors.notesText,
          subColor: CipherColors.notesSub,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotesScreen(currentUid: widget.currentUser.uid),
            ),
          ),
        ),
        _buildGridCard(
          bg: CipherColors.tasksBg,
          iconBg: Colors.white,
          iconColor: CipherColors.pinkPrimary,
          icon: Icons.check_box_rounded,
          title: "Tasks",
          sub: "make your tasks complete",
          titleColor: CipherColors.tasksText,
          subColor: CipherColors.tasksSub,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyTasksScreen(currentUser: widget.currentUser),
            ),
          ),
        ),
        _buildGridCard(
          bg: CipherColors.quizBg,
          iconBg: Colors.white,
          iconColor: CipherColors.greenPrimary,
          icon: Icons.help_center_rounded,
          title: "Quiz",
          sub: "play and learn",
          titleColor: CipherColors.quizText,
          subColor: CipherColors.quizSub,
          onTap: () => _openGroupSelectorForQuiz(context),
        ),
        _buildGridCard(
          bg: CipherColors.aiBg,
          iconBg: Colors.white,
          iconColor: CipherColors.orangePrimary,
          icon: Icons.adb_rounded,
          title: "AI Assistant",
          sub: "Ask anything",
          titleColor: CipherColors.aiText,
          subColor: CipherColors.aiSub,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required Color bg,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String sub,
    required Color titleColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: iconBg,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: titleColor.withValues(alpha: 0.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CipherTextStyles.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: CipherTextStyles.poppins(
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // QUICK AI ASSISTANT OVERLAY CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildQuickAiAccessCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AiChatScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CipherColors.purpleGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask AI Study Assistant',
                    style: CipherTextStyles.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get instant answers to any question',
                    style: CipherTextStyles.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // STUDY TIMER OVERLAY CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildStudyTimerCard() {
    return GestureDetector(
      onTap: () => _openGroupSelectorForTimer(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CipherColors.headerGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Studying',
                    style: CipherTextStyles.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track your study time and build a streak',
                    style: CipherTextStyles.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

