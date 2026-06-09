import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/user_tile.dart';
import 'direct_message_screen.dart';

class FriendsListScreen extends StatefulWidget {
  final String currentUid;
  final AppUser? currentUser;
  const FriendsListScreen({
    super.key,
    required this.currentUid,
    this.currentUser,
  });

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: StreamBuilder<AppUser?>(
        stream: _databaseService.userStream(widget.currentUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }
          final currentUser = snapshot.data;
          if (currentUser == null || currentUser.friends.isEmpty) {
            return const Center(
              child: Text('No friends yet. Search for peers to connect.'),
            );
          }
          return FutureBuilder<List<AppUser>>(
            future: _databaseService.getUsersByIds(currentUser.friends),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }
              final friends = friendSnapshot.data ?? [];
              if (friends.isEmpty) {
                return const Center(child: Text('No friends found.'));
              }
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final chatId = _getChatId(widget.currentUid, friend.uid);
                  return UserTile(
                    user: friend,
                    subtitle: friend.email,
                    actionLabel: 'Chat',
                    actionColor: const Color(0xFF4CAF50),
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectMessageScreen(
                            currentUser: widget.currentUser ?? currentUser,
                            currentUserAuthData:
                                FirebaseAuth.instance.currentUser!,
                            friend: friend,
                            chatId: chatId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getChatId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }
}
