import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_sizes.dart';

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: textTheme.bodyLarge,
              ),
            ),
            const SizedBox(width: AppSizes.space8),
            Text(
              username,
              style: textTheme.titleMedium?.copyWith(letterSpacing: 1.4),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(onPressed: onSearch, icon: const Icon(Icons.search)),
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
      ],
    );
  }
}
