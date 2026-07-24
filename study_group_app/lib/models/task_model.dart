import 'package:cloud_firestore/cloud_firestore.dart';
 
class SubtaskModel {
  final String id;
  final String title;
  final bool isDone;
 
  SubtaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
  });
 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }
 
  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isDone: map['isDone'] == true,
    );
  }
 
  SubtaskModel copyWith({String? title, bool? isDone}) {
    return SubtaskModel(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
 
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'personal' | 'group'
  final String? groupId; // set only when type == 'group'
  final String creatorUid;
  final List<String> assignedTo; // uids
  final DateTime? dueDate;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'pending' | 'in_progress' | 'completed'
  final List<SubtaskModel> subtasks;
  final String? attachmentUrl; // Cloudinary secureUrl
  final String? attachmentFileName;
  final String? attachmentFileType; // 'pdf' | 'doc' | 'ppt' | 'xls' | 'image'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;
 
  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    this.groupId,
    required this.creatorUid,
    this.assignedTo = const [],
    this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.subtasks = const [],
    this.attachmentUrl,
    this.attachmentFileName,
    this.attachmentFileType,
    required this.createdAt,
    this.completedAt,
    this.completedBy,
  });
 
  bool get isOverdue =>
      dueDate != null && status != 'completed' && dueDate!.isBefore(DateTime.now());
 
  int get completedSubtaskCount => subtasks.where((s) => s.isDone).length;
 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'groupId': groupId,
      'creatorUid': creatorUid,
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority,
      'status': status,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'attachmentFileType': attachmentFileType,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
    };
  }
 
  factory TaskModel.fromMap(String docId, Map<String, dynamic> map) {
    return TaskModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'personal',
      groupId: map['groupId'] as String?,
      creatorUid: map['creatorUid'] ?? '',
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      subtasks: (map['subtasks'] as List<dynamic>? ?? [])
          .map((s) => SubtaskModel.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentFileName: map['attachmentFileName'] as String?,
      attachmentFileType: map['attachmentFileType'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: map['completedBy'] as String?,
    );
  }
 
  TaskModel copyWith({
    String? title,
    String? description,
    List<String>? assignedTo,
    DateTime? dueDate,
    String? priority,
    String? status,
    List<SubtaskModel>? subtasks,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      groupId: groupId,
      creatorUid: creatorUid,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      subtasks: subtasks ?? this.subtasks,
      attachmentUrl: attachmentUrl,
      attachmentFileName: attachmentFileName,
      attachmentFileType: attachmentFileType,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}
 