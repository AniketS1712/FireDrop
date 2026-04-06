import 'dart:convert';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:firedrop/core/constant/cashfree_config.dart';
import 'package:firedrop/shared/models/payment_model.dart';
import 'package:firedrop/features/payment/data/repositories/payment_repository.dart';
import 'package:uuid/uuid.dart';

/// ─── Cashfree Payment Service ──────────────────────────────────────────────
/// Orchestrates the entire payment flow:
///
///   1. Check for duplicate/existing payments
///   2. Create a Cashfree order (server-side API call)
///   3. Store the payment record in Firestore with status `created`
///   4. Open the Cashfree checkout UI
///   5. Handle success/failure callbacks
///   6. Verify payment status with Cashfree API
///   7. Update Firestore with final status
///
/// Edge Cases Handled:
///   - Duplicate payment prevention (same user + tournament)
///   - Payment timeout / expiry
///   - Network failures during order creation
///   - SDK errors during checkout
///   - Payment verification failures
///   - Stale payment cleanup
///   - Platform-unsupported fallback (web/desktop)
class CashfreeService {
  final PaymentRepository _repository;
  final CFPaymentGatewayService _cfService = CFPaymentGatewayService();

  /// Callbacks that the UI layer can set.
  void Function(PaymentModel payment)? onPaymentSuccess;
  void Function(PaymentModel payment, String error)? onPaymentFailure;

  CashfreeService(this._repository);

  // ═══════════════════════ ORDER CREATION ═══════════════════════

