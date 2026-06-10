import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart'; 
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FE),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
          );
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          final User loggedInUser = authSnapshot.data!;
          // FIX: Pass the required logged-in user object directly to HomeScreen
          return HomeScreen(user: loggedInUser); 
        }

        return const LoginScreen(); 
      },
    );
  }
}