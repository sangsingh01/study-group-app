import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_group_app/models/user_model.dart';
import 'package:study_group_app/screens/create_group_screen.dart';
import 'package:study_group_app/screens/groups_screen.dart';
import 'package:study_group_app/screens/search_users_screen.dart';

class TaskItem {
  TaskItem({
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
  });

  final String title;
  final String dueDate;
  bool isCompleted;
}

class GamifiedHomeSkeleton extends StatefulWidget {
  const GamifiedHomeSkeleton({
    super.key,
    required this.currentUser,
    required this.user,
  });

  final AppUser? currentUser;
  final User user;

  @override
  State<GamifiedHomeSkeleton> createState() => _GamifiedHomeSkeletonState();
}

class _GamifiedHomeSkeletonState extends State<GamifiedHomeSkeleton> {
  final TextEditingController _taskController = TextEditingController();
  late final List<TaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      TaskItem(
        title: 'Finish chapter 5 of Flutter state management',
        dueDate: 'Today',
      ),
      TaskItem(
        title: 'Review peer study notes and highlight examples',
        dueDate: 'Today',
      ),
      TaskItem(
        title: 'Submit project brainstorm summary',
        dueDate: 'Today',
      ),
      TaskItem(
        title: 'Practice algorithm problems for 30 min',
        dueDate: 'Today',
      ),
    ];
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _toggleTask(TaskItem task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Add a new study goal',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep your daily task list fresh and motivated.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _taskController,
                textInputAction: TextInputAction.done,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter study goal title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onSubmitted: (_) => _handleAddTask(),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _handleAddTask,
                child: Text(
                  'Add Task',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAddTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a study task before adding.')),
      );
      return;
    }

    setState(() {
      _tasks.insert(
        0,
        TaskItem(title: title, dueDate: 'Today'),
      );
    });
    _taskController.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final slateGray = colorScheme.onSurface.withAlpha(153);
    final firstName = widget.currentUser?.username
            .trim()
            .split(RegExp(r'\s+'))
            .firstWhere((part) => part.isNotEmpty, orElse: () => 'Sang') ??
        'Sang';
    final emailHandle = widget.user.email?.split('@').first ?? 'Guest';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $firstName',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level 5 Developer',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: slateGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Signed in as $emailHandle',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: slateGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A50),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '14',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XP Progress',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 0.8,
                          minHeight: 18,
                          valueColor: AlwaysStoppedAnimation(primary),
                          backgroundColor: Color.fromRGBO(
                            primary.r.round(),
                            primary.g.round(),
                            primary.b.round(),
                            0.16,
                          ),
                        ),
                      ),
                      Text(
                        '800 / 1000 XP',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.group_add_rounded,
                  title: 'Create New Group',
                  color: Colors.indigoAccent.shade200,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateGroupScreen(user: widget.user),
                    ),
                  ),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.explore_rounded,
                  title: 'Discover Find Groups',
                  color: Colors.greenAccent.shade400,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupsScreen(
                        currentUser: widget.currentUser,
                        user: widget.user,
                      ),
                    ),
                  ),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Add Friend Invite Someone',
                  color: Colors.pinkAccent.shade200,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchUsersScreen(currentUid: widget.user.uid),
                    ),
                  ),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.smart_toy_rounded,
                  title: 'AI Help Ask Anything',
                  color: Colors.deepPurple.shade300,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Help coming soon!')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY\'S TASKS',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: slateGray,
                  ),
                ),
                GestureDetector(
                  onTap: _showAddTaskSheet,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 20, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        '+ Add Task',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(
                  context,
                  item: _tasks[index],
                  primary: primary,
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required TaskItem item,
    required Color primary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTask(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted
                      ? Color.fromRGBO(primary.r.round(), primary.g.round(), primary.b.round(), 0.16)
                      : Colors.white,
                  border: Border.all(
                    color: item.isCompleted ? primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: item.isCompleted
                    ? Icon(Icons.check, color: primary, size: 18)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  decoration: item.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  color: item.isCompleted ? Colors.grey.shade500 : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? Color.fromRGBO(primary.r.round(), primary.g.round(), primary.b.round(), 0.14)
                    : Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.dueDate,
                style: GoogleFonts.poppins(
                  color: item.isCompleted ? primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
