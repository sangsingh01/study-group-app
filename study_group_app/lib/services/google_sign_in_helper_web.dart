class GoogleSignIn {
  Future<GoogleSignInAccount?> signIn() async => null;
  Future<void> signOut() async {}
}

class GoogleSignInAccount {
  Future<GoogleSignInAuthentication> get authentication async =>
      GoogleSignInAuthentication();
}

class GoogleSignInAuthentication {
  String? get accessToken => null;
  String? get idToken => null;
}

GoogleSignIn createGoogleSignIn() => GoogleSignIn();
