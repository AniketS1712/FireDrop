/// ─── Cashfree Payment Gateway Configuration ──────────────────────────────────
///
/// IMPORTANT: In production, the [appId] and [secretKey] should NEVER be stored
/// in client-side code. Order creation MUST happen on a secure backend
/// (e.g., Firebase Cloud Functions) that holds the secret key.
///
/// For development/testing, we use the SANDBOX environment.
/// Switch to PRODUCTION when going live.
///
/// Setup checklist:
///   1. Create a Cashfree merchant account at https://merchant.cashfree.com
///   2. Generate API keys from the merchant dashboard
///   3. Replace the placeholder values below with your actual keys
///   4. Set up a backend endpoint for order creation (see [CashfreeService])
/// ─────────────────────────────────────────────────────────────────────────────
library;

class CashfreeConfig {
  CashfreeConfig._();

  // ── Environment ──────────────────────────────────────────────────────────
  /// Set to `true` for sandbox testing, `false` for production.
  static const bool isSandbox = true;

  // ── API Credentials ──────────────────────────────────────────────────────
  /// Your Cashfree App ID (from merchant dashboard).
  /// Sandbox and production have different App IDs.
  static const String appId = 'YOUR_CASHFREE_APP_ID';

  /// Your Cashfree Secret Key.
  /// ⚠️ DO NOT ship this in production client code!
  /// This should only be used in a secure backend.
  static const String secretKey = 'YOUR_CASHFREE_SECRET_KEY';

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
