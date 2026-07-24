import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_group_app/constants/design_system.dart';
import '../models/assignment_model.dart';
import '../services/database_service.dart';
import 'assignment_detail_screen.dart';
 
class AssignmentsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUid;
  final String currentUserName;
  final int totalGroupMembers; // pass widget.group.members.length from caller
 
  const AssignmentsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUid,
    required this.currentUserName,
    required this.totalGroupMembers,
  });
 
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}
 
class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final DatabaseService _db = DatabaseService();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: CipherColors.purplePrimary,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
        onPressed: _showCreateAssignmentSheet,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<AssignmentModel>>(
              stream: _db.getGroupAssignments(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: CipherColors.purplePrimary));
                }
                final assignments = snapshot.data ?? [];
                if (assignments.isEmpty) return _buildEmptyState();
 
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: assignments.length,
                  itemBuilder: (context, idx) => _buildAssignmentCard(assignments[idx]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, bottom: 24, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: CipherColors.purpleGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assignments', style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(widget.groupName, style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final progress = assignment.progressFraction(widget.totalGroupMembers);
    final overdue = assignment.isOverdue();
    final myDone = assignment.memberCompletion[widget.currentUid] == true;
 
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(
            groupId: widget.groupId,
            assignmentId: assignment.id,
            currentUid: widget.currentUid,
            currentUserName: widget.currentUserName,
            totalGroupMembers: widget.totalGroupMembers,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CipherTextStyles.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (myDone)
                  const Icon(Icons.check_circle_rounded, color: CipherColors.greenPrimary, size: 20)
                else
                  Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                color: progress >= 1.0 ? CipherColors.greenPrimary : CipherColors.purplePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${assignment.doneCount()}/${widget.totalGroupMembers} done',
                  style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
                if (assignment.dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: overdue ? CipherColors.pinkPrimary : Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM').format(assignment.dueDate!),
                        style: CipherTextStyles.poppins(
                          fontSize: 11,
                          color: overdue ? CipherColors.pinkPrimary : Colors.grey[500],
                          fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 54, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No assignments yet', style: CipherTextStyles.poppins(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
 
  void _showCreateAssignmentSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDueDate;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('New Assignment', style: CipherTextStyles.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: CipherTextStyles.poppins(color: Colors.grey),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CipherColors.purplePrimary)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: CipherTextStyles.poppins(color: Colors.grey),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CipherColors.purplePrimary)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheetState(() => selectedDueDate = picked);
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: CipherColors.purplePrimary),
                    const SizedBox(width: 10),
                    Text(
                      selectedDueDate == null ? 'Set due date (optional)' : DateFormat('dd MMM yyyy').format(selectedDueDate!),
                      style: CipherTextStyles.poppins(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    await _db.createAssignment(
                      groupId: widget.groupId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      dueDate: selectedDueDate,
                      createdBy: widget.currentUid,
                      createdByName: widget.currentUserName,
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CipherColors.purplePrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Create Assignment', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
 