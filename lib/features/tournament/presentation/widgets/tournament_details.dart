import 'package:flutter/material.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:intl/intl.dart';

class TournamentTitleSection extends StatelessWidget {
  final TournamentModel tournament;
  const TournamentTitleSection({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tournament.title.toUpperCase(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tournament.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class TournamentStatsGrid extends StatelessWidget {
  final TournamentModel tournament;
  const TournamentStatsGrid({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    final String startTime = formatter.format(tournament.startTime);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TournamentStatCard(
                label: 'START TIME',
                value: startTime,
                icon: Icons.alarm_rounded,
                isSmall: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TournamentStatCard(
                label: 'PRIZE POOL',
                value: '₹${tournament.prizePool}',
                icon: Icons.emoji_events_rounded,
                isHighlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TournamentMiniStat(
              label: 'SLOTS',
              value: '${tournament.maxSlots}',
              icon: Icons.people_rounded,
            ),
            TournamentMiniStat(
              label: 'MODE',
              value: tournament.gameMode.name.toUpperCase(),
              icon: Icons.sports_esports_rounded,
            ),
            TournamentMiniStat(
              label: 'ENTRY',
              value: tournament.entryFee == 0
                  ? 'FREE'
                  : '₹${tournament.entryFee}',
              icon: Icons.payments_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class TournamentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;
  final bool isSmall;

  const TournamentStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
        color: isHighlight
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(
          color: isHighlight
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isHighlight
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isHighlight
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                (isSmall
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.displaySmall)
                    ?.copyWith(
                      color: isHighlight
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: isHighlight ? 18 : 14,
                    ),
          ),
        ],
      ),
    );
  }
}

class TournamentMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const TournamentMiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentSectionHeader extends StatelessWidget {
  final String title;
  const TournamentSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
