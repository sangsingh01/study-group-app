import 'dart:async';
import 'dart:typed_data';
 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
 
import '../models/group_message.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/direct_message.dart';
import '../models/message_model.dart';
import '../models/study_models.dart';
import '../models/task_model.dart';
import '../models/assignment_model.dart';
import 'cloudinary_service.dart'; // the one built for chat file sharing
 
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  DatabaseService() {
    _firestore.settings = const Settings(persistenceEnabled: true);
  }
 
  Future<void> createUserProfile(User authUser) async {
    final uid = authUser.uid;
    final userDoc = _firestore.collection('users').doc(uid);
    final snapshot = await userDoc.get();
 
    final email = authUser.email ?? '';
 
    // 1. Safe Extraction: If display name is null or empty, split the email prefix cleanly
    String rawName = authUser.displayName ?? '';
    if (rawName.isEmpty && email.isNotEmpty) {
      rawName = email.split('@').first;
    }
    if (rawName.isEmpty) {
      rawName = "Student"; // Bulletproof baseline fallback
    }
 
    // 2. Generate the unique username string safely
    final username = await _generateUniqueUsername(rawName.split(' ').first);
 
    // 3. Extract existing lists if the user document already exists to prevent wiping them out
    Map<String, dynamic> existingData = snapshot.exists ? (snapshot.data() ?? {}) : {};
    List friendsList = existingData['friends'] ?? [];
    List friendRequestsList = existingData['friendRequests'] ?? [];
    List sentRequestsList = existingData['sentRequests'] ?? [];
 
    // 4. Safe Write: We add explicit data maps to guarantee the UI never reads a null value
    await userDoc.set({
      'uid': uid,
      'username': username,
      'name': rawName, // Explicitly map 'name' for UI card visibility
      'email': email,
      'profileImage': authUser.photoURL,
      'isActive': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
      'friends': friendsList,
      'friendRequests': friendRequestsList,
      'sentRequests': sentRequestsList,
    }, SetOptions(merge: true)); // Merge prevents wipes during app re-auth runs
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
          .where(FieldPath.documentId, whereIn: chunk)
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
          .where(FieldPath.documentId, whereIn: uids)
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
          .where(FieldPath.documentId, whereIn: chunk)
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
 
      final fromData = fromSnapshot.data() ?? {};
      final toData = toSnapshot.data() ?? {};
 
      final List myFriends = fromData['friends'] ?? [];
      final List mySentRequests = fromData['sentRequests'] ?? [];
      final List receiverIncomingRequests = toData['friendRequests'] ?? [];
 
      if (myFriends.contains(toUid) ||
          mySentRequests.contains(toUid) ||
          receiverIncomingRequests.contains(fromUid)) {
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
 
    final chatId = getChatId(currentUid, requesterUid);
    final chatRef = _firestore.collection('chats').doc(chatId);
 
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
 
    await chatRef.set({
      'chatId': chatId,
      'lastMessage': 'You are now connected! Start chatting 👋',
      'lastMessageTime': Timestamp.now(),
      'participants': [currentUid, requesterUid],
      'users': [currentUid, requesterUid],
      'unread_$currentUid': 0,
      'unread_$requesterUid': 0,
      'typing_$currentUid': false,
      'typing_$requesterUid': false,
    }, SetOptions(merge: true));
  }
 
  Future<void> declineFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    final currentRef = _firestore.collection('users').doc(currentUid);
    final requesterRef = _firestore.collection('users').doc(requesterUid);
 
    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentRef);
      final requesterSnapshot = await transaction.get(requesterRef);
 
      if (currentSnapshot.exists) {
        transaction.update(currentRef, {
          'friendRequests': FieldValue.arrayRemove([requesterUid]),
        });
      }
      if (requesterSnapshot.exists) {
        transaction.update(requesterRef, {
          'sentRequests': FieldValue.arrayRemove([currentUid]),
        });
      }
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
 
  /// Sends a file/image GroupMessage AND auto-saves it into the `notes`
  /// collection so it shows up in NotesScreen for this group — mirrors
  /// sendDirectFileMessage's behavior for DMs.
  Future<void> sendGroupFileMessage({
    required String groupId,
    required GroupMessage message,
  }) async {
    // 1. Send as a normal group message
    await sendGroupMessage(groupId, message);
 
    // 2. Auto-save into the plain `notes` collection your NotesScreen reads.
    if (message.type == 'image' || message.type == 'file') {
      await _firestore.collection('notes').add({
        'title': message.fileName ?? 'Untitled',
        'fileType': message.fileType ?? 'doc',
        'fileUrl': message.fileUrl,
        'fileSizeBytes': message.fileSizeBytes,
        'uploaderId': message.senderUid,
        'uploaderName': message.senderName,
        'groupId': groupId,
        'dmChatId': null,
        'starredBy': [],
        'createdAt': Timestamp.now(),
      });
    }
  }
 
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
 
  Future<String> uploadGroupImage(
    Uint8List bytes,
    String groupId,
    String messageId, {
    void Function(double)? onProgress,
  }) async {
    final path = 'groups/$groupId/messages/$messageId.jpg';
    return uploadImageData(bytes: bytes, path: path, onProgress: onProgress);
  }
 
  String _conversationId(String a, String b) {
    final parts = [a, b]..sort();
    return parts.join('_');
  }
 
  Future<void> sendLegacyDirectMessage(DirectMessage message) async {
    final convoId = _conversationId(message.senderUid, message.receiverUid);
    await _firestore
        .collection('direct_chats')
        .doc(convoId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }
 
  Stream<List<DirectMessage>> legacyDirectMessages(String uidA, String uidB) {
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
 
  Future<void> setUserActive(String uid, bool isActive) async {
    final ref = _firestore.collection('users').doc(uid);
    await ref.set({
      'isActive': isActive,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
 
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
 
  String getChatId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }
 
  Future<void> sendDirectMessage(
    String chatId,
    MessageModel message,
    String receiverId,
  ) async {
    try {
      final batch = _firestore.batch();
 
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);
      batch.set(msgRef, message.toMap());
 
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.set(chatRef, {
        'lastMessage': message.message,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'participants': [message.senderId, receiverId],
        'users': [message.senderId, receiverId],
        'unread_$receiverId': FieldValue.increment(1),
        'unread_${message.senderId}': 0,
      }, SetOptions(merge: true));
 
      await batch.commit();
    } catch (e) {
      debugPrint('Error sending direct message: $e');
      rethrow;
    }
  }
 
  Stream<List<MessageModel>> getDirectMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }
 
  Stream<List<Map<String, dynamic>>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['chatId'] = doc.id;
              return data;
            }).toList());
  }
 
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({'unread_$userId': 0});
 
      final unreadMsgs = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
 
      final batch = _firestore.batch();
      for (var doc in unreadMsgs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
 
  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'typing_$userId': isTyping});
  }
 
  Stream<bool> getFriendTypingStatus(String chatId, String friendId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.data()?['typing_$friendId'] ?? false);
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
 
  // =========================================================================
  // 🚀 CIPHER FRIEND SYSTEM
  // =========================================================================
 
  Stream<List<AppUser>> cipherUsersByIdsStream(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }
 
  Stream<List<AppUser>> cipherSearchUsers(String queryText, String currentUid) {
    final lowerQuery = queryText.toLowerCase().trim();
    if (lowerQuery.length < 2) return Stream.value([]);
 
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromMap(doc.data());
      }).where((user) {
        final Map<String, dynamic> dataMap = user.toMap();
 
        final String searchName = (dataMap['name'] ?? dataMap['displayName'] ?? '').toString().toLowerCase();
        final String searchEmail = (dataMap['email'] ?? '').toString().toLowerCase();
 
        return user.uid != currentUid &&
               (searchName.contains(lowerQuery) || searchEmail.contains(lowerQuery));
      }).toList();
    });
  }
 
  // ========== 🎯 SHARED NOTES METHODS ==========
 
  /// Share a note with one or more friends
  Future<void> shareNote({
    required String noteId,
    required String noteName,
    required String fileUrl,
    required String fileType,
    required String currentUserId,
    required String currentUserName,
    required String currentUserPhoto,
    required List<String> recipientIds,
    required String message,
  }) async {
    try {
      final sharedNoteId = _firestore.collection('sharedNotes').doc().id;
 
      await _firestore.collection('sharedNotes').doc(sharedNoteId).set({
        'id': sharedNoteId,
        'noteId': noteId,
        'noteTitle': noteName,
        'noteFileUrl': fileUrl,
        'noteFileType': fileType,
        'sharedBy': currentUserId,
        'sharedByName': currentUserName,
        'sharedByPhotoUrl': currentUserPhoto,
        'sharedWith': recipientIds,
        'sharedDate': Timestamp.now(),
        'message': message,
        'viewedBy': [],
      });
 
      // Create individual share entries for each recipient for easier querying
      for (String recipientId in recipientIds) {
        await _firestore
            .collection('users')
            .doc(recipientId)
            .collection('sharedNotesReceived')
            .doc(sharedNoteId)
            .set({
          'sharedNoteId': sharedNoteId,
          'sharedDate': Timestamp.now(),
          'sharedBy': currentUserId,
          'isRead': false,
        });
      }
    } catch (e) {
      throw Exception('Error sharing note: $e');
    }
  }
 
  /// Get all notes shared with the current user
  Stream<List<Map<String, dynamic>>> getSharedNotesStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('sharedNotesReceived')
        .orderBy('sharedDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> sharedNotes = [];
 
      for (var doc in snapshot.docs) {
        final sharedNoteId = doc['sharedNoteId'];
        final sharedNoteDoc = await _firestore
            .collection('sharedNotes')
            .doc(sharedNoteId)
            .get();
 
        if (sharedNoteDoc.exists) {
          final data = sharedNoteDoc.data() ?? {};
          final isRead = doc['isRead'] ?? false;
          sharedNotes.add({...data, 'isRead': isRead});
        }
      }
 
      return sharedNotes;
    });
  }
 
  /// Mark a shared note as read
  Future<void> markSharedNoteAsRead(
    String currentUserId,
    String sharedNoteId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sharedNotesReceived')
          .doc(sharedNoteId)
          .update({'isRead': true});
 
      // Also update the viewedBy list in the main sharedNotes document
      await _firestore.collection('sharedNotes').doc(sharedNoteId).update({
        'viewedBy': FieldValue.arrayUnion([currentUserId])
      });
    } catch (e) {
      throw Exception('Error marking note as read: $e');
    }
  }
 
  /// Get notes shared by the current user
  Stream<List<Map<String, dynamic>>> getSharedNotesByUserStream(
    String currentUserId,
  ) {
    return _firestore
        .collection('sharedNotes')
        .where('sharedBy', isEqualTo: currentUserId)
        .orderBy('sharedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }
 
  /// Delete a shared note (only the sharer can delete)
  Future<void> deleteSharedNote(String sharedNoteId) async {
    try {
      // Get the shared note to find all recipients
      final doc = await _firestore.collection('sharedNotes').doc(sharedNoteId).get();
 
      if (doc.exists) {
        final data = doc.data() ?? {};
        final recipientIds = List<String>.from(data['sharedWith'] ?? []);
 
        // Delete from each recipient's collection
        for (String recipientId in recipientIds) {
          await _firestore
              .collection('users')
              .doc(recipientId)
              .collection('sharedNotesReceived')
              .doc(sharedNoteId)
              .delete();
        }
      }
 
      // Delete the main shared note document
      await _firestore.collection('sharedNotes').doc(sharedNoteId).delete();
    } catch (e) {
      throw Exception('Error deleting shared note: $e');
    }
  }
 
  /// Get unread count of shared notes for current user
  Future<int> getUnreadSharedNotesCount(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sharedNotesReceived')
          .where('isRead', isEqualTo: false)
          .count()
          .get();
 
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
 
  // =========================================================================
  // 📁 DIRECT CHAT FILE & IMAGE UPLOADS (NEW — for chat file sharing feature)
  // =========================================================================
 
  /// Uploads a document (pdf, etc.) sent in a DM to Storage.
  /// Reuses the same bytes-based pattern as uploadImageData above —
  /// works fine for non-image files too, despite the method's name.
  Future<String> uploadDirectChatFile({
    required Uint8List bytes,
    required String chatId,
    required String messageId,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'chat_files/$chatId/${messageId}_$fileName';
    return uploadImageData(bytes: bytes, path: path, onProgress: onProgress);
  }
 
  /// Uploads an image sent in a DM to Storage (mirrors uploadGroupImage,
  /// but for the 1:1 chats collection).
  Future<String> uploadDirectChatImage({
    required Uint8List bytes,
    required String chatId,
    required String messageId,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'chat_files/$chatId/$messageId.jpg';
    return uploadImageData(bytes: bytes, path: path, onProgress: onProgress);
  }
 
  /// Sends a file/image MessageModel in a DM chat AND auto-saves it into
  /// the `notes` collection so it shows up in NotesScreen for this DM.
  ///
  /// [message] must already have messageType set to 'image' or 'file',
  /// and fileUrl/fileName/fileType/fileSizeBytes populated.
  Future<void> sendDirectFileMessage({
    required String chatId,
    required MessageModel message,
    required String receiverId,
  }) async {
    // 1. Send as a normal chat message — reuses your existing logic
    //    (updates lastMessage, unread counts, etc. automatically).
    await sendDirectMessage(chatId, message, receiverId);
 
    // 2. Auto-save into the plain `notes` collection your NotesScreen reads.
    if (message.messageType == 'image' || message.messageType == 'file') {
      await _firestore.collection('notes').add({
        'title': message.fileName ?? 'Untitled',
        'fileType': message.fileType ?? 'doc',
        'fileUrl': message.fileUrl,
        'fileSizeBytes': message.fileSizeBytes,
        'uploaderId': message.senderId,
        'uploaderName': message.senderName,
        'groupId': null,
        'dmChatId': chatId,
        'starredBy': [],
        'createdAt': Timestamp.now(),
      });
    }
  }
 
  // =========================================================================
  // ✅ TASK MANAGEMENT
  // =========================================================================
 
  String generateTaskId() {
    return _firestore.collection('tasks').doc().id;
  }
 
  /// Creates a new task (personal or group). [task.id] should already be
  /// generated via [generateTaskId] before calling this.
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }
 
  /// Generic partial update — pass only the fields that changed.
  /// e.g. updateTask(taskId, {'title': 'New title', 'priority': 'high'})
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await _firestore.collection('tasks').doc(taskId).update(updates);
  }
 
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
 
  /// Updates just the status, and stamps completedAt/completedBy when
  /// the task is marked completed (or clears them if reopened).
  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
    String? completedBy,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'completed') {
      data['completedAt'] = Timestamp.now();
      data['completedBy'] = completedBy;
    } else {
      data['completedAt'] = null;
      data['completedBy'] = null;
    }
    await _firestore.collection('tasks').doc(taskId).update(data);
  }
 
  /// Overwrites the full subtask checklist (simplest approach — read the
  /// current list client-side, toggle/add/remove locally, then save it back).
  Future<void> updateTaskSubtasks(String taskId, List<SubtaskModel> subtasks) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
    });
  }
 
  /// All tasks for one group (group tasks only), newest first.
  /// Requires a composite index: tasks(groupId Asc, type Asc, createdAt Desc).
  Stream<List<TaskModel>> streamGroupTasks(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .where('type', isEqualTo: 'group')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskModel.fromMap(d.id, d.data())).toList());
  }
 
  /// All tasks relevant to a user: personal tasks they created, PLUS any
  /// group task they're assigned to (across every group). Two Firestore
  /// queries merged client-side into one stream — same pattern as
  /// getGroupsForUser() above, since Firestore can't OR across different
  /// fields in a single query.
  ///
  /// NOTE: like getGroupsForUser, this cache is additive — if a task stops
  /// matching one of the two queries (e.g. you're unassigned from it), it
  /// will still show in this stream until the doc is deleted or the stream
  /// is restarted, because we merge by doc id into a persistent map. This
  /// mirrors the existing pattern elsewhere in this file; revisit if you
  /// need stricter live consistency.
  Stream<List<TaskModel>> streamMyTasks(String uid) {
    final controller = StreamController<List<TaskModel>>.broadcast();
    final subs = <StreamSubscription>[];
    final Map<String, TaskModel> cache = {};
 
    void emit() {
      final list = cache.values.toList();
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      controller.add(list);
    }
 
    final personalQuery = _firestore
        .collection('tasks')
        .where('type', isEqualTo: 'personal')
        .where('creatorUid', isEqualTo: uid)
        .snapshots();
 
    final assignedQuery = _firestore
        .collection('tasks')
        .where('assignedTo', arrayContains: uid)
        .snapshots();
 
    subs.add(personalQuery.listen((snap) {
      for (final doc in snap.docs) {
        cache[doc.id] = TaskModel.fromMap(doc.id, doc.data());
      }
      emit();
    }));
 
    subs.add(assignedQuery.listen((snap) {
      for (final doc in snap.docs) {
        cache[doc.id] = TaskModel.fromMap(doc.id, doc.data());
      }
      emit();
    }));
 
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
 
    return controller.stream;
  }
 
  // =========================================================================
  // 📋 ASSIGNMENT COLLABORATION
  // =========================================================================
 
  /// Creates a new assignment inside a group.
  Future<String> createAssignment({
    required String groupId,
    required String title,
    required String description,
    DateTime? dueDate,
    required String createdBy,
    required String createdByName,
  }) async {
    final ref = _firestore.collection('groups').doc(groupId).collection('assignments').doc();
 
    final assignment = AssignmentModel(
      id: ref.id,
      groupId: groupId,
      title: title,
      description: description,
      dueDate: dueDate,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      memberCompletion: {},
      attachments: [],
    );
 
    await ref.set(assignment.toMap());
    return ref.id;
  }
 
  /// Live stream of all assignments in a group, most recently created first.
  Stream<List<AssignmentModel>> getGroupAssignments(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AssignmentModel.fromMap(doc.id, doc.data())).toList());
  }
 
  /// Live stream of a single assignment (for the detail screen).
  Stream<AssignmentModel?> getAssignmentStream(String groupId, String assignmentId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AssignmentModel.fromMap(doc.id, doc.data()!);
    });
  }
 
  /// Toggles the current user's own completion status for an assignment.
  /// Only ever writes the caller's own uid key — one member can't mark
  /// another member done.
  Future<void> setMyAssignmentCompletion({
    required String groupId,
    required String assignmentId,
    required String uid,
    required bool completed,
  }) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .update({'memberCompletion.$uid': completed});
  }
 
  /// Uploads a file via Cloudinary and attaches it to the assignment.
  Future<void> addAssignmentAttachment({
    required String groupId,
    required String assignmentId,
    required Uint8List bytes,
    required String fileName,
    required bool isImage,
    required String uploaderId,
    required String uploaderName,
  }) async {
    final cloudinary = CloudinaryService();
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final fileType = isImage
        ? 'image'
        : (ext == 'pdf'
            ? 'pdf'
            : (['doc', 'docx'].contains(ext) ? 'doc' : (['ppt', 'pptx'].contains(ext) ? 'ppt' : 'doc')));
 
    final response = await cloudinary.uploadBytes(
      bytes: bytes,
      fileName: fileName,
      isImage: isImage,
    );
 
    final attachment = AssignmentAttachment(
      fileUrl: response.secureUrl,
      fileName: fileName,
      fileType: fileType,
      uploadedBy: uploaderId,
      uploadedByName: uploaderName,
    );
 
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .update({
      'attachments': FieldValue.arrayUnion([attachment.toMap()]),
    });
  }
 
  Future<void> deleteAssignment(String groupId, String assignmentId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .delete();
  }
 
  // ---- comments (mini discussion thread per assignment) ----
 
  Future<void> addAssignmentComment({
    required String groupId,
    required String assignmentId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final ref = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('comments')
        .doc();
 
    final comment = AssignmentCommentModel(
      id: ref.id,
      text: text,
      senderId: senderId,
      senderName: senderName,
      timestamp: DateTime.now(),
    );
 
    await ref.set(comment.toMap());
  }
 
  Stream<List<AssignmentCommentModel>> getAssignmentComments(String groupId, String assignmentId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AssignmentCommentModel.fromMap(doc.id, doc.data())).toList());
  }
}
 
