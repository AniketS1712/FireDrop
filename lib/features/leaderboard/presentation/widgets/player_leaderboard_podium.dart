import 'package:flutter/material.dart';
import 'package:eagle_esports/shared/models/published_leaderboard.dart';

class PlayerLeaderboardPodium extends StatelessWidget {
  final List<PublishedStanding> standings;

  const PlayerLeaderboardPodium({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return const SizedBox.shrink();

    final first = standings.isNotEmpty ? standings[0] : null;
    final second = standings.length > 1 ? standings[1] : null;
    final third = standings.length > 2 ? standings[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        children: [
          _buildPodiumLabel(context),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (second != null)
                Expanded(child: _PodiumPillar(standing: second, rank: 2, height: 110)),
              const SizedBox(width: 12),
              if (first != null)
                Expanded(child: _PodiumPillar(standing: first, rank: 1, height: 160)),
              const SizedBox(width: 12),
              if (third != null)
                Expanded(child: _PodiumPillar(standing: third, rank: 3, height: 90)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 40, height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'CHAMPIONS CIRCLE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
          ),
        ),
        Container(width: 40, height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
      ],
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final PublishedStanding standing;
  final int rank;
  final double height;

  const _PodiumPillar({required this.standing, required this.rank, required this.height});

  Color _rankColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rank == 1) return colorScheme.primary;
    if (rank == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _rankColor(context);
    final isFirst = rank == 1;

    return Column(
      children: [
        if (isFirst) ...[
          const Text('👑', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
        ],
        Text(
          standing.teamName.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: isFirst ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: isFirst ? 14 : 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${standing.totalPoints} PTS',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: Center(
            child: Text(
              rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉'),
              style: TextStyle(fontSize: isFirst ? 40 : 32),
            ),
          ),
        ),
      ],
    );
  }
}
