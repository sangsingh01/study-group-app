import 'package:cloud_firestore/cloud_firestore.dart';

class DirectMessage {
  final String id; // messageId
  final String senderUid;
  final String receiverUid;
  final String senderName;
  final String? senderImage;
  final String type; // 'text' | 'note' | 'image'
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool edited;

  DirectMessage({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.senderName,
    this.senderImage,
    required this.type,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.edited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'senderName': senderName,
      'senderImage': senderImage,
      'type': type,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'edited': edited,
    };
  }

  factory DirectMessage.fromMap(Map<String, dynamic> map) {
    final content = map['content'] ?? map['text'] ?? '';
    return DirectMessage(
      id: map['id'] ?? '',
      senderUid: map['senderUid'] ?? '',
      receiverUid: map['receiverUid'] ?? map['toUid'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] as String?,
      type: map['type'] ?? (map['imageUrl'] != null ? 'image' : 'text'),
      content: content,
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      edited: map['edited'] == true,
    );
  }
}
