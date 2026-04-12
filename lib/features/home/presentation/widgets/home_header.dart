import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;

  const HomeHeader({
    super.key,
    required this.username,
    this.onSearch,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final gradients = Theme.of(context).extension<AppGradients>();

    return Row(
      children: [
        // ── Avatar with Gradient Border ──
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradients?.primary,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(80),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.surface,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.space12),

        // ── Username ──
        Expanded(
          child: Text(
            username.toUpperCase(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ── Action Buttons ──
        _HeaderAction(
          icon: Icons.search_rounded,
          onPressed: onSearch,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AppSizes.space8),
        _HeaderAction(
          icon: Icons.notifications_none_rounded,
          onPressed: onNotifications,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _HeaderAction({
    required this.icon,
    this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: colorScheme.onSurface, size: 22),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
