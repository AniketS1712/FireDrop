import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/routes/route_names.dart';
// import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/tournament/presentation/widgets/action_btn.dart';
import 'package:firedrop/features/tournament/presentation/widgets/registered_teams_sheet.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActionButtons extends ConsumerWidget {
  final TournamentModel tournament;
  final Future<void> Function(TournamentStatus) onAct;

  const ActionButtons({
    super.key,
    required this.tournament,
    required this.onAct,
  });

  void _goToLeaderboard(BuildContext context) {
    context.pushNamed(RouteNames.leaderboard, extra: tournament);
  }

  void _showTeamsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RegisteredTeamsSheet(tournament: tournament),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = tournament.status;
    return switch (status) {
      TournamentStatus.upcoming || TournamentStatus.registrationOpen => Row(
        children: [
          Expanded(
            child: ActionBtn(
              label: 'Start',
              icon: Icons.play_circle_outline,
              color: Colors.green,
              onTap: () => onAct(TournamentStatus.live),
            ),
          ),
          const SizedBox(width: AppSizes.space16),
          Expanded(
            child: ActionBtn(
              label: 'Teams Joined',
              icon: Icons.groups_3,
              color: Theme.of(context).colorScheme.secondary,
              onTap: () => _showTeamsSheet(context),
            ),
          ),
        ],
      ),
      TournamentStatus.live => Row(
        children: [
          Expanded(
            child: ActionBtn(
              label: 'Edit Leaderboard',
              icon: Icons.leaderboard,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _goToLeaderboard(context),
            ),
          ),
          const SizedBox(width: AppSizes.space16),
          Expanded(
            child: ActionBtn(
              label: 'Complete',
              icon: Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => onAct(TournamentStatus.completed),
            ),
          ),
        ],
      ),
      TournamentStatus.completed => Column(
        children: [
          ActionBtn(
            label: 'View Leaderboard',
            icon: Icons.leaderboard,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => _goToLeaderboard(context),
            fullWidth: true,
          ),
          const SizedBox(height: AppSizes.space8),
          ActionBtn(
            label: 'Tournament Completed',
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () => {},
            fullWidth: true,
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
