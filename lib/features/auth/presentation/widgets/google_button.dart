import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const GoogleButton({
    super.key,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: disabled
                ? scheme.outlineVariant
                : scheme.primary.withAlpha(160),
            width: 1.5,
          ),
          color: disabled
              ? scheme.surfaceContainer
              : scheme.onSurface.withAlpha(15),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSecondary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.google,
                    color: scheme.onSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Text(
                    'Continue with Google',
                    style: textTheme.labelLarge?.copyWith(
                      color: disabled
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
