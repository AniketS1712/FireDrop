import 'package:flutter/material.dart';

class TournamentStepIndicator extends StatelessWidget {
  final int currentStep;

  const TournamentStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _StepItem(label: 'Template', index: 1, isActive: currentStep >= 0, isCompleted: currentStep > 0),
          _StepLine(isActive: currentStep >= 1),
          _StepItem(label: 'Details', index: 2, isActive: currentStep >= 1, isCompleted: currentStep > 1),
          _StepLine(isActive: currentStep >= 2),
          _StepItem(label: 'Preview', index: 3, isActive: currentStep >= 2, isCompleted: currentStep > 2),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final int index;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.label,
    required this.index,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? colorScheme.primary : (isActive ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? colorScheme.primary : color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 2,
          color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
