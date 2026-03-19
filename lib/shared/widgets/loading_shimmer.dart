import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_sizes.dart';

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      child: Column(
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _shimmer,
            builder: (_, _) => Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: AppSizes.space16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                gradient: LinearGradient(
                  begin: Alignment(_shimmer.value - 1, 0),
                  end: Alignment(_shimmer.value, 0),
                  colors: [
                    scheme.surface,
                    scheme.surfaceContainerHighest,
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
