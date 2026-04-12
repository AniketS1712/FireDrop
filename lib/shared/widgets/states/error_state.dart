import 'package:flutter/material.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, color: scheme.error, size: 40),
            const SizedBox(height: AppSizes.space16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.space8),
            Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
