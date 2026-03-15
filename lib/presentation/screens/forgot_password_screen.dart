import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:firedrop/presentation/widgets/auth/auth_button.dart';
import 'package:firedrop/presentation/widgets/auth/auth_card.dart';
import 'package:firedrop/presentation/widgets/auth/auth_layout.dart';
import 'package:firedrop/presentation/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordResetEmail(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Back button ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_ios_rounded, color: scheme.primary),
              ),
            ),

            const SizedBox(height: AppSizes.space16),

            // ─── Header ──────────────────────────────────────────────────
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withAlpha(30),
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: scheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space24),
                  Text(
                    'Reset Password',
                    style: textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.space8),
                  Text(
                    'Enter your email and we\'ll send you a reset link.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.space40),

            // ─── Card ────────────────────────────────────────────────────
            if (!_emailSent)
              AuthCard(
                child: Column(
                  children: [
                    buildField(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.alternate_email_rounded,
                      hint: 'player@esports.com',
                      scheme: scheme,
                      textTheme: textTheme,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required field';
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.space32),

                    AuthButton(
                      text: 'SEND RESET LINK',
                      loading: _isLoading,
                      onPressed: _sendReset,
                    ),
                  ],
                ),
              )
            else
              // ── Success state ──────────────────────────────────────────
              AuthCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.mark_email_read_rounded,
                      color: scheme.primary,
                      size: 56,
                    ),
                    const SizedBox(height: AppSizes.space16),
                    Text(
                      'Check Your Inbox',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.space8),
                    Text(
                      'A password reset link has been sent to\n'
                      '${_emailController.text.trim()}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.space24),
                    AuthButton(
                      text: 'BACK TO LOGIN',
                      loading: false,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSizes.space32),
          ],
        ),
      ),
    );
  }
}
