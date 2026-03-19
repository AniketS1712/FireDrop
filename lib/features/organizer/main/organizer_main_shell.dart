import 'package:firedrop/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firedrop/features/organizer/dashboard/presentation/widgets/header.dart';
import 'package:firedrop/features/organizer/dashboard/presentation/screens/organizer_dashboard_screen.dart';
import 'package:firedrop/features/organizer/tournaments/presentation/screens/organizer_tournaments_screen.dart';
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
    const _ComingSoonScreen(title: 'Reports'),
    const _ComingSoonScreen(title: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;
    final gradients = theme.extension<AppGradients>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradients.background),
        child: SafeArea(
          child: Column(
            children: [
              const TopSafeArea(),
              const DashboardHeader(),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSecondary.withAlpha(160),
          selectedLabelStyle: textScheme.labelMedium,
          unselectedLabelStyle: textScheme.labelMedium,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports_rounded),
              label: 'Tournaments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune_rounded),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            '$title coming soon',
            style: const TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
