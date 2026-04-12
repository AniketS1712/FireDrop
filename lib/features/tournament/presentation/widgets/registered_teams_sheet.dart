import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/features/leaderboard/presentation/providers/leaderboard_providers.dart';
import 'package:eagle_esports/shared/models/teams_model.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';

class RegisteredTeamsSheet extends ConsumerWidget {
  final TournamentModel tournament;

  const RegisteredTeamsSheet({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournament.id));
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radius24),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                  ),
                ),
              ),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REGISTERED TEAMS',
                            style: textScheme.labelMedium?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                          Text(
                            tournament.title,
                            style: textScheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    teamsAsync.when(
                      data: (teams) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withAlpha(80),
                          ),
                        ),
                        child: Text(
                          '${teams.length} / ${tournament.maxSlots}',
                          style: textScheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colorScheme.outline),

              // ── Body ──
              Expanded(
                child: teamsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: textScheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  data: (teams) {
                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              color: colorScheme.onSurface.withAlpha(100),
                              size: 52,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No teams have registered yet.',
                              style: textScheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(AppSizes.space16),
                      itemCount: teams.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.space12),
                      itemBuilder: (context, i) =>
                          _TeamCard(team: teams[i], index: i),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final TeamModel team;
  final int index;

  const _TeamCard({required this.team, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    final captainAsync = ref.watch(userByIdProvider(team.organizerID));
    final captainName = captainAsync.maybeWhen(
      data: (u) => u?.name ?? team.organizerID.substring(0, 8),
      orElse: () => '…',
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          // ── Top row: rank + team name + member count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space12,
              AppSizes.space12,
              AppSizes.space12,
              AppSizes.space8,
            ),
            child: Row(
              children: [
                // Rank number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${index + 1}',
                    style: textScheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),

                // Team name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: textScheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            captainName,
                            style: textScheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Member count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: colorScheme.primary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${team.members.length}',
                        style: textScheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline),

          // ── Bottom row: IGN + invite code + registered date ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space12,
              AppSizes.space8,
              AppSizes.space12,
              AppSizes.space12,
            ),
            child: Row(
              children: [
                // IGN
                if (team.ign != null && team.ign!.isNotEmpty) ...[
                  Icon(
                    Icons.sports_esports_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    team.ign!,
                    style: textScheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                ],

                // Invite code (copyable)
                if (team.inviteCode != null && team.inviteCode!.isNotEmpty) ...[
                  Icon(
                    Icons.tag_rounded,
                    color: colorScheme.tertiary,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: team.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied!'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      team.inviteCode!,
                      style: textScheme.labelSmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Registered at
                Icon(
                  Icons.access_time_rounded,
                  color: colorScheme.onSurfaceVariant.withAlpha(150),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM, HH:mm').format(team.createdAt),
                  style: textScheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
