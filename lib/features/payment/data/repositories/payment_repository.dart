import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedrop/shared/models/payment_model.dart';

/// ─── Payment Repository ────────────────────────────────────────────────────
/// Handles all Firestore operations for the `payments` collection.
///
/// Firestore Structure:
///   payments/
///     {paymentId}/
///       orderId, userId, tournamentId, amount, status, ...
///
/// Indexes required:
///   - (userId, tournamentId) → for checking existing payments
///   - (tournamentId, status) → for tournament payment reports
///   - (userId, status) → for user payment history
class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the `payments` collection.
  CollectionReference get _payments => _firestore.collection('payments');

  // ═════════════════════ CREATE ═════════════════════

  /// Creates a new payment record in Firestore.
  /// Uses the [payment.id] as the document ID for easy lookups.
  Future<void> createPayment(PaymentModel payment) async {
    await _payments.doc(payment.id).set(payment.toMap());
  }

  // ═════════════════════ UPDATE ═════════════════════

  /// Updates specific fields of a payment document.
  /// Uses Firestore merge to avoid overwriting unmodified fields.
  Future<void> updatePayment(String paymentId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _payments.doc(paymentId).update(data);
  }

  /// Updates the payment status and optionally the status message.
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? statusMessage,
    String? paymentRefId,
    String? paymentMethod,
    String? cfOrderId,
    int? verificationAttempts,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (statusMessage != null) updates['statusMessage'] = statusMessage;
    if (paymentRefId != null) updates['paymentRefId'] = paymentRefId;
    if (paymentMethod != null) updates['paymentMethod'] = paymentMethod;
    if (cfOrderId != null) updates['cfOrderId'] = cfOrderId;
    if (verificationAttempts != null) {
      updates['verificationAttempts'] = verificationAttempts;
    }

    await _payments.doc(paymentId).update(updates);
  }

  /// Links a team ID to the payment after successful team creation.
  Future<void> linkTeamToPayment(String paymentId, String teamId) async {
    await _payments.doc(paymentId).update({
      'teamId': teamId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═════════════════════ READ ═════════════════════

  /// Fetches a single payment by its document ID.
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _payments.doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Fetches a payment by its Cashfree order ID.
  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    final snapshot = await _payments
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Checks if a user already has a successful or pending payment for a
  /// tournament. This prevents duplicate charges.
  ///
  /// Returns the existing payment if found, null otherwise.
  Future<PaymentModel?> getExistingPayment({
    required String userId,
    required String tournamentId,
  }) async {
    final snapshot = await _payments
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournamentId)
        .where('status', whereIn: [
          PaymentStatus.success.name,
          PaymentStatus.created.name,
          PaymentStatus.initiated.name,
          PaymentStatus.pending.name,
        ])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Gets all payments for a user (for payment history).
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    final snapshot = await _payments
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Gets all payments for a tournament (for organizer dashboard).
  Future<List<PaymentModel>> getTournamentPayments(String tournamentId) async {
    final snapshot = await _payments
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Streams a single payment document for real-time status updates.
  Stream<PaymentModel?> streamPayment(String paymentId) {
    return _payments.doc(paymentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ═════════════════════ CLEANUP ═════════════════════

  /// Marks stale payments (created > 30 mins ago and still pending) as expired.
  /// Call this periodically or on app startup.
  Future<void> expireStalePayments(String userId) async {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 30));

    final snapshot = await _payments
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          PaymentStatus.created.name,
          PaymentStatus.initiated.name,
        ])
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = PaymentModel.parseDateTime(data['createdAt']);
      if (createdAt.isBefore(cutoff)) {
        batch.update(doc.reference, {
          'status': PaymentStatus.expired.name,
          'statusMessage': 'Payment expired due to inactivity',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }
}
