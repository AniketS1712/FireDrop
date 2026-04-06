import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final TournamentStatus? selected;
  final ValueChanged<TournamentStatus?> onChanged;

  const FilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _filters = <String, TournamentStatus?>{
    'Live': TournamentStatus.live,
    'Upcoming': TournamentStatus.upcoming,
    'Completed': TournamentStatus.completed,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space16),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _filters.entries.map((e) {
            final isSelected = selected == e.value;
            return GestureDetector(
              onTap: () => onChanged(e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space24,
                  vertical: AppSizes.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Text(
                  e.key,
                  style: textScheme.titleSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
