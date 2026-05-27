import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String? senderImage;
  final String text;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    this.senderImage,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImage': senderImage,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupMessage.fromMap(Map<String, dynamic> map) {
    return GroupMessage(
      id: map['id'] ?? '',
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] as String?,
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
