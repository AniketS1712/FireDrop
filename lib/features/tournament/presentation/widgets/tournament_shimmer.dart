import 'package:flutter/material.dart';

class TournamentShimmer extends StatefulWidget {
  const TournamentShimmer({super.key});

  @override
  State<TournamentShimmer> createState() => _TournamentShimmerState();
}

class _TournamentShimmerState extends State<TournamentShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _anim = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment(_anim.value - 1, 0),
                end: Alignment(_anim.value, 0),
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
