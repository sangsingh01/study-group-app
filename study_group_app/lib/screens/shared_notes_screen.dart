import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_group_app/constants/design_system.dart';
import '../models/study_models.dart';
import '../services/database_service.dart';
import 'shared_note_detail_screen.dart';

class SharedNotesScreen extends StatefulWidget {
  final String currentUid;
  final String currentUserName;
  final String currentUserPhoto;

  const SharedNotesScreen({
    super.key,
    required this.currentUid,
    required this.currentUserName,
    required this.currentUserPhoto,
  });

  @override
  State<SharedNotesScreen> createState() => _SharedNotesScreenState();
}

class _SharedNotesScreenState extends State<SharedNotesScreen> {
  late final DatabaseService _dbService;
  String searchQuery = '';
  String filterType = 'All'; // All, Unread, PDF, Images

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          Expanded(child: _buildSharedNotesList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: CipherColors.purpleGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared Notes',
                      style: CipherTextStyles.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notes shared with you',
                      style: CipherTextStyles.poppins(
                        fontSize: 13,
                        color: Colors.white,
                        alpha: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: widget.currentUserPhoto.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.currentUserPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.white24,
                  ),
                  child: widget.currentUserPhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              hintStyle: CipherTextStyles.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: ['All', 'Unread', 'PDF', 'Images'].map((filter) {
                final isSelected = filterType == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: CipherTextStyles.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isSelected ? CipherColors.purplePrimary : Colors.grey[200],
                    onSelected: (selected) {
                      setState(() => filterType = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedNotesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getSharedNotesStream(widget.currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No shared notes yet',
                  style: CipherTextStyles.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notes shared with you will appear here',
                  style: CipherTextStyles.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> notes = snapshot.data!;

        // Apply filters
        notes = notes.where((note) {
          final matchesSearch = (note['noteTitle'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery);

          bool matchesFilter = true;
          if (filterType == 'Unread') {
            matchesFilter = !(note['viewedBy'] as List).contains(widget.currentUid);
          } else if (filterType == 'PDF') {
            matchesFilter = note['noteFileType'] == 'pdf';
          } else if (filterType == 'Images') {
            matchesFilter = note['noteFileType'] == 'image';
          }

          return matchesSearch && matchesFilter;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isUnread = !(note['viewedBy'] as List).contains(widget.currentUid);

            return _buildNoteCard(note, isUnread);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, bool isUnread) {
    final sharedBy = note['sharedByName'] ?? 'Anonymous';
    final sharedDate = (note['sharedDate'] as Timestamp).toDate();
    final timeAgo = _getTimeAgo(sharedDate);
    final title = note['noteTitle'] ?? 'Untitled';
    final fileType = (note['noteFileType'] ?? 'doc').toUpperCase();

    return GestureDetector(
      onTap: () async {
        // Mark as read
        await _dbService.markSharedNoteAsRead(widget.currentUid, note['id']);

        // Navigate to detail screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedNoteDetailScreen(
                note: note,
                currentUid: widget.currentUid,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? CipherColors.purplePrimary.withOpacity(0.3) : Colors.grey[300]!,
            width: isUnread ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // File type icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _getFileTypeGradient(note['noteFileType']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getFileTypeIcon(note['noteFileType']),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Note details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CipherTextStyles.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CipherColors.purplePrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shared by $sharedBy • $timeAgo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CipherTextStyles.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if ((note['message'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          note['message'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CipherTextStyles.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // File type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fileType,
                  style: CipherTextStyles.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String? fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  LinearGradient _getFileTypeGradient(String? fileType) {
    switch (fileType) {
      case 'pdf':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
        );
      case 'image':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
        );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
