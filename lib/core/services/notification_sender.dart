import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagle_esports/shared/models/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationSenderProvider = Provider((ref) => NotificationSender());

class NotificationSender {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a notification to a specific user
  Future<void> sendToUser({
    required String uid,
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
    String? targetId,
  }) async {
    final notification = AppNotification(
      id: '',
      title: title,
      message: message,
      type: type,
      targetId: targetId,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(notification.toMap());
  }

  /// Send a notification to multiple users simultaneously
  Future<void> sendToMultiple({
    required List<String> uids,
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
    String? targetId,
  }) async {
    if (uids.isEmpty) return;

    final batch = _firestore.batch();

    final data = AppNotification(
      id: '',
      title: title,
      message: message,
      type: type,
      targetId: targetId,
      createdAt: DateTime.now(),
      isRead: false,
    ).toMap();

    for (final uid in uids) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Send a global notification
  Future<void> sendGlobal({
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
    String? targetId,
  }) async {
    final data = AppNotification(
      id: '',
      title: title,
      message: message,
      type: type,
      targetId: targetId,
      createdAt: DateTime.now(),
      isRead: false,
    ).toMap();

    await _firestore.collection('global_notifications').add(data);
  }
}
