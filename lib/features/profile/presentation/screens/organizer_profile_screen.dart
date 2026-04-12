import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/shared/models/users_model.dart';
import 'package:eagle_esports/features/video/data/repositories/upload_repository.dart';

class OrganizerProfileScreen extends ConsumerStatefulWidget {
  const OrganizerProfileScreen({super.key});

  @override
  ConsumerState<OrganizerProfileScreen> createState() =>
      _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends ConsumerState<OrganizerProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

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
            SnackBar(content: Text('Failed to update avatar: $e')),
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
    final gradients = Theme.of(context).extension<AppGradients>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradients.background),
        child: userAsync.when(
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

            final uid = user.uid;
            final tournamentsAsync = ref.watch(
              organizerTournamentsProvider(uid),
            );

            final initials = user.name.isNotEmpty
                ? user.name
                      .trim()
                      .split(' ')
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join()
                : 'O';

            return FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Top spacing ──
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSizes.space48),
                  ),

                  // ── Profile Header ──
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      user: user,
                      initials: initials,
                      isUploading: _isUploading,
                      onPickImage: () => _pickAndUploadImage(user),
                    ),
                  ),

                  // ── Organizer Stats ──
                  SliverToBoxAdapter(
                    child: tournamentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSizes.space32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (tournaments) {
                        final total = tournaments.length;
                        final live = tournaments.where((t) => t.isLive).length;
                        final upcoming = tournaments
                            .where((t) => t.isUpcoming)
                            .length;
                        final completed = tournaments
                            .where((t) => t.isCompleted)
                            .length;

                        return _OrganizerStatsSection(
                          totalTournaments: total,
                          liveTournaments: live,
                          upcomingTournaments: upcoming,
                          completedTournaments: completed,
                        );
                      },
                    ),
                  ),

                  // ── Quick Actions ──
                  SliverToBoxAdapter(
                    child: _SectionTitle(title: 'QUICK ACTIONS'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                      ),
                      child: Column(
                        children: [
                          _GlassActionTile(
                            icon: Icons.edit_rounded,
                            title: 'Edit Profile',
                            subtitle: 'Update your name, email & avatar',
                            accentColor: colorScheme.primary,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSizes.space12),
                          _GlassActionTile(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notifications',
                            subtitle: 'Manage push & in-app alerts',
                            accentColor: AppColorTokens.warning,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSizes.space12),
                          _GlassActionTile(
                            icon: Icons.shield_rounded,
                            title: 'Security',
                            subtitle: 'Password & two-factor settings',
                            accentColor: AppColorTokens.success,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSizes.space12),
                          _GlassActionTile(
                            icon: Icons.bar_chart_rounded,
                            title: 'Analytics',
                            subtitle: 'Deep dive into tournament metrics',
                            accentColor: colorScheme.secondary,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Account section ──
                  SliverToBoxAdapter(child: _SectionTitle(title: 'ACCOUNT')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                      ),
                      child: Column(
                        children: [
                          _GlassActionTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'FAQs, contact us, report a bug',
                            accentColor: colorScheme.onSurfaceVariant,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSizes.space12),
                          _GlassActionTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About FireDrop',
                            subtitle: 'Version, licenses & credits',
                            accentColor: colorScheme.onSurfaceVariant,
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSizes.space12),
                          _LogoutTile(
                            onTap: () => _showLogoutDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom padding ──
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        title: Text(
          'Log Out',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your organizer account?',
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
                borderRadius: BorderRadius.circular(AppSizes.radius8),
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
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// PROFILE HEADER
// ════════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final String initials;
  final bool isUploading;
  final VoidCallback onPickImage;

  const _ProfileHeader({
    required this.user,
    required this.initials,
    required this.isUploading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      child: Column(
        children: [
          // ── Avatar with glow ──
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(60),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: colorScheme.secondary.withAlpha(30),
                      blurRadius: 48,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(100),
                    width: 3,
                  ),
                ),
                child: isUploading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : user.avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 40,
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
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
              ),
              // Camera button
              Positioned(
                bottom: 4,
                right: 0,
                left: 76,
                child: GestureDetector(
                  onTap: isUploading ? null : onPickImage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space24),

          // ── Name ──
          Text(
            user.name,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.space8),

          // ── Email ──
          Text(
            user.email,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.space16),

          // ── Role badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(30),
                  colorScheme.secondary.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: colorScheme.primary.withAlpha(60)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(20),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user.role.name.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space8),

          // ── Member since ──
          Text(
            'Member since ${_formatDate(user.createdAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
          const SizedBox(height: AppSizes.space24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// ORGANIZER STATS SECTION
// ════════════════════════════════════════════════════════════════════════════════

class _OrganizerStatsSection extends StatelessWidget {
  final int totalTournaments;
  final int liveTournaments;
  final int upcomingTournaments;
  final int completedTournaments;

  const _OrganizerStatsSection({
    required this.totalTournaments,
    required this.liveTournaments,
    required this.upcomingTournaments,
    required this.completedTournaments,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      child: Column(
        children: [
          // Top row - 2 big stats
          Row(
            children: [
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Total Hosted',
                  value: '$totalTournaments',
                  accentColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.stream_rounded,
                  label: 'Live Now',
                  value: '$liveTournaments',
                  accentColor: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),
          // Bottom row - 2 stats
          Row(
            children: [
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Upcoming',
                  value: '$upcomingTournaments',
                  accentColor: AppColorTokens.warning,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.check_circle_outlined,
                  label: 'Completed',
                  value: '$completedTournaments',
                  accentColor: AppColorTokens.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space24),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// GLASS STAT CARD
// ════════════════════════════════════════════════════════════════════════════════

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _GlassStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withAlpha(12),
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(color: accentColor.withAlpha(50), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 18,
                      shadows: [Shadow(color: accentColor, blurRadius: 8)],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: AppSizes.space12),
              Text(
                value,
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: accentColor.withAlpha(80), blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ════════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        AppSizes.space8,
        AppSizes.space16,
        AppSizes.space16,
      ),
      child: Text(
        title,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// GLASS ACTION TILE
// ════════════════════════════════════════════════════════════════════════════════

class _GlassActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.space16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(10),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: accentColor.withAlpha(30)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 22,
                    shadows: [Shadow(color: accentColor, blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: AppSizes.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// LOGOUT TILE
// ════════════════════════════════════════════════════════════════════════════════

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.space16),
            decoration: BoxDecoration(
              color: colorScheme.error.withAlpha(10),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: colorScheme.error.withAlpha(40)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                    size: 22,
                    shadows: [Shadow(color: colorScheme.error, blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: AppSizes.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Out',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sign out of your organizer account',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.error.withAlpha(160),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
