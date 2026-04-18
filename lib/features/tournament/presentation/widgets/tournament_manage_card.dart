import 'dart:async';
import 'package:eagle_esports/core/constant/app_enums.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/action_buttons.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/start_match_dialog.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String _formatCountdown(DateTime target) {
  final now = DateTime.now();
  final diff = target.difference(now);
  if (diff.isNegative) return 'STARTED';
  if (diff.inDays >= 1) return '${diff.inDays}D ${diff.inHours.remainder(24)}H';
  if (diff.inHours >= 1) {
    return '${diff.inHours}H ${diff.inMinutes.remainder(60)}M';
  }
  return '${diff.inMinutes}M ${diff.inSeconds.remainder(60)}S';
}

Duration _tickInterval(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.inDays >= 1) return const Duration(minutes: 1);
  return const Duration(seconds: 1);
}

class TournamentManageCard extends ConsumerStatefulWidget {
  final TournamentModel tournament;
  final int index;
  final Future<void> Function(TournamentModel, TournamentStatus) onChangeStatus;

  const TournamentManageCard({
    super.key,
    required this.tournament,
    required this.index,
    required this.onChangeStatus,
  });

  @override
  ConsumerState<TournamentManageCard> createState() =>
      _TournamentManageCardState();
}

class _TournamentManageCardState extends ConsumerState<TournamentManageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  String _countdownText = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final delayed = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (widget.index * 0.1).clamp(0.0, 0.5),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(delayed);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(delayed);
    _ctrl.forward();
    _updateCountdown();
    _scheduleNextTick();
  }

  void _updateCountdown() {
    if (!mounted) return;
    setState(
      () => _countdownText = _formatCountdown(widget.tournament.startTime),
    );
  }

  void _scheduleNextTick() {
    final t = widget.tournament.startTime;
    if (t.isBefore(DateTime.now())) return;
    _timer = Timer(_tickInterval(t), () {
      _updateCountdown();
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _act(TournamentStatus s) async {
    if (s == TournamentStatus.live) {
      final roomDetails = await showStartMatchDialog(context);
      if (roomDetails == null) return;
      setState(() => _loading = true);
      await widget.onChangeStatus(
        widget.tournament.copyWith(roomDetails: roomDetails),
        s,
      );
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    await widget.onChangeStatus(widget.tournament, s);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teamsCountAsync = ref.watch(teamsCountProvider(t.id));
    final filledSlots = teamsCountAsync.value ?? 0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              // Banner Area
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        t.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: colorScheme.surfaceContainer,
                          child: Icon(
                            Icons.sports_esports_rounded,
                            color: colorScheme.outline,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: t.isLive
                        ? _LiveBadge()
                        : _StatusBadge(
                            text: t.status.name.toUpperCase(),
                            color: t.isCompleted
                                ? Colors.grey
                                : colorScheme.primary,
                          ),
                  ),
                  if (!t.isLive && !t.isCompleted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _CountdownBadge(text: _countdownText),
                    ),
                  // Title overlay on image
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      t.title.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Metadata Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MetaItem(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat(
                            'd MMM • HH:mm',
                          ).format(t.startTime),
                        ),
                        _MetaItem(
                          icon: Icons.group_rounded,
                          label: '$filledSlots / ${t.maxSlots} JOINED',
                        ),
                        _MetaItem(
                          icon: Icons.monetization_on_rounded,
                          label: '₹${t.entryFee}',
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    if (_loading)
                      const SizedBox(
                        height: 44,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      ActionButtons(tournament: t, onAct: _act),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.red, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final String text;
  const _CountdownBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
