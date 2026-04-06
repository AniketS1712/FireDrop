import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class QuickManagement extends StatelessWidget {
  final VoidCallback? onTapCreate;
  final VoidCallback? onTapReports;

  const QuickManagement({super.key, this.onTapCreate, this.onTapReports});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Management',
            style: textScheme.headlineLarge?.copyWith(
              shadows: [
                Shadow(color: colorScheme.primary, blurRadius: 10),
                Shadow(color: colorScheme.primary, blurRadius: 10),
                Shadow(color: colorScheme.primary, blurRadius: 10),
                Shadow(color: colorScheme.secondary, blurRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSizes.space16,
            crossAxisSpacing: AppSizes.space16,
            childAspectRatio: 1.5,
            children: [
              _QuickManagementCard(
                title: 'Create\nTournament',
                icon: Icons.add_rounded,
                color: colorScheme.primary,
                onTap: onTapCreate,
              ),
              _QuickManagementCard(
                title: 'Analytics\nReports',
                icon: Icons.bar_chart_rounded,
                color: colorScheme.secondary,
                onTap: onTapReports,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickManagementCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickManagementCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: color),
          boxShadow: [
            BoxShadow(color: color.withAlpha(50), blurRadius: 10),
            BoxShadow(color: Colors.black38),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.space8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: [
                  BoxShadow(color: color.withAlpha(30), blurRadius: 10),
                  BoxShadow(color: color.withAlpha(30), blurRadius: 10),
                ],
              ),
              child: Icon(icon, color: color, size: AppSizes.iconXl),
            ),
            const SizedBox(height: AppSizes.space8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textScheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
