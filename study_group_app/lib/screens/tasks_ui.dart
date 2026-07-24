import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
 
import '../models/task_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/chat_file_picker.dart';
 
const _accent = Color(0xFF6C63FF);
 
Color _priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return const Color(0xFFFF6584);
    case 'low':
      return const Color(0xFF43A047);
    default:
      return const Color(0xFFFFA726);
  }
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
 
// =========================================================================
// TASK CARD (list item)
// =========================================================================
 
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback? onToggleComplete;
 
  const TaskCard({super.key, required this.task, required this.onTap, this.onToggleComplete});
 
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
                  border: Border.all(color: isDone ? const Color(0xFF43A047) : Colors.grey.shade400, width: 2),
                ),
                child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
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
                        decoration: BoxDecoration(color: _priorityColor(task.priority), shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(task.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (task.dueDate != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: dueColor),
                          const SizedBox(width: 3),
                          Text(DateFormat('MMM d').format(task.dueDate!),
                              style: GoogleFonts.poppins(fontSize: 11, color: dueColor, fontWeight: FontWeight.w500)),
                        ]),
                      if (task.subtasks.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.checklist_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('${task.completedSubtaskCount}/${task.subtasks.length}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                        ]),
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
 
// =========================================================================
// CREATE TASK SHEET
// =========================================================================
 
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
    builder: (_) => _CreateTaskSheet(currentUser: currentUser, groupId: groupId, groupMembers: groupMembers),
  );
}
 
class _CreateTaskSheet extends StatefulWidget {
  final AppUser currentUser;
  final String? groupId;
  final List<AppUser> groupMembers;
 
  const _CreateTaskSheet({required this.currentUser, this.groupId, this.groupMembers = const []});
 
  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}
 
class _CreateTaskSheetState extends State<_CreateTaskSheet> {
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
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
 
