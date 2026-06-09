import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'google_sign_in_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userState => _auth.authStateChanges();

  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user == null) {
        debugPrint('Registration failed: Firebase returned no user.');
        return null;
      }

      await user.updateDisplayName(displayName);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': displayName,
        'email': email,
        'level': 1,
        'xp': 0,
        'streak': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          debugPrint('Registration error: The password provided is too weak.');
          break;
        case 'email-already-in-use':
          debugPrint(
            'Registration error: The account already exists for that email.',
          );
          break;
        case 'invalid-email':
          debugPrint('Registration error: The email address is not valid.');
          break;
        default:
          debugPrint('Registration error: ${e.code} - ${e.message}');
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error during registration: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('Unexpected registration error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          debugPrint('Sign in error: No user found for that email.');
          break;
        case 'wrong-password':
          debugPrint('Sign in error: Wrong password provided for that user.');
          break;
        case 'invalid-email':
          debugPrint('Sign in error: The email address is not valid.');
          break;
        case 'user-disabled':
          debugPrint('Sign in error: The user account has been disabled.');
          break;
        default:
          debugPrint('Sign in error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Unexpected sign in error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        return userCredential.user;
      } else {
        final googleSignIn = _googleSignIn ?? createGoogleSignIn();
        _googleSignIn ??= googleSignIn;

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }
}
