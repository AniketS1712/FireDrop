import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/models/users_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email / Password ─────────────────────────────────────────────────────

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Fetches the Firestore user document for a given [uid].
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint("Error fetching user Data: $e");
    }
    return null;
  }

  Future<void> updateUserAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      debugPrint("Error updating user avatar: $e");
      rethrow;
    }
  }

  /// Signs in with email/password and returns the full [UserModel].
  Future<UserModel> signInAndGetUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('User profile not found. Please contact support.');
    }

    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Creates a new account and Firestore profile.
  /// Throws [GamerTagTakenException] if the gamer tag is already in use.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.player,
  }) async {
    // Check gamer-tag uniqueness BEFORE creating the Firebase auth account
    await _assertGamerTagAvailable(name);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      phone: '',
      avatarUrl: '',
      isBanned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Google Sign-In (google_sign_in v7 + Firebase Auth) ──────────────────

  /// Triggers the Google account picker, exchanges the ID token with
  /// Firebase Auth, and returns the [UserModel] (creating a Firestore
  /// profile on first sign-in).
  Future<UserModel> signInWithGoogle() async {
    // Shows the native Google account picker
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // v7 only surfaces an idToken (no accessToken in `authentication`)
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    return _ensureFirestoreProfile(userCredential);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Ensures a Firestore user document exists for the [UserCredential].
  /// Returns the existing or newly created [UserModel].
  Future<UserModel> _ensureFirestoreProfile(UserCredential cred) async {
    final uid = cred.user!.uid;
    final existing = await _firestore.collection('users').doc(uid).get();

    if (existing.exists && existing.data() != null) {
      return UserModel.fromMap(existing.data()!, uid);
    }

    // Derive a gamer tag from the Google display name or email prefix
    final rawName =
        cred.user?.displayName ??
        cred.user?.email?.split('@').first ??
        'Player';

    final gamerTag = await _makeUniqueGamerTag(rawName);

    final user = UserModel(
      uid: uid,
      name: gamerTag,
      email: cred.user?.email ?? '',
      role: UserRole.player,
      phone: '',
      avatarUrl: cred.user?.photoURL ?? '',
      isBanned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  /// Throws [GamerTagTakenException] if [name] is already used by another user.
  Future<void> _assertGamerTagAvailable(String name) async {
    final query =
        await _firestore
            .collection('users')
            .where('name', isEqualTo: name.trim())
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      throw GamerTagTakenException(name);
    }
  }

  /// Returns a gamer tag based on [base] that is not yet taken in Firestore.
  Future<String> _makeUniqueGamerTag(String base) async {
    String candidate = base.trim();

    for (int i = 1; i <= 9999; i++) {
      final query =
          await _firestore
              .collection('users')
              .where('name', isEqualTo: candidate)
              .limit(1)
              .get();

      if (query.docs.isEmpty) return candidate;
      candidate = '${base.trim()}$i';
    }

    return '${base.trim()}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ─── Custom Exceptions ────────────────────────────────────────────────────────

class GamerTagTakenException implements Exception {
  final String tag;
  const GamerTagTakenException(this.tag);

  @override
  String toString() =>
      'The gamer tag "$tag" is already taken. Please choose another.';
}
