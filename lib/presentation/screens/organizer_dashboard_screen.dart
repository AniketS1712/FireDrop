import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/widgets/top_safe_area.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/models/tournaments_model.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:firedrop/presentation/providers/tournament_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/presentation/screens/videos_screen.dart';
import 'package:firedrop/presentation/screens/profile_screen.dart';
import 'package:firedrop/presentation/screens/leaderboard_screen.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────
class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState
    extends ConsumerState<OrganizerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  TournamentStatus? _filterStatus; // null = all

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Status action helpers ─────────────────────────────────────────────────

  Future<void> _changeStatus(
    TournamentModel t,
    TournamentStatus newStatus,
  ) async {
    final service = ref.read(tournamentServiceProvider);
    try {
      switch (newStatus) {
        case TournamentStatus.live:
          await service.startTournament(t);
          break;
        case TournamentStatus.completed:
          await service.completeTournament(t);
          break;
        case TournamentStatus.cancelled:
          await service.cancelTournament(t);
          break;
        default:
          break;
      }
      if (mounted) {
        _showSnack('Status updated to ${newStatus.name}', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? AppColorTokens.error
            : AppColorTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final organizer = ref.read(currentUserProvider).value;
    if (organizer == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTournamentSheet(organizerId: organizer.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizer = ref.watch(currentUserProvider).value;
    final uid = organizer?.uid ?? '';
    final tournamentsAsync = ref.watch(organizerTournamentsProvider(uid));

    return Scaffold(
      backgroundColor: AppColorTokens.bgPrimary,
      floatingActionButton: _CreateFAB(onTap: _openCreateSheet),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const PageScrollPhysics(),
          slivers: [
            // ── Top Safe Area ───────────────────────────────────────────────
            const SliverToBoxAdapter(child: TopSafeArea()),

            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(context),

            // ── Stats row ───────────────────────────────────────────────────
            tournamentsAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, _) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (list) =>
                  SliverToBoxAdapter(child: _StatsRow(tournaments: list)),
            ),

            // ── Filter chips ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _StatusFilterRow(
                selected: _filterStatus,
                onChanged: (s) => setState(() => _filterStatus = s),
              ),
            ),

            // ── Tournaments list ─────────────────────────────────────────────
            tournamentsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _DashboardShimmer()),
              error: (e, _) =>
                  SliverToBoxAdapter(child: _ErrorView(message: e.toString())),
              data: (list) {
                final filtered = _filterStatus == null
                    ? list
                    : list.where((t) => t.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyView());
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.space16,
                    0,
                    AppSizes.space16,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _TournamentManageCard(
                        tournament: filtered[i],
                        index: i,
                        onChangeStatus: _changeStatus,
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final organizer = ref.watch(currentUserProvider).value;
    final name = organizer?.name ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'O';

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        8, // Reduced since TopSafeArea is adaptive
        AppSizes.space16,
        AppSizes.space16,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 50, // Slightly smaller
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColorTokens.primary, AppColorTokens.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColorTokens.primary.withAlpha(102),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ORGANIZER',
                    style: TextStyle(
                      color: AppColorTokens.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Action Buttons
            IconButton(
              icon: const Icon(
                Icons.video_library_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VideosScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<TournamentModel> tournaments;
  const _StatsRow({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    final total = tournaments.length;
    final live = tournaments.where((t) => t.isLive).length;
    final upcoming = tournaments.where((t) => t.isUpcoming).length;
    final completed = tournaments.where((t) => t.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        0,
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: '$total',
            color: AppColorTokens.primary,
          ),
          const SizedBox(width: AppSizes.space8),
          _StatChip(label: 'Live', value: '$live', color: Colors.redAccent),
          const SizedBox(width: AppSizes.space8),
          _StatChip(
            label: 'Upcoming',
            value: '$upcoming',
            color: AppColorTokens.gold,
          ),
          const SizedBox(width: AppSizes.space8),
          _StatChip(
            label: 'Done',
            value: '$completed',
            color: AppColorTokens.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: color.withAlpha(64)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Filter Row ───────────────────────────────────────────────────────
class _StatusFilterRow extends StatelessWidget {
  final TournamentStatus? selected;
  final ValueChanged<TournamentStatus?> onChanged;

  const _StatusFilterRow({required this.selected, required this.onChanged});

  static const _filters = <String, TournamentStatus?>{
    'All': null,
    'Live': TournamentStatus.live,
    'Upcoming': TournamentStatus.upcoming,
    'Completed': TournamentStatus.completed,
    'Cancelled': TournamentStatus.cancelled,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSizes.space16,
        0,
        AppSizes.space16,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
        child: Row(
          children: _filters.entries.map((e) {
            final isSelected = selected == e.value;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.space8),
              child: GestureDetector(
                onTap: () => onChanged(e.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColorTokens.primary
                        : AppColorTokens.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? AppColorTokens.primary
                          : AppColorTokens.border,
                    ),
                  ),
                  child: Text(
                    e.key,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : AppColorTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Tournament Manage Card ───────────────────────────────────────────────────
class _TournamentManageCard extends StatefulWidget {
  final TournamentModel tournament;
  final int index;
  final Future<void> Function(TournamentModel, TournamentStatus) onChangeStatus;

  const _TournamentManageCard({
    required this.tournament,
    required this.index,
    required this.onChangeStatus,
  });

  @override
  State<_TournamentManageCard> createState() => _TournamentManageCardState();
}

class _TournamentManageCardState extends State<_TournamentManageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final delayed = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (widget.index * 0.08).clamp(0.0, 0.5),
        1.0,
        curve: Curves.easeOut,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(delayed);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(delayed);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _act(TournamentStatus s) async {
    if (s == TournamentStatus.live) {
      final roomDetails = await _showStartMatchDialog(context);
      if (roomDetails == null) return;

      setState(() => _loading = true);
      final updatedT = widget.tournament.copyWith(roomDetails: roomDetails);
      await widget.onChangeStatus(updatedT, s);
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    await widget.onChangeStatus(widget.tournament, s);
    if (mounted) setState(() => _loading = false);
  }

  Future<RoomDetails?> _showStartMatchDialog(BuildContext context) {
    final roomIdController = TextEditingController();
    final passwordController = TextEditingController();

    return showDialog<RoomDetails>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColorTokens.surface,
          title: const Text(
            'Start Match',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Room details. These will be securely shared with registered players.',
                style: TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: roomIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room ID',
                  labelStyle: const TextStyle(
                    color: AppColorTokens.textSecondary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorTokens.border),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorTokens.primary),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Password',
                  labelStyle: const TextStyle(
                    color: AppColorTokens.textSecondary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorTokens.border),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorTokens.primary),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColorTokens.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorTokens.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
              ),
              onPressed: () {
                final rId = roomIdController.text.trim();
                final pwd = passwordController.text.trim();
                if (rId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room ID is required')),
                  );
                  return;
                }
                Navigator.pop(context, RoomDetails(roomId: rId, password: pwd));
              },
              child: const Text(
                'Start',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColorTokens.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(color: AppColorTokens.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image + status badge ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radius16),
                    ),
                    child: Image.network(
                      t.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 130,
                        color: AppColorTokens.bgTertiary,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColorTokens.textDisabled,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radius16),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xAA000000)],
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: _StatusPill(status: t.status),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Text(
                      '₹${t.prizePool}',
                      style: const TextStyle(
                        color: AppColorTokens.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Info ──
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColorTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy • HH:mm').format(t.startTime),
                          style: const TextStyle(
                            color: AppColorTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space16),
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: AppColorTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${t.maxSlots} slots',
                          style: const TextStyle(
                            color: AppColorTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorTokens.bgTertiary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: Text(
                            t.gameMode.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColorTokens.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space16),
                    // ── Action buttons ──
                    if (_loading)
                      const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColorTokens.primary,
                          ),
                        ),
                      )
                    else
                      _ActionButtons(tournament: t, onAct: _act),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final TournamentStatus status;
  const _StatusPill({required this.status});

  Color get _color {
    switch (status) {
      case TournamentStatus.live:
        return Colors.redAccent;
      case TournamentStatus.upcoming:
        return AppColorTokens.primary;
      case TournamentStatus.registrationOpen:
        return AppColorTokens.secondary;
      case TournamentStatus.completed:
        return Colors.grey;
      case TournamentStatus.cancelled:
        return AppColorTokens.error;
      case TournamentStatus.draft:
        return AppColorTokens.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(51),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: _color.withAlpha(128)),
      ),
      child: Text(
        status.name.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final TournamentModel tournament;
  final Future<void> Function(TournamentStatus) onAct;

  const _ActionButtons({required this.tournament, required this.onAct});

  void _goToLeaderboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(tournament: tournament),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = tournament.status;
    return switch (status) {
      TournamentStatus.upcoming || TournamentStatus.registrationOpen => Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: 'Start',
              icon: Icons.play_circle_outline,
              color: AppColorTokens.success,
              onTap: () => onAct(TournamentStatus.live),
            ),
          ),
          const SizedBox(width: AppSizes.space8),
          Expanded(
            child: _ActionBtn(
              label: 'Cancel',
              icon: Icons.cancel_outlined,
              color: AppColorTokens.error,
              onTap: () => onAct(TournamentStatus.cancelled),
            ),
          ),
        ],
      ),
      TournamentStatus.live => Column(
        children: [
          _ActionBtn(
            label: 'Leaderboard',
            icon: Icons.emoji_events_rounded,
            color: AppColorTokens.gold,
            onTap: () => _goToLeaderboard(context),
          ),
          const SizedBox(height: AppSizes.space8),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Complete',
                  icon: Icons.check_circle_outline,
                  color: AppColorTokens.primary,
                  onTap: () => onAct(TournamentStatus.completed),
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: _ActionBtn(
                  label: 'Cancel',
                  icon: Icons.cancel_outlined,
                  color: AppColorTokens.error,
                  onTap: () => onAct(TournamentStatus.cancelled),
                ),
              ),
            ],
          ),
        ],
      ),
      TournamentStatus.completed => Column(
        children: [
          // Leaderboard button (primary CTA)
          _ActionBtn(
            label: 'Edit / View Leaderboard',
            icon: Icons.emoji_events_rounded,
            color: AppColorTokens.gold,
            onTap: () => _goToLeaderboard(context),
            fullWidth: true,
          ),
          const SizedBox(height: AppSizes.space8),
          // Status indicator
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColorTokens.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColorTokens.success,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Tournament Completed',
                  style: TextStyle(
                    color: AppColorTokens.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TournamentStatus.cancelled => Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColorTokens.bgTertiary,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: AppColorTokens.error, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Tournament Cancelled',
                    style: TextStyle(
                      color: AppColorTokens.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: color.withAlpha(89)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create FAB ───────────────────────────────────────────────────────────────
class _CreateFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.space24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColorTokens.primaryLight, AppColorTokens.primary],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColorTokens.primary.withAlpha(102),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.black, size: 22),
            SizedBox(width: 8),
            Text(
              'Create Tournament',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Tournament Bottom Sheet ──────────────────────────────────────────
class _CreateTournamentSheet extends ConsumerStatefulWidget {
  final String organizerId;
  const _CreateTournamentSheet({required this.organizerId});

  @override
  ConsumerState<_CreateTournamentSheet> createState() =>
      _CreateTournamentSheetState();
}

class _CreateTournamentSheetState
    extends ConsumerState<_CreateTournamentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController(text: '0');
  final _maxSlotsCtrl = TextEditingController(text: '100');
  final _prize1Ctrl = TextEditingController();
  final _prize2Ctrl = TextEditingController();
  final _prize3Ctrl = TextEditingController();

  GameMode _gameMode = GameMode.squad;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 2));
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _imageCtrl,
      _rulesCtrl,
      _entryFeeCtrl,
      _maxSlotsCtrl,
      _prize1Ctrl,
      _prize2Ctrl,
      _prize3Ctrl,
    ]) {
      c.dispose();
    }
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColorTokens.primary,
          onPrimary: Colors.black,
          surface: AppColorTokens.surfaceElevated,
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final service = ref.read(tournamentServiceProvider);
      await service.createTournament(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        gameMode: _gameMode,
        entryFee: int.tryParse(_entryFeeCtrl.text) ?? 0,
        prizeDistribution: PrizeDistribution(
          first: int.tryParse(_prize1Ctrl.text) ?? 0,
          second: int.tryParse(_prize2Ctrl.text) ?? 0,
          third: int.tryParse(_prize3Ctrl.text) ?? 0,
        ),
        maxSlots: int.tryParse(_maxSlotsCtrl.text) ?? 100,
        organizerId: widget.organizerId,
        startTime: _startTime,
        rulesText: _rulesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament created successfully! 🎉'),
            backgroundColor: AppColorTokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColorTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColorTokens.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColorTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space16,
              AppSizes.space8,
              AppSizes.space16,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColorTokens.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'New Tournament',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColorTokens.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space16,
                AppSizes.space16,
                AppSizes.space16,
                AppSizes.space16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      ctrl: _titleCtrl,
                      label: 'Tournament Title',
                      hint: 'e.g. Firedrop Pro League S6',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    _field(
                      ctrl: _descCtrl,
                      label: 'Description',
                      hint: 'Tell players about this tournament',
                      maxLines: 3,
                    ),
                    _field(
                      ctrl: _imageCtrl,
                      label: 'Banner Image URL',
                      hint: 'https://...',
                      keyboard: TextInputType.url,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    // Game Mode
                    const _FieldLabel('Game Mode'),
                    const SizedBox(height: 8),
                    Row(
                      children: GameMode.values.map((m) {
                        final sel = _gameMode == m;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSizes.space8,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _gameMode = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColorTokens.primary
                                      : AppColorTokens.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radius8,
                                  ),
                                  border: Border.all(
                                    color: sel
                                        ? AppColorTokens.primary
                                        : AppColorTokens.border,
                                  ),
                                ),
                                child: Text(
                                  m.name.toUpperCase(),
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.black
                                        : AppColorTokens.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.space16),
                    // Start Date/time
                    const _FieldLabel('Start Date & Time'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radius8),
                          border: Border.all(color: AppColorTokens.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColorTokens.primary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSizes.space8),
                            Text(
                              DateFormat(
                                'd MMM yyyy • HH:mm',
                              ).format(_startTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColorTokens.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.space16),
                    // Entry fee + max slots
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            ctrl: _entryFeeCtrl,
                            label: 'Entry Fee (₹)',
                            hint: '0',
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.space16),
                        Expanded(
                          child: _field(
                            ctrl: _maxSlotsCtrl,
                            label: 'Max Slots',
                            hint: '100',
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    // Prize distribution
                    const _FieldLabel('Prize Distribution (₹)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            ctrl: _prize1Ctrl,
                            label: '🥇 1st',
                            hint: '0',
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            ctrl: _prize2Ctrl,
                            label: '🥈 2nd',
                            hint: '0',
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            ctrl: _prize3Ctrl,
                            label: '🥉 3rd',
                            hint: '0',
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    _field(
                      ctrl: _rulesCtrl,
                      label: 'Rules & Guidelines',
                      hint: 'Enter rules, one per line...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSizes.space8),
                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: GestureDetector(
                        onTap: _submitting ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: _submitting
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppColorTokens.primaryLight,
                                      AppColorTokens.primary,
                                    ],
                                  ),
                            color: _submitting ? AppColorTokens.border : null,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                            boxShadow: _submitting
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColorTokens.primary.withAlpha(
                                        89,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'CREATE TOURNAMENT',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.space8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 4,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColorTokens.textDisabled,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColorTokens.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                borderSide: const BorderSide(color: AppColorTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                borderSide: const BorderSide(
                  color: AppColorTokens.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                borderSide: const BorderSide(color: AppColorTokens.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                borderSide: const BorderSide(
                  color: AppColorTokens.error,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColorTokens.error,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColorTokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _DashboardShimmer extends StatefulWidget {
  const _DashboardShimmer();

  @override
  State<_DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<_DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      child: Column(
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: AppSizes.space16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                gradient: LinearGradient(
                  begin: Alignment(_anim.value - 1, 0),
                  end: Alignment(_anim.value, 0),
                  colors: const [
                    AppColorTokens.surface,
                    AppColorTokens.surfaceElevated,
                    AppColorTokens.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space40,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColorTokens.border),
              ),
              child: const Icon(
                Icons.sports_esports_outlined,
                color: AppColorTokens.textDisabled,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            const Text(
              'No tournaments yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Create Tournament" to get started',
              style: TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColorTokens.error,
              size: 40,
            ),
            const SizedBox(height: AppSizes.space16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
