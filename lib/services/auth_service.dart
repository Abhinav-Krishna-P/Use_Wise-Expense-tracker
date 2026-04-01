import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google.
  /// After Firebase auth succeeds, the backend syncs the user profile to Firestore.
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      await _syncUserWithBackend(
        user,
        signInMethod: 'google',
        displayName: user.displayName,
        photoURL: user.photoURL,
      );
    }

    return user;
  }

  /// Sign in with email and password.
  /// After Firebase auth succeeds, the backend syncs the user profile to Firestore.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? user = userCredential.user;

    if (user != null) {
      await _syncUserWithBackend(user, signInMethod: 'email');
    }

    return user;
  }

  /// Create a new user with email and password.
  /// Does NOT keep an active session after account creation — the caller
  /// is expected to sign out after this so the user signs in separately.
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null && fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
      await user.reload();
      user = _auth.currentUser ?? user;
    }

    if (user != null) {
      await _syncUserWithBackend(
        user,
        signInMethod: 'email',
        displayName: fullName.trim().isNotEmpty ? fullName.trim() : null,
      );
    }

    return user;
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Public entry point called by AuthProvider whenever a Firebase user is
  /// detected (fresh sign-in OR app restart with an existing session).
  /// Errors are non-fatal so they never block the auth flow.
  Future<void> syncWithBackend(
    User user, {
    String signInMethod = 'email',
  }) async {
    await _syncUserWithBackend(
      user,
      signInMethod: signInMethod,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  /// Calls POST /api/auth/sync on the backend to create or update the user
  /// document in Firestore. Errors are logged but not re-thrown so that
  /// a sync failure never blocks the sign-in flow.
  Future<void> _syncUserWithBackend(
    User user, {
    required String signInMethod,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      // ignore: avoid_print
      print('[AuthService] Syncing user ${user.uid} with backend...');
      await ApiService.post('/auth/sync', {
        'signInMethod': signInMethod,
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        if (photoURL != null && photoURL.isNotEmpty) 'photoURL': photoURL,
      });
      // ignore: avoid_print
      print('[AuthService] Backend sync successful for ${user.uid}');
    } catch (e) {
      // ignore: avoid_print
      print('[AuthService] Backend sync failed: $e');
    }
  }
}
