import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/shared/models/teams_model.dart';
import 'package:eagle_esports/core/constant/app_enums.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:eagle_esports/features/team/presentation/screens/team_selection_screen.dart';
import 'package:eagle_esports/features/team/presentation/screens/my_team_screen.dart';
import 'package:eagle_esports/features/leaderboard/presentation/screens/player_leaderboard_screen.dart';

class TournamentBottomBar extends ConsumerWidget {
  final TournamentModel tournament;
  const TournamentBottomBar({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canJoin =
        tournament.status == TournamentStatus.upcoming ||
        tournament.status == TournamentStatus.registrationOpen;

    final teamAsync = ref.watch(userTeamForTournamentProvider(tournament.id));
    final isRegistered = teamAsync.value != null;
    final team = teamAsync.value;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
        ),
        child: TournamentBottomActionButton(
          tournament: tournament,
          isRegistered: isRegistered,
          canJoin: canJoin,
          team: team,
        ),
      ),
    );
  }
}

class TournamentBottomActionButton extends StatelessWidget {
  final TournamentModel tournament;
  final bool isRegistered;
  final bool canJoin;
  final TeamModel? team;

  const TournamentBottomActionButton({
    super.key,
    required this.tournament,
    required this.isRegistered,
    required this.canJoin,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String text;
    IconData icon;
    Color buttonColor;
    VoidCallback? onTap;

    if (tournament.isCompleted) {
      text = 'VIEW FULL STANDINGS';
      icon = Icons.emoji_events_rounded;
      buttonColor = colorScheme.primary;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerLeaderboardScreen(tournament: tournament),
            ),
          );
    } else if (isRegistered) {
      text = 'MY TEAM DASHBOARD';
      icon = Icons.dashboard_rounded;
      buttonColor = colorScheme.secondary;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyTeamScreen(tournament: tournament, team: team!),
            ),
          );
    } else if (canJoin) {
      text = 'REGISTER NOW';
      icon = Icons.bolt_rounded;
      buttonColor = colorScheme.primary;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamSelectionScreen(tournament: tournament),
            ),
          );
    } else {
      text = 'REGISTRATION CLOSED';
      icon = Icons.lock_rounded;
      buttonColor = colorScheme.onSurfaceVariant;
      onTap = null;
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        enableFeedback: true,
        backgroundColor: buttonColor,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 12,
        shadowColor: buttonColor.withValues(alpha: 0.4),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
