import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String id; // messageId
  final String senderUid;
  final String senderName;
  final String? senderImage;
  final String groupId;
  final String type; // 'text' | 'note' | 'image' | 'file'
  final String content; // text or note content or image/file caption
  final String? imageUrl; // if type == 'image'
  final String? fileUrl; // if type == 'file' (or 'image', reuses same Cloudinary url)
  final String? fileName;
  final String? fileType; // 'pdf' | 'doc' | 'ppt' | 'xls' | 'image'
  final int? fileSizeBytes;
  final DateTime createdAt;
  final bool edited;

  GroupMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    this.senderImage,
    required this.groupId,
    required this.type,
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSizeBytes,
    required this.createdAt,
    this.edited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImage': senderImage,
      'groupId': groupId,
      'type': type,
      'content': content,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'createdAt': Timestamp.fromDate(createdAt),
      'edited': edited,
    };
  }

  factory GroupMessage.fromMap(Map<String, dynamic> map) {
    // Backwards compatibility: older messages might have 'text'
    final content = map['content'] ?? map['text'] ?? '';
    return GroupMessage(
      id: map['id'] ?? '',
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] as String?,
      groupId: map['groupId'] ?? map['group'] ?? '',
      type: map['type'] ?? (map['imageUrl'] != null ? 'image' : 'text'),
      content: content,
      imageUrl: map['imageUrl'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String?,
      fileType: map['fileType'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      edited: map['edited'] == true,
    );
  }
}