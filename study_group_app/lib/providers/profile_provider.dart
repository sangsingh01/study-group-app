import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';

class ProfileProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  AppUser? user;
  bool loading = true;
  StreamSubscription<AppUser?>? _userSubscription;

  ProfileProvider(this._databaseService);

  Future<void> initialize(User authUser) async {
    await _databaseService.createUserProfile(authUser);
    _userSubscription?.cancel();
    _userSubscription = _databaseService.userStream(authUser.uid).listen((
      profile,
    ) {
      user = profile;
      loading = false;
      notifyListeners();
    });
  }

  bool isFriend(String otherUid) {
    return user?.friends.contains(otherUid) ?? false;
  }

  bool hasRequested(String otherUid) {
    return user?.sentRequests.contains(otherUid) ?? false;
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Clears the loaded profile and cancels subscriptions. Call on sign-out.
  Future<void> clearProfile() async {
    _userSubscription?.cancel();
    _userSubscription = null;
    user = null;
    loading = true;
    notifyListeners();
  }
}