  Future<void> _pickAttachment() async {
    final picked = await pickChatFile();
    if (picked != null) setState(() => _pickedAttachment = picked);
  }
 
  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title')));
      return;
    }
    setState(() => _isSaving = true);
 
    try {
      String? attachmentUrl, attachmentFileName, attachmentFileType;
 
      if (_pickedAttachment != null) {
        final response = await CloudinaryService().uploadBytes(
          bytes: _pickedAttachment!.bytes,
          fileName: _pickedAttachment!.fileName,
          isImage: _pickedAttachment!.isImage,
        );
        attachmentUrl = response.secureUrl;
        attachmentFileName = _pickedAttachment!.fileName;
        attachmentFileType = _deriveFileType(_pickedAttachment!.fileName, _pickedAttachment!.isImage);
      }
 
      final taskId = _databaseService.generateTaskId();
      final assignedTo = _isGroupTask
          ? (_selectedAssignees.isNotEmpty ? _selectedAssignees.toList() : widget.groupMembers.map((m) => m.uid).toList())
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create task: $e')));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? color : Colors.transparent)),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(_isGroupTask ? 'New Group Task' : 'New Task', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
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
              Row(children: [
                _priorityChip('low', 'Low', const Color(0xFF43A047)),
                const SizedBox(width: 8),
                _priorityChip('medium', 'Medium', const Color(0xFFFFA726)),
                const SizedBox(width: 8),
                _priorityChip('high', 'High', const Color(0xFFFF6584)),
              ]),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: _accent),
                    const SizedBox(width: 10),
                    Text(_dueDate == null ? 'Set due date' : DateFormat('EEE, MMM d, yyyy').format(_dueDate!), style: GoogleFonts.poppins(fontSize: 13)),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(onTap: () => setState(() => _dueDate = null), child: const Icon(Icons.close, size: 16, color: Colors.grey)),
                  ]),
                ),
              ),
              if (_isGroupTask && widget.groupMembers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Assign to', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text('Leave empty to assign to the whole group', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.groupMembers.map((member) {
                    final selected = _selectedAssignees.contains(member.uid);
                    return FilterChip(
                      label: Text(member.username, style: GoogleFonts.poppins(fontSize: 12)),
                      selected: selected,
                      onSelected: (val) => setState(() => val ? _selectedAssignees.add(member.uid) : _selectedAssignees.remove(member.uid)),
                      selectedColor: _accent.withValues(alpha: 0.15),
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
                  child: Row(children: [
                    const Icon(Icons.attach_file_rounded, size: 18, color: _accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_pickedAttachment?.fileName ?? 'Attach a file (optional)',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                    if (_pickedAttachment != null)
                      GestureDetector(onTap: () => setState(() => _pickedAttachment = null), child: const Icon(Icons.close, size: 16, color: Colors.grey)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
 
// =========================================================================
// TASK DETAIL SCREEN
// =========================================================================
 
class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  final AppUser currentUser;
  final bool isGroupAdmin;
 
  const TaskDetailScreen({super.key, required this.task, required this.currentUser, this.isGroupAdmin = false});
 
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}
 
class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _databaseService = DatabaseService();
  final _newSubtaskController = TextEditingController();
  late TaskModel _task;
 
  bool get _canEdit => _task.creatorUid == widget.currentUser.uid || widget.isGroupAdmin;
 
  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }
 
  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }
 
  Future<void> _updateStatus(String newStatus) async {
    await _databaseService.updateTaskStatus(
      taskId: _task.id,
      status: newStatus,
      completedBy: newStatus == 'completed' ? widget.currentUser.uid : null,
    );
    setState(() => _task = _task.copyWith(
          status: newStatus,
          completedAt: newStatus == 'completed' ? DateTime.now() : null,
          completedBy: newStatus == 'completed' ? widget.currentUser.uid : null,
        ));
  }
 
  Future<void> _toggleSubtask(SubtaskModel subtask) async {
    final updated = _task.subtasks.map((s) => s.id == subtask.id ? s.copyWith(isDone: !s.isDone) : s).toList();
    await _databaseService.updateTaskSubtasks(_task.id, updated);
    setState(() => _task = _task.copyWith(subtasks: updated));
  }
 
  Future<void> _addSubtask() async {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;
    final updated = [..._task.subtasks, SubtaskModel(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title)];
    await _databaseService.updateTaskSubtasks(_task.id, updated);
    setState(() => _task = _task.copyWith(subtasks: updated));
    _newSubtaskController.clear();
  }
 
  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _databaseService.deleteTask(_task.id);
      if (mounted) Navigator.pop(context);
    }
  }
 
  Widget _statusButton(String value, String label) {
    final selected = _task.status == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      selected: selected,
      onSelected: (_) => _updateStatus(value),
      selectedColor: _accent.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: selected ? _accent : Colors.grey[700]),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final isDone = _task.status == 'completed';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Task Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [if (_canEdit) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _deleteTask)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: Text(_task.title,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _priorityColor(_task.priority).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_task.priority.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: _priorityColor(_task.priority))),
            ),
          ]),
          if (_task.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_task.description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
          ],
          const SizedBox(height: 16),
          if (_task.dueDate != null)
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: _task.isOverdue ? const Color(0xFFFF6584) : Colors.grey[600]),
              const SizedBox(width: 6),
              Text('Due ${DateFormat('EEE, MMM d, yyyy').format(_task.dueDate!)}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: _task.isOverdue ? const Color(0xFFFF6584) : Colors.grey[600], fontWeight: FontWeight.w500)),
            ]),
          const SizedBox(height: 20),
          Text('Status', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [_statusButton('pending', 'Pending'), _statusButton('in_progress', 'In Progress'), _statusButton('completed', 'Completed')]),
          if (_task.attachmentUrl != null) ...[
            const SizedBox(height: 20),
            Text('Attachment', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse(_task.attachmentUrl!)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.insert_drive_file_rounded, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_task.attachmentFileName ?? 'Attachment', style: GoogleFonts.poppins(fontSize: 13))),
                  const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Checklist', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._task.subtasks.map((s) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: s.isDone,
                onChanged: (_) => _toggleSubtask(s),
                title: Text(s.title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, decoration: s.isDone ? TextDecoration.lineThrough : null, color: s.isDone ? Colors.grey : const Color(0xFF1A1A2E))),
              )),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _newSubtaskController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add a checklist item',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _addSubtask(),
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle, color: _accent), onPressed: _addSubtask),
          ]),
        ],
      ),
    );
  }
}
 
