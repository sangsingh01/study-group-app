import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/user_tile.dart';

class SearchUsersScreen extends StatefulWidget {
  final String currentUid;
  const SearchUsersScreen({super.key, required this.currentUid});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _query = '';

  void _onSendRequest(AppUser targetUser) async {
    try {
      await _databaseService.sendFriendRequest(
        widget.currentUid,
        targetUser.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${targetUser.username}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send request.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Study Buddies'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) {
                setState(() => _query = value.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Type a username to search.'))
                : StreamBuilder<List<AppUser>>(
                    stream: _databaseService.searchUsers(
                      _query,
                      excludeUid: widget.currentUid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                          ),
                        );
                      }
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return UserTile(
                            user: user,
                            subtitle: user.email,
                            actionLabel: 'Request',
                            onAction: () => _onSendRequest(user),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
