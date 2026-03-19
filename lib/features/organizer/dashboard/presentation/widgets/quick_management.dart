import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class QuickManagement extends StatelessWidget {
  final VoidCallback? onTapCreate;
  final VoidCallback? onTapReports;

  const QuickManagement({super.key, this.onTapCreate, this.onTapReports});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorsScheme = theme.colorScheme;
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
            style: textScheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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
                color: colorsScheme.primary,
                onTap: onTapCreate,
              ),
              _QuickManagementCard(
                title: 'Analytics\nReports',
                icon: Icons.bar_chart_rounded,
                color: colorsScheme.secondary,
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
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.space8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: AppSizes.iconXl),
            ),
            const SizedBox(height: AppSizes.space12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textScheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
