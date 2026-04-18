import 'package:eagle_esports/core/routes/route_names.dart';
import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/team/presentation/providers/team_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/shared/models/users_model.dart';
import 'package:eagle_esports/features/video/data/repositories/upload_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_grid.dart';
import '../widgets/profile_tournament_list.dart';
import '../widgets/profile_menu_tiles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
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
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final uploadRepo = UploadRepository();
        final avatarDataUri = await uploadRepo.uploadAvatarBytes(
          user.uid,
          bytes,
        );
        await ref
            .read(authServiceProvider)
            .updateUserAvatar(user.uid, avatarDataUri);
        // Refresh the user so the new avatar shows immediately
        ref.invalidate(currentUserProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update avatar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          title: Text(
            'LOG OUT',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          content: Text(
            'Are you sure you want to end your session?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final appGradient = Theme.of(context).extension<AppGradients>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: userAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);
          final publicAsync = ref.watch(publicTournamentsProvider);

          return Container(
            decoration: BoxDecoration(gradient: appGradient?.background),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),

                  // ── Header Section ──
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      user: user,
                      isUploading: _isUploading,
                      onPickImage: () => _pickAndUploadImage(user),
                    ),
                  ),

                  // ── Stats Section ──
                  SliverToBoxAdapter(
                    child: joinedTeamsAsync.when(
                      data: (teams) =>
                          ProfileStatsGrid(tournamentCount: teams.length),
                      loading: () => const ProfileStatsGrid(tournamentCount: 0),
                      error: (_, _) =>
                          const ProfileStatsGrid(tournamentCount: 0),
                    ),
                  ),

                  // ── Tournament List Section ──
                  SliverToBoxAdapter(
                    child: publicAsync.maybeWhen(
                      data: (allTournaments) {
                        return joinedTeamsAsync.maybeWhen(
                          data: (teams) {
                            final joinedIds = teams
                                .map((t) => t.tournamentId)
                                .toSet();
                            final myTournaments =
                                allTournaments
                                    .where((t) => joinedIds.contains(t.id))
                                    .toList()
                                  ..sort(
                                    (a, b) =>
                                        b.createdAt.compareTo(a.createdAt),
                                  );

                            return ProfileTournamentList(
                              tournaments: myTournaments.take(3).toList(),
                              onViewAll: () {
                                ref
                                    .read(tournamentFilterProvider.notifier)
                                    .setFilter(TournamentFilter.joined);
                                context.goNamed(RouteNames.home);
                              },
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ),

                  // ── Menu Options Section ──
                  SliverToBoxAdapter(
                    child: ProfileMenuTiles(
                      onSettingsTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings feature coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          ),
                      onLogoutTap: _logout,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
