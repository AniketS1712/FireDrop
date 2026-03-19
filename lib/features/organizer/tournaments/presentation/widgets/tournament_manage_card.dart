import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/routes/route_names.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/organizer/tournaments/presentation/widgets/status_pill.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TournamentManageCard extends StatefulWidget {
  final TournamentModel tournament;
  final int index;
  final Future<void> Function(TournamentModel, TournamentStatus) onChangeStatus;

  const TournamentManageCard({
    super.key,
    required this.tournament,
    required this.index,
    required this.onChangeStatus,
  });

  @override
  State<TournamentManageCard> createState() => _TournamentManageCardState();
}

class _TournamentManageCardState extends State<TournamentManageCard>
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
                    child: StatusPill(status: t.status),
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

class _ActionButtons extends StatelessWidget {
  final TournamentModel tournament;
  final Future<void> Function(TournamentStatus) onAct;

  const _ActionButtons({required this.tournament, required this.onAct});

  void _goToLeaderboard(BuildContext context) {
    context.pushNamed(RouteNames.leaderboard, extra: tournament);
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
        ],
      ),
      TournamentStatus.live => Column(
        children: [
          _ActionBtn(
            label: 'Edit Leaderboard',
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
            ],
          ),
        ],
      ),
      TournamentStatus.completed => Column(
        children: [
          _ActionBtn(
            label: 'View Leaderboard',
            icon: Icons.emoji_events_rounded,
            color: AppColorTokens.gold,
            onTap: () => _goToLeaderboard(context),
            fullWidth: true,
          ),
          const SizedBox(height: AppSizes.space8),
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
