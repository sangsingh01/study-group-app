import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  final String currentUid;
  const FriendRequestsScreen({super.key, required this.currentUid});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _accept(String requesterUid) async {
    await _databaseService.acceptFriendRequest(widget.currentUid, requesterUid);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request accepted.')));
    }
  }

  Future<void> _decline(String requesterUid) async {
    await _databaseService.declineFriendRequest(
      widget.currentUid,
      requesterUid,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request declined.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
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
          if (currentUser == null || currentUser.friendRequests.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          return FutureBuilder<List<AppUser>>(
            future: _databaseService.getUsersByIds(currentUser.friendRequests),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }
              final requests = requestSnapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(child: Text('No pending requests.'));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final requester = requests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundImage: requester.profileImage != null
                            ? NetworkImage(requester.profileImage!)
                            : null,
                        child: requester.profileImage == null
                            ? Text(
                                requester.initials,
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(
                        requester.username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(requester.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _accept(requester.uid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _decline(requester.uid),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
