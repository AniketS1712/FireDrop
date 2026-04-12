import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/features/home/presentation/widgets/match_card.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/shared/models/published_leaderboard.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/features/leaderboard/presentation/screens/player_leaderboard_screen.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);
    final publicAsync = ref.watch(publicTournamentsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY MATCHES',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Orbitron',
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress and results',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tournament List ──
            joinedTeamsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error: $e',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return SliverFillRemaining(child: _EmptyMatchesState());
                }

                return publicAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ),
                  data: (allTournaments) {
                    final joinedIds = teams.map((t) => t.tournamentId).toSet();

                    final myTournaments =
                        allTournaments
                            .where((t) => joinedIds.contains(t.id))
                            .toList()
                          ..sort((a, b) => b.startTime.compareTo(a.startTime));

                    if (myTournaments.isEmpty) {
                      return SliverFillRemaining(child: _EmptyMatchesState());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final tournament = myTournaments[index];
                          return _JoinedMatchItem(tournament: tournament);
                        }, childCount: myTournaments.length),
                      ),
                    );
                  },
                );
              },
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _JoinedMatchItem extends ConsumerWidget {
  final TournamentModel tournament;
  const _JoinedMatchItem({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(publishedLeaderboardProvider(tournament.id));

    return lbAsync.when(
      data: (lb) {
        final isPublished = lb != null && lb.isPublished;

        return MatchCard(
          tournament: tournament,
          isMatchScreen: true,
          actionButton: _LeaderboardButton(
            tournament: tournament,
            hasPublishedLeaderboard: isPublished,
          ),
          onTap: isPublished
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlayerLeaderboardScreen(tournament: tournament),
                    ),
                  );
                }
              : null,
        );
      },
      loading: () => MatchCard(
        tournament: tournament,
        actionButton: const Center(child: LinearProgressIndicator()),
      ),
      error: (_, _) => MatchCard(tournament: tournament),
    );
  }
}

class _LeaderboardButton extends StatelessWidget {
  final TournamentModel tournament;
  final bool hasPublishedLeaderboard;

  const _LeaderboardButton({
    required this.tournament,
    required this.hasPublishedLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: hasPublishedLeaderboard
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PlayerLeaderboardScreen(tournament: tournament),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPublishedLeaderboard
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withAlpha(100),
          foregroundColor: hasPublishedLeaderboard
              ? Colors.black
              : colorScheme.onSurfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            side: hasPublishedLeaderboard
                ? BorderSide.none
                : BorderSide(color: colorScheme.outline.withAlpha(50)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPublishedLeaderboard
                  ? Icons.emoji_events_rounded
                  : Icons.pending_actions_rounded,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              (hasPublishedLeaderboard ? 'VIEW LEADERBOARD' : 'RESULTS PENDING')
                  .toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontFamily: 'Orbitron',
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              color: colorScheme.primary.withAlpha(50),
              size: 80,
            ),
            const SizedBox(height: AppSizes.space24),
            Text(
              'NO MATCHES YET',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                fontFamily: 'Orbitron',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            Text(
              'Join tournaments to see your progress and battle history here.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
