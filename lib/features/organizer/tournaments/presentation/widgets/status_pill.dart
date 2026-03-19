import 'package:flutter/material.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';

class StatusPill extends StatelessWidget {
  final TournamentStatus status;
  const StatusPill({super.key, required this.status});

  Color get _color {
    switch (status) {
      case TournamentStatus.live:
        return Colors.redAccent;
      case TournamentStatus.upcoming:
        return AppColorTokens.primary;
      case TournamentStatus.registrationOpen:
        return AppColorTokens.secondary;
      case TournamentStatus.completed:
        return Colors.grey;
      case TournamentStatus.draft:
        return AppColorTokens.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withAlpha(50),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: _color),
        ),
        child: Text(
          status.name.toUpperCase().replaceAll('_', ' '),
          style: textScheme.bodySmall?.copyWith(
            color: _color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
