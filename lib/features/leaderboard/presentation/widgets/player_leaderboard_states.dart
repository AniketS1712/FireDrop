import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaderboardNotPublishedView extends StatelessWidget {
  final String tournamentTitle;

  const LeaderboardNotPublishedView({super.key, required this.tournamentTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_rounded, color: colorScheme.primary, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              'RESULTS PENDING',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Official standings for "$tournamentTitle" are being finalized. Check back soon!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('GO BACK'),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardErrorView extends StatelessWidget {
  final String message;

  const LeaderboardErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 56),
          const SizedBox(height: 16),
          Text(
            'OOPS! SOMETHING WENT WRONG',
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GO BACK')),
        ],
      ),
    );
  }
}

class LeaderboardPublishedChip extends StatelessWidget {
  final DateTime updatedAt;

  const LeaderboardPublishedChip({super.key, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
            const SizedBox(width: 8),
            Text(
              'OFFICIALLY PUBLISHED • ${DateFormat('MMM dd, HH:mm').format(updatedAt)}',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
