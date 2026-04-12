import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eagle_esports/shared/models/leaderboard_entry.dart';

// Column width constants
const double colPosition = 72.0;
const double colKills = 72.0;
const double colPoints = 80.0;

class LeaderboardTableHeader extends StatelessWidget {
  const LeaderboardTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24), // Edge padding
          Expanded(
            child: Text(
              'TEAM NAME',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _headerCell('RANK', colPosition, colorScheme),
          _headerCell('KILLS', colKills, colorScheme),
          _headerCell('TOTAL', colPoints, colorScheme),
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
            color: colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class LeaderboardRowItem extends StatefulWidget {
  final LeaderboardEntry entry;
  final String leaderName;
  final int rank;
  final ValueChanged<int> onPositionChanged;
  final ValueChanged<int> onKillsChanged;

  const LeaderboardRowItem({
    super.key,
    required this.entry,
    required this.leaderName,
    required this.rank,
    required this.onPositionChanged,
    required this.onKillsChanged,
  });

  @override
  State<LeaderboardRowItem> createState() => _LeaderboardRowItemState();
}

class _LeaderboardRowItemState extends State<LeaderboardRowItem> {
  late final TextEditingController _posCtrl;
  late final TextEditingController _killsCtrl;

  @override
  void initState() {
    super.initState();
    _posCtrl = TextEditingController(
      text: widget.entry.position > 0 ? '${widget.entry.position}' : '',
    );
    _killsCtrl = TextEditingController(text: '${widget.entry.kills}');
  }

  @override
  void dispose() {
    _posCtrl.dispose();
    _killsCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LeaderboardRowItem old) {
    super.didUpdateWidget(old);
    final newPos = widget.entry.position > 0 ? '${widget.entry.position}' : '';
    if (_posCtrl.text != newPos) {
      _posCtrl.value = TextEditingValue(
        text: newPos,
        selection: TextSelection.collapsed(offset: newPos.length),
      );
    }
    final newKills = '${widget.entry.kills}';
    if (_killsCtrl.text != newKills) {
      _killsCtrl.value = TextEditingValue(
        text: newKills,
        selection: TextSelection.collapsed(offset: newKills.length),
      );
    }
  }

  Color _rankColor(BuildContext context, int rank) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rank == 1) return colorScheme.primary;
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTop3 = widget.rank <= 3 && widget.rank > 0;
    final rColor = _rankColor(context, widget.rank);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isTop3 ? rColor.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank Indicator Line
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isTop3 ? rColor : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.entry.teamName.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isTop3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.rank == 1
                          ? '🥇 CHAMPION'
                          : (widget.rank == 2
                                ? '🥈 RUNNER UP'
                                : '🥉 3RD PLACE'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: rColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Text(
                    'Leader: ${widget.leaderName}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),

          // Position Input
          _buildInputCell(
            _posCtrl,
            colPosition,
            '—',
            (v) => widget.onPositionChanged(int.tryParse(v) ?? 0),
          ),

          // Kills Input
          _buildInputCell(
            _killsCtrl,
            colKills,
            '0',
            (v) => widget.onKillsChanged(int.tryParse(v) ?? 0),
          ),

          // Total Points
          SizedBox(
            width: colPoints,
            child: Center(
              child: Text(
                '${widget.entry.totalPoints}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isTop3 ? rColor : colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCell(
    TextEditingController ctrl,
    double width,
    String hint,
    ValueChanged<String> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO TEAMS REGISTERED',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leaderboard will appear once teams join.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
