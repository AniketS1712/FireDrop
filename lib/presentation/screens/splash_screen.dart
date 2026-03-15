import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/core/routes/route_paths.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  static const _duration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(_duration);
    if (!mounted) return;
    // Navigate to home — the router redirect in router.dart
    // will intercept and send to the correct screen based on auth/role.
    context.go(RoutePaths.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surfaceContainerHighest, scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (_, _) {
                final percent = (_progressAnimation.value * 100).toInt().clamp(
                  0,
                  100,
                );

                return Column(
                  children: [
                    const Spacer(),

                    // ===== LOGO BOX =====
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        border: Border.all(color: scheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withAlpha(160),
                            blurRadius: 80,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: AppSizes.space24),

                    // ===== TITLE =====
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'ARENA',
                            style: textTheme.displayMedium?.copyWith(
                              color: scheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: 'X',
                            style: textTheme.displayMedium?.copyWith(
                              color: scheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.space16),

                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ===== TAGLINE =====
                    Column(
                      children: [
                        Text(
                          'COMPETE. WIN. RISE.',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface.withAlpha(200),
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSizes.space16),
                        Text(
                          'THE ULTIMATE ESPORTS CIRCUIT',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ===== PROGRESS LABEL =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INITIALIZING ASSETS',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.space16),

                    // ===== PROGRESS BAR =====
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),

                    const SizedBox(height: AppSizes.space16),

                    Text(
                      'CONNECTING TO ARENA SERVERS...',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withAlpha(180),
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: AppSizes.space32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
