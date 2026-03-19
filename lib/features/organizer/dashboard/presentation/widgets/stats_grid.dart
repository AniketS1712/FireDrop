import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';

class StatsGrid extends StatelessWidget {
  final List<TournamentModel> tournaments;
  const StatsGrid({super.key, required this.tournaments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;
    final total = tournaments.length;
    final live = tournaments.where((t) => t.isLive).length;
    final upcoming = tournaments.where((t) => t.isUpcoming).length;
    final completed = tournaments.where((t) => t.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Stats',
            style: textScheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSizes.space12,
            crossAxisSpacing: AppSizes.space12,
            childAspectRatio: 2,
            children: [
              _StatChip(
                label: 'Total',
                value: '$total',
                color: colorScheme.primary,
              ),
              _StatChip(
                label: 'Live',
                value: '$live',
                color: colorScheme.secondary,
              ),
              _StatChip(
                label: 'Upcoming',
                value: '$upcoming',
                color: colorScheme.tertiary,
              ),
              _StatChip(
                label: 'Completed',
                value: '$completed',
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: color.withAlpha(160)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: textScheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 3),
          Text(label, style: textScheme.bodyMedium),
        ],
      ),
    );
  }
}
