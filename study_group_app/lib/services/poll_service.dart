import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_model.dart';
 
class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  CollectionReference _pollsRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('polls');
 
  /// Live stream of all polls in a group, newest first.
  Stream<List<PollModel>> pollsStream(String groupId) {
    return _pollsRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PollModel.fromDoc(d, groupId)).toList());
  }
 
  /// Live stream of a single poll (used on the detail/voting screen).
  Stream<PollModel> pollStream(String groupId, String pollId) {
    return _pollsRef(groupId)
        .doc(pollId)
        .snapshots()
        .map((d) => PollModel.fromDoc(d, groupId));
  }
 
  Future<void> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
    required String createdBy,
    required String createdByName,
    required bool allowMultipleChoice,
  }) async {
    await _pollsRef(groupId).add({
      'question': question,
      'options': options,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.now(),
      'allowMultipleChoice': allowMultipleChoice,
      'isClosed': false,
      'votes': <String, dynamic>{},
    });
  }
 
  /// Casts / toggles a vote for [uid] on [optionIndex].
  /// - Single choice: selecting a new option replaces the previous one.
  /// - Multiple choice: tapping an already-selected option removes it,
  ///   tapping a new one adds it.
  Future<void> vote({
    required String groupId,
    required String pollId,
    required String uid,
    required int optionIndex,
    required bool allowMultipleChoice,
  }) async {
    final docRef = _pollsRef(groupId).doc(pollId);
 
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
 
      if (data['isClosed'] == true) return;
 
      final rawVotes = Map<String, dynamic>.from(data['votes'] ?? {});
      final current = List<int>.from(rawVotes[uid] ?? []);
 
      if (allowMultipleChoice) {
        if (current.contains(optionIndex)) {
          current.remove(optionIndex);
        } else {
          current.add(optionIndex);
        }
      } else {
        if (current.length == 1 && current.first == optionIndex) {
          current.clear(); // tapping the same single choice un-votes
        } else {
          current
            ..clear()
            ..add(optionIndex);
        }
      }
 
      rawVotes[uid] = current;
      tx.update(docRef, {'votes': rawVotes});
    });
  }
 
  Future<void> closePoll(String groupId, String pollId) async {
    await _pollsRef(groupId).doc(pollId).update({'isClosed': true});
  }
 
  Future<void> reopenPoll(String groupId, String pollId) async {
    await _pollsRef(groupId).doc(pollId).update({'isClosed': false});
  }
 
  Future<void> deletePoll(String groupId, String pollId) async {
    await _pollsRef(groupId).doc(pollId).delete();
  }
}
