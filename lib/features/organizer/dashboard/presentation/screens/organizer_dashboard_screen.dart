import 'package:eagle_esports/features/organizer/dashboard/presentation/screens/tournament_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';

import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/stats_grid.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/quick_management.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';

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

  void _showSnack(String msg, Color color, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
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
      showDragHandle: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TournamentSheet(organizerId: organizer.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizer = ref.watch(currentUserProvider).value;
    final uid = organizer?.uid ?? '';
    final tournamentsAsync = ref.watch(organizerTournamentsProvider(uid));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          tournamentsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (list) =>
                SliverToBoxAdapter(child: StatsGrid(tournaments: list)),
          ),
          SliverToBoxAdapter(
            child: QuickManagement(
              onTapCreate: _openCreateSheet,
              onTapReports: () {
                _showSnack(
                  'Analytics reports coming soon!',
                  colorScheme.secondary,
                  isError: false,
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.space32)),
        ],
      ),
    );
  }
}
