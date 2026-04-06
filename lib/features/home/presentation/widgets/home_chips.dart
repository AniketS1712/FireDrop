import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeChips extends ConsumerWidget {
  const HomeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(tournamentFilterProvider);
    final modeFilter = ref.watch(gameModeFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space16),
      child: Column(
        children: [
          // Row 1: Status Filters
          Center(
            child: Wrap(
              spacing: AppSizes.space16,
              runSpacing: AppSizes.space8,
              children: [
                _ChipItem(
                  label: 'Joined',
                  selected: statusFilter == TournamentFilter.joined,
                  onSelected: () => ref
                      .read(tournamentFilterProvider.notifier)
                      .setFilter(TournamentFilter.joined),
                ),
                _ChipItem(
                  label: 'Upcoming',
                  selected: statusFilter == TournamentFilter.upcoming,
                  onSelected: () => ref
                      .read(tournamentFilterProvider.notifier)
                      .setFilter(TournamentFilter.upcoming),
                ),
                _ChipItem(
                  label: 'Live',
                  selected: statusFilter == TournamentFilter.live,
                  onSelected: () => ref
                      .read(tournamentFilterProvider.notifier)
                      .setFilter(TournamentFilter.live),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.space8),

          // Row 2: Game Mode Filters
          Center(
            child: Wrap(
              spacing: AppSizes.space16,
              runSpacing: AppSizes.space8,
              children: [
                _ChipItem(
                  label: 'All',
                  selected: modeFilter == GameModeFilter.all,
                  onSelected: () => ref
                      .read(gameModeFilterProvider.notifier)
                      .setFilter(GameModeFilter.all),
                ),
                _ChipItem(
                  label: 'Solo',
                  selected: modeFilter == GameModeFilter.solo,
                  onSelected: () => ref
                      .read(gameModeFilterProvider.notifier)
                      .setFilter(GameModeFilter.solo),
                ),
                _ChipItem(
                  label: 'Duo',
                  selected: modeFilter == GameModeFilter.duo,
                  onSelected: () => ref
                      .read(gameModeFilterProvider.notifier)
                      .setFilter(GameModeFilter.duo),
                ),
                _ChipItem(
                  label: 'Squad',
                  selected: modeFilter == GameModeFilter.squad,
                  onSelected: () => ref
                      .read(gameModeFilterProvider.notifier)
                      .setFilter(GameModeFilter.squad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _ChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(
        label,
        style: textScheme.headlineMedium?.copyWith(
          color: selected
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
          fontSize: 16,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      color: WidgetStatePropertyAll(
        selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        side: BorderSide(
          color: selected ? Colors.transparent : colorScheme.outlineVariant,
          width: 1.8,
        ),
      ),
    );
  }
}
