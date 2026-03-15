import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:firedrop/presentation/providers/team_providers.dart';
import 'package:firedrop/presentation/providers/tournament_providers.dart';
import 'package:firedrop/models/tournaments_model.dart';
import 'package:firedrop/models/users_model.dart';
import 'package:firedrop/repositories/upload_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:firedrop/core/routes/route_names.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final File file = File(pickedFile.path);
        final uploadRepo = UploadRepository();
        final downloadUrl = await uploadRepo.uploadAvatar(user.uid, file);
        await ref
            .read(authServiceProvider)
            .updateUserAvatar(user.uid, downloadUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update avatar: \$e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading profile: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Not logged in',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          final initials = user.name.isNotEmpty
              ? user.name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join()
              : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.space24),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.space16),
                _buildAvatar(context, user, initials),
                const SizedBox(height: AppSizes.space24),
                Text(
                  user.name,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSizes.space8),
                Text(
                  user.email,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.space16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.space32),
                _buildStats(context, ref, user),
                const SizedBox(height: AppSizes.space32),
                _buildRecentTournaments(context, ref),
                const SizedBox(height: AppSizes.space48),
                _ProfileOption(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {},
                ),
                const SizedBox(height: AppSizes.space16),
                _ProfileOption(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: AppSizes.space16),
                _ProfileOption(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius16,
                          ),
                        ),
                        title: Text(
                          'Log Out',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'CANCEL',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius8,
                                ),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'LOG OUT',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await ref.read(authServiceProvider).signOut();
                    }
                  },
                ),
                const SizedBox(height: 100), // Bottom padding for navbar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserModel user, String initials) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _isUploading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : user.avatarUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : () => _pickAndUploadImage(user),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: colorScheme.onPrimary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, WidgetRef ref, UserModel user) {
    final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Total Wins',
                value: '0', // TODO: Implement wins in user model
              ),
            ),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Tournaments',
                value: joinedTeamsAsync.when(
                  data: (teams) => teams.length.toString(),
                  loading: () => '-',
                  error: (_, _) => '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            context,
            label: 'Total Earnings',
            value: '₹0', // TODO: Implement earnings tracking
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: _StatColumn(label: label, value: value),
    );
  }

  Widget _buildRecentTournaments(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);
    final publicAsync = ref.watch(publicTournamentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENTLY JOINED',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // To switch the tab safely, you could emit an event to the main nav
                // For now, let's just trigger updating the global filter so when they go back it's there
                ref
                    .read(tournamentFilterProvider.notifier)
                    .setFilter(TournamentFilter.joined);
                // In a production app with go_router stateful shell, you'd navigate here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to Home -> Joined Tab to view all'),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        joinedTeamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Error loading tournaments: \$e',
            style: TextStyle(color: colorScheme.error),
          ),
          data: (teams) {
            if (teams.isEmpty) {
              return Text(
                'You haven\'t joined any tournaments yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              );
            }

            return publicAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Error loading tournaments: \$e',
                style: TextStyle(color: colorScheme.error),
              ),
              data: (allTournaments) {
                // Find matching tournament models
                final joinedTournamentIds = teams
                    .map((t) => t.tournamentId)
                    .toSet();

                final myTournaments = allTournaments
                    .where((t) => joinedTournamentIds.contains(t.id))
                    .toList();

                myTournaments.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );

                final recentThree = myTournaments.take(3).toList();

                if (recentThree.isEmpty) {
                  return Text(
                    'You haven\'t joined any tournaments yet.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  );
                }

                return Column(
                  children: recentThree
                      .map((t) => _buildMiniTournamentCard(context, t))
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniTournamentCard(
    BuildContext context,
    TournamentModel tournament,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () =>
          context.pushNamed(RouteNames.tournamentDetail, extra: tournament),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space12),
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Image.network(
                tournament.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 60,
                  height: 60,
                  color: colorScheme.outlineVariant,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tournament.gameMode.name.toUpperCase()} • \$${tournament.entryFee}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Text(
          value,
          style: textTheme.headlineLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final bgColor = isDestructive
        ? colorScheme.errorContainer.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final borderColor = isDestructive
        ? colorScheme.error.withValues(alpha: 0.3)
        : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space24,
          vertical: AppSizes.space16,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
