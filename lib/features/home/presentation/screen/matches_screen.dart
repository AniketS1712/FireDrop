import 'dart:ui';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';
import 'package:firedrop/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:firedrop/shared/models/published_leaderboard.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/features/leaderboard/presentation/screens/player_leaderboard_screen.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);
    final publicAsync = ref.watch(publicTournamentsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space16,
                AppSizes.space16,
                AppSizes.space16,
                AppSizes.space8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MY MATCHES',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 13),
                    child: Text(
                      'Tournaments you\'ve joined & their results',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (myTournaments.isEmpty) {
                    return SliverFillRemaining(child: _EmptyMatchesState());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space16,
                      vertical: AppSizes.space8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tournament = myTournaments[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.space16,
                          ),
                          child: _MatchTournamentCard(tournament: tournament),
                        );
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
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// MATCH TOURNAMENT CARD
// ════════════════════════════════════════════════════════════════════════════════

class _MatchTournamentCard extends ConsumerWidget {
  final TournamentModel tournament;

  const _MatchTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lbAsync = ref.watch(publishedLeaderboardProvider(tournament.id));

    final bool hasPublishedLeaderboard = lbAsync.when(
      data: (lb) => lb != null && lb.isPublished,
      loading: () => false,
      error: (_, _) => false,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withAlpha(12),
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(
              color: _statusColor(tournament, colorScheme).withAlpha(50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _statusColor(tournament, colorScheme).withAlpha(15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Tournament Image ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radius16),
                    ),
                    child: Image.network(
                      tournament.imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 150,
                        color: colorScheme.primaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.videogame_asset_rounded,
                            color: colorScheme.primary,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radius16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusBadge(tournament: tournament),
                  ),
                  // Game Mode badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.onSurfaceVariant.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        tournament.gameMode.name.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      tournament.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Info + Actions ──
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Column(
                  children: [
                    // Info row
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.people_alt_rounded,
                          label: '${tournament.maxSlots} slots',
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.space12),
                        _InfoChip(
                          icon: Icons.monetization_on_rounded,
                          label: '\$${tournament.entryFee}',
                          color: AppColorTokens.warning,
                        ),
                        const SizedBox(width: AppSizes.space12),
                        _InfoChip(
                          icon: Icons.emoji_events_rounded,
                          label: '\$${tournament.prizePool}',
                          color: AppColorTokens.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space16),

                    // Leaderboard Button
                    _LeaderboardButton(
                      tournament: tournament,
                      hasPublishedLeaderboard: hasPublishedLeaderboard,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(TournamentModel t, ColorScheme cs) {
    if (t.isLive) return cs.error;
    if (t.isCompleted) return AppColorTokens.success;
    return cs.primary;
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ════════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final TournamentModel tournament;
  const _StatusBadge({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (tournament.isLive) {
      color = Theme.of(context).colorScheme.error;
      label = 'LIVE';
      icon = Icons.circle;
    } else if (tournament.isCompleted) {
      color = AppColorTokens.success;
      label = 'COMPLETED';
      icon = Icons.check_circle_rounded;
    } else {
      color = Theme.of(context).colorScheme.primary;
      label = 'UPCOMING';
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// INFO CHIP
// ════════════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// LEADERBOARD BUTTON
// ════════════════════════════════════════════════════════════════════════════════

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
    final textTheme = Theme.of(context).textTheme;

    if (hasPublishedLeaderboard) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerLeaderboardScreen(tournament: tournament),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withAlpha(25),
                colorScheme.secondary.withAlpha(25),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(color: colorScheme.primary.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(20),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: colorScheme.primary,
                size: 20,
                shadows: [Shadow(color: colorScheme.primary, blurRadius: 8)],
              ),
              const SizedBox(width: 10),
              Text(
                'VIEW LEADERBOARD',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: colorScheme.secondary, blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not published yet
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withAlpha(10),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.onSurfaceVariant.withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'RESULTS PENDING',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════════

class _EmptyMatchesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports_outlined,
            color: colorScheme.onSurfaceVariant.withAlpha(80),
            size: 72,
          ),
          const SizedBox(height: AppSizes.space16),
          Text(
            'No Matches Yet',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            'Join tournaments from the home screen\nto see your matches here.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
