import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
 
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message; // for file/image messages, use as a caption or leave ''
  final DateTime timestamp;
  final bool isRead;
  final String messageType; // 'text' | 'image' | 'file'
 
  // NEW fields — only populated when messageType is 'image' or 'file'
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? fileType; // 'pdf' | 'image' | 'doc' | 'ppt' | 'xls'
 
  MessageModel({
    String? id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.fileType,
  }) : id = id ?? const Uuid().v4();
 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (fileType != null) 'fileType': fileType,
    };
  }
 
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      messageType: map['messageType'] ?? 'text',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt(),
      fileType: map['fileType'],
    );
  }
}
 