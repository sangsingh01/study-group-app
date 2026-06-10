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
  
  // Track individual row operations to prevent double-clicks without locking the whole screen
  final Map<String, bool> _processingIds = {};
  // Track accepted item states locally so they can gracefully display "Friends" before fading out
  final Set<String> _acceptedIds = {};
  // Track declined items locally so they can fade out smoothly
  final Set<String> _declinedIds = {};

  Future<void> _accept(String requesterUid) async {
    if (_processingIds[requesterUid] == true) return;
    
    setState(() {
      _processingIds[requesterUid] = true;
    });
    
    try {
      await _databaseService.acceptFriendRequest(widget.currentUid, requesterUid);
      if (mounted) {
        setState(() {
          _acceptedIds.add(requesterUid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted! Chat room opened.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIds[requesterUid] = false;
        });
      }
    }
  }

  Future<void> _decline(String requesterUid) async {
    if (_processingIds[requesterUid] == true) return;

    setState(() {
      _processingIds[requesterUid] = true;
    });

    try {
      await _databaseService.declineFriendRequest(widget.currentUid, requesterUid);
      if (mounted) {
        setState(() {
          _declinedIds.add(requesterUid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIds[requesterUid] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
          
          // Build up the visual array, keeping items valid while animations or state updates complete
          final List<String> displayUids = currentUser?.friendRequests.toList() ?? [];
          
          // Keep locally accepted users in the view so the "Friends" badge stays visible
          for (var id in _acceptedIds) {
            if (!displayUids.contains(id)) {
              displayUids.add(id);
            }
          }
          
          // Instantly filter out elements marked as declined
          displayUids.removeWhere((id) => _declinedIds.contains(id));

          if (currentUser == null || displayUids.isEmpty) {
            return const Center(
              child: Text('No pending requests.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return FutureBuilder<List<AppUser>>(
            // Fetch profiles based on the calculated list
            future: _databaseService.getUsersByIds(displayUids),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting && !requestSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }
              
              final requests = requestSnapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(
                  child: Text('No pending requests.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final requester = requests[index];
                  final bool isAccepted = _acceptedIds.contains(requester.uid);
                  final bool isRowLoading = _processingIds[requester.uid] == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundImage: requester.profileImage != null
                            ? NetworkImage(requester.profileImage!)
                            : null,
                        child: requester.profileImage == null
                            ? Text(
                                requester.initials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        requester.username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        isAccepted ? 'Request accepted' : requester.email,
                        style: TextStyle(
                          color: isAccepted ? Colors.green : Colors.grey.shade600,
                          fontWeight: isAccepted ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isAccepted
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Friends',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            )
                          : isRowLoading
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6C63FF),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                      onPressed: () => _accept(requester.uid),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
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