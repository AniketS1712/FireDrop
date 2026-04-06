import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/features/payment/data/repositories/payment_repository.dart';
import 'package:firedrop/features/payment/data/services/cashfree_service.dart';
import 'package:firedrop/shared/models/payment_model.dart';

/// ─── Payment Repository Provider ───────────────────────────────────────────
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// ─── Cashfree Service Provider ─────────────────────────────────────────────
final cashfreeServiceProvider = Provider<CashfreeService>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return CashfreeService(repo);
});

/// ─── User's Payment for a Tournament ───────────────────────────────────────
/// Checks if the user already has an existing (successful/pending) payment
/// for a specific tournament. Used to prevent duplicate charges.
final existingPaymentProvider = FutureProvider.family<PaymentModel?, ({String userId, String tournamentId})>(
  (ref, params) async {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getExistingPayment(
      userId: params.userId,
      tournamentId: params.tournamentId,
    );
  },
);

/// ─── Real-time Payment Status Stream ───────────────────────────────────────
/// Streams a single payment document for live status updates during checkout.
final paymentStatusProvider = StreamProvider.family<PaymentModel?, String>(
  (ref, paymentId) {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.streamPayment(paymentId);
  },
);

/// ─── User Payment History ──────────────────────────────────────────────────
/// Fetches all payments for a user (for payment history / receipts screen).
final userPaymentsProvider = FutureProvider.family<List<PaymentModel>, String>(
  (ref, userId) async {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getUserPayments(userId);
  },
);

/// ─── Tournament Payments ───────────────────────────────────────────────────
/// Fetches all payments for a tournament (organizer dashboard).
final tournamentPaymentsProvider =
    FutureProvider.family<List<PaymentModel>, String>(
  (ref, tournamentId) async {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getTournamentPayments(tournamentId);
  },
);
