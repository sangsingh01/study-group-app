import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String subject;
  final String createdBy;
  final String createdByName;
  final String adminUid;
  final String inviteCode;
  final List<String> members;
  final Map<String, String> memberRoles;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.createdBy,
    required this.createdByName,
    required this.adminUid,
    required this.inviteCode,
    required this.members,
    required this.memberRoles,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'adminUid': adminUid,
      'inviteCode': inviteCode,
      'members': members,
      'memberRoles': memberRoles,
      'createdAt': createdAt,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      adminUid: map['adminUid'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
