import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_sizes.dart';

class MatchCard extends ConsumerWidget {
  final TournamentModel tournament;

  /// Callback for the "Register Now" button — only shown for non-live tournaments.
  final VoidCallback? onJoin;

  const MatchCard({super.key, required this.tournament, this.onJoin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final isLive = tournament.isLive;

    final timeDiff = tournament.startTime.difference(DateTime.now());
    final String timeLabel;
    if (isLive) {
      timeLabel = 'Live Now';
    } else if (timeDiff.inMinutes > 0) {
      final hours = timeDiff.inHours;
      final minutes = timeDiff.inMinutes % 60;
      if (hours > 0) {
        timeLabel = 'Starts in ${hours}h ${minutes}m';
      } else {
        timeLabel = 'Starts in ${minutes}m';
      }
    } else {
      timeLabel = 'Starting soon';
    }

    return GestureDetector(
      onTap: onJoin,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isLive
                ? colorScheme.primary.withValues(alpha: 0.6)
                : colorScheme.outlineVariant,
            width: isLive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tournament Image ──────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    child: Image.network(
                      tournament.imageUrl,
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Live badge overlaid on the image
                  if (isLive)
                    Positioned(
                      top: AppSizes.space8,
                      left: AppSizes.space8,
                      child: _LiveBadge(colorScheme: colorScheme),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.space16),

              // ── Title + Entry Fee ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(tournament.title, style: textTheme.titleMedium),
                  ),
                  Text(
                    '\$${tournament.entryFee}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.space8),

              // ── Time label ────────────────────────────────────────────────
              Text(
                timeLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: isLive ? colorScheme.primary : colorScheme.secondary,
                  fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                ),
              ),

              const SizedBox(height: AppSizes.space16),

              // ── Registrations + Button ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Registrations: ${tournament.maxSlots}',
                    style: textTheme.bodyMedium,
                  ),

                  // Only allow registration for non-live tournaments
                  if (!isLive)
                    Consumer(
                      builder: (context, ref, _) {
                        final teamAsync = ref.watch(userTeamForTournamentProvider(tournament.id));
                        final isRegistered = teamAsync.value != null;

                        return ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                            foregroundColor: isRegistered ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: isRegistered ? colorScheme.outline : colorScheme.outline,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(AppSizes.radius16),
                            ),
                          ),
                          child: Text(
                            isRegistered ? 'Registered' : 'Register Now',
                            style: textTheme.bodyMedium?.copyWith(
                              color: isRegistered ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
                              fontWeight: isRegistered ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }
                    )
                  else
                    // Informational chip shown for live matches
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: AppSizes.space8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'In Progress',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
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

// ── Pulsing Live Badge ────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  final ColorScheme colorScheme;
  const _LiveBadge({required this.colorScheme});

  @override
  State<_LiveBadge> createState() => LiveBadgeState();
}

class LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Opacity(
        opacity: _pulse.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.colorScheme.error,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
