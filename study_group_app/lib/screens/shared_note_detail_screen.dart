import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_group_app/constants/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedNoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String currentUid;

  const SharedNoteDetailScreen({
    super.key,
    required this.note,
    required this.currentUid,
  });

  @override
  State<SharedNoteDetailScreen> createState() => _SharedNoteDetailScreenState();
}

class _SharedNoteDetailScreenState extends State<SharedNoteDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final title = widget.note['noteTitle'] ?? 'Note';
    final sharedBy = widget.note['sharedByName'] ?? 'Anonymous';
    final sharedByPhoto = widget.note['sharedByPhotoUrl'] ?? '';
    final message = widget.note['message'] ?? '';
    final fileUrl = widget.note['noteFileUrl'] ?? '';
    final fileType = widget.note['noteFileType'] ?? 'doc';
    final sharedDate = (widget.note['sharedDate'] as Timestamp).toDate();
    final viewedBy = List<String>.from(widget.note['viewedBy'] ?? []);

    return Scaffold(
      backgroundColor: CipherColors.background,
      appBar: AppBar(
        backgroundColor: CipherColors.purplePrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Note Details',
          style: CipherTextStyles.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadNote(fileUrl),
            tooltip: 'Download',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note Title
            Text(
              title,
              style: CipherTextStyles.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Shared By Card
            _buildSharedByCard(sharedBy, sharedByPhoto, sharedDate),
            const SizedBox(height: 16),

            // Message Section
            if (message.isNotEmpty) ...[
              Text(
                'Message',
                style: CipherTextStyles.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  message,
                  style: CipherTextStyles.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // File Preview Section
            _buildFilePreview(fileType),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadNote(fileUrl),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CipherColors.purplePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openNote(fileUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CipherColors.purplePrimary,
                      side: const BorderSide(color: CipherColors.purplePrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Viewed By Section
            _buildViewedBySection(viewedBy),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedByCard(
    String sharedBy,
    String photo,
    DateTime sharedDate,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F7FA), Color(0xFFEEF2F7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: photo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[300],
            ),
            child: photo.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sharedBy,
                  style: CipherTextStyles.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Shared ${_getTimeAgoDetailed(sharedDate)}',
                  style: CipherTextStyles.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(String fileType) {
    final iconData = _getFileTypeIcon(fileType);
    final gradient = _getFileTypeGradient(fileType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            iconData,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            fileType.toUpperCase(),
            style: CipherTextStyles.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Note File',
            style: CipherTextStyles.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewedBySection(List<String> viewedBy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewed by (${viewedBy.length})',
          style: CipherTextStyles.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (viewedBy.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No one has viewed this note yet',
              style: CipherTextStyles.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          )
        else
          Column(
            children: List.generate(
              viewedBy.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'User viewed this note',
                        style: CipherTextStyles.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadNote(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file URL')),
      );
      return;
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download file: $e')),
      );
    }
  }

  Future<void> _openNote(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file URL')),
      );
      return;
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
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

  String _getTimeAgoDetailed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
