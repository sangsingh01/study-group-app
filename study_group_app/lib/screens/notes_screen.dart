import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_group_app/constants/design_system.dart';
import '../models/study_models.dart';
import '../services/cloudinary_service.dart';
import '../utils/pick_chat_file.dart';
import 'package:url_launcher/url_launcher.dart';

class NotesScreen extends StatefulWidget {
  final String currentUid;
  final String? groupId;
  const NotesScreen({super.key, required this.currentUid, this.groupId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('notes');
    if (widget.groupId != null) {
      query = query.where('groupId', isEqualTo: widget.groupId);
    }

    return Scaffold(
      backgroundColor: CipherColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: CipherColors.purplePrimary,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
        onPressed: () => _showUploadBottomSheet(),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(child: _buildNotesGrid(query)),
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
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Notes',
                    style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Access group documents and references',
                    style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = ['All', 'PDF', 'Images', 'Starred'];
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: chips.map((chip) {
          final isSelected = selectedFilter == chip;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ChoiceChip(
              label: Text(chip),
              labelStyle: CipherTextStyles.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              selected: isSelected,
              selectedColor: CipherColors.purplePrimary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) => setState(() => selectedFilter = chip),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesGrid(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CipherColors.purplePrimary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        // NoteModel.fromMap takes ONE argument — id is already stored inside the doc's own map (see toMap())
        var notes = snapshot.data!.docs
            .map((d) => NoteModel.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        if (selectedFilter == 'PDF') notes = notes.where((n) => n.fileType == 'pdf').toList();
        if (selectedFilter == 'Images') notes = notes.where((n) => n.fileType == 'image').toList();
        if (selectedFilter == 'Starred') notes = notes.where((n) => n.starredBy.contains(widget.currentUid)).toList();

        if (notes.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: notes.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, idx) {
            final note = notes[idx];
            final isStarred = note.starredBy.contains(widget.currentUid);
            return _buildCustomNoteRow(note, isStarred);
          },
        );
      },
    );
  }

  Widget _buildCustomNoteRow(NoteModel note, bool isStarred) {
    Color typeBg = note.fileType == 'pdf' ? CipherColors.tasksBg : (note.fileType == 'image' ? CipherColors.notesBg : CipherColors.quizBg);
    Color iconColor = note.fileType == 'pdf' ? CipherColors.pinkPrimary : (note.fileType == 'image' ? CipherColors.purplePrimary : CipherColors.greenPrimary);
    IconData typeIcon = note.fileType == 'pdf' ? Icons.picture_as_pdf_rounded : (note.fileType == 'image' ? Icons.image_rounded : Icons.description_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: typeBg, radius: 22, child: Icon(typeIcon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Shared by ${note.uploaderName}', style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 20, color: Colors.black54),
                      // fileUrl is a non-nullable String in your model — empty for text notes
                      onPressed: note.fileUrl.isNotEmpty ? () => _downloadOrOpen(note.fileUrl) : null,
                    ),
                    IconButton(
                      icon: Icon(isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 22, color: isStarred ? Colors.amber : Colors.grey),
                      onPressed: () => _toggleStar(note.id, isStarred),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStar(String noteId, bool isStarred) async {
    final ref = FirebaseFirestore.instance.collection('notes').doc(noteId);
    if (isStarred) {
      await ref.update({'starredBy': FieldValue.arrayRemove([widget.currentUid])});
    } else {
      await ref.update({'starredBy': FieldValue.arrayUnion([widget.currentUid])});
    }
  }

  void _downloadOrOpen(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 54, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No matching notes discovered', style: CipherTextStyles.poppins(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  void _showUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => _UploadSheet(currentUid: widget.currentUid, groupId: widget.groupId),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final String currentUid;
  final String? groupId;
  const _UploadSheet({required this.currentUid, this.groupId});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  bool isFileMode = true;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  PickedChatFile? pickedFile;
  bool isUploading = false;

  final _cloudinaryService = CloudinaryService();

  Future<void> _pickFile() async {
    final result = await pickChatFile();
    if (result != null) setState(() => pickedFile = result);
  }

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty) return;
    setState(() => isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uploaderName = user?.displayName ?? 'Anonymous';
      final uploaderId = widget.currentUid;
      final docRef = FirebaseFirestore.instance.collection('notes').doc();

      if (isFileMode) {
        if (pickedFile == null) {
          setState(() => isUploading = false);
          return;
        }

        // your real CloudinaryService: instance method, takes isImage bool, returns CloudinaryResponse
        final response = await _cloudinaryService.uploadBytes(
          bytes: pickedFile!.bytes,
          fileName: pickedFile!.fileName,
          isImage: pickedFile!.isImage,
        );

        final note = NoteModel(
          id: docRef.id,
          groupId: widget.groupId ?? '',
          groupName: 'General', // TODO: replace with real group name if available on this screen
          title: titleController.text.trim(),
          fileUrl: response.secureUrl,
          fileType: pickedFile!.isImage ? 'image' : 'pdf',
          content: null,
          uploaderName: uploaderName,
          uploaderId: uploaderId,
          uploadDate: DateTime.now(),
          starredBy: [],
        );

        await docRef.set(note.toMap());
      } else {
        if (contentController.text.trim().isEmpty) {
          setState(() => isUploading = false);
          return;
        }

        final note = NoteModel(
          id: docRef.id,
          groupId: widget.groupId ?? '',
          groupName: 'General',
          title: titleController.text.trim(),
          fileUrl: '',
          fileType: 'text',
          content: contentController.text.trim(),
          uploaderName: uploaderName,
          uploaderId: uploaderId,
          uploadDate: DateTime.now(),
          starredBy: [],
        );

        await docRef.set(note.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Add Study Material', style: CipherTextStyles.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _modeButton('Upload File', isFileMode, () => setState(() => isFileMode = true))),
              const SizedBox(width: 10),
              Expanded(child: _modeButton('Write Note', !isFileMode, () => setState(() => isFileMode = false))),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Title",
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: CipherColors.purplePrimary)),
            ),
          ),
          const SizedBox(height: 16),
          if (isFileMode) ...[
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(pickedFile == null ? 'Choose PDF or Image' : pickedFile!.fileName),
            ),
          ] else ...[
            TextField(
              controller: contentController,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Write your notes here...', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isUploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: CipherColors.purplePrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isUploading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Publish', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CipherColors.purplePrimary : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: CipherTextStyles.poppins(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}