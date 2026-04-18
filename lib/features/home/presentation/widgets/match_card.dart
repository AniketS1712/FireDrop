import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';

class MatchCard extends ConsumerWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap;
  final Widget? actionButton;
  final bool isMatchScreen;

  const MatchCard({
    super.key,
    required this.tournament,
    this.onTap,
    this.actionButton,
    this.isMatchScreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final isLive = tournament.isLive;
    final now = DateTime.now();

    // ── Time Formatting Logic ───────────────────────────────────────────────
    final startDateStr = DateFormat(
      'MMM dd, hh:mm a',
    ).format(tournament.startTime);

    final regDiff = tournament.startTime.difference(now);
    final String regLabel;

    if (regDiff.isNegative) {
      regLabel = 'CLOSED';
    } else {
      final days = regDiff.inDays;
      final hours = regDiff.inHours % 24;
      final minutes = regDiff.inMinutes % 60;

      if (days > 0) {
        regLabel = '${days}d ${hours}h left';
      } else if (hours > 0) {
        regLabel = '${hours}h ${minutes}m left';
      } else {
        regLabel = '${minutes}m left';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(50),
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          border: Border.all(color: colorScheme.outline, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Section (Image) ───────────────────────────────
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                    ).createShader(
                      Rect.fromLTRB(0, 0, rect.width, rect.height + 200),
                    );
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.network(
                    tournament.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.sports_esports,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Entry Fee Overlay
                if (!isMatchScreen)
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(100),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹${tournament.entryFee}',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Information Section ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title.toUpperCase(),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.space12),

                  // Match Metadata Row
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.sports_esports_outlined,
                        text: tournament.gameMode.name.toUpperCase(),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.people_outline_rounded,
                        text: '${tournament.maxSlots} SLOTS',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  if (!isMatchScreen) ...[
                    const SizedBox(height: AppSizes.space16),
                    const Divider(height: 2),
                    const SizedBox(height: AppSizes.space16),

                    Row(
                      children: [
                        Expanded(
                          child: _TimeInfo(
                            label: 'START AT',
                            value: startDateStr,
                            icon: Icons.calendar_month_outlined,
                            colorScheme: colorScheme,
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 2,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _TimeInfo(
                            label: 'REGISTRATION ENDS IN',
                            value: regLabel,
                            icon: Icons.timer_outlined,
                            colorScheme: colorScheme,
                            highlight: !isLive && !regDiff.isNegative,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSizes.space24),

                  // Call to Action
                  if (actionButton != null)
                    actionButton!
                  else if (!isLive)
                    Consumer(
                      builder: (context, ref, _) {
                        final teamAsync = ref.watch(
                          userTeamForTournamentProvider(tournament.id),
                        );
                        final isRegistered = teamAsync.value != null;

                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRegistered
                                  ? colorScheme.surfaceContainerHighest
                                        .withAlpha(200)
                                  : colorScheme.primary,
                              foregroundColor: isRegistered
                                  ? colorScheme.onSurface
                                  : Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius16,
                                ),
                                side: isRegistered
                                    ? BorderSide(color: colorScheme.outline)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Text(
                              (isRegistered ? 'REGISTERED' : 'REGISTER NOW')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    // Live Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withAlpha(50),
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        border: Border.all(
                          color: colorScheme.error.withAlpha(100),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'MATCH IN PROGRESS',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.error,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  const _StatItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool highlight;

  const _TimeInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: highlight
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
