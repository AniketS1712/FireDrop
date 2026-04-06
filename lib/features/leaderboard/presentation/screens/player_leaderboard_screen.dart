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
    final gradients = Theme.of(context).extension<AppGradients>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(gradient: gradients?.background),
        child: lbAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (lb) {
            if (lb == null || !lb.isPublished) {
              return _NotPublishedView(tournamentTitle: tournament.title);
            }
            return _LeaderboardView(tournament: tournament, lb: lb);
          },
        ),
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
          SliverToBoxAdapter(child: _buildUpdatedChip(context, lb.updatedAt!)),

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
              AppSizes.space32,
              AppSizes.space16,
              AppSizes.space8,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Text(
                  'FULL STANDINGS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(child: _buildTableHeader(context)),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) =>
                _StandingRow(standing: lb.standings[i], isEven: i.isEven),
            childCount: lb.standings.length,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  // ── Sliver app bar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppSizes.space8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withAlpha(150),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withAlpha(100),
                  size: 48,
                ),
              ),
            ),
            // Gradient overlay using theme gradients
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface.withAlpha(50),
                    Theme.of(context).colorScheme.surface,
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // Title + trophy
            Positioned(
              bottom: AppSizes.space24,
              left: AppSizes.space24,
              right: AppSizes.space24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
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

  Widget _buildUpdatedChip(BuildContext context, DateTime updatedAt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space24,
        AppSizes.space16,
        AppSizes.space24,
        0,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space8,
          ),
          decoration: BoxDecoration(
            color: AppColorTokens.success.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: AppColorTokens.success.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: AppColorTokens.success.withAlpha(20),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppColorTokens.success,
                size: 14,
              ),
              const SizedBox(width: AppSizes.space8),
              Text(
                'Published · ${DateFormat('d MMM yyyy, HH:mm').format(updatedAt)}',
                style: TextStyle(
                  color: AppColorTokens.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────────────────────

  Widget _buildTableHeader(BuildContext context) {
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radius16),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('RANK', style: style, textAlign: TextAlign.center),
          ),
          const SizedBox(width: AppSizes.space8),
          Expanded(child: Text('TEAM', style: style)),
          SizedBox(
            width: 56,
            child: Text('POS', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 56,
            child: Text('KILLS', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 64,
            child: Text('PTS', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

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

    final gradients = Theme.of(context).extension<AppGradients>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space32,
        AppSizes.space16,
        0,
      ),
      child: Column(
        children: [
          // Premium dividers
          _buildPodiumHeader(context, gradients),
          const SizedBox(height: AppSizes.space40),
          // Podium layout: 2nd | 1st | 3rd
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumPillar(
                  standing: second,
                  place: 2,
                  accentColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 100,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                flex: 1,
                child: _PodiumPillar(
                  standing: first,
                  place: 1,
                  accentColor: Theme.of(context).colorScheme.primary,
                  height: 140,
                  isWinner: true,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: _PodiumPillar(
                  standing: third,
                  place: 3,
                  accentColor: Theme.of(context).colorScheme.secondary,
                  height: 80,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space24),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumHeader(BuildContext context, AppGradients gradients) {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).colorScheme.primary.withAlpha(150),
                Theme.of(context).colorScheme.secondary.withAlpha(150),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space24,
            vertical: AppSizes.space8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(50),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: AppSizes.space12),
              Text(
                'TOP 3',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Icon(
                Icons.star_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 16,
              ),
            ],
          ),
        ),
      ],
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

    final gradients = Theme.of(context).extension<AppGradients>();

    return Column(
      children: [
        // Winner crown animation for 1st place
        if (isWinner) ...[
          const Text('👑', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppSizes.space8),
        ],
        // Team name
        Text(
          standing!.teamName,
          style: TextStyle(
            color: isWinner
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isWinner ? 14 : 12,
            fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSizes.space8),
        // Points badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space12,
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: accentColor.withAlpha(80)),
            boxShadow: isWinner
                ? [BoxShadow(color: accentColor.withAlpha(40), blurRadius: 8)]
                : [],
          ),
          child: Text(
            '${standing!.totalPoints} pts',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        // Pillar
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: isWinner
                ? (gradients?.primary ??
                      LinearGradient(
                        colors: [accentColor, accentColor.withAlpha(150)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ))
                : LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12.0),
            ),
            border: Border(
              top: BorderSide(color: accentColor, width: isWinner ? 3 : 2),
              left: BorderSide(color: accentColor.withAlpha(100), width: 1),
              right: BorderSide(color: accentColor.withAlpha(100), width: 1),
            ),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(100),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              _placeEmoji,
              style: TextStyle(fontSize: isWinner ? 36 : 28),
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

  Color _rankColor(BuildContext context, int rank) {
    if (rank == 1) return Theme.of(context).colorScheme.primary;
    if (rank == 2) return Theme.of(context).colorScheme.onSurfaceVariant;
    if (rank == 3) return Theme.of(context).colorScheme.secondary;
    return Theme.of(context).colorScheme.primary;
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
        ? _rankColor(context, standing.rank).withAlpha(15)
        : (isEven
              ? Theme.of(context).colorScheme.surface
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(50));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          left: isTop3
              ? BorderSide(color: _rankColor(context, standing.rank), width: 3)
              : BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            width: 1,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space16,
          vertical: AppSizes.space16,
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  _rankLabel(standing.rank),
                  style: TextStyle(
                    color: isTop3
                        ? _rankColor(context, standing.rank)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isTop3 ? 18 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.space8),
            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    standing.teamName,
                    style: TextStyle(
                      color: isTop3
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(200),
                      fontSize: 14,
                      fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Finished #${standing.position > 0 ? standing.position : "—"}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Kills
            SizedBox(
              width: 56,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gps_fixed_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${standing.kills}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Total points
            SizedBox(
              width: 64,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(isTop3 ? 25 : 15),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(isTop3 ? 80 : 30),
                    ),
                  ),
                  child: Text(
                    '${standing.totalPoints}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.space8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AppSizes.space24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: AppSizes.space32),
          Text(
            'RESULTS PENDING',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space40),
            child: Text(
              'The organizer hasn\'t published the leaderboard for "$tournamentTitle" yet. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: AppSizes.space16),
            Text(
              'Error loading leaderboard',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error.withAlpha(200),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
