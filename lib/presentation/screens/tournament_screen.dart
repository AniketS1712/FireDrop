import 'package:firedrop/core/widgets/top_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/presentation/screens/team_selection_screen.dart';
import 'package:firedrop/presentation/screens/my_team_screen.dart';
import 'package:firedrop/models/tournaments_model.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:firedrop/presentation/providers/team_providers.dart';
import 'package:firedrop/presentation/providers/tournament_providers.dart';
import 'package:firedrop/presentation/screens/player_leaderboard_screen.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const TournamentScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  final Map<String, bool> _expandedRules = {
    'General Requirements': true,
    'Gameplay Settings': false,
    'Fair Play Policy': false,
  };

  TournamentModel get t => widget.tournament;

  String get _formattedDate =>
      "${t.startTime.day}/${t.startTime.month}/${t.startTime.year} • "
      "${t.startTime.hour}:${t.startTime.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: TopSafeArea()),
              _buildHeroSliver(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.space16),
                      _buildCountdownOrDateCard(),
                      const SizedBox(height: AppSizes.space16),
                      _buildInfoRow(),
                      const SizedBox(height: AppSizes.space16),
                      _buildRoomDetailsSection(),
                      const SizedBox(height: AppSizes.space24),
                      _buildTitleAndDescription(context),
                      const SizedBox(height: AppSizes.space24),
                      _buildPrizeDistribution(context),
                      const SizedBox(height: AppSizes.space24),
                      _buildRulesSection(context),
                      if (t.isCompleted) ...[
                        const SizedBox(height: AppSizes.space24),
                        _buildLeaderboardSection(context),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ─── Hero Sliver ────────────────────────────────────────────────────────────
  Widget _buildHeroSliver(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      primary: false,
      backgroundColor: scheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.surface.withAlpha(200),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_left, color: scheme.onSurface, size: 22),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.surface.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share_outlined,
              color: scheme.onSurface,
              size: 18,
            ),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            Image.network(t.imageUrl, fit: BoxFit.cover),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0x7C000000),
                    scheme.surface,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Status badge
            Positioned(
              bottom: 20,
              left: AppSizes.space16,
              child: _StatusBadge(status: t.status, scheme: scheme),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date / Prize Card ──────────────────────────────────────────────────────
  Widget _buildCountdownOrDateCard() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space24,
        vertical: AppSizes.space16,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'START TIME',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: scheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formattedDate,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: scheme.outline),
          const SizedBox(width: AppSizes.space16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PRIZE POOL',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${t.prizePool}',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Room Details Section ──────────────────────────────────────────────────
  Widget _buildRoomDetailsSection() {
    final scheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isOrganizer =
        user?.uid == t.organizerId || user?.role == UserRole.admin;

    final hasRoom =
        t.roomDetails != null &&
        t.roomDetails!.roomId != null &&
        t.roomDetails!.roomId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(isOrganizer ? 30 : 50),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(
          color: scheme.primary.withAlpha(isOrganizer ? 50 : 100),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'ROOM DETAILS',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (isOrganizer)
                TextButton.icon(
                  onPressed: _showEditRoomDetailsDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: scheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (hasRoom) ...[
            _roomInfoRow('Room ID', t.roomDetails!.roomId!, scheme),
            const SizedBox(height: 8),
            _roomInfoRow('Password', t.roomDetails!.password ?? 'None', scheme),
          ] else
            Text(
              isOrganizer
                  ? 'No room details set yet. Update them now.'
                  : 'Room details will be shown here when the match starts.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                fontStyle: isOrganizer ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomInfoRow(String label, String value, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Monospace',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              color: scheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  void _showEditRoomDetailsDialog() {
    final roomIdController = TextEditingController(
      text: t.roomDetails?.roomId ?? '',
    );
    final passwordController = TextEditingController(
      text: t.roomDetails?.password ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Room Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomIdController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter room password',
              ),
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
                    .updateRoomDetails(t.id, newDetails);

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

  // ─── Info Row ───────────────────────────────────────────────────────────────
  Widget _buildInfoRow() {
    return Row(
      children: [
        _infoCard(Icons.people_alt_outlined, 'SLOTS', '${t.maxSlots}'),
        const SizedBox(width: AppSizes.space16),
        _infoCard(
          Icons.sports_esports_outlined,
          'MODE',
          t.gameMode.name.toUpperCase(),
        ),
        const SizedBox(width: AppSizes.space16),
        _infoCard(
          Icons.monetization_on_outlined,
          'ENTRY',
          t.entryFee == 0 ? 'FREE' : '₹${t.entryFee}',
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Title & Description ────────────────────────────────────────────────────
  Widget _buildTitleAndDescription(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with left accent bar
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: Text(
                t.title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        Text(
          t.description,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // ─── Prize Distribution ─────────────────────────────────────────────────────
  Widget _buildPrizeDistribution(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Prize Distribution'),
        const SizedBox(height: AppSizes.space16),
        Row(
          children: [
            _podiumCard(
              '2nd',
              '₹${t.prizeDistribution.second}',
              const Color(0xFFC0C0C0),
              Icons.workspace_premium,
            ),
            const SizedBox(width: AppSizes.space8),
            _podiumCard(
              '1st',
              '₹${t.prizeDistribution.first}',
              const Color(0xFFFFD700),
              Icons.emoji_events,
              isFirst: true,
            ),
            const SizedBox(width: AppSizes.space8),
            _podiumCard(
              '3rd',
              '₹${t.prizeDistribution.third}',
              const Color(0xFFCD7F32),
              Icons.workspace_premium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _podiumCard(
    String place,
    String amount,
    Color accentColor,
    IconData icon, {
    bool isFirst = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isFirst ? AppSizes.space24 : AppSizes.space16,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: isFirst ? accentColor.withAlpha(200) : scheme.outline,
            width: isFirst ? 1.5 : 1,
          ),
          boxShadow: isFirst
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: isFirst ? 28 : 22),
            const SizedBox(height: 8),
            Text(
              place,
              style: TextStyle(
                color: accentColor,
                fontSize: isFirst ? 16 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: isFirst ? 15 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Rules Section ──────────────────────────────────────────────────────────
  Widget _buildRulesSection(BuildContext context) {
    // Split rulesText into lines for bullet points
    final rulesLines = t.rulesText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Tournament Rules'),
        const SizedBox(height: AppSizes.space16),
        // General Requirements (from rulesText)
        _ruleAccordion('General Requirements', rulesLines),
        _ruleAccordion('Gameplay Settings', const [
          'All matches played on official servers.',
          'Custom loadouts permitted within ruleset.',
          'Pause requests via admin only.',
        ]),
        _ruleAccordion('Fair Play Policy', const [
          'Zero tolerance for cheating or exploits.',
          'Disputes must be reported within 10 minutes.',
          'Coaches cannot communicate during rounds.',
        ]),
      ],
    );
  }

  Widget _ruleAccordion(String title, List<String> items) {
    final scheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedRules[title] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.space8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedRules[title] = !isExpanded),
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space16,
                vertical: AppSizes.space16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: scheme.outline),
            Padding(
              padding: const EdgeInsets.all(AppSizes.space16),
              child: Column(
                children: items.map((t) => _bulletItem(t, scheme)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bulletItem(String text, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Leaderboard Section (shown when tournament is completed) ───────────────
  Widget _buildLeaderboardSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerLeaderboardScreen(tournament: t),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColorTokens.gold.withAlpha(25),
              AppColorTokens.primary.withAlpha(15),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: AppColorTokens.gold.withAlpha(100)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColorTokens.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSizes.radius16),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColorTokens.gold,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSizes.space16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap to view the full results & standings',
                    style: TextStyle(
                      color: AppColorTokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColorTokens.gold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canJoin =
        t.status == TournamentStatus.upcoming ||
        t.status == TournamentStatus.registrationOpen;

    final teamAsync = ref.watch(userTeamForTournamentProvider(t.id));
    final isRegistered = teamAsync.value != null;
    final team = teamAsync.value;

    // ── Completed: show leaderboard button ──────────────────────────────────
    if (t.isCompleted) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space16,
            AppSizes.space16,
            AppSizes.space16,
            AppSizes.space24,
          ),
          decoration: BoxDecoration(
            color: AppColorTokens.bgSecondary,
            border: const Border(top: BorderSide(color: AppColorTokens.border)),
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerLeaderboardScreen(tournament: t),
              ),
            ),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8860B), AppColorTokens.gold],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColorTokens.gold.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Default: join / view team ───────────────────────────────────────────
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          AppSizes.space16,
          AppSizes.space16,
          AppSizes.space24,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outline, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isRegistered) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MyTeamScreen(tournament: t, team: team!),
                      ),
                    );
                  } else if (canJoin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamSelectionScreen(tournament: t),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: (canJoin || isRegistered)
                        ? LinearGradient(
                            colors: [scheme.primaryContainer, scheme.primary],
                          )
                        : null,
                    color: (canJoin || isRegistered) ? null : scheme.outline,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    boxShadow: (canJoin || isRegistered)
                        ? [
                            BoxShadow(
                              color: scheme.primary.withAlpha(100),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isRegistered
                            ? 'VIEW TEAM'
                            : (canJoin
                                  ? 'JOIN TOURNAMENT'
                                  : 'REGISTRATION CLOSED'),
                        style: TextStyle(
                          color: (canJoin || isRegistered)
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant.withAlpha(150),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (canJoin || isRegistered) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: scheme.onPrimary,
                          size: 18,
                        ),
                      ],
                    ],
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

// ─── Shared Section Header ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Status Badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final TournamentStatus status;
  final ColorScheme scheme;

  const _StatusBadge({required this.status, required this.scheme});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case TournamentStatus.live:
        color = scheme.error;
        icon = Icons.circle;
        break;
      case TournamentStatus.upcoming:
        color = scheme.primary;
        icon = Icons.access_time_rounded;
        break;
      case TournamentStatus.registrationOpen:
        color = scheme.secondary;
        icon = Icons.how_to_reg_outlined;
        break;
      case TournamentStatus.completed:
        color = scheme.onSurfaceVariant;
        icon = Icons.check_circle_outline;
        break;
      case TournamentStatus.cancelled:
        color = scheme.error;
        icon = Icons.cancel_outlined;
        break;
      case TournamentStatus.draft:
        color = scheme.onSurfaceVariant.withAlpha(150);
        icon = Icons.edit_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space8,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: status == TournamentStatus.live ? 8 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
