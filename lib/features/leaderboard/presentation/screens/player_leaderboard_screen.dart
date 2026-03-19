import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/published_leaderboard.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PlayerLeaderboardScreen extends ConsumerWidget {
  final TournamentModel tournament;

  const PlayerLeaderboardScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(publishedLeaderboardProvider(tournament.id));

    return Scaffold(
      backgroundColor: AppColorTokens.bgPrimary,
      body: lbAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColorTokens.primary),
        ),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (lb) {
          if (lb == null || !lb.isPublished) {
            return _NotPublishedView(tournamentTitle: tournament.title);
          }
          return _LeaderboardView(tournament: tournament, lb: lb);
        },
      ),
    );
  }
}

// ─── Main Leaderboard View ────────────────────────────────────────────────────

class _LeaderboardView extends StatelessWidget {
  final TournamentModel tournament;
  final PublishedLeaderboard lb;

  const _LeaderboardView({required this.tournament, required this.lb});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── App bar ──────────────────────────────────────────────────────────
        _buildSliverAppBar(context),

        // ── Timestamp chip ───────────────────────────────────────────────────
        if (lb.updatedAt != null)
          SliverToBoxAdapter(child: _buildUpdatedChip(lb.updatedAt!)),

        // ── Podium (top 3) ───────────────────────────────────────────────────
        if (lb.standings.length >= 3)
          SliverToBoxAdapter(
            child: _Podium(standings: lb.standings.take(3).toList()),
          ),

