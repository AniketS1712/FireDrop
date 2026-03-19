import 'package:flutter/material.dart';

class TopSafeArea extends StatelessWidget {
  const TopSafeArea({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.of(context).padding.top);
  }
}
