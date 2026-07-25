//
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
      backgroundColor: const Color(0xFF1E293B),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a study group to view or create quizzes.',
                style: CipherTextStyles.poppins(
                  fontSize: 12,
                  color: Colors.grey[400]!,
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
                          style: CipherTextStyles.poppins(color: Colors.redAccent),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'You are not a member of any study groups yet.',
                          style: CipherTextStyles.poppins(color: Colors.grey[400]!),
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
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF064E3B),
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
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${group.members.length} members',
                            style: CipherTextStyles.poppins(
                              fontSize: 12,
                              color: Colors.grey[400]!,
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
      backgroundColor: const Color(0xFF1E293B),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose which group this study session counts toward.',
                style: CipherTextStyles.poppins(
                  fontSize: 12,
                  color: Colors.grey[400]!,
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
                          style: CipherTextStyles.poppins(color: Colors.redAccent),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'You are not a member of any study groups yet.',
                          style: CipherTextStyles.poppins(color: Colors.grey[400]!),
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
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF831843),
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
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${group.members.length} members',
                            style: CipherTextStyles.poppins(
                              fontSize: 12,
                              color: Colors.grey[400]!,
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
      backgroundColor: const Color(0xFF0F172A),
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
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
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
              color: Colors.grey[400]!,
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
          bg: const Color(0xFF1E1B4B),
          iconBg: const Color(0xFF334155),
          iconColor: const Color(0xFFA855F7),
          icon: Icons.folder_copy_rounded,
          title: "Notes",
          sub: " share files",
          titleColor: Colors.white,
          subColor: Colors.grey[400]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotesScreen(currentUid: widget.currentUser.uid),
            ),
          ),
        ),
        _buildGridCard(
          bg: const Color.fromARGB(255, 203, 103, 143),
          iconBg: const Color(0xFF334155),
          iconColor: const Color(0xFFEC4899),
          icon: Icons.check_box_rounded,
          title: "Tasks",
          sub: "make your tasks complete",
          titleColor: Colors.white,
          subColor: Colors.grey[400]!,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyTasksScreen(currentUser: widget.currentUser),
            ),
          ),
        ),
        _buildGridCard(
          bg: const Color.fromARGB(255, 179, 175, 93),
          iconBg: const Color(0xFF334155),
          iconColor: const Color(0xFF10B981),
          icon: Icons.help_center_rounded,
          title: "Quiz",
          sub: "play and learn",
          titleColor: Colors.white,
          subColor: Colors.grey[400]!,
          onTap: () => _openGroupSelectorForQuiz(context),
        ),
        _buildGridCard(
          bg: const Color.fromARGB(255, 152, 200, 212),
          iconBg: const Color(0xFF334155),
          iconColor: const Color(0xFFF97316),
          icon: Icons.adb_rounded,
          title: "AI Assistant",
          sub: "Ask anything",
          titleColor: Colors.white,
          subColor: Colors.grey[400]!,
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
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
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
            const Icon(Icons.psychology_rounded, color: Color(0xFF38BDF8), size: 32),
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
                      color: Colors.grey[400]!,
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
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
            const Icon(Icons.timer_rounded, color: Color(0xFFEC4899), size: 32),
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
                      color: Colors.grey[400]!,
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

