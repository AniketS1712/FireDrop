import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

Widget buildField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  required String hint,
  required ColorScheme scheme,
  required TextTheme textTheme,
  bool obscure = false,
  Widget? suffix,
  String? Function(String?)? validator,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius16),
    borderSide: BorderSide(color: scheme.primary, width: 1.5),
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius16),
    borderSide: BorderSide(color: scheme.primary, width: 1),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: textTheme.labelLarge?.copyWith(color: scheme.primary)),

      const SizedBox(height: AppSizes.space8),

      TextFormField(
        controller: controller,
        obscureText: obscure,
        style: textTheme.bodyMedium,

        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return "Required field";
              }
              return null;
            },

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),

          prefixIcon: Icon(icon, color: scheme.primary),

          suffixIcon: suffix,

          filled: true,
          fillColor: scheme.surfaceContainer,

          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,

          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSizes.space16,
            horizontal: AppSizes.space8,
          ),
        ),
      ),
    ],
  );
}
