import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/core/constant/app_enums.dart';
import 'tournament_details.dart'; // For SectionHeader

// ─── ROOM DETAILS ────────────────────────────────────────────────────────────

class TournamentRoomDetails extends ConsumerWidget {
  final TournamentModel tournament;
  const TournamentRoomDetails({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isOrganizer =
        user?.uid == tournament.organizerId || user?.role == UserRole.admin;

    final hasRoom =
        tournament.roomDetails != null &&
        tournament.roomDetails!.roomId != null &&
        tournament.roomDetails!.roomId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'ROOM DETAILS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (isOrganizer)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showEditRoomDetailsDialog(context, ref),
                  color: colorScheme.secondary,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          if (hasRoom) ...[
            TournamentRoomInfoRow(
              label: 'ROOM ID',
              value: tournament.roomDetails!.roomId!,
              onCopy: () => _copy(context, tournament.roomDetails!.roomId!),
            ),
            const SizedBox(height: 12),
            TournamentRoomInfoRow(
              label: 'PASSWORD',
              value: tournament.roomDetails!.password ?? 'None',
              onCopy: () => _copy(context, tournament.roomDetails!.password ?? 'None'),
            ),
          ] else
            Text(
              isOrganizer
                  ? 'No room details set yet. Update them now.'
                  : 'Room details will be revealed shortly before the match.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _showEditRoomDetailsDialog(BuildContext context, WidgetRef ref) {
    final roomIdController = TextEditingController(
      text: tournament.roomDetails?.roomId ?? '',
    );
    final passwordController = TextEditingController(
      text: tournament.roomDetails?.password ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Update Room Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomIdController,
              decoration: const InputDecoration(labelText: 'Room ID'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              final newDetails = RoomDetails(
                roomId: roomIdController.text.trim(),
                password: passwordController.text.trim(),
              );

              try {
                await ref
                    .read(tournamentServiceProvider)
                    .updateRoomDetails(tournament.id, newDetails);

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Room details updated!')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}

class TournamentRoomInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const TournamentRoomInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'Monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 14, color: colorScheme.secondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PRIZE DISTRIBUTION ──────────────────────────────────────────────────────

class TournamentPrizeDistribution extends StatelessWidget {
  final TournamentModel tournament;
  const TournamentPrizeDistribution({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TournamentSectionHeader(title: 'PRIZE POOL'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TournamentPrizeCard(
              place: '2nd',
              amount: '₹${tournament.prizeDistribution.second}',
              accentColor: const Color(0xFFC0C0C0),
              isMain: false,
            ),
            const SizedBox(width: 12),
            TournamentPrizeCard(
              place: '1st',
              amount: '₹${tournament.prizeDistribution.first}',
              accentColor: const Color(0xFFFFD166),
              isMain: true,
            ),
            const SizedBox(width: 12),
            TournamentPrizeCard(
              place: '3rd',
              amount: '₹${tournament.prizeDistribution.third}',
              accentColor: const Color(0xFFCD7F32),
              isMain: false,
            ),
          ],
        ),
      ],
    );
  }
}

class TournamentPrizeCard extends StatelessWidget {
  final String place;
  final String amount;
  final Color accentColor;
  final bool isMain;

  const TournamentPrizeCard({
    super.key,
    required this.place,
    required this.amount,
    required this.accentColor,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMain ? 24 : 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: isMain ? accentColor : colorScheme.outline.withValues(alpha: 0.2),
            width: isMain ? 2 : 1,
          ),
          boxShadow: isMain
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              isMain ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded,
              color: accentColor,
              size: isMain ? 32 : 24,
            ),
            const SizedBox(height: 12),
            Text(
              place,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: isMain ? 18 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TOURNAMENT RULES ────────────────────────────────────────────────────────

class TournamentRules extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentRules({super.key, required this.tournament});

  @override
  State<TournamentRules> createState() => _TournamentRulesState();
}

class _TournamentRulesState extends State<TournamentRules> {
  final Map<String, bool> _expanded = {
    'General': true,
    'Gameplay': false,
    'Policy': false,
  };

  @override
  Widget build(BuildContext context) {
    final rulesLines = widget.tournament.rulesText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TournamentSectionHeader(title: 'RULES & INFO'),
        const SizedBox(height: 16),
        TournamentRuleAccordion(
          title: 'General Requirements',
          items: rulesLines,
          isExpanded: _expanded['General']!,
          onToggle: (v) => setState(() => _expanded['General'] = v),
        ),
        TournamentRuleAccordion(
          title: 'Gameplay Settings',
          items: const [
            'Match settings: Standard Competitive',
            'All map picks are random unless specified',
            'Admin decisions are final',
          ],
          isExpanded: _expanded['Gameplay']!,
          onToggle: (v) => setState(() => _expanded['Gameplay'] = v),
        ),
        TournamentRuleAccordion(
          title: 'Fair Play Policy',
          items: const [
            'Anti-cheat must be enabled at all times',
            'No toxic behavior or harassment',
            'Report any exploits immediately',
          ],
          isExpanded: _expanded['Policy']!,
          onToggle: (v) => setState(() => _expanded['Policy'] = v),
        ),
      ],
    );
  }
}

class TournamentRuleAccordion extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  const TournamentRuleAccordion({
    super.key,
    required this.title,
    required this.items,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => onToggle(!isExpanded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            trailing: Icon(
              isExpanded ? Icons.remove_rounded : Icons.add_rounded,
              color: colorScheme.primary,
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: items.map((t) => TournamentRuleItem(text: t)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TournamentRuleItem extends StatelessWidget {
  final String text;
  const TournamentRuleItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
