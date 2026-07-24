import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
 
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/chat_file_picker.dart';
 
/// Shows the create-task bottom sheet. Pass [groupId] + [groupMembers] to
/// create a group task with an assignee picker; omit both for a personal
/// task. Returns nothing — the sheet saves directly via DatabaseService.
Future<void> showCreateTaskSheet({
  required BuildContext context,
  required AppUser currentUser,
  String? groupId,
  List<AppUser> groupMembers = const [],
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateTaskSheet(
      currentUser: currentUser,
      groupId: groupId,
      groupMembers: groupMembers,
    ),
  );
}
 
class CreateTaskSheet extends StatefulWidget {
  final AppUser currentUser;
  final String? groupId;
  final List<AppUser> groupMembers;
 
  const CreateTaskSheet({
    super.key,
    required this.currentUser,
    this.groupId,
    this.groupMembers = const [],
  });
 
  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}
 
class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _databaseService = DatabaseService();
 
  DateTime? _dueDate;
  String _priority = 'medium';
  final Set<String> _selectedAssignees = {};
 
  PickedChatFile? _pickedAttachment;
  bool _isSaving = false;
 
  bool get _isGroupTask => widget.groupId != null;
 
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
 
  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
 
  Future<void> _pickAttachment() async {
    final picked = await pickChatFile();
    if (picked != null) setState(() => _pickedAttachment = picked);
  }
 
  String _deriveFileType(String fileName, bool isImage) {
    if (isImage) return 'image';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (ext == 'pdf') return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'doc';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['xls', 'xlsx'].contains(ext)) return 'xls';
    return 'doc';
  }
 
  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }
 
    setState(() => _isSaving = true);
 
    try {
      String? attachmentUrl;
      String? attachmentFileName;
      String? attachmentFileType;
 
      if (_pickedAttachment != null) {
        final cloudinaryService = CloudinaryService();
        final response = await cloudinaryService.uploadBytes(
          bytes: _pickedAttachment!.bytes,
          fileName: _pickedAttachment!.fileName,
          isImage: _pickedAttachment!.isImage,
        );
        attachmentUrl = response.secureUrl;
        attachmentFileName = _pickedAttachment!.fileName;
        attachmentFileType = _deriveFileType(_pickedAttachment!.fileName, _pickedAttachment!.isImage);
      }
 
      final taskId = _databaseService.generateTaskId();
 
      // For group tasks with nobody explicitly picked, default to assigning
      // the whole group so it shows up for every member's "My Tasks" feed.
      final assignedTo = _isGroupTask
          ? (_selectedAssignees.isNotEmpty
              ? _selectedAssignees.toList()
              : widget.groupMembers.map((m) => m.uid).toList())
          : <String>[widget.currentUser.uid];
 
      final task = TaskModel(
        id: taskId,
        title: title,
        description: _descController.text.trim(),
        type: _isGroupTask ? 'group' : 'personal',
        groupId: widget.groupId,
        creatorUid: widget.currentUser.uid,
        assignedTo: assignedTo,
        dueDate: _dueDate,
        priority: _priority,
        status: 'pending',
        attachmentUrl: attachmentUrl,
        attachmentFileName: attachmentFileName,
        attachmentFileType: attachmentFileType,
        createdAt: DateTime.now(),
      );
 
      await _databaseService.createTask(task);
 
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  Widget _priorityChip(String value, String label, Color color) {
    final selected = _priority == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
      selected: selected,
      onSelected: (_) => setState(() => _priority = value),
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? color : Colors.grey[700]),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? color : Colors.transparent),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isGroupTask ? 'New Group Task' : 'New Task',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  filled: true,
                  fillColor: const Color(0xFFF1F1F1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  filled: true,
                  fillColor: const Color(0xFFF1F1F1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text('Priority', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              Row(
                children: [
                  _priorityChip('low', 'Low', const Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  _priorityChip('medium', 'Medium', const Color(0xFFFFA726)),
                  const SizedBox(width: 8),
                  _priorityChip('high', 'High', const Color(0xFFFF6584)),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate == null ? 'Set due date' : DateFormat('EEE, MMM d, yyyy').format(_dueDate!),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isGroupTask && widget.groupMembers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Assign to', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text(
                  'Leave empty to assign to the whole group',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.groupMembers.map((member) {
                    final selected = _selectedAssignees.contains(member.uid);
                    return FilterChip(
                      label: Text(member.username, style: GoogleFonts.poppins(fontSize: 12)),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedAssignees.add(member.uid);
                          } else {
                            _selectedAssignees.remove(member.uid);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickAttachment,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedAttachment?.fileName ?? 'Attach a file (optional)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                      if (_pickedAttachment != null)
                        GestureDetector(
                          onTap: () => setState(() => _pickedAttachment = null),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Create Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 