        // ── Full table ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              AppSizes.space24,
              AppSizes.space16,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColorTokens.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'FULL STANDINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(child: _buildTableHeader()),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _StandingRow(
              standing: lb.standings[i],
              isEven: i.isEven,
            ),
            childCount: lb.standings.length,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // ── Sliver app bar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColorTokens.bgSecondary,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColorTokens.primary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Tournament cover
            Image.network(
              tournament.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColorTokens.bgTertiary,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColorTokens.textDisabled,
                  size: 48,
                ),
              ),
            ),
            // Dark gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55000000), Color(0xEE121212)],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
            // Title + trophy
            Positioned(
              bottom: 16,
              left: AppSizes.space16,
              right: AppSizes.space16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColorTokens.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'FINAL RESULTS',
                        style: TextStyle(
                          color: AppColorTokens.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tournament.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Updated chip ──────────────────────────────────────────────────────────

  Widget _buildUpdatedChip(DateTime updatedAt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        0,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColorTokens.success.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: AppColorTokens.success.withAlpha(100),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColorTokens.success,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  'Published · ${DateFormat('d MMM yyyy, HH:mm').format(updatedAt)}',
                  style: const TextStyle(
                    color: AppColorTokens.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space12,
        AppSizes.space16,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColorTokens.bgTertiary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radius16),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              'RANK',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text('TEAM', style: _headerStyle),
          ),
          SizedBox(
            width: 56,
            child: Text(
              'POS',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              'KILLS',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'PTS',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: AppColorTokens.primary,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
);

// ─── Podium Widget ────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<PublishedStanding> standings;

  const _Podium({required this.standings});

  @override
  Widget build(BuildContext context) {
    // standings are sorted by rank — index 0 = 1st
    final first = standings.isNotEmpty ? standings[0] : null;
    final second = standings.length > 1 ? standings[1] : null;
    final third = standings.length > 2 ? standings[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space24,
        AppSizes.space16,
        0,
      ),
      child: Column(
        children: [
          // Glow divider
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColorTokens.gold,
                  AppColorTokens.primary,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          const Text(
            '🏆  TOP 3  🏆',
            style: TextStyle(
              color: AppColorTokens.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          // Podium layout: 2nd | 1st | 3rd
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumPillar(
                  standing: second,
                  place: 2,
                  accentColor: const Color(0xFFC0C0C0),
                  height: 90,
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: _PodiumPillar(
                  standing: first,
                  place: 1,
                  accentColor: AppColorTokens.gold,
                  height: 120,
                  isWinner: true,
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: _PodiumPillar(
                  standing: third,
                  place: 3,
                  accentColor: const Color(0xFFCD7F32),
                  height: 70,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space16),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColorTokens.border,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final PublishedStanding? standing;
  final int place;
  final Color accentColor;
  final double height;
  final bool isWinner;

  const _PodiumPillar({
    required this.standing,
    required this.place,
    required this.accentColor,
    required this.height,
    this.isWinner = false,
  });

  String get _placeEmoji {
    switch (place) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      default:
        return '🥉';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (standing == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Winner crown animation for 1st place
        if (isWinner) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.05),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const Text('👑', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
        ],
        // Team name
        Text(
          standing!.teamName,
          style: TextStyle(
            color: isWinner ? Colors.white : AppColorTokens.textSecondary,
            fontSize: isWinner ? 13 : 12,
            fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Points badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: accentColor.withAlpha(100)),
          ),
          child: Text(
            '${standing!.totalPoints} pts',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        // Pillar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radius8),
            ),
            border: Border.all(color: accentColor.withAlpha(80)),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              _placeEmoji,
              style: TextStyle(fontSize: isWinner ? 32 : 24),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Standing Row ─────────────────────────────────────────────────────────────

class _StandingRow extends StatelessWidget {
  final PublishedStanding standing;
  final bool isEven;

  const _StandingRow({required this.standing, required this.isEven});

  Color _rankColor(int rank) {
    if (rank == 1) return AppColorTokens.gold;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColorTokens.textSecondary;
  }

  String _rankLabel(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = standing.rank <= 3;
    final rowColor = isTop3
        ? _rankColor(standing.rank).withAlpha(12)
        : (isEven ? AppColorTokens.bgPrimary : AppColorTokens.bgSecondary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          left: isTop3
              ? BorderSide(
                  color: _rankColor(standing.rank).withAlpha(160),
                  width: 3,
                )
              : BorderSide.none,
          bottom: const BorderSide(color: AppColorTokens.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  _rankLabel(standing.rank),
                  style: TextStyle(
                    color: _rankColor(standing.rank),
                    fontSize: isTop3 ? 16 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    standing.teamName,
                    style: TextStyle(
                      color: isTop3 ? Colors.white : AppColorTokens.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          isTop3 ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Finished #${standing.position > 0 ? standing.position : "—"}',
                    style: const TextStyle(
                      color: AppColorTokens.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Position finish
            SizedBox(
              width: 56,
              child: Center(
                child: Text(
                  standing.position > 0 ? '#${standing.position}' : '—',
                  style: const TextStyle(
                    color: AppColorTokens.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Kills
            SizedBox(
              width: 56,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColorTokens.error,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${standing.kills}',
                      style: const TextStyle(
                        color: AppColorTokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Total points
            SizedBox(
              width: 64,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorTokens.primary.withAlpha(isTop3 ? 30 : 20),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: AppColorTokens.primary.withAlpha(isTop3 ? 120 : 60),
                    ),
                  ),
                  child: Text(
                    '${standing.totalPoints}',
                    style: const TextStyle(
                      color: AppColorTokens.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Not Published View ───────────────────────────────────────────────────────

class _NotPublishedView extends StatelessWidget {
  final String tournamentTitle;
  const _NotPublishedView({required this.tournamentTitle});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColorTokens.primary,
              ),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.hourglass_top_rounded,
            color: AppColorTokens.textDisabled,
            size: 64,
          ),
          const SizedBox(height: AppSizes.space16),
          const Text(
            'Results Pending',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space40),
            child: Text(
              'The organizer hasn\'t published the leaderboard for "$tournamentTitle" yet. Check back soon!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space32),
        child: Text(
          'Error loading leaderboard:\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColorTokens.error, fontSize: 14),
        ),
      ),
    );
  }
}
