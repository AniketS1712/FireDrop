import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/published_leaderboard.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import '../widgets/player_leaderboard_podium.dart';
import '../widgets/player_leaderboard_table.dart';
import '../widgets/player_leaderboard_states.dart';

class PlayerLeaderboardScreen extends ConsumerWidget {
  final TournamentModel tournament;

  const PlayerLeaderboardScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(publishedLeaderboardProvider(tournament.id));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tournament.title), centerTitle: false),
      backgroundColor: colorScheme.surface,
      body: lbAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (e, _) => LeaderboardErrorView(message: e.toString()),
        data: (lb) {
          if (lb == null || !lb.isPublished) {
            return LeaderboardNotPublishedView(
              tournamentTitle: tournament.title,
            );
          }

          final top3 = lb.standings.take(3).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (lb.updatedAt != null)
                SliverToBoxAdapter(
                  child: LeaderboardPublishedChip(updatedAt: lb.updatedAt!),
                ),

              if (lb.standings.length >= 3)
                SliverToBoxAdapter(
                  child: PlayerLeaderboardPodium(standings: top3),
                ),

              // Standings Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'FULL STANDINGS',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: PlayerLeaderboardTableHeader()),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final standing = lb.standings[index];
                  return PlayerStandingRow(
                    standing: standing,
                    isEven: index.isEven,
                  );
                }, childCount: lb.standings.length),
              ),

              // Bottom Spacing
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
