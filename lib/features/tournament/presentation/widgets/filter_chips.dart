import 'package:eagle_esports/core/constant/app_enums.dart';
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filters.entries.map((e) {
            final isSelected = selected == e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onChanged(e.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
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
