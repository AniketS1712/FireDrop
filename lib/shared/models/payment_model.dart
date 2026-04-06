import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── Payment Status ────────────────────────────────────────────────────────
/// Tracks the lifecycle of a payment from creation to completion/failure.
enum PaymentStatus {
  /// Order created on Cashfree, awaiting user action.
  created,

  /// User has initiated the payment (checkout opened).
  initiated,

  /// Payment is being processed (e.g., UPI intent sent).
  pending,

  /// Payment completed successfully and verified.
  success,

  /// Payment failed (user cancelled, bank declined, etc.).
  failed,

  /// Payment was refunded after a successful charge.
  refunded,

  /// Payment expired (user didn't complete in time).
  expired,
}

/// ─── Payment Model ─────────────────────────────────────────────────────────
/// Represents a single payment transaction stored in Firestore.
///
/// Firestore collection: `payments`
/// Document ID: auto-generated or [orderId]
///
/// This model tracks every payment attempt so we can:
///   - Prevent duplicate charges
///   - Audit payment history
///   - Handle refunds
///   - Correlate payments with team registrations
class PaymentModel {
  /// Unique payment document ID (Firestore doc ID).
  final String id;

  /// The Cashfree order ID returned from order creation API.
  final String orderId;

  /// The Cashfree payment session ID used to open checkout.
  final String? paymentSessionId;

  /// Cashfree's internal CF order ID for reference.
  final String? cfOrderId;

  /// The payment reference ID from the payment gateway (e.g., UPI ref).
  final String? paymentRefId;

  /// The payment method used (e.g., 'upi', 'card', 'netbanking').
  final String? paymentMethod;

  /// The user UID who made the payment.
  final String userId;

  /// The tournament this payment is for.
  final String tournamentId;

  /// The team ID this payment is associated with (set after team creation).
  final String? teamId;

  /// Amount in the smallest currency unit (e.g., paise for INR).
  /// Store as int to avoid floating point issues.
  final int amount;

  /// Currency code (e.g., 'INR').
  final String currency;

  /// Current status of the payment.
  final PaymentStatus status;

  /// Human-readable status message (e.g., error description).
  final String? statusMessage;

  /// Whether it was a room creation or room join payment.
  final String paymentType; // 'create_room' or 'join_room'

  /// Timestamp when the payment record was created.
  final DateTime createdAt;

  /// Timestamp when the payment was last updated.
  final DateTime updatedAt;

  /// Number of verification attempts (to prevent infinite retries).
  final int verificationAttempts;

  const PaymentModel({
    required this.id,
    required this.orderId,
    this.paymentSessionId,
    this.cfOrderId,
    this.paymentRefId,
    this.paymentMethod,
    required this.userId,
    required this.tournamentId,
    this.teamId,
    required this.amount,
    required this.currency,
    required this.status,
    this.statusMessage,
    required this.paymentType,
    required this.createdAt,
    required this.updatedAt,
    this.verificationAttempts = 0,
  });

  // ═══════════════════════ COPY WITH ═══════════════════════

  PaymentModel copyWith({
    String? orderId,
    String? paymentSessionId,
    String? cfOrderId,
    String? paymentRefId,
    String? paymentMethod,
    String? teamId,
    PaymentStatus? status,
    String? statusMessage,
    DateTime? updatedAt,
    int? verificationAttempts,
  }) {
    return PaymentModel(
      id: id,
      orderId: orderId ?? this.orderId,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      cfOrderId: cfOrderId ?? this.cfOrderId,
      paymentRefId: paymentRefId ?? this.paymentRefId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      userId: userId,
      tournamentId: tournamentId,
      teamId: teamId ?? this.teamId,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      paymentType: paymentType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationAttempts:
          verificationAttempts ?? this.verificationAttempts,
    );
  }

  // ═══════════════════════ FROM MAP ═══════════════════════

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      orderId: map['orderId'] ?? '',
      paymentSessionId: map['paymentSessionId'],
      cfOrderId: map['cfOrderId'],
      paymentRefId: map['paymentRefId'],
      paymentMethod: map['paymentMethod'],
      userId: map['userId'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      teamId: map['teamId'],
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'INR',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.created,
      ),
      statusMessage: map['statusMessage'],
      paymentType: map['paymentType'] ?? 'create_room',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      verificationAttempts: map['verificationAttempts'] ?? 0,
    );
  }

  // ═══════════════════════ TO MAP ═══════════════════════

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'paymentSessionId': paymentSessionId,
    'cfOrderId': cfOrderId,
    'paymentRefId': paymentRefId,
    'paymentMethod': paymentMethod,
    'userId': userId,
    'tournamentId': tournamentId,
    'teamId': teamId,
    'amount': amount,
    'currency': currency,
    'status': status.name,
    'statusMessage': statusMessage,
    'paymentType': paymentType,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'verificationAttempts': verificationAttempts,
  };

  // ═══════════════════════ HELPERS ═══════════════════════

  /// Parses various date formats from Firestore into DateTime.
  /// Handles Timestamp, DateTime, and ISO 8601 String formats.
  static DateTime parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// Whether payment is in a terminal state (no further action needed).
  bool get isTerminal =>
      status == PaymentStatus.success ||
      status == PaymentStatus.failed ||
      status == PaymentStatus.refunded ||
      status == PaymentStatus.expired;

  /// Whether payment succeeded.
  bool get isSuccessful => status == PaymentStatus.success;

  /// Whether payment is still in progress.
  bool get isInProgress =>
      status == PaymentStatus.created ||
      status == PaymentStatus.initiated ||
      status == PaymentStatus.pending;
}
