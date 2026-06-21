// lib/screens/study_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/design_system.dart';
import 'notes_screen.dart';
import 'task_screen.dart';
import 'quiz_screen.dart';
import 'ai_assistant_screen.dart';

class StudyScreen extends StatefulWidget {
  final String currentUid; // 🌟 Passed from your authenticated root tab controller
  const StudyScreen({super.key, required this.currentUid});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  bool isWeeklySelected = true; // Tracks the state of the analytics switcher toggle

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  _buildQuickAiAccessCard(),
                  const SizedBox(height: 40), // Safe spacing for navigation padding
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
            style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'All your learning in one place',
            style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
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
          sub: "12 shared files",
          titleColor: CipherColors.notesText,
          subColor: CipherColors.notesSub,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(currentUid: widget.currentUid))),
        ),
        _buildGridCard(
          bg: CipherColors.tasksBg,
          iconBg: Colors.white,
          iconColor: CipherColors.pinkPrimary,
          icon: Icons.check_box_rounded,
          title: "Tasks",
          sub: "3 due today",
          titleColor: CipherColors.tasksText,
          subColor: CipherColors.tasksSub,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen(currentUid: widget.currentUid))),
        ),
        _buildGridCard(
          bg: CipherColors.quizBg,
          iconBg: Colors.white,
          iconColor: CipherColors.greenPrimary,
          icon: Icons.help_center_rounded,
          title: "Quiz",
          sub: "2 items pending",
          titleColor: CipherColors.quizText,
          subColor: CipherColors.quizSub,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizListScreen(currentUid: widget.currentUid))),
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
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(currentUid: widget.currentUid))),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required Color bg, required Color iconBg, required Color iconColor, required IconData icon,
    required String title, required String sub, required Color titleColor, required Color subColor, required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(radius: 18, backgroundColor: iconBg, child: Icon(icon, color: iconColor, size: 18)),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: titleColor.withValues(alpha: 0.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CipherTextStyles.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
                const SizedBox(height: 2),
                Text(sub, style: CipherTextStyles.poppins(fontSize: 11, color: subColor)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // ANALYTICS & CHARTS SECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  
  

 

  

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // QUICK STATUS ROW (4 CARDS)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
 

  Widget _buildStatCard(String label, String value, IconData icon, Color bg, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 4,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: CipherTextStyles.poppins(fontSize: 9, color: Colors.grey[600]!, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // UPCOMING DEADLINES SECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
 
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // TODAY'S GOALS GOAL METRICS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
 

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // QUICK AI ASSISTANT OVERLAY CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildQuickAiAccessCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(currentUid: widget.currentUid))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CipherColors.purpleGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ask AI Study Assistant', style: CipherTextStyles.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Get instant answers to any question', style: CipherTextStyles.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}