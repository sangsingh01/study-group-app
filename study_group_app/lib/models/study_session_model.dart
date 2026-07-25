class StudySession {
  final String id;
  final String groupId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime; // null while session is still running
  final int durationInSeconds;
 
  StudySession({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationInSeconds = 0,
  });
 
  factory StudySession.fromMap(String id, Map<String, dynamic> data) {
    return StudySession(
      id: id,
      groupId: data['groupId'],
      userId: data['userId'],
      startTime: data['startTime'].toDate(),
      endTime: data['endTime'] != null ? data['endTime'].toDate() : null,
      durationInSeconds: data['durationInSeconds'] ?? 0,
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'durationInSeconds': durationInSeconds,
    };
  }
}
 