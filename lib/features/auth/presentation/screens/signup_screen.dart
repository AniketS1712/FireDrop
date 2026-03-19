import 'package:firedrop/core/routes/route_names.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/features/auth/presentation/widgets/google_button.dart';
import 'package:firedrop/shared/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:go_router/go_router.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_button.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_card.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_layout.dart';
import 'package:firedrop/features/auth/data/auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider)
          .signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } on GamerTagTakenException catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyFirebaseError(e.toString()));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      _navigateAfterAuth(user.role);
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyFirebaseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateAfterAuth(UserRole role) {
    if (role == UserRole.organizer || role == UserRole.admin) {
      context.goNamed(RouteNames.organizerDashboard);
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyFirebaseError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists for this email.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak.';
    }
    if (raw.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  String? _validateGamerTag(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required field';
    if (v.trim().length < 3) return 'Minimum 3 characters';
    if (v.trim().length > 20) return 'Maximum 20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_\-\.]+$').hasMatch(v.trim())) {
      return 'Only letters, numbers, _, - and . allowed';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Required field';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required field';
    if (v.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add a number';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Required field';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final anyLoading = _isLoading || _isGoogleLoading;

    return AuthLayout(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.space24),

              /// Header
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 1),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Join the Arena', style: textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Create your account to start competing',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Form Card
              Expanded(
                child: Center(
                  child: AuthCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildField(
                          label: 'Gamer Tag',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          hint: 'Enter your gamer tag',
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: _validateGamerTag,
                        ),

                        const SizedBox(height: 12),

                        buildField(
                          label: 'Email Address',
                          controller: _emailController,
                          icon: Icons.alternate_email_rounded,
                          hint: 'player@esports.com',
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 12),

                        buildField(
                          label: 'Password',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Min 8 chars',
                          obscure: _obscure,
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: _validatePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: scheme.primary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),

                        const SizedBox(height: 12),

                        buildField(
                          label: 'Confirm Password',
                          controller: _confirmController,
                          icon: Icons.shield_outlined,
                          hint: 'Repeat password',
                          obscure: _obscureConfirm,
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: _validateConfirm,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: scheme.primary,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        AuthButton(
                          text: 'START COMPETING',
                          loading: _isLoading,
                          onPressed: _signup,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: scheme.outlineVariant),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: scheme.outlineVariant),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.space16),

                        GoogleButton(
                          loading: _isGoogleLoading,
                          disabled: anyLoading,
                          onTap: _signupWithGoogle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already a player?', style: textTheme.labelLarge),
                  TextButton(
                    onPressed: anyLoading ? null : () => context.pop(),
                    child: Text(
                      'Login here',
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
