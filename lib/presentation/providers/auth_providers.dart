import 'package:firedrop/models/users_model.dart';
import 'package:firedrop/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authServiceProvider = Provider(
  (ref) => AuthService(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

/// Streams the full [UserModel] for the currently signed-in user.
/// Emits null when no user is signed in.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  // Re-run whenever the Firebase auth user changes
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    loading: () => const Stream.empty(),
    error: (_, _) => Stream.value(null),
    data: (firebaseUser) async* {
      if (firebaseUser == null) {
        yield null;
      } else {
        final user = await ref
            .read(authServiceProvider)
            .getUserById(firebaseUser.uid);
        yield user;
      }
    },
  );
});
