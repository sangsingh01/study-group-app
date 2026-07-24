import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_group_app/constants/design_system.dart';
import '../models/assignment_model.dart';
import '../services/database_service.dart';
import '../widgets/chat_file_picker.dart';
 
class AssignmentDetailScreen extends StatefulWidget {
  final String groupId;
  final String assignmentId;
  final String currentUid;
  final String currentUserName;
  final int totalGroupMembers;
 
  const AssignmentDetailScreen({
    super.key,
    required this.groupId,
    required this.assignmentId,
    required this.currentUid,
    required this.currentUserName,
    required this.totalGroupMembers,
  });
 
  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}
 
class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  bool _isUploadingAttachment = false;
 
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      appBar: AppBar(
        backgroundColor: CipherColors.purplePrimary,
        elevation: 0,
        title: Text('Assignment', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<AssignmentModel?>(
        stream: _db.getAssignmentStream(widget.groupId, widget.assignmentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator(color: CipherColors.purplePrimary));
          }
          final assignment = snapshot.data!;
          final myDone = assignment.memberCompletion[widget.currentUid] == true;
 
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTitleCard(assignment),
                    const SizedBox(height: 16),
                    _buildMyCompletionToggle(myDone),
                    const SizedBox(height: 16),
                    _buildProgressSection(assignment),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(assignment),
                    const SizedBox(height: 16),
                    _buildCommentsSection(),
                  ],
                ),
              ),
              _buildCommentInputBar(),
            ],
          );
        },
      ),
    );
  }
 
  Widget _buildTitleCard(AssignmentModel assignment) {
    final overdue = assignment.isOverdue();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.title, style: CipherTextStyles.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          if (assignment.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(assignment.description, style: CipherTextStyles.poppins(fontSize: 13, color: Colors.grey[700])),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text('By ${assignment.createdByName}', style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[500])),
              if (assignment.dueDate != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.schedule_rounded, size: 13, color: overdue ? CipherColors.pinkPrimary : Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Due ${DateFormat('dd MMM yyyy').format(assignment.dueDate!)}',
                  style: CipherTextStyles.poppins(
                    fontSize: 11,
                    color: overdue ? CipherColors.pinkPrimary : Colors.grey[500],
                    fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildMyCompletionToggle(bool myDone) {
    return InkWell(
      onTap: () => _db.setMyAssignmentCompletion(
        groupId: widget.groupId,
        assignmentId: widget.assignmentId,
        uid: widget.currentUid,
        completed: !myDone,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: myDone ? CipherColors.greenPrimary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: myDone ? CipherColors.greenPrimary : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              myDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: myDone ? CipherColors.greenPrimary : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              myDone ? 'You marked your part done' : 'Mark my part as done',
              style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: myDone ? CipherColors.greenPrimary : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildProgressSection(AssignmentModel assignment) {
    final progress = assignment.progressFraction(widget.totalGroupMembers);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group progress', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: progress >= 1.0 ? CipherColors.greenPrimary : CipherColors.purplePrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${assignment.doneCount()} of ${widget.totalGroupMembers} members done',
            style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
 
  Widget _buildAttachmentsSection(AssignmentModel assignment) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attachments', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _isUploadingAttachment ? null : _handleAddAttachment,
                icon: _isUploadingAttachment
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: CipherColors.purplePrimary))
                    : const Icon(Icons.attach_file_rounded, size: 16, color: CipherColors.purplePrimary),
                label: Text('Add', style: CipherTextStyles.poppins(fontSize: 12, color: CipherColors.purplePrimary)),
              ),
            ],
          ),
          if (assignment.attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No files yet', style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey[500])),
            )
          else
            ...assignment.attachments.map((a) => _buildAttachmentRow(a)),
        ],
      ),
    );
  }
 
  Widget _buildAttachmentRow(AssignmentAttachment a) {
    final isPdf = a.fileType == 'pdf';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isPdf ? CipherColors.tasksBg : CipherColors.notesBg,
            child: Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
              size: 15,
              color: isPdf ? CipherColors.pinkPrimary : CipherColors.purplePrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              a.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CipherTextStyles.poppins(fontSize: 13),
            ),
          ),
          Text('by ${a.uploadedByName}', style: CipherTextStyles.poppins(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
 
  Future<void> _handleAddAttachment() async {
    final picked = await pickChatFile();
    if (picked == null) return;
 
    setState(() => _isUploadingAttachment = true);
    try {
      await _db.addAssignmentAttachment(
        groupId: widget.groupId,
        assignmentId: widget.assignmentId,
        bytes: picked.bytes,
        fileName: picked.fileName,
        isImage: picked.isImage,
        uploaderId: widget.currentUid,
        uploaderName: widget.currentUserName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachment upload failed: $e'), backgroundColor: CipherColors.pinkPrimary),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }
 
  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discussion', style: CipherTextStyles.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<List<dynamic>>(
            stream: _db.getAssignmentComments(widget.groupId, widget.assignmentId),
            builder: (context, snapshot) {
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Text('No comments yet — ask a question!', style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey[500]));
              }
              return Column(
                children: comments.map((c) => _buildCommentRow(c)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
 
  Widget _buildCommentRow(dynamic comment) {
    // dynamic here to keep this snippet resilient to your exact
    // AssignmentCommentModel import path — swap to the typed model
    // once wired into your real project.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.senderName, style: CipherTextStyles.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: CipherColors.purplePrimary)),
          const SizedBox(height: 2),
          Text(comment.text, style: CipherTextStyles.poppins(fontSize: 13)),
        ],
      ),
    );
  }
 
  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(hintText: 'Ask a question...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final text = _commentController.text.trim();
              if (text.isEmpty) return;
              _commentController.clear();
              await _db.addAssignmentComment(
                groupId: widget.groupId,
                assignmentId: widget.assignmentId,
                text: text,
                senderId: widget.currentUid,
                senderName: widget.currentUserName,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: CipherColors.purplePrimary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
 