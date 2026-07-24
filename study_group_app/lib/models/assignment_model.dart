import 'package:cloud_firestore/cloud_firestore.dart';
 
class AssignmentAttachment {
  final String fileUrl;
  final String fileName;
  final String fileType; // 'pdf' | 'image' | 'doc' | ...
  final String uploadedBy;
  final String uploadedByName;
 
  AssignmentAttachment({
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedByName,
  });
 
  Map<String, dynamic> toMap() => {
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
      };
 
  factory AssignmentAttachment.fromMap(Map<String, dynamic> map) {
    return AssignmentAttachment(
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? 'File',
      fileType: map['fileType'] ?? 'doc',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? 'Unknown',
    );
  }
}
 
class AssignmentModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
 
  /// uid -> whether that member has marked their part done
  final Map<String, bool> memberCompletion;
  final List<AssignmentAttachment> attachments;
 
  AssignmentModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    this.dueDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.memberCompletion,
    required this.attachments,
  });
 
  /// Fraction of members who've marked themselves done, e.g. 3/5.
  /// [totalMemberCount] should come from the live group member list,
  /// not just memberCompletion.length, so members added later still count.
  double progressFraction(int totalMemberCount) {
    if (totalMemberCount == 0) return 0;
    final doneCount = memberCompletion.values.where((v) => v == true).length;
    return doneCount / totalMemberCount;
  }
 
  int doneCount() => memberCompletion.values.where((v) => v == true).length;
 
  bool isOverdue() {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
 
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberCompletion': memberCompletion,
      'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }
 
  factory AssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AssignmentModel(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? 'Untitled Assignment',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? 'Unknown',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      memberCompletion: Map<String, bool>.from(map['memberCompletion'] ?? {}),
      attachments: (map['attachments'] as List<dynamic>? ?? [])
          .map((a) => AssignmentAttachment.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
    );
  }
}
 
class AssignmentCommentModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
 
  AssignmentCommentModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
  });
 
  Map<String, dynamic> toMap() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'timestamp': Timestamp.fromDate(timestamp),
      };
 
  factory AssignmentCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return AssignmentCommentModel(
      id: id,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
