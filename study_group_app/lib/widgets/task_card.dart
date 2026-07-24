import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
 
import '../models/task_model.dart';
 
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback? onToggleComplete;
 
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onToggleComplete,
  });
 
  Color _priorityColor() {
    switch (task.priority) {
      case 'high':
        return const Color(0xFFFF6584);
      case 'low':
        return const Color(0xFF43A047);
      case 'medium':
      default:
        return const Color(0xFFFFA726);
    }
  }
 
  Color _statusColor() {
    switch (task.status) {
      case 'completed':
        return const Color(0xFF43A047);
      case 'in_progress':
        return const Color(0xFF6C63FF);
      case 'pending':
      default:
        return Colors.grey;
    }
  }
 
  String _statusLabel() {
    switch (task.status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In progress';
      default:
        return 'Pending';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'completed';
    final dueColor = task.isOverdue ? const Color(0xFFFF6584) : Colors.grey[600];
 
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF43A047) : Colors.transparent,
                  border: Border.all(
                    color: isDone ? const Color(0xFF43A047) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: _priorityColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(),
                          ),
                        ),
                      ),
                      if (task.dueDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 11, color: dueColor),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: GoogleFonts.poppins(fontSize: 11, color: dueColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      if (task.subtasks.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.checklist_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              '${task.completedSubtaskCount}/${task.subtasks.length}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      if (task.attachmentUrl != null)
                        const Icon(Icons.attach_file_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 