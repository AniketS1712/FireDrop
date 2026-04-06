import 'dart:ui';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/widgets/nav_item.dart';
import 'package:firedrop/shared/widgets/states/coming_soon.dart';
import 'package:flutter/material.dart';
import 'package:firedrop/features/organizer/dashboard/presentation/widgets/header.dart';
import 'package:firedrop/features/organizer/dashboard/presentation/screens/organizer_dashboard_screen.dart';
import 'package:firedrop/features/profile/presentation/screens/organizer_profile_screen.dart';
import 'package:firedrop/features/tournament/presentation/screens/organizer_tournaments_screen.dart';
import 'package:firedrop/shared/widgets/top_safe_area.dart';

class OrganizerMainShell extends StatefulWidget {
  const OrganizerMainShell({super.key});

  @override
  State<OrganizerMainShell> createState() => _OrganizerMainShellState();
}

class _OrganizerMainShellState extends State<OrganizerMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OrganizerDashboardScreen(),
    const OrganizerTournamentsScreen(),
    const ComingSoonScreen(title: 'Reports'),
    const OrganizerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = theme.extension<AppGradients>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradients.background),
        child: SafeArea(
          child: Column(
            children: [
              const TopSafeArea(),
              // Only show dashboard header when NOT on profile tab
              if (_currentIndex != 3) const DashboardHeader(),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _OrganizerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// ORGANIZER BOTTOM NAV — Glassmorphic style matching MainBottomNav
// ════════════════════════════════════════════════════════════════════════════════

class _OrganizerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _OrganizerBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: AppSizes.space8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(AppSizes.space8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.onSurface.withAlpha(30),
                      colorScheme.onSurface.withAlpha(30),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    NavItem(
                      icon: Icons.sports_esports_rounded,
                      label: 'Tournaments',
                      isSelected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
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
