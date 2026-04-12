import 'dart:ui';
import 'package:eagle_esports/core/routes/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _entryScaleAnimation;
  late final Animation<double> _entryOpacityAnimation;
  late final Animation<Offset> _textSlideAnimation;

  static const _duration = Duration(seconds: 5);
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();

    // ─── Progress & Global Timeout (5 seconds) ───
    _progressController = AnimationController(vsync: this, duration: _duration);
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // ─── Continuous Pulse (Breathing effect) ───
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // ─── Entry Staggered Animations ───
    _entryScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _entryOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.1, 0.35, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: const Interval(0.2, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    // Start tracking
    _progressController.forward();
    _pulseController.repeat(reverse: true);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationComplete = true;
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (!mounted) return;
    // Wait until the 5s minimum progress finishes AND the user auth finishes loading
    if (_animationComplete && !ref.read(currentUserProvider).isLoading) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to currentUserProvider changes so we can trigger navigation
    ref.listen(currentUserProvider, (_, _) => _checkAndNavigate());

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gradients = Theme.of(context).extension<AppGradients>();

    return Scaffold(
      body: Stack(
        children: [
          // ─── Base Background Gradient ───
          Container(decoration: BoxDecoration(gradient: gradients?.background)),

          // ─── Ambient Glowing Background Orbs ───
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: -150,
                    left: -100,
                    child: Opacity(
                      opacity: 0.4 + (_pulseAnimation.value * 0.2),
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withAlpha(80),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withAlpha(100),
                              blurRadius: 150,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    right: -100,
                    child: Opacity(
                      opacity: 0.3 + ((1 - _pulseAnimation.value) * 0.2),
                      child: Container(
                        width: 500,
                        height: 500,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.secondary.withAlpha(60),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.secondary.withAlpha(80),
                              blurRadius: 200,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ─── Glassmorphism Overlay ───
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: scheme.surface.withAlpha(50), // Subtle surface tint
            ),
          ),

          // ─── Main Content ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space32,
                vertical: AppSizes.space24,
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _progressController,
                  _pulseController,
                ]),
                builder: (_, _) {
                  final percent = (_progressAnimation.value * 100)
                      .toInt()
                      .clamp(0, 100);

                  // Dynamic logo scale combined with entry pop and continuous heartbeat pulse
                  final logoScale =
                      _entryScaleAnimation.value +
                      (_pulseAnimation.value * 0.03);

                  return Column(
                    children: [
                      const Spacer(flex: 3),

                      // ─── LOGO WITH PREMIUM NEON GLOW ───
                      Transform.scale(
                        scale: logoScale,
                        child: Opacity(
                          opacity: _entryOpacityAnimation.value,
                          child: Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius24,
                              ),
                              border: Border.all(
                                color: scheme.primary.withAlpha(
                                  (150 + (_pulseAnimation.value * 100)).toInt(),
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                // Core intense glow
                                BoxShadow(
                                  color: scheme.primary.withAlpha(100),
                                  blurRadius: 20 + (_pulseAnimation.value * 10),
                                  spreadRadius: 2,
                                ),
                                // Ambient scattered glow
                                BoxShadow(
                                  color: scheme.primary.withAlpha(
                                    (60 + (_pulseAnimation.value * 40)).toInt(),
                                  ),
                                  blurRadius: 80 + (_pulseAnimation.value * 40),
                                  spreadRadius:
                                      25 + (_pulseAnimation.value * 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius24 - 2,
                              ),
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.space40),

                      // ─── TEXT LAYER STAGGERED ENTRY ───
                      SlideTransition(
                        position: _textSlideAnimation,
                        child: Opacity(
                          opacity: _entryOpacityAnimation.value,
                          child: Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'EAGLE',
                                      style: textTheme.displaySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ESPORTS',
                                      style: textTheme.displaySmall?.copyWith(
                                        color: scheme.primary,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.space24),
                              Container(
                                width: AppSizes.space56,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withAlpha(200),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.space64),
                              Text(
                                'COMPETE. WIN. RISE.',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(height: AppSizes.space12),
                              Text(
                                'THE ULTIMATE ESPORTS CIRCUIT',
                                textAlign: TextAlign.center,
                                style: textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant.withAlpha(150),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // ─── PROGRESS BAR / STATUS ───
                      Opacity(
                        opacity: _entryOpacityAnimation.value,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SYSTEM INITIALIZING',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: scheme.secondary,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.space16),

                            // CUSTOM NEON PROGRESS BAR
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withAlpha(150),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withAlpha(100),
                                        blurRadius: 4,
                                        spreadRadius: -1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSizes.space24),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                ref.read(currentUserProvider).isLoading
                                    ? 'AUTHENTICATING SECURE CONNECTION...'
                                    : 'ESTABLISHING ARENA UPLINK...',
                                key: ValueKey(
                                  ref.read(currentUserProvider).isLoading,
                                ),
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant.withAlpha(150),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.space24),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