// =========================================================================
// SETUP NOTES (not code — read before wiring in)
// =========================================================================
//
// TASKS
// 1. Also add task_model.dart to lib/models/ and tasks_ui.dart to
//    lib/screens/ (the UI screens/widgets — TaskCard, create-task sheet,
//    TaskDetailScreen, MyTasksScreen, GroupTasksScreen).
// 2. Firestore composite index needed for streamGroupTasks:
//    Collection: tasks | Fields: groupId (Asc), type (Asc), createdAt (Desc)
//    If missing, Firestore prints a direct link to create it in the debug
//    console the first time GroupTasksScreen runs — just click it.
// 3. Wire in entry points:
//    MyTasksScreen(currentUser: currentUser)
//    GroupTasksScreen(group: group, currentUser: currentUser)
// 4. Firestore security rules — add to firestore.rules:
//
// match /tasks/{taskId} {
//   allow read: if isOwner() || isAssignee() || isGroupMember();
//   allow create: if request.auth != null &&
//                    request.resource.data.creatorUid == request.auth.uid;
//   allow update, delete: if isOwner() || isGroupAdmin();
//   allow update: if isAssignee() &&
//     request.resource.data.diff(resource.data).affectedKeys()
//       .hasOnly(['status', 'subtasks', 'completedAt', 'completedBy']);
//
//   function isOwner() {
//     return request.auth != null && resource.data.creatorUid == request.auth.uid;
//   }
//   function isAssignee() {
//     return request.auth != null && resource.data.assignedTo is list &&
//            request.auth.uid in resource.data.assignedTo;
//   }
//   function isGroupMember() {
//     return resource.data.type == 'group' && request.auth != null &&
//            request.auth.uid in get(/databases/$(database)/documents/groups/$(resource.data.groupId)).data.members;
//   }
//   function isGroupAdmin() {
//     return resource.data.type == 'group' && request.auth != null &&
//            get(/databases/$(database)/documents/groups/$(resource.data.groupId)).data.adminUid == request.auth.uid;
//   }
// }
//
// 5. Not implemented (as scoped): push notifications for due dates,
//    recurring tasks, kanban view. Group tasks with no explicit assignee
//    default to the whole group (see _CreateTaskSheet._save in tasks_ui.dart).
//
// ASSIGNMENTS
// 6. Assignments live under groups/{groupId}/assignments/{assignmentId}
//    (and a comments subcollection under each assignment). This is a
//    separate concept from `tasks` — Assignments are group-wide items
//    where every member tracks their OWN completion via memberCompletion,
//    while Tasks are individually assignable to specific member(s).
//    Security rules for `assignments` and its `comments` subcollection
//    aren't included above — add rules gated on group membership
//    (mirror the isGroupMember()/isGroupAdmin() pattern from the tasks
//    rules, but scoped to the groups/{groupId} path instead of a top-level
//    collection field lookup).
 