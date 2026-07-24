import 'package:cloud_firestore/cloud_firestore.dart';
 
// 🎯 NEW: SharedNote Model for tracking notes shared between users
class SharedNoteModel {
  final String id;
  final String noteId;
  final String noteTitle;
  final String noteFileUrl;
  final String noteFileType; // 'pdf', 'image', 'doc'
  final String sharedBy; // UID of person sharing
  final String sharedByName; // Name of person sharing
  final String sharedByPhotoUrl;
  final List<String> sharedWith; // UIDs of recipients
  final DateTime sharedDate;
  final String message; // Optional message with the share
  final List<String> viewedBy; // UIDs of people who viewed it
 
  SharedNoteModel({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.noteFileUrl,
    required this.noteFileType,
    required this.sharedBy,
    required this.sharedByName,
    required this.sharedByPhotoUrl,
    required this.sharedWith,
    required this.sharedDate,
    required this.message,
    required this.viewedBy,
  });
 
  Map<String, dynamic> toMap() => {
    'id': id,
    'noteId': noteId,
    'noteTitle': noteTitle,
    'noteFileUrl': noteFileUrl,
    'noteFileType': noteFileType,
    'sharedBy': sharedBy,
    'sharedByName': sharedByName,
    'sharedByPhotoUrl': sharedByPhotoUrl,
    'sharedWith': sharedWith,
    'sharedDate': Timestamp.fromDate(sharedDate),
    'message': message,
    'viewedBy': viewedBy,
  };
 
  factory SharedNoteModel.fromMap(Map<String, dynamic> map) => SharedNoteModel(
    id: map['id'] ?? '',
    noteId: map['noteId'] ?? '',
    noteTitle: map['noteTitle'] ?? 'Untitled Note',
    noteFileUrl: map['noteFileUrl'] ?? '',
    noteFileType: map['noteFileType'] ?? 'doc',
    sharedBy: map['sharedBy'] ?? '',
    sharedByName: map['sharedByName'] ?? 'Anonymous',
    sharedByPhotoUrl: map['sharedByPhotoUrl'] ?? '',
    sharedWith: List<String>.from(map['sharedWith'] ?? []),
    sharedDate: (map['sharedDate'] as Timestamp).toDate(),
    message: map['message'] ?? '',
    viewedBy: List<String>.from(map['viewedBy'] ?? []),
  );
 
  // Mark note as viewed
  SharedNoteModel copyWithViewed(String userId) {
    final updatedViewed = List<String>.from(viewedBy);
    if (!updatedViewed.contains(userId)) {
      updatedViewed.add(userId);
    }
    return SharedNoteModel(
      id: id,
      noteId: noteId,
      noteTitle: noteTitle,
      noteFileUrl: noteFileUrl,
      noteFileType: noteFileType,
      sharedBy: sharedBy,
      sharedByName: sharedByName,
      sharedByPhotoUrl: sharedByPhotoUrl,
      sharedWith: sharedWith,
      sharedDate: sharedDate,
      message: message,
      viewedBy: updatedViewed,
    );
  }
}
 

class NoteModel {
  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final String fileUrl;       // empty string '' for text notes
  final String fileType;      // 'pdf', 'image', 'doc', or 'text'
  final String? content;      // note body text, only for fileType == 'text'
  final String uploaderName;
  final String uploaderId;
  final DateTime uploadDate;
  final List<String> starredBy;
 
  NoteModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    this.content,
    required this.uploaderName,
    required this.uploaderId,
    required this.uploadDate,
    required this.starredBy,
  });
 
  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'groupName': groupName,
    'title': title,
    'fileUrl': fileUrl,
    'fileType': fileType,
    'content': content,
    'uploaderName': uploaderName,
    'uploaderId': uploaderId,
    'uploadDate': Timestamp.fromDate(uploadDate),
    'starredBy': starredBy,
  };
 
  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
  id: map['id'] ?? '',
  groupId: map['groupId'] ?? '',
  groupName: map['groupName'] ?? 'General',
  title: map['title'] ?? '',
  fileUrl: map['fileUrl'] ?? '',
  fileType: map['fileType'] ?? 'doc',
  content: map['content'],
  uploaderName: map['uploaderName'] ?? 'Anonymous',
  uploaderId: map['uploaderId'] ?? '',
  uploadDate: map['uploadDate'] != null
      ? (map['uploadDate'] as Timestamp).toDate()
      : DateTime.now(),
  starredBy: List<String>.from(map['starredBy'] ?? []),
);
}
class QuizModel {
  final String id;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final int timeLimitMinutes;
  final List<QuestionModel> questions;
 
  QuizModel({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.timeLimitMinutes,
    required this.questions,
  });
 
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'timeLimitMinutes': timeLimitMinutes,
    'questions': questions.map((q) => q.toMap()).toList(),
  };
 
  factory QuizModel.fromMap(Map<String, dynamic> map) => QuizModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    timeLimitMinutes: map['timeLimitMinutes'] ?? 10,
    questions: (map['questions'] as List? ?? []).map((q) => QuestionModel.fromMap(q)).toList(),
  );
}
 
class QuestionModel {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? imageUrl;
 
  QuestionModel({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.imageUrl,
  });
 
  Map<String, dynamic> toMap() => {
    'questionText': questionText,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'imageUrl': imageUrl,
  };
 
  factory QuestionModel.fromMap(Map<String, dynamic> map) => QuestionModel(
    questionText: map['questionText'] ?? '',
    options: List<String>.from(map['options'] ?? []),
    correctOptionIndex: map['correctOptionIndex'] ?? 0,
    imageUrl: map['imageUrl'],
  );
}
 
class ProgressModel {
  final String date;
  final int studyMinutes;
  final int tasksCompleted;
  final int quizzesTaken;
  final int xpEarned;
 
  ProgressModel({
    required this.date,
    required this.studyMinutes,
    required this.tasksCompleted,
    required this.quizzesTaken,
    required this.xpEarned,
  });
 
  factory ProgressModel.fromMap(Map<String, dynamic> map) => ProgressModel(
    date: map['date'] ?? '',
    studyMinutes: map['studyMinutes'] ?? 0,
    tasksCompleted: map['tasksCompleted'] ?? 0,
    quizzesTaken: map['quizzesTaken'] ?? 0,
    xpEarned: map['xpEarned'] ?? 0,
  );
}
 