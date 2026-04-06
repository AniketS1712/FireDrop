import 'dart:async';

import 'package:firedrop/core/constant/app_enums.dart';
// import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';
import 'package:firedrop/features/tournament/presentation/widgets/action_buttons.dart';
import 'package:firedrop/features/tournament/presentation/widgets/start_match_dialog.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Returns a human-readable countdown string from [now] to [target].
/// Shows days when ≥ 1 day left, hours when < 1 day, minutes when < 1 hour.
String _formatCountdown(DateTime target) {
  final now = DateTime.now();
  final diff = target.difference(now);

  if (diff.isNegative) return 'Started';

  if (diff.inDays >= 1) {
    return '${diff.inDays}d ${diff.inHours.remainder(24)}h left';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes}m ${diff.inSeconds.remainder(60)}s left';
  } else {
    return '${diff.inSeconds}s left';
  }
}

/// Picks the tick interval: 1 h when days remain, 1 min when hours remain,
/// 1 s when only minutes remain.
Duration _tickInterval(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.inDays >= 1) return const Duration(minutes: 1);
  if (diff.inHours >= 1) return const Duration(seconds: 30);
  return const Duration(seconds: 1);
}

// ─── Widget ───────────────────────────────────────────────────────────────────

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
  // ── entry animation ──
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // ── countdown ──
  Timer? _timer;
  String _countdownText = '';

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final delayed = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (widget.index * 0.08).clamp(0.0, 0.5),
        1.0,
        curve: Curves.easeOut,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(delayed);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(delayed);
    _ctrl.forward();

    // Kick off countdown
    _updateCountdown();
    _scheduleNextTick();
  }

  void _updateCountdown() {
    if (!mounted) return;
    setState(() {
      _countdownText = _formatCountdown(widget.tournament.startTime);
    });
  }

  void _scheduleNextTick() {
    final t = widget.tournament.startTime;
    if (t.isBefore(DateTime.now())) return; // already started
    _timer = Timer(_tickInterval(t), () {
      _updateCountdown();
      _scheduleNextTick(); // reschedule with the new interval
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
      final updatedT = widget.tournament.copyWith(roomDetails: roomDetails);
      await widget.onChangeStatus(updatedT, s);
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
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    // Live slot count from Firestore
    final teamsCountAsync = ref.watch(teamsCountProvider(t.id));
    final filledSlots = teamsCountAsync.value ?? 0;
    final slotsLeft = (t.maxSlots - filledSlots).clamp(0, t.maxSlots);
    final isStarted = t.startTime.isBefore(DateTime.now());

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSizes.space16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(color: colorScheme.outlineVariant, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withAlpha(50),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image + prize badge ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radius16),
                    ),
                    child: Image.network(
                      t.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: 130,
                        color: colorScheme.surface,
                        child: Center(
                          child: Image.asset(
                            'assets/images/free_fire.png',
                            fit: BoxFit.cover,
                            height: 130,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radius16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colorScheme.onPrimary.withAlpha(150),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Prize pool badge
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Text(
                      '₹${t.prizePool}',
                      style: textScheme.headlineLarge?.copyWith(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  // Countdown badge (top-left)
                  if (!t.isCompleted && !t.isLive)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: _CountdownBadge(
                        text: _countdownText,
                        isUrgent:
                            !isStarted &&
                            t.startTime.difference(DateTime.now()).inHours < 24,
                      ),
                    ),
                  if (t.isLive)
                    Positioned(top: 10, left: 12, child: _LiveBadge()),
                ],
              ),

              // ── Info ──
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: textScheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // ── Date + slots row ──
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: colorScheme.onSurface.withAlpha(200),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy • HH:mm').format(t.startTime),
                          style: textScheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                        const Spacer(),
                        // Game mode chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: Text(
                            t.gameMode.name.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── Dynamic slot progress ──
                    _SlotsRow(
                      filled: filledSlots,
                      max: t.maxSlots,
                      slotsLeft: slotsLeft,
                      isLoading: teamsCountAsync.isLoading,
                    ),

                    const SizedBox(height: AppSizes.space16),

                    // ── Action buttons ──
                    if (_loading)
                      Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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

// ─── Countdown Badge ──────────────────────────────────────────────────────────

class _CountdownBadge extends StatelessWidget {
  final String text;
  final bool isUrgent;

  const _CountdownBadge({required this.text, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final color = isUrgent
        ? Colors.orange
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withAlpha(180)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.timer_outlined : Icons.schedule_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withAlpha(220),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slots Row ────────────────────────────────────────────────────────────────

class _SlotsRow extends StatelessWidget {
  final int filled;
  final int max;
  final int slotsLeft;
  final bool isLoading;

  const _SlotsRow({
    required this.filled,
    required this.max,
    required this.slotsLeft,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 14,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            if (isLoading)
              const SizedBox(
                width: 60,
                child: LinearProgressIndicator(minHeight: 4),
              )
            else
              Text(
                '$slotsLeft / $max slots left',
                style: textScheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const Spacer(),
            Text(
              '$filled joined',
              style: textScheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
