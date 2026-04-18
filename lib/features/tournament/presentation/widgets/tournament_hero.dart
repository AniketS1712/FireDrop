import 'package:flutter/material.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/core/constant/app_enums.dart';

class TournamentHero extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentHero({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: TournamentHeaderButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        TournamentHeaderButton(icon: Icons.share_rounded, onPressed: () {}),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Hero(
              tag: 'tournament_image_${tournament.id}',
              child: Image.network(
                tournament.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, color: colorScheme.primary),
                ),
              ),
            ),
            // Multi-stage overlay for punchy look
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.1),
                    Colors.transparent,
                    colorScheme.surface.withValues(alpha: 0.6),
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
            // Floating Status Badge at bottom left
            Positioned(
              bottom: 16,
              left: 20,
              child: TournamentStatusBadge(status: tournament.status),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const TournamentHeaderButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.onSurface, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;
  const TournamentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color color;
    String text = status.name.toUpperCase().replaceAll('_', ' ');

    switch (status) {
      case TournamentStatus.live:
        color = colorScheme.error;
        break;
      case TournamentStatus.upcoming:
        color = colorScheme.primary;
        break;
      case TournamentStatus.registrationOpen:
        color = colorScheme.primary; // Kept consistent with user's last manual change
        break;
      default:
        color = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == TournamentStatus.live)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
