import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserTile extends StatelessWidget {
  final AppUser user;
  final String subtitle;
  final VoidCallback? onAction;
  final String actionLabel;
  final Color actionColor;

  const UserTile({
    super.key,
    required this.user,
    required this.subtitle,
    this.onAction,
    this.actionLabel = 'Add',
    this.actionColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundImage: user.profileImage != null
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null
              ? Text(user.initials, style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(actionLabel),
        ),
      ),
    );
  }
}
