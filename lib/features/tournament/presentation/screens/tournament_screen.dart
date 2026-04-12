import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import '../widgets/tournament_hero.dart';
import '../widgets/tournament_details.dart';
import '../widgets/tournament_info_sections.dart';
import '../widgets/tournament_leaderboard_card.dart';
import '../widgets/tournament_bottom_bar.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const TournamentScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  TournamentModel get t => widget.tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Removed TopSafeArea here to fix button alignment
              TournamentHero(tournament: t),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space24,
                  vertical: AppSizes.space24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TournamentTitleSection(tournament: t),
                    const SizedBox(height: AppSizes.space24),
                    TournamentStatsGrid(tournament: t),
                    const SizedBox(height: AppSizes.space24),
                    TournamentRoomDetails(tournament: t),
                    const SizedBox(height: AppSizes.space24),
                    TournamentPrizeDistribution(tournament: t),
                    const SizedBox(height: AppSizes.space24),
                    TournamentRules(tournament: t),
                    if (t.isCompleted) ...[
                      const SizedBox(height: AppSizes.space24),
                      TournamentLeaderboardCard(tournament: t),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          TournamentBottomBar(tournament: t),
        ],
      ),
    );
  }
}
