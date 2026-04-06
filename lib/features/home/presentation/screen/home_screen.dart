import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firedrop/core/routes/route_names.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:firedrop/shared/widgets/top_safe_area.dart';
import 'package:firedrop/features/home/presentation/widgets/section_header.dart';
import 'package:firedrop/features/home/presentation/widgets/home_chips.dart';
import 'package:firedrop/features/home/presentation/widgets/home_header.dart';
import 'package:firedrop/shared/widgets/loading_shimmer.dart';
import 'package:firedrop/shared/widgets/main_bottom_nav.dart';
import 'package:firedrop/features/home/presentation/widgets/match_card.dart';
import 'package:firedrop/shared/widgets/states/empty_state.dart';
import 'package:firedrop/shared/widgets/states/error_state.dart';
import 'package:firedrop/shared/widgets/animations/animated_tournament_card.dart';
import 'package:firedrop/features/video/presentation/screens/videos_screen.dart';
import 'package:firedrop/features/profile/presentation/screens/profile_screen.dart';
import 'package:firedrop/features/home/presentation/screen/matches_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredTournamentsProvider);
    final statusFilter = ref.watch(tournamentFilterProvider);

    // Keep the background status-sync stream alive while this screen is mounted.
    ref.watch(tournamentStatusSyncProvider);

    final user = ref.watch(currentUserProvider).value;
    final name = user?.name ?? '';

    final gradients = Theme.of(context).extension<AppGradients>()!;

    String sectionTitle;
    String sectionSubtitle;
    bool showLiveDot = false;

    switch (statusFilter) {
      case TournamentFilter.live:
        sectionTitle = 'Live Now';
        sectionSubtitle = 'Join before slots fill up';
        showLiveDot = true;
        break;

      case TournamentFilter.upcoming:
        sectionTitle = 'Upcoming Tournaments';
        sectionSubtitle = 'Register and get ready to compete';
        break;

      case TournamentFilter.joined:
        sectionTitle = 'Your Tournaments';
        sectionSubtitle = 'Tournaments you have joined';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradients.background),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const PageScrollPhysics(),
                slivers: [
                  // ── Safe Area Top Padding ──────────────────────────────────────
                  const SliverToBoxAdapter(child: TopSafeArea()),

                  // ── Header ────────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.space16,
                        0,
                        AppSizes.space16,
                        0,
                      ),
                      child: HomeHeader(username: name),
                    ),
                  ),

                  // ── Filter Chips ───────────────────────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, AppSizes.space24, 0, 0),
                      child: HomeChips(),
                    ),
                  ),

                  // ── Section Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.space16),
                      child: SectionHeader(
                        title: sectionTitle,
                        subtitle: sectionSubtitle,
                        showLiveDot: showLiveDot,
                      ),
                    ),
                  ),

                  // ── Tournament List ───────────────────────────────────────────
                  filteredAsync.when(
                    loading: () =>
                        const SliverToBoxAdapter(child: LoadingShimmer()),

                    error: (e, _) => SliverToBoxAdapter(
                      child: ErrorState(message: e.toString()),
                    ),

                    data: (tournaments) => tournaments.isEmpty
                        ? const SliverToBoxAdapter(child: EmptyState())
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.space16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final tournament = tournaments[index];

                                return AnimatedTournamentCard(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSizes.space16,
                                    ),
                                    child: MatchCard(
                                      tournament: tournament,
                                      onJoin: () {
                                        context.pushNamed(
                                          RouteNames.tournamentDetail,
                                          extra: tournament,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }, childCount: tournaments.length),
                            ),
                          ),
                  ),

                  // ── Bottom spacing for navigation bar ─────────────────────────
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            const VideosScreen(),

            const MatchesScreen(),

            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
