import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final gradients = Theme.of(context).extension<AppGradients>()!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        gradient: gradients.card,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(color: scheme.onSecondary.withAlpha(180), blurRadius: 16),
        ],
      ),
      child: child,
    );
  }
}
