import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/database_service.dart';

class AddMembersBottomSheet extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;

  const AddMembersBottomSheet({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<AddMembersBottomSheet> createState() => _AddMembersBottomSheetState();
}

class _AddMembersBottomSheetState extends State<AddMembersBottomSheet> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AppUser>> _loadFriendCandidates() {
    final availableFriends = widget.currentUser.friends
        .where((uid) => !widget.group.members.contains(uid))
        .toList();
    return _databaseService.getUsersByIds(availableFriends);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by username or friend name',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: _query.isEmpty
                ? FutureBuilder<List<AppUser>>(
                    future: _loadFriendCandidates(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                          ),
                        );
                      }
                      final friends = snapshot.data ?? [];
                      if (friends.isEmpty) {
                        return const Center(
                          child: Text('No friends available to add.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final selected = _selected.contains(friend.uid);
                          return CheckboxListTile(
                            title: Text(friend.username),
                            subtitle: Text(friend.email),
                            value: selected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(friend.uid);
                                } else {
                                  _selected.remove(friend.uid);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  )
                : StreamBuilder<List<AppUser>>(
                    stream: _databaseService.searchUsers(
                      _query,
                      excludeUid: widget.currentUser.uid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                          ),
                        );
                      }
                      final candidates =
                          snapshot.data
                              ?.where(
                                (user) =>
                                    !widget.group.members.contains(user.uid),
                              )
                              .toList() ??
                          [];
                      if (candidates.isEmpty) {
                        return const Center(
                          child: Text('No users found for that username.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final user = candidates[index];
                          final selected = _selected.contains(user.uid);
                          return CheckboxListTile(
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            value: selected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(user.uid);
                                } else {
                                  _selected.remove(user.uid);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              onPressed: _selected.isEmpty
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      for (final uid in _selected) {
                        await _databaseService.addGroupMember(
                          widget.group.id,
                          uid,
                        );
                      }
                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Members added to group.'),
                          ),
                        );
                      }
                    },
              child: const Text('Add selected members'),
            ),
          ),
        ],
      ),
    );
  }
}
