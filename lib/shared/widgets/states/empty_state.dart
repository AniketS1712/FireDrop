import 'package:flutter/material.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String subMessage;

  const EmptyState({
    super.key,
    this.message = 'No tournaments found',
    this.subMessage = 'Join Some Tournaments',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space40,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline),
              ),
              child: Icon(
                Icons.sports_esports_outlined,
                color: scheme.onSurfaceVariant.withAlpha(150),
                size: 32,
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            Text(
              message,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.space8),
            Text(
              subMessage,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
