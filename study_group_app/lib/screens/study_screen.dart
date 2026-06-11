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
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildDeadlinesSection(),
                  const SizedBox(height: 24),
                  _buildTodayGoalsSection(),
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
  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Progress', style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _buildToggleBtn("Week", isWeeklySelected, () => setState(() => isWeeklySelected = true)),
                  _buildToggleBtn("Month", !isWeeklySelected, () => setState(() => isWeeklySelected = false)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 4,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => CipherColors.purplePrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(1) + 'h',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, meta) => Text('${val.toInt()}h', style: CipherTextStyles.poppins(fontSize: 10, color: Colors.grey)),
                  )
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(weekdays[val.toInt() % 7], style: CipherTextStyles.poppins(fontSize: 10, color: Colors.grey)),
                      );
                    },
                  )
                )
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeBarGroup(0, 1.5, false),
                _makeBarGroup(1, 2.3, false),
                _makeBarGroup(2, 3.5, true), // Today's Highlighted Bar (Brighter Purple)
                _makeBarGroup(3, 1.2, false),
                _makeBarGroup(4, 2.8, false),
                _makeBarGroup(5, 0.5, false),
                _makeBarGroup(6, 1.9, false),
              ],
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subject Breakdown', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _buildHorizontalSubjectBar("Flutter", "4.2h", 0.85, CipherColors.purplePrimary),
              _buildHorizontalSubjectBar("Data Science", "2.5h", 0.55, const Color(0xFF43E97B)),
              _buildHorizontalSubjectBar("Web Dev", "3.1h", 0.70, Colors.blueAccent),
              _buildHorizontalSubjectBar("AI/ML", "1.8h", 0.40, CipherColors.orangePrimary),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CipherColors.purplePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: CipherTextStyles.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isToday) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isToday ? const Color(0xFF948DFF) : CipherColors.purplePrimary,
          width: 14,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          
        )
      ],
    );
  }

  Widget _buildHorizontalSubjectBar(String title, String hrs, double factor, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(title, style: CipherTextStyles.poppins(fontSize: 12, color: Colors.black87))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: factor,
                color: barColor,
                backgroundColor: Colors.grey[100],
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(hrs, style: CipherTextStyles.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // QUICK STATUS ROW (4 CARDS)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard("Streak", "5", Icons.local_fire_department_rounded, CipherColors.aiBg, CipherColors.orangePrimary),
        _buildStatCard("Avg Time", "2.1h", Icons.access_time_filled_rounded, CipherColors.quizBg, CipherColors.quizText),
        _buildStatCard("Best Day", "3h", Icons.emoji_events_rounded, CipherColors.notesBg, CipherColors.purplePrimary),
        _buildStatCard("Goal Rate", "72%", Icons.track_changes_rounded, CipherColors.tasksBg, CipherColors.pinkPrimary),
      ],
    );
  }

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
  Widget _buildDeadlinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Deadlines', style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 4, backgroundColor: Colors.redAccent), // Red means today/urgent
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submit UI Architecture Spec', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Flutter Group • Due 3:00 PM', style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                'Due in 2 hours',
                style: CipherTextStyles.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  // TODAY'S GOALS GOAL METRICS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildTodayGoalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Goals", style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  children: [
                    Center(child: CircularProgressIndicator(value: 0.75, color: CipherColors.purplePrimary, backgroundColor: Colors.grey[100], strokeWidth: 5.5)),
                    Center(child: Text('75%', style: CipherTextStyles.poppins(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1.5h / 2h Completed', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: 3 / 5, color: const Color(0xFF43E97B), backgroundColor: Colors.grey[100], minHeight: 6),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('3/5 tasks completed', style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: CipherColors.aiBg, borderRadius: BorderRadius.circular(6)),
                          child: Text('150 XP', style: CipherTextStyles.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: CipherColors.orangePrimary)),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

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