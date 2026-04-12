library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class CashfreeConfig {
  CashfreeConfig._();

  // ── Environment ──────────────────────────────────────────────────────────
  /// Set to `true` for sandbox testing, `false` for production.
  /// Reads from `CASHFREE_IS_SANDBOX` in `.env`.
  static bool get isSandbox =>
      dotenv.env['CASHFREE_IS_SANDBOX']?.toLowerCase() == 'true';

  // ── API Credentials ──────────────────────────────────────────────────────
  /// Your Cashfree App ID (from merchant dashboard).
  /// Sandbox and production have different App IDs.
  /// Reads from `CASHFREE_APP_ID` in `.env`.
  static String get appId => dotenv.env['CASHFREE_APP_ID'] ?? '';

  /// Your Cashfree Secret Key.
  /// ⚠️ DO NOT ship this in production client code!
  /// This should only be used in a secure backend.
  /// Reads from `CASHFREE_SECRET_KEY` in `.env`.
  static String get secretKey => dotenv.env['CASHFREE_SECRET_KEY'] ?? '';

  // ── API Endpoints ────────────────────────────────────────────────────────
  /// Base URL for Cashfree REST API (Sandbox).
  static const String sandboxBaseUrl = 'https://sandbox.cashfree.com/pg';

  /// Base URL for Cashfree REST API (Production).
  static const String productionBaseUrl = 'https://api.cashfree.com/pg';

  /// Returns the active base URL based on the environment.
  static String get baseUrl => isSandbox ? sandboxBaseUrl : productionBaseUrl;

  // ── Backend Order Creation Endpoint ──────────────────────────────────────
  /// If you have a Firebase Cloud Function or custom backend for order
  /// creation, put its URL here. The app will call this endpoint instead
  /// of hitting Cashfree API directly from the client.
  ///
  /// Set to empty string to use the built-in direct API call (dev only).
  static const String backendOrderUrl = '';

  // ── API Version ──────────────────────────────────────────────────────────
  static const String apiVersion = '2023-08-01';

  // ── Currency ─────────────────────────────────────────────────────────────
  static const String currency = 'INR';

  // ── Return URL ───────────────────────────────────────────────────────────
  /// The return URL after payment completion on web.
  /// For mobile SDK this is handled via callbacks.
  static const String returnUrl = 'https://firedrop.app/payment/return';
}
