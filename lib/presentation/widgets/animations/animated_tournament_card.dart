import 'package:flutter/material.dart';

class AnimatedTournamentCard extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedTournamentCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<AnimatedTournamentCard> createState() => _AnimatedTournamentCardState();
}

class _AnimatedTournamentCardState extends State<AnimatedTournamentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delayed = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (widget.index * 0.1).clamp(0.0, 0.6),
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(delayed);

    _fade = Tween<double>(begin: 0, end: 1).animate(delayed);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
