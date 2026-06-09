import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'chats_screen.dart';

class ChatScreen extends StatelessWidget {
  final AppUser? currentUser;
  final User user;

  const ChatScreen({
    super.key,
    this.currentUser,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ChatsScreen(
      currentUser: currentUser,
      user: user,
    );
  }
}