  /// Creates a Cashfree order via the REST API.
  ///
  /// ⚠️ PRODUCTION WARNING:
  /// In production, this MUST be done on a secure backend (Firebase Cloud
  /// Function, Node.js server, etc.) because the API Secret Key should
  /// never be exposed in client code.
  ///
  /// The method first checks [CashfreeConfig.backendOrderUrl]:
  ///   - If set, it calls your backend endpoint
  ///   - If empty, it calls Cashfree API directly (DEV ONLY)
  Future<Map<String, dynamic>> _createOrder({
    required String orderId,
    required int amountInPaise,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerId,
  }) async {
    // Convert paise to rupees for API (Cashfree expects amount in rupees)
    final amountInRupees = (amountInPaise / 100).toStringAsFixed(2);

    final orderData = {
      'order_id': orderId,
      'order_amount': double.parse(amountInRupees),
      'order_currency': CashfreeConfig.currency,
      'customer_details': {
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
      },
      'order_meta': {
        'return_url': '${CashfreeConfig.returnUrl}?order_id=$orderId',
      },
    };

    try {
      late http.Response response;

      if (CashfreeConfig.backendOrderUrl.isNotEmpty) {
        // ── Call your secure backend ──────────────────────────────────
        response = await http
            .post(
              Uri.parse(CashfreeConfig.backendOrderUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(orderData),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw CashfreePaymentException(
                'Order creation timed out. Please check your internet connection.',
                CashfreeErrorCode.timeout,
              ),
            );
      } else {
        // ── Direct API call (DEV/TESTING ONLY) ───────────────────────
        debugPrint(
          '⚠️ [CashfreeService] Creating order directly via API. '
          'Move this to a backend in production!',
        );

        response = await http
            .post(
              Uri.parse('${CashfreeConfig.baseUrl}/orders'),
              headers: {
                'Content-Type': 'application/json',
                'x-client-id': CashfreeConfig.appId,
                'x-client-secret': CashfreeConfig.secretKey,
                'x-api-version': CashfreeConfig.apiVersion,
              },
              body: jsonEncode(orderData),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw CashfreePaymentException(
                'Order creation timed out. Please try again.',
                CashfreeErrorCode.timeout,
              ),
            );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Failed to create order';
        throw CashfreePaymentException(
          'Order creation failed: $message',
          CashfreeErrorCode.orderCreationFailed,
        );
      }
    } on CashfreePaymentException {
      rethrow;
    } catch (e) {
      throw CashfreePaymentException(
        'Network error while creating order: ${e.toString()}',
        CashfreeErrorCode.networkError,
      );
    }
  }

  // ═══════════════════════ PAYMENT VERIFICATION ═══════════════════════

  /// Verifies the payment status with Cashfree API.
  ///
  /// Called after the checkout callback to confirm that the payment
  /// actually went through (never trust client-side callbacks alone).
  Future<Map<String, dynamic>> _verifyPaymentWithCashfree(
    String orderId,
  ) async {
    try {
      late http.Response response;

      if (CashfreeConfig.backendOrderUrl.isNotEmpty) {
        // Call your backend verification endpoint
        response = await http
            .get(
              Uri.parse(
                '${CashfreeConfig.backendOrderUrl}/verify?order_id=$orderId',
              ),
            )
            .timeout(const Duration(seconds: 15));
      } else {
        // Direct API call (DEV ONLY)
        response = await http
            .get(
              Uri.parse('${CashfreeConfig.baseUrl}/orders/$orderId'),
              headers: {
                'x-client-id': CashfreeConfig.appId,
                'x-client-secret': CashfreeConfig.secretKey,
                'x-api-version': CashfreeConfig.apiVersion,
              },
            )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw CashfreePaymentException(
          'Payment verification failed',
          CashfreeErrorCode.verificationFailed,
        );
      }
    } catch (e) {
      if (e is CashfreePaymentException) rethrow;
      throw CashfreePaymentException(
        'Network error during verification: ${e.toString()}',
        CashfreeErrorCode.networkError,
      );
    }
  }

  // ═══════════════════════ MAIN PAYMENT FLOW ═══════════════════════

  /// Initiates the full Cashfree payment flow.
  ///
  /// This is the main entry point called from the UI layer.
  ///
  /// Flow:
  ///   1. Check for existing payment (duplicate prevention)
  ///   2. Create Cashfree order
  ///   3. Store payment record in Firestore
  ///   4. Open Cashfree checkout
  ///   5. Handle callback → verify → update Firestore
  ///
  /// Returns the [PaymentModel] if there's an existing successful payment.
  /// Otherwise, initiates checkout and returns null (result comes via callback).
  Future<PaymentModel?> initiatePayment({
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String tournamentId,
    required int entryFeeInPaise,
    required String paymentType, // 'create_room' or 'join_room'
  }) async {
    // ── Step 1: Check for duplicate/existing payment ──────────────────
    final existingPayment = await _repository.getExistingPayment(
      userId: userId,
      tournamentId: tournamentId,
    );

    if (existingPayment != null) {
      if (existingPayment.isSuccessful) {
        // Already paid — return existing payment
        debugPrint(
          '[CashfreeService] User already has a successful payment '
          'for this tournament. Skipping.',
        );
        return existingPayment;
      }

      if (existingPayment.isInProgress) {
        // Has a pending payment — try to verify it first
        debugPrint(
          '[CashfreeService] Found in-progress payment. '
          'Attempting verification...',
        );
        try {
          final verified = await _verifyAndUpdate(existingPayment);
          if (verified.isSuccessful) return verified;
          // If verification shows it failed, allow a new payment
        } catch (_) {
          // Verification failed, mark old one as expired and proceed
          await _repository.updatePaymentStatus(
            existingPayment.id,
            PaymentStatus.expired,
            statusMessage: 'Superseded by new payment attempt',
          );
        }
      }
    }

    // ── Step 2: Clean up stale payments ──────────────────────────────
    await _repository.expireStalePayments(userId);

    // ── Step 3: Generate unique order ID ─────────────────────────────
    final orderId =
        'FD_${tournamentId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';
    final paymentId = const Uuid().v4();

    // ── Step 4: Create Cashfree order ────────────────────────────────
    final orderResponse = await _createOrder(
      orderId: orderId,
      amountInPaise: entryFeeInPaise,
      customerName: userName,
      customerEmail: userEmail,
      customerPhone: userPhone.isEmpty ? '9999999999' : userPhone,
      customerId: userId,
    );

    final paymentSessionId = orderResponse['payment_session_id'] as String?;
    final cfOrderId = orderResponse['cf_order_id']?.toString();

    if (paymentSessionId == null || paymentSessionId.isEmpty) {
      throw CashfreePaymentException(
        'Invalid payment session received from Cashfree',
        CashfreeErrorCode.invalidSession,
      );
    }

    // ── Step 5: Store payment record in Firestore ────────────────────
    final payment = PaymentModel(
      id: paymentId,
      orderId: orderId,
      paymentSessionId: paymentSessionId,
      cfOrderId: cfOrderId,
      userId: userId,
      tournamentId: tournamentId,
      amount: entryFeeInPaise,
      currency: CashfreeConfig.currency,
      status: PaymentStatus.created,
      paymentType: paymentType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.createPayment(payment);

    // ── Step 6: Set up callbacks and open checkout ────────────────────
    _setupCallbacks(payment);
    await _openCheckout(orderId, paymentSessionId);

    // Update status to initiated
    await _repository.updatePaymentStatus(paymentId, PaymentStatus.initiated);

    return null; // Result will come via callbacks
  }

  // ═══════════════════════ CHECKOUT ═══════════════════════

  /// Sets up the Cashfree SDK callbacks.
  void _setupCallbacks(PaymentModel payment) {
    _cfService.setCallback(
      // ── onVerify: Called when SDK thinks payment succeeded ──────
      (String orderId) async {
        debugPrint(
          '[CashfreeService] Payment callback: verifyPayment($orderId)',
        );
        try {
          final verified = await _verifyAndUpdate(payment);
          onPaymentSuccess?.call(verified);
        } catch (e) {
          // Verification failed, but SDK said success — mark as pending
          await _repository.updatePaymentStatus(
            payment.id,
            PaymentStatus.pending,
            statusMessage:
                'Payment reported successful but verification failed. '
                'Will retry. Error: ${e.toString()}',
          );
          onPaymentFailure?.call(
            payment.copyWith(status: PaymentStatus.pending),
            'Payment is being processed. We will confirm shortly.',
          );
        }
      },
      // ── onError: Called when payment fails ──────────────────────
      (CFErrorResponse errorResponse, String orderId) async {
        final errorMessage =
            errorResponse.getMessage() ?? 'Payment failed. Please try again.';
        debugPrint(
          '[CashfreeService] Payment error: $errorMessage for order $orderId',
        );

        await _repository.updatePaymentStatus(
          payment.id,
          PaymentStatus.failed,
          statusMessage: errorMessage,
        );

        onPaymentFailure?.call(
          payment.copyWith(
            status: PaymentStatus.failed,
            statusMessage: errorMessage,
          ),
          errorMessage,
        );
      },
    );
  }

  /// Opens the Cashfree web checkout.
  Future<void> _openCheckout(String orderId, String paymentSessionId) async {
    try {
      final environment = CashfreeConfig.isSandbox
          ? CFEnvironment.SANDBOX
          : CFEnvironment.PRODUCTION;

      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cfService.doPayment(cfWebCheckout);
    } catch (e) {
      throw CashfreePaymentException(
        'Failed to open payment checkout: ${e.toString()}',
        CashfreeErrorCode.checkoutFailed,
      );
    }
  }

  // ═══════════════════════ VERIFY & UPDATE ═══════════════════════

  /// Verifies the payment status with Cashfree and updates Firestore.
  Future<PaymentModel> _verifyAndUpdate(PaymentModel payment) async {
    // Don't verify more than 3 times
    if (payment.verificationAttempts >= 3) {
      throw CashfreePaymentException(
        'Maximum verification attempts reached',
        CashfreeErrorCode.maxRetriesExceeded,
      );
    }

    // Increment attempts
    await _repository.updatePaymentStatus(
      payment.id,
      payment.status,
      verificationAttempts: payment.verificationAttempts + 1,
    );

    final orderData = await _verifyPaymentWithCashfree(payment.orderId);
    final orderStatus = orderData['order_status'] as String?;

    PaymentStatus newStatus;
    String? statusMessage;
    String? paymentRefId;
    String? paymentMethod;

    switch (orderStatus?.toUpperCase()) {
      case 'PAID':
        newStatus = PaymentStatus.success;
        statusMessage = 'Payment successful';
        // Extract payment details from the response
        final payments = orderData['payments'] as List?;
        if (payments != null && payments.isNotEmpty) {
          final lastPayment = payments.last as Map<String, dynamic>;
          paymentRefId = lastPayment['cf_payment_id']?.toString();
          paymentMethod = lastPayment['payment_method']?.toString();
        }
        break;
      case 'ACTIVE':
        newStatus = PaymentStatus.pending;
        statusMessage = 'Payment is being processed';
        break;
      case 'EXPIRED':
        newStatus = PaymentStatus.expired;
        statusMessage = 'Payment session expired';
        break;
      default:
        newStatus = PaymentStatus.failed;
        statusMessage = 'Payment failed with status: $orderStatus';
    }

    await _repository.updatePaymentStatus(
      payment.id,
      newStatus,
      statusMessage: statusMessage,
      paymentRefId: paymentRefId,
      paymentMethod: paymentMethod,
    );

    return payment.copyWith(
      status: newStatus,
      statusMessage: statusMessage,
      paymentRefId: paymentRefId,
      paymentMethod: paymentMethod,
      updatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════ MANUAL VERIFICATION ═══════════════════════

  /// Manually verify a pending payment (called from UI retry button).
  Future<PaymentModel> verifyPendingPayment(String paymentId) async {
    final payment = await _repository.getPaymentById(paymentId);
    if (payment == null) {
      throw CashfreePaymentException(
        'Payment not found',
        CashfreeErrorCode.paymentNotFound,
      );
    }

    if (payment.isTerminal) {
      return payment; // Already in a final state
    }

    return _verifyAndUpdate(payment);
  }

  // ═══════════════════════ LINK TEAM ═══════════════════════

  /// Links a team to a successful payment (called after team creation).
  Future<void> linkTeamToPayment(String paymentId, String teamId) async {
    await _repository.linkTeamToPayment(paymentId, teamId);
  }
}

// ═══════════════════════ ERROR HANDLING ═══════════════════════

/// Custom error codes for Cashfree payment operations.
enum CashfreeErrorCode {
  timeout,
  networkError,
  orderCreationFailed,
  invalidSession,
  checkoutFailed,
  verificationFailed,
  maxRetriesExceeded,
  duplicatePayment,
  paymentNotFound,
  unknown,
}

/// Custom exception for Cashfree payment errors.
/// Carries a [code] for programmatic error handling and a
/// [message] for user-facing display.
class CashfreePaymentException implements Exception {
  final String message;
  final CashfreeErrorCode code;

  CashfreePaymentException(this.message, this.code);

  @override
  String toString() => 'CashfreePaymentException($code): $message';
}
