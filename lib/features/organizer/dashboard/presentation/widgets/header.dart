import 'package:eagle_esports/core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizer = ref.watch(currentUserProvider).value;
    final name = organizer?.name ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'O';
    final theme = Theme.of(context);
    final colorsScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
        AppSizes.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorsScheme.primary, width: 2),
            ),
            child: Center(
              child: Text(initials, style: textScheme.headlineMedium),
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Text(
              name,
              style: textScheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: colorsScheme.primary, width: 0.3),
              color: colorsScheme.primary.withAlpha(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.video_library_rounded,
                color: colorsScheme.secondary,
              ),
              onPressed: () => context.pushNamed(RouteNames.videos),
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: colorsScheme.primary, width: 0.3),
              color: colorsScheme.primary.withAlpha(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none_rounded,
                color: colorsScheme.secondary,
              ),
              onPressed: () => context.pushNamed(RouteNames.notifications),
            ),
          ),
        ],
      ),
    );
  }
}
