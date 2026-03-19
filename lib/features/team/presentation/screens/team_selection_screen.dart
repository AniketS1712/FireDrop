import 'package:firedrop/core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:go_router/go_router.dart';

class TeamSelectionScreen extends StatelessWidget {
  final TournamentModel tournament;

  const TeamSelectionScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColorTokens.bgPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join Tournament',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              tournament.title,
              style: const TextStyle(
                color: AppColorTokens.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            const Text(
              'Tournament Entry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            const Text(
              'Choose how you want to enter the tournament.',
              style: TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSizes.space48),
            _SelectionOptionCard(
              title: 'Create Room',
              description: 'Form a new squad and invite your friends to join.',
              icon: Icons.add_circle_outline,
              accentColor: AppColorTokens.primary,
              onTap: () {
                context.pushNamed(RouteNames.createRoom, extra: tournament);
              },
            ),
            const SizedBox(height: AppSizes.space24),
            _SelectionOptionCard(
              title: 'Join Room',
              description: 'Already have an invite? Enter the team code here.',
              icon: Icons.login_rounded,
              accentColor: AppColorTokens.secondary,
              onTap: () {
                context.pushNamed(RouteNames.joinRoom, extra: tournament);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _SelectionOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space24),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: AppColorTokens.border),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(20),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withAlpha(100)),
              ),
              child: Icon(icon, color: accentColor, size: 32),
            ),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColorTokens.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.space8),
            Icon(Icons.chevron_right, color: accentColor, size: 28),
          ],
        ),
      ),
    );
  }
}
