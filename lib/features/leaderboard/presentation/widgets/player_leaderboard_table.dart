import 'package:flutter/material.dart';
import 'package:eagle_esports/shared/models/published_leaderboard.dart';

const double playerColRank = 64.0;
const double playerColPos = 56.0;
const double playerColKills = 56.0;
const double playerColPoints = 72.0;

class PlayerLeaderboardTableHeader extends StatelessWidget {
  const PlayerLeaderboardTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          _headerCell('RANK', playerColRank, colorScheme),
          Expanded(
            child: Text(
              'TEAM NAME',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _headerCell('POS', playerColPos, colorScheme),
          _headerCell('KILLS', playerColKills, colorScheme),
          _headerCell('TOTAL', playerColPoints, colorScheme),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, ColorScheme colorScheme) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class PlayerStandingRow extends StatelessWidget {
  final PublishedStanding standing;
  final bool isEven;

  const PlayerStandingRow({
    super.key,
    required this.standing,
    required this.isEven,
  });

  Color _rankColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (standing.rank == 1) return colorScheme.primary;
    if (standing.rank == 2) return const Color(0xFFC0C0C0);
    if (standing.rank == 3) return const Color(0xFFCD7F32);
    return colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTop3 = standing.rank <= 3;
    final color = _rankColor(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isTop3
            ? color.withValues(alpha: 0.05)
            : (isEven ? colorScheme.surface : Colors.transparent),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank Indicator
          SizedBox(
            width: playerColRank,
            child: Center(
              child: isTop3
                  ? Text(
                      standing.rank == 1
                          ? '🥇'
                          : (standing.rank == 2 ? '🥈' : '🥉'),
                      style: const TextStyle(fontSize: 20),
                    )
                  : Text(
                      '#${standing.rank}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  standing.teamName.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isTop3 ? color : colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Final Placement: #${standing.position}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Position
          _valueCell(
            '#${standing.position}',
            playerColPos,
            colorScheme.onSurface,
          ),

          // Kills
          _valueCell(
            '${standing.kills}',
            playerColKills,
            colorScheme.onSurface,
          ),

          // Total
          SizedBox(
            width: playerColPoints,
            child: Center(
              child: Text(
                '${standing.totalPoints}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isTop3 ? color : colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCell(String value, double width, Color textColor) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
