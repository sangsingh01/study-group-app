// lib/screens/task_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
import '../models/study_models.dart';

class TaskScreen extends StatefulWidget {
  final String currentUid;
  final String? groupId;
  const TaskScreen({super.key, required this.currentUid, this.groupId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query baseQuery = FirebaseFirestore.instance.collection('tasks');
    if (widget.groupId != null) {
      baseQuery = baseQuery.where('groupId', isEqualTo: widget.groupId);
    }

    return Scaffold(
      backgroundColor: CipherColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: CipherColors.pinkPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => _showCreateTaskSheet(),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: CipherColors.pinkPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: CipherColors.pinkPrimary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: "Today"),
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskListStream(baseQuery.where('isCompleted', isEqualTo: false)),
                _buildTaskListStream(baseQuery.where('isCompleted', isEqualTo: false)),
                _buildTaskListStream(baseQuery.where('isCompleted', isEqualTo: true)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, bottom: 24, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: CipherColors.pinkGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), 
            onPressed: () => Navigator.pop(context)
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Tracker', style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Manage your personal updates and project deadlines', style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListStream(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CipherColors.pinkPrimary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
        
        final docs = snapshot.data!.docs;
        final tasks = docs.map((d) => TaskModel.fromMap(d.data() as Map<String, dynamic>)).toList();

        if (tasks.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: tasks.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, idx) {
            final task = tasks[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Dismissible(
                  key: Key(task.id),
                  background: Container(
                    padding: const EdgeInsets.only(left: 20),
                    color: CipherColors.greenPrimary.withValues(alpha: 0.85), 
                    alignment: Alignment.centerLeft, 
                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24)
                  ),
                  secondaryBackground: Container(
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent.withValues(alpha: 0.85), 
                    alignment: Alignment.centerRight, 
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24)
                  ),
                  onDismissed: (dir) {
                    if (dir == DismissDirection.startToEnd) {
                      _toggleComplete(task.id, true);
                    } else {
                      FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
                    }
                  },
                  child: _buildTaskCard(task),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    bool isHighPriority = task.priority == 'High';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isHighPriority ? const Border(left: BorderSide(color: Colors.redAccent, width: 4)) : null,
      ),
      child: ListTile(
        leading: Transform.scale(
          scale: 1.1,
          child: IconButton(
            icon: Icon(
              task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 
              color: task.isCompleted ? CipherColors.greenPrimary : CipherColors.pinkPrimary
            ),
            onPressed: () => _toggleComplete(task.id, !task.isCompleted),
          ),
        ),
        title: Text(
  task.title, 
  style: CipherTextStyles.poppins(
    fontSize: 14, 
    fontWeight: FontWeight.bold,
    color: task.isCompleted ? Colors.grey : Colors.black87,
  ).copyWith(
    decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
  ),
),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            task.groupName, 
            style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey[500]!)
          ),
        ),
        trailing: isHighPriority 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Urgent', style: CipherTextStyles.poppins(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Future<void> _toggleComplete(String taskId, bool state) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'isCompleted': state});
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 54, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('All tasks fully cleared!', style: CipherTextStyles.poppins(color: Colors.grey[500]!, fontSize: 14)),
        ],
      ),
    );
  }

  void _showCreateTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Add New Task', style: CipherTextStyles.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Task Description Title",
                labelStyle: CipherTextStyles.poppins(color: Colors.grey),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CipherColors.pinkPrimary)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CipherColors.pinkPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Commit Entry', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}