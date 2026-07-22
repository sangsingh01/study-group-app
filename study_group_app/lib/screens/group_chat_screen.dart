import 'dart:async';

import 'package:flutter/material.dart';

import '../models/group_message.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/chat_file_picker.dart';
import 'package:study_group_app/services/cloudinary_service.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  bool _isUploading = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (_isTyping == isTyping) return;
    _isTyping = isTyping;
    await _databaseService.updateGroupTypingStatus(
      groupId: widget.group.id,
      uid: widget.currentUser.uid,
      username: widget.currentUser.username,
      isTyping: isTyping,
    );
  }

  void _onMessageChanged(String text) {
    _typingTimer?.cancel();
    final shouldType = text.trim().isNotEmpty;
    _updateTypingStatus(shouldType);

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = GroupMessage(
      id: _databaseService.generateGroupMessageId(widget.group.id),
      senderUid: widget.currentUser.uid,
      senderName: widget.currentUser.username,
      senderImage: widget.currentUser.profileImage,
      groupId: widget.group.id,
      type: 'text',
      content: text,
      createdAt: DateTime.now(),
    );

    _messageController.clear();
    await _databaseService.sendGroupMessage(widget.group.id, message);
    await _updateTypingStatus(false);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // ---------------- file/image sending ----------------

  String _deriveFileType(String fileName, bool isImage) {
    if (isImage) return 'image';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (ext == 'pdf') return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'doc';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['xls', 'xlsx'].contains(ext)) return 'xls';
    return 'doc';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handlePickedFile(PickedChatFile picked) async {
    setState(() => _isUploading = true);

    try {
      final cloudinaryService = CloudinaryService();
      final derivedType = _deriveFileType(picked.fileName, picked.isImage);

      final response = await cloudinaryService.uploadBytes(
        bytes: picked.bytes,
        fileName: picked.fileName,
        isImage: picked.isImage,
      );

      final downloadUrl = response.secureUrl;

      final message = GroupMessage(
        id: _databaseService.generateGroupMessageId(widget.group.id),
        senderUid: widget.currentUser.uid,
        senderName: widget.currentUser.username,
        senderImage: widget.currentUser.profileImage,
        groupId: widget.group.id,
        type: picked.isImage ? 'image' : 'file',
        content: picked.isImage ? '📷 Photo' : '📎 ${picked.fileName}',
        imageUrl: picked.isImage ? downloadUrl : null,
        fileUrl: downloadUrl,
        fileName: picked.fileName,
        fileType: derivedType,
        fileSizeBytes: picked.bytes.length,
        createdAt: DateTime.now(),
      );

      await _databaseService.sendGroupFileMessage(
        groupId: widget.group.id,
        message: message,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // -----------------------------------------------------

  Widget _buildChatBubble(GroupMessage message) {
    final isOwnMessage = message.senderUid == widget.currentUser.uid;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: message.type == 'image'
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
            bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(184),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (message.type == 'image' && message.fileUrl != null)
              _buildImageBubbleContent(message)
            else if (message.type == 'file' && message.fileUrl != null)
              _buildFileBubbleContent(message, isOwnMessage)
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isOwnMessage
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: message.type == 'image'
                  ? const EdgeInsets.only(left: 4, bottom: 2)
                  : EdgeInsets.zero,
              child: Text(
                _formatTimestamp(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: (isOwnMessage && message.type != 'text')
                      ? colorScheme.onPrimary.withAlpha(200)
                      : colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubbleContent(GroupMessage message) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _FullScreenImageViewer(url: message.fileUrl!)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
          color: Colors.grey[200],
          child: Image.network(
            message.fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stack) => const SizedBox(
              height: 160,
              child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileBubbleContent(GroupMessage message, bool isOwnMessage) {
    final isPdf = message.fileType == 'pdf';
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPdf ? const Color(0xFFFFE3EC) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
            color: isPdf ? const Color(0xFFFF6584) : const Color(0xFF43A047),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.fileName ?? 'File',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOwnMessage ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatFileSize(message.fileSizeBytes),
                style: TextStyle(
                  fontSize: 11,
                  color: isOwnMessage
                      ? colorScheme.onPrimary.withAlpha(200)
                      : colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.download_rounded, size: 18,
            color: isOwnMessage ? colorScheme.onPrimary : Colors.black45),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.group.name} Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: _databaseService.groupMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation with your group.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildChatBubble(message);
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: _databaseService.groupTypingUsers(
              widget.group.id,
              widget.currentUser.uid,
            ),
            builder: (context, snapshot) {
              final typers = snapshot.data ?? [];
              if (typers.isEmpty) return const SizedBox.shrink();
              final typingText = typers.length == 1
                  ? '${typers.first} is typing...'
                  : 'Several people are typing...';
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    typingText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 10,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file_rounded, color: Theme.of(context).colorScheme.primary),
                  onPressed: _isUploading
                      ? null
                      : () async {
                          final picked = await pickChatFile();
                          if (picked != null) _handlePickedFile(picked);
                        },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _onMessageChanged,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  const _FullScreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}