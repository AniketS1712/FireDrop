import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagle_esports/shared/models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final markNotificationReadProvider = Provider((ref) {
  return (String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }
  };
});
