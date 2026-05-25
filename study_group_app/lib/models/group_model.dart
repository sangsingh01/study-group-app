class GroupModel {
  final String id;
  final String name;
  final String description;
  final String subject;
  final String createdBy;
  final String createdByName;
  final List<String> members;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.createdBy,
    required this.createdByName,
    required this.members,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'members': members,
      'createdAt': createdAt,
    };
  }

  // Convert from Firestore Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: map['createdAt'].toDate(),
    );
  }
}