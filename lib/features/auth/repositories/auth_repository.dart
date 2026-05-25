import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../shared/models/app_user.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user as AppUser
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      // First-run resilience: if auth account exists but Firestore profile does not,
      // create it so navigation can proceed immediately after signup/login.
      return await _createUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
      );
    } catch (_) {
      // Keep auth flow unblocked if Firestore is unavailable during first launch.
      final now = DateTime.now();
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
      );
    }
  }

  /// Sign in with email and password
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed');
      }

      final user = credential.user!;
      final now = DateTime.now();

      // Do not block login on Firestore availability during first-run setup.
      _syncUserProfileInBackground(user);

      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create account with email and password
  Future<AppUser> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Account creation failed');
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      final user = credential.user!;
      final now = DateTime.now();

      // Do not block signup completion on Firestore writes.
      _syncUserProfileInBackground(user);

      return AppUser(
        id: user.uid,
        email: email,
        displayName: displayName,
        createdAt: now,
        lastLoginAt: now,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<AppUser> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google sign in failed');
      }

      final user = userCredential.user!;
      final now = DateTime.now();
      _syncUserProfileInBackground(user);
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Apple
  Future<AppUser> signInWithApple() async {
    try {
      // Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw Exception('Apple sign in failed');
      }

      final user = userCredential.user!;
      final now = DateTime.now();
      _syncUserProfileInBackground(user);
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get or create user document
  Future<AppUser> _getOrCreateUser(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      await _updateLastLogin(user.uid);
      return AppUser.fromFirestore(doc);
    }

    return await _createUserDocument(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName ?? user.email!.split('@')[0],
      photoUrl: user.photoURL,
    );
  }

  /// Create user document in Firestore
  Future<AppUser> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final appUser = AppUser(
      id: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
      lastLoginAt: now,
    );

    await _firestore.collection('users').doc(uid).set(appUser.toFirestore());

    return appUser;
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore first-run race where the user profile document is not yet created.
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  Future<void> _syncUserProfileInBackground(User user) async {
    try {
      await _getOrCreateUser(user);
    } catch (_) {
      // Keep auth UX responsive even if Firestore sync fails initially.
    }
  }
}
