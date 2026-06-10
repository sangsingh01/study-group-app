import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Friend Requests',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
        ),
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
          
          final List<String> displayUids = currentUser?.friendRequests.toList() ?? [];
          
          for (var id in _acceptedIds) {
            if (!displayUids.contains(id)) {
              displayUids.add(id);
            }
          }
          
          displayUids.removeWhere((id) => _declinedIds.contains(id));

          if (currentUser == null || displayUids.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder<List<AppUser>>(
            future: _databaseService.getUsersByIds(displayUids),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting && !requestSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }
              
              final requests = requestSnapshot.data ?? [];
              if (requests.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final requester = requests[index];
                  final bool isAccepted = _acceptedIds.contains(requester.uid);
                  final bool isRowLoading = _processingIds[requester.uid] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          foregroundImage: requester.profileImage != null
                              ? NetworkImage(requester.profileImage!)
                              : null,
                          child: requester.profileImage == null
                              ? Text(
                                  requester.initials,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6C63FF),
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requester.username,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                isAccepted ? 'Request accepted' : 'Wants to study together',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isAccepted ? const Color(0xFF43E97B) : Colors.grey[500],
                                  fontWeight: isAccepted ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        isAccepted
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43E97B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF43E97B)),
                                ),
                                child: Text(
                                  'Friends',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF43E97B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
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
                                        onPressed: () => _decline(requester.uid),
                                        icon: const Icon(Icons.close_rounded, color: Color(0xFFFF6584)),
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF6584).withValues(alpha: 0.1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _accept(requester.uid),
                                        icon: const Icon(Icons.check_rounded, color: Color(0xFF43E97B)),
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFF43E97B).withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 36, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            'No pending invitations right now.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}