// =========================================================================
// MY TASKS SCREEN (personal + all assigned group tasks)
// =========================================================================
 
class MyTasksScreen extends StatefulWidget {
  final AppUser currentUser;
  const MyTasksScreen({super.key, required this.currentUser});
 
  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}
 
class _MyTasksScreenState extends State<MyTasksScreen> {
  final _databaseService = DatabaseService();
  String _filter = 'all';
 
  List<TaskModel> _applyFilter(List<TaskModel> tasks) => _filter == 'all' ? tasks : tasks.where((t) => t.status == _filter).toList();
 
  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _accent.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: selected ? _accent : Colors.grey[700]),
        backgroundColor: Colors.grey[100],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: Text('My Tasks', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: () => showCreateTaskSheet(context: context, currentUser: widget.currentUser),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('all', 'All'),
                _filterChip('pending', 'Pending'),
                _filterChip('in_progress', 'In Progress'),
                _filterChip('completed', 'Completed'),
              ]),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _databaseService.streamMyTasks(widget.currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }
                final tasks = _applyFilter(snapshot.data ?? []);
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('📝', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 12),
                      Text('No tasks here yet', style: GoogleFonts.poppins(color: Colors.grey)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, currentUser: widget.currentUser))),
                      onToggleComplete: () => _databaseService.updateTaskStatus(
                        taskId: task.id,
                        status: task.status == 'completed' ? 'pending' : 'completed',
                        completedBy: task.status == 'completed' ? null : widget.currentUser.uid,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 
// =========================================================================
// GROUP TASKS SCREEN (one group)
// =========================================================================
 
class GroupTasksScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;
  const GroupTasksScreen({super.key, required this.group, required this.currentUser});
 
  @override
  State<GroupTasksScreen> createState() => _GroupTasksScreenState();
}
 
class _GroupTasksScreenState extends State<GroupTasksScreen> {
  final _databaseService = DatabaseService();
  String _filter = 'all';
 
  bool get _isAdmin => widget.group.adminUid == widget.currentUser.uid;
 
  List<TaskModel> _applyFilter(List<TaskModel> tasks) => _filter == 'all' ? tasks : tasks.where((t) => t.status == _filter).toList();
 
  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _accent.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: selected ? _accent : Colors.grey[700]),
        backgroundColor: Colors.grey[100],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: Text('${widget.group.name} Tasks', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      floatingActionButton: StreamBuilder<List<AppUser>>(
        stream: _databaseService.usersByIdsStream(widget.group.members),
        builder: (context, memberSnapshot) {
          final members = memberSnapshot.data ?? [];
          return FloatingActionButton(
            backgroundColor: _accent,
            onPressed: () => showCreateTaskSheet(context: context, currentUser: widget.currentUser, groupId: widget.group.id, groupMembers: members),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('all', 'All'),
                _filterChip('pending', 'Pending'),
                _filterChip('in_progress', 'In Progress'),
                _filterChip('completed', 'Completed'),
              ]),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _databaseService.streamGroupTasks(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }
                final tasks = _applyFilter(snapshot.data ?? []);
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('📚', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 12),
                      Text('No group tasks yet', style: GoogleFonts.poppins(color: Colors.grey)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, currentUser: widget.currentUser, isGroupAdmin: _isAdmin)),
                      ),
                      onToggleComplete: () => _databaseService.updateTaskStatus(
                        taskId: task.id,
                        status: task.status == 'completed' ? 'pending' : 'completed',
                        completedBy: task.status == 'completed' ? null : widget.currentUser.uid,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 