import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new group
  Future<void> createGroup(GroupModel group) async {
    await _firestore
        .collection('groups')
        .doc(group.id)
        .set(group.toMap());
  }

  // Get all groups
  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data()))
            .toList());
  }

  // Join a group
  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  // Get my groups
  Stream<List<GroupModel>> getMyGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data()))
            .toList());
  }
}