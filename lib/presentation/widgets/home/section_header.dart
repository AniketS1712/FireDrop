import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLiveDot;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLiveDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: textTheme.titleLarge),
                if (showLiveDot) ...[
                  const SizedBox(width: AppSizes.space8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.error.withValues(alpha: 0.47),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: scheme.onSurfaceVariant,
          size: AppSizes.iconMd,
          fontWeight: FontWeight.w900,
        ),
      ],
    );
  }
}
