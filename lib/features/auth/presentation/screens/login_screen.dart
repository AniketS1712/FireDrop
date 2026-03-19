import 'package:firebase_auth/firebase_auth.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/routes/route_names.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/users_model.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_button.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_card.dart';
import 'package:firedrop/features/auth/presentation/widgets/auth_layout.dart';
import 'package:firedrop/features/auth/presentation/widgets/google_button.dart';
import 'package:firedrop/shared/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginLoadingState _loadingState = LoginLoadingState.none;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateUser(UserModel user) {
    if (user.role == UserRole.organizer || user.role == UserRole.admin) {
      context.goNamed(RouteNames.organizerDashboard);
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loadingState = LoginLoadingState.email);

    try {
      final user = await ref
          .read(authServiceProvider)
          .signInAndGetUser(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;
      _navigateUser(user);
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyFirebaseError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingState = LoginLoadingState.none);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loadingState = LoginLoadingState.google);

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();

      if (!mounted) return;
      _navigateUser(user);
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyFirebaseError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingState = LoginLoadingState.none);
      }
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

  String _friendlyFirebaseError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'user-disabled':
          return 'Account disabled. Contact support.';
        case 'network-request-failed':
          return 'No internet connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final anyLoading = _loadingState != LoginLoadingState.none;

    return AuthLayout(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.space24),

              /// ─── Logo Section ─────────────────────
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 1),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withAlpha(155),
                            blurRadius: 24,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                        child: Image.asset(
                          'assets/images/logo.jpeg',
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter Arena',
                      style: textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join the ultimate esports experience',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSizes.space24),

              /// ─── Form Card ─────────────────────
              Expanded(
                child: Center(
                  child: AuthCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildField(
                          label: 'Email Address',
                          controller: _emailController,
                          icon: Icons.alternate_email_rounded,
                          hint: 'player@esports.com',
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Required field';
                            }
                            final emailRegex = RegExp(
                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        buildField(
                          label: 'Password',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          hint: '••••••••',
                          obscure: _obscure,
                          scheme: scheme,
                          textTheme: textTheme,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Required field';
                            }
                            if (v.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
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

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: anyLoading
                                ? null
                                : () => context.pushNamed(
                                    RouteNames.forgotPassword,
                                  ),
                            child: Text(
                              'Forgot Password?',
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        AuthButton(
                          text: 'SIGN IN',
                          loading: _loadingState == LoginLoadingState.email,
                          onPressed: () => _login(),
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

                        const SizedBox(height: 16),

                        GoogleButton(
                          loading: _loadingState == LoginLoadingState.google,
                          disabled: anyLoading,
                          onTap: _loginWithGoogle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// ─── Footer ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to Arena?',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: anyLoading
                        ? null
                        : () => context.pushNamed(RouteNames.signup),
                    child: Text(
                      'Create Account',
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
