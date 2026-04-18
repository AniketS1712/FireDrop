import 'package:eagle_esports/core/routes/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/shared/models/payment_model.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:eagle_esports/features/payment/presentation/providers/payment_providers.dart';
import 'package:eagle_esports/features/payment/data/services/cashfree_service.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ─── Create Room Screen ────────────────────────────────────────────────────
/// Allows a user to create a new team room for a tournament.
///
/// If the tournament has an entry fee, the Cashfree payment flow is triggered
/// before the team is actually created. The flow is:
///   1. Validate form inputs (team name, IGN)
///   2. If entry fee > 0 → Initiate Cashfree payment
///   3. On payment success → Create team in Firestore
///   4. Link payment to team → Navigate to success screen
///   5. If entry fee == 0 → Create team directly
class CreateRoomScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const CreateRoomScreen({super.key, required this.tournament});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _ignController = TextEditingController();

  bool _isLoading = false;
  String? _paymentStatusText;

  @override
  void dispose() {
    _teamNameController.dispose();
    _ignController.dispose();
    super.dispose();
  }

  // ═══════════════════════ MAIN ACTION ═══════════════════════

  Future<void> _onCreateTeam() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _paymentStatusText = null;
    });

    bool willHandleLoadingInCallbacks = false;

    try {
      if (widget.tournament.entryFee > 0) {
        if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
          _showInfoSnackBar('Payment skipped on this platform (testing mode)');
          await _createTeamOnServer();
        } else {
          willHandleLoadingInCallbacks = true;
          await _startCashfreePayment();
        }
      } else {
        await _createTeamOnServer();
      }
    } on CashfreePaymentException catch (e) {
      _handlePaymentError(e.message);
    } catch (e) {
      _handlePaymentError(e.toString());
    } finally {
      // If we started a payment flow, the callbacks (onPaymentSuccess/onPaymentFailure)
      // will handle resetting the loading state. We only reset here if we didn't
      // start that flow or if an immediate error occurred.
      if (!willHandleLoadingInCallbacks && mounted) {
        setState(() {
          _isLoading = false;
          _paymentStatusText = null;
        });
      }
    }
  }

  // ═══════════════════════ CASHFREE PAYMENT ═══════════════════════

  Future<void> _startCashfreePayment() async {
    final currentUser = ref.read(currentUserProvider).value;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || firebaseUser == null) {
      throw Exception('User not logged in');
    }

    setState(() => _paymentStatusText = 'Creating payment order...');

    final cashfreeService = ref.read(cashfreeServiceProvider);

    // ── Set up callbacks BEFORE initiating payment ──────────────────
    cashfreeService.onPaymentSuccess = (PaymentModel payment) async {
      if (!mounted) return;
      setState(
        () => _paymentStatusText = 'Payment successful! Creating team...',
      );

      try {
        await _createTeamOnServer(paymentId: payment.id);
      } catch (e) {
        // Payment succeeded but team creation failed
        // This is a critical edge case — payment is already taken
        if (mounted) {
          _showErrorDialog(
            'Payment was successful but team creation failed. '
            'Your payment reference: ${payment.orderId}. '
            'Please contact support for assistance.\n\n'
            'Error: ${e.toString()}',
          );
          setState(() {
            _isLoading = false;
            _paymentStatusText = null;
          });
        }
      }
    };

    cashfreeService.onPaymentFailure = (PaymentModel payment, String error) {
      if (!mounted) return;
      _handlePaymentError(error);
    };

    // ── Initiate payment ────────────────────────────────────────────
    final existingPayment = await cashfreeService.initiatePayment(
      userId: firebaseUser.uid,
      userName: currentUser.name,
      userEmail: currentUser.email,
      userPhone: currentUser.phone,
      tournamentId: widget.tournament.id,
      entryFeeInRupees: widget.tournament.entryFee,
      paymentType: 'create_team',
    );

    // If there's an existing successful payment, create team directly
    if (existingPayment != null && existingPayment.isSuccessful) {
      setState(
        () =>
            _paymentStatusText = 'Payment already completed. Creating team...',
      );
      await _createTeamOnServer(paymentId: existingPayment.id);
    }

    // If null, the checkout is open and we wait for callbacks
    // Loading state stays true until callback fires
  }

  // ═══════════════════════ TEAM CREATION ═══════════════════════

  Future<void> _createTeamOnServer({String? paymentId}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _paymentStatusText = 'Creating your team...';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final team = await ref
          .read(teamServiceProvider)
          .createTeamRoom(
            tournamentId: widget.tournament.id,
            teamName: _teamNameController.text.trim(),
            captainId: userId,
            maxSlots: widget.tournament.maxSlots,
            ign: _ignController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      // ── Link payment to team if there was a payment ─────────────
      if (paymentId != null) {
        try {
          final cashfreeService = ref.read(cashfreeServiceProvider);
          await cashfreeService.linkTeamToPayment(paymentId, team.id);
        } catch (e) {
          debugPrint('[CreateRoomScreen] Failed to link payment to team: $e');
        }
      }

      if (!mounted) return;
      // Navigate directly to My Team screen
      context.pushReplacementNamed(
        RouteNames.myTeam,
        extra: <String, dynamic>{'tournament': widget.tournament, 'team': team},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create team: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentStatusText = null;
        });
      }
    }
  }

  // ═══════════════════════ ERROR HANDLING ═══════════════════════

  void _handlePaymentError(String error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _paymentStatusText = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: _onCreateTeam,
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a non-dismissable error dialog for critical payment issues
  /// (e.g., payment succeeded but team creation failed).
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Action Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'GO TO HOME',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ BUILD ═══════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Team',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register Your Team for',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tournament.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),

              // ── Entry Fee Badge ────────────────────────────────────
              if (widget.tournament.entryFee > 0) ...[
                const SizedBox(height: AppSizes.space16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Entry Fee: ₹${widget.tournament.entryFee}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.space32),

              const Text(
                'Team Name',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _teamNameController,
                hintText: 'e.g., Toxic Avengers',
                prefixIcon: Icons.group_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Team Name is required';
                  }
                  if (val.trim().length < 3) {
                    return 'Team Name must be at least 3 characters';
                  }
                  if (val.trim().length > 30) {
                    return 'Team Name must be under 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.space24),

              const Text(
                'Captain In-Game Name (IGN)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ignController,
                hintText: 'e.g., NinjaPro99',
                prefixIcon: Icons.sports_esports_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'IGN is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.space48),

              // ── Payment Status Indicator ──────────────────────────────
              if (_paymentStatusText != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: AppSizes.space24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _paymentStatusText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Create Team Button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isLoading ? null : _onCreateTeam,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer.withAlpha(150),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(150),
                              ]
                            : [
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                Theme.of(context).colorScheme.primary,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(100),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            widget.tournament.entryFee > 0
                                ? 'PAY ₹${widget.tournament.entryFee} & CREATE TEAM'
                                : 'CREATE TEAM',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),

              // ── Secure Payment Note ──────────────────────────────────
              if (widget.tournament.entryFee > 0) ...[
                const SizedBox(height: AppSizes.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secured by Cashfree Payment Gateway',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withAlpha(120),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════ TEXT FIELD ═══════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 22,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }
}
