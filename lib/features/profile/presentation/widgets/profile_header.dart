import 'package:flutter/material.dart';
import 'package:eagle_esports/shared/models/users_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isUploading;
  final VoidCallback onPickImage;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isUploading,
    required this.onPickImage,
  });

  String get _initials {
    if (user.name.isEmpty) return 'U';
    return user.name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar Section with Glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                  image: user.avatarUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(user.avatarUrl), fit: BoxFit.cover)
                      : null,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: (user.avatarUrl.isEmpty && !isUploading)
                    ? Center(
                        child: Text(
                          _initials,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : isUploading
                        ? Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2))
                        : null,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
                      ],
                    ),
                    child: Icon(Icons.camera_alt_rounded, size: 16, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // User Info
          Text(
            user.name.toUpperCase(),
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary.withValues(alpha: 0.1), colorScheme.primary.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  (user.role.name == 'player' ? 'PRO GAMER' : user.role.name.toUpperCase()),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
