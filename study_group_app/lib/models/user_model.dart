class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? profileImage;
  final List<String> friends;
  final List<String> friendRequests;
  final List<String> sentRequests;
  final List<String> groupInvites;
  final List<String> blockedUsers;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImage,
    this.friends = const [],
    this.friendRequests = const [],
    this.sentRequests = const [],
    this.groupInvites = const [],
    this.blockedUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'friends': friends,
      'friendRequests': friendRequests,
      'sentRequests': sentRequests,
      'groupInvites': groupInvites,
      'blockedUsers': blockedUsers,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] as String?,
      friends: List<String>.from(map['friends'] ?? []),
      friendRequests: List<String>.from(map['friendRequests'] ?? []),
      sentRequests: List<String>.from(map['sentRequests'] ?? []),
      groupInvites: List<String>.from(map['groupInvites'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }

  String get initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '';
  }
}
