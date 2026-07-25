import 'package:cloud_firestore/cloud_firestore.dart';
 
class PollModel {
  final String id;
  final String groupId;
  final String question;
  final List<String> options;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool allowMultipleChoice;
  final bool isClosed;
 
  /// uid -> list of selected option indices
  final Map<String, List<int>> votes;
 
  PollModel({
    required this.id,
    required this.groupId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.allowMultipleChoice,
    required this.isClosed,
    required this.votes,
  });
 
  factory PollModel.fromDoc(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
 
    final rawVotes = (data['votes'] as Map<String, dynamic>? ?? {});
    final parsedVotes = <String, List<int>>{};
    rawVotes.forEach((uid, value) {
      parsedVotes[uid] = List<int>.from(value ?? []);
    });
 
    return PollModel(
      id: doc.id,
      groupId: groupId,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? 'Member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allowMultipleChoice: data['allowMultipleChoice'] ?? false,
      isClosed: data['isClosed'] ?? false,
      votes: parsedVotes,
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'allowMultipleChoice': allowMultipleChoice,
      'isClosed': isClosed,
      'votes': votes,
    };
  }
 
  /// Number of votes each option index has received.
  List<int> get voteCounts {
    final counts = List<int>.filled(options.length, 0);
    for (final selections in votes.values) {
      for (final index in selections) {
        if (index >= 0 && index < counts.length) counts[index]++;
      }
    }
    return counts;
  }
 
  int get totalVoters => votes.length;
 
  List<int> selectionsFor(String uid) => votes[uid] ?? [];
 
  bool hasVoted(String uid) => votes.containsKey(uid) && votes[uid]!.isNotEmpty;
 
  /// uids of everyone who picked a given option index.
  List<String> votersForOption(int optionIndex) {
    return votes.entries
        .where((e) => e.value.contains(optionIndex))
        .map((e) => e.key)
        .toList();
  }
}
 