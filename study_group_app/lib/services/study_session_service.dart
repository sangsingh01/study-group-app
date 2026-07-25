import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session_model.dart';

class StudySessionService {
  final CollectionReference _sessions =
      FirebaseFirestore.instance.collection('study_sessions');

  /// Call when user taps "Start". Returns the new session's doc ID —
  /// keep this ID in your screen's state so you can stop it later.
  Future<String> startSession({
    required String groupId,
    required String userId,
  }) async {
    final doc = await _sessions.add({
      'groupId': groupId,
      'userId': userId,
      'startTime': DateTime.now(),
      'endTime': null,
      'durationInSeconds': 0,
    });
    return doc.id;
  }

  /// Call when user taps "Stop".
  Future<void> stopSession(String sessionId, DateTime startTime) async {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inSeconds;
    await _sessions.doc(sessionId).update({
      'endTime': endTime,
      'durationInSeconds': duration,
    });
  }

  /// Total seconds studied today, for this user in this group.
  Stream<int> watchTodayTotalSeconds(String groupId, String userId) {
    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _watchTotalSecondsSince(groupId, userId, startOfDay);
  }

  /// Total seconds studied this week (last 7 days), for this user in this group.
  Stream<int> watchWeekTotalSeconds(String groupId, String userId) {
    final startOfWeek = DateTime.now().subtract(const Duration(days: 7));
    return _watchTotalSecondsSince(groupId, userId, startOfWeek);
  }

  Stream<int> _watchTotalSecondsSince(
      String groupId, String userId, DateTime since) {
    return _sessions
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: since)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['durationInSeconds'] ?? 0) as int;
      }
      return total;
    });
  }

  /// Current streak = number of consecutive days (ending today) with at
  /// least one completed session. Looks back 60 days, which is plenty
  /// for any realistic streak.
  Stream<int> watchCurrentStreak(String groupId, String userId) {
    final lookback = DateTime.now().subtract(const Duration(days: 60));
    return _sessions
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: lookback)
        .snapshots()
        .map((snapshot) {
      // Collect the distinct calendar days that have a session.
      final daysWithSession = <DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final start = (data['startTime'] as Timestamp).toDate();
        daysWithSession.add(DateTime(start.year, start.month, start.day));
      }

      // Walk backward from today counting consecutive days present.
      int streak = 0;
      DateTime cursor = DateTime.now();
      cursor = DateTime(cursor.year, cursor.month, cursor.day);
      while (daysWithSession.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    });
  }
}