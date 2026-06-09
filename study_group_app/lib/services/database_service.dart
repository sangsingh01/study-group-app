import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_message.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/direct_message.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseService() {
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  Future<void> createUserProfile(User authUser) async {
    final uid = authUser.uid;
    final userDoc = _firestore.collection('users').doc(uid);
    final snapshot = await userDoc.get();
    if (snapshot.exists) return;

    final email = authUser.email ?? '';
    final username = await _generateUniqueUsername(
      authUser.displayName?.split(' ').first ?? email.split('@').first,
    );

    await userDoc.set(
      AppUser(
        uid: uid,
        username: username,
        email: email,
        profileImage: authUser.photoURL,
        isActive: true,
        lastSeen: DateTime.now(),
      ).toMap(),
    );
  }

  Future<String> _generateUniqueUsername(String rawName) async {
    final base = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    var candidate = base.isEmpty ? 'student' : base;
    var suffix = 1;

    while (true) {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: candidate)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return candidate;
      }
      candidate = '$base$suffix';
      suffix += 1;
    }
  }

  Stream<AppUser?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap(snapshot.data()!);
    });
  }

  Future<AppUser?> getUserByUid(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.exists && snapshot.data() != null
        ? AppUser.fromMap(snapshot.data()!)
        : null;
  }

  Stream<List<AppUser>> searchUsers(String query, {String? excludeUid}) {
    final searchText = query.toLowerCase();
    return _firestore
        .collection('users')
        .orderBy('username')
        .startAt([searchText])
        .endAt(['$searchText\uf8ff'])
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data()))
              .where((user) => user.uid != excludeUid)
              .toList(),
        );
  }

  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <AppUser>[];
    final chunks = _chunkList(uids, 10);

    for (final chunk in chunks) {
      final query = await _firestore
          .collection('users')
          .where('uid', whereIn: chunk)
          .get();
      results.addAll(query.docs.map((doc) => AppUser.fromMap(doc.data())));
    }
    return results;
  }

  Stream<List<AppUser>> usersByIdsStream(List<String> uids) {
    if (uids.isEmpty) {
      return Stream<List<AppUser>>.value([]);
    }

    if (uids.length <= 10) {
      return _firestore
          .collection('users')
          .where('uid', whereIn: uids)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AppUser.fromMap(doc.data()))
                .toList(),
          );
    }

    final controller = StreamController<List<AppUser>>.broadcast();
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    final cache = <String, AppUser>{};

    void emit() {
      controller.add(cache.values.toList());
    }

    for (final chunk in _chunkList(uids, 10)) {
      final stream = _firestore
          .collection('users')
          .where('uid', whereIn: chunk)
          .snapshots();
      final subscription = stream.listen((snapshot) {
        for (final doc in snapshot.docs) {
          final user = AppUser.fromMap(doc.data());
          cache[user.uid] = user;
        }
        emit();
      });
      subs.add(subscription);
    }

    controller.onCancel = () {
      for (final subscription in subs) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  Future<AppUser?> getUserByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return AppUser.fromMap(query.docs.first.data());
  }

  Future<GroupModel?> joinGroupByInviteCode(
    String inviteCode,
    String userId,
  ) async {
    final group = await getGroupByInviteCode(inviteCode.trim());
    if (group == null) return null;
    if (group.members.contains(userId)) return group;
    await joinGroup(group.id, userId);
    return group;
  }

  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    if (fromUid == toUid) return;
    final fromRef = _firestore.collection('users').doc(fromUid);
    final toRef = _firestore.collection('users').doc(toUid);

    await _firestore.runTransaction((transaction) async {
      final fromSnapshot = await transaction.get(fromRef);
      final toSnapshot = await transaction.get(toRef);
      if (!fromSnapshot.exists || !toSnapshot.exists) return;

      final fromUser = AppUser.fromMap(fromSnapshot.data()!);
      final toUser = AppUser.fromMap(toSnapshot.data()!);

      if (toUser.friendRequests.contains(fromUid) ||
          toUser.friends.contains(fromUid) ||
          fromUser.sentRequests.contains(toUid)) {
        return;
      }

      transaction.update(toRef, {
        'friendRequests': FieldValue.arrayUnion([fromUid]),
      });
      transaction.update(fromRef, {
        'sentRequests': FieldValue.arrayUnion([toUid]),
      });
    });
  }

  Future<void> acceptFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    final currentRef = _firestore.collection('users').doc(currentUid);
    final requesterRef = _firestore.collection('users').doc(requesterUid);

    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentRef);
      final requesterSnapshot = await transaction.get(requesterRef);
      if (!currentSnapshot.exists || !requesterSnapshot.exists) return;

      transaction.update(currentRef, {
        'friends': FieldValue.arrayUnion([requesterUid]),
        'friendRequests': FieldValue.arrayRemove([requesterUid]),
      });
      transaction.update(requesterRef, {
        'friends': FieldValue.arrayUnion([currentUid]),
        'sentRequests': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<void> declineFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    final currentRef = _firestore.collection('users').doc(currentUid);
    final requesterRef = _firestore.collection('users').doc(requesterUid);

    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentRef);
      if (!currentSnapshot.exists) return;
      transaction.update(currentRef, {
        'friendRequests': FieldValue.arrayRemove([requesterUid]),
      });
      transaction.update(requesterRef, {
        'sentRequests': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<void> createGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).set(group.toMap());
  }

  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<GroupModel?> groupStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return GroupModel.fromMap(snapshot.data()!);
    });
  }

  Future<GroupModel?> getGroupByInviteCode(String inviteCode) async {
    final query = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return GroupModel.fromMap(query.docs.first.data());
  }

  Future<void> addGroupMember(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([memberUid]),
      'memberRoles.$memberUid': 'member',
    });
  }

  Stream<List<GroupModel>> getMyGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'memberRoles.$userId': 'member',
    });
  }

  String generateGroupMessageId(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc()
        .id;
  }

  Stream<List<GroupMessage>> groupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMessage.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendGroupMessage(String groupId, GroupMessage message) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Upload image bytes to Firebase Storage and return download URL.
  Future<String> uploadImageData({
    required Uint8List bytes,
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putData(bytes);

    uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }
    });

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  /// Upload group image for a message and return download URL.
  Future<String> uploadGroupImage(
    Uint8List bytes,
    String groupId,
    String messageId, {
    void Function(double)? onProgress,
  }) async {
    final path = 'groups/$groupId/messages/$messageId.jpg';
    return uploadImageData(bytes: bytes, path: path, onProgress: onProgress);
  }

  /// Helper to deterministically compute conversation id for two users.
  String _conversationId(String a, String b) {
    final parts = [a, b]..sort();
    return parts.join('_');
  }

  /// Send direct message between two users (one-to-one chat)
  Future<void> sendDirectMessage(DirectMessage message) async {
    final convoId = _conversationId(message.senderUid, message.receiverUid);
    await _firestore
        .collection('direct_chats')
        .doc(convoId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Stream direct messages for conversation between two users
  Stream<List<DirectMessage>> directMessages(String uidA, String uidB) {
    final convoId = _conversationId(uidA, uidB);
    return _firestore
        .collection('direct_chats')
        .doc(convoId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => DirectMessage.fromMap(d.data()))
              .toList(),
        );
  }

  /// Update user presence fields in Firestore
  Future<void> setUserActive(String uid, bool isActive) async {
    final ref = _firestore.collection('users').doc(uid);
    await ref.set({
      'isActive': isActive,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  /// Stream groups where the user is a member or admin. Merges two queries to provide an OR-like result.
  Stream<List<GroupModel>> getGroupsForUser(String userId) {
    final controller = StreamController<List<GroupModel>>.broadcast();

    final subs = <StreamSubscription>[];
    final Map<String, GroupModel> cache = {};

    void emit() {
      controller.add(cache.values.toList());
    }

    final q1 = _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots();
    final q2 = _firestore
        .collection('groups')
        .where('adminUid', isEqualTo: userId)
        .snapshots();

    subs.add(
      q1.listen((snap) {
        for (final doc in snap.docs) {
          final g = GroupModel.fromMap(doc.data());
          cache[g.id] = g;
        }
        emit();
      }),
    );

    subs.add(
      q2.listen((snap) {
        for (final doc in snap.docs) {
          final g = GroupModel.fromMap(doc.data());
          cache[g.id] = g;
        }
        emit();
      }),
    );

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> updateGroupTypingStatus({
    required String groupId,
    required String uid,
    required String username,
    required bool isTyping,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('typing')
        .doc(uid)
        .set({
          'uid': uid,
          'username': username,
          'isTyping': isTyping,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
  }

  Stream<List<String>> groupTypingUsers(String groupId, String excludeUid) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('typing')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.id != excludeUid)
              .where((doc) => doc.data()['isTyping'] == true)
              .map((doc) => doc.data()['username'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList(),
        );
  }

  // ===== Direct Message / Chat Methods =====

  String _getChatId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String receiverId,
    String message,
  ) async {
    final messageId = _firestore.collection('chats').doc().id;
    final timestamp = DateTime.now();

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
          'id': messageId,
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message,
          'timestamp': Timestamp.fromDate(timestamp),
          'isRead': false,
          'messageType': 'text',
        });

    // Update chat metadata
    await _firestore
        .collection('chats')
        .doc(chatId)
        .set({
          'lastMessage': message,
          'lastMessageTime': Timestamp.fromDate(timestamp),
          'participants': [senderId, receiverId],
          'unread_$receiverId': FieldValue.increment(1),
        }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => doc.data())
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => doc.data())
              .toList(),
        );
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'unread_$userId': 0});
  }

  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          int totalUnread = 0;
          for (final doc in snap.docs) {
            final unreadKey = 'unread_$userId';
            final unreadCount = doc.data()[unreadKey] ?? 0;
            totalUnread += (unreadCount as int);
          }
          return totalUnread;
        });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'memberRoles.$userId': FieldValue.delete(),
    });
  }
}
