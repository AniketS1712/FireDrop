import 'package:firedrop/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final gradients = Theme.of(context).extension<AppGradients>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradients.background),
        child: SafeArea(child: Center(child: child)),
      ),
    );
  }
}
