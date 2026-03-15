import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/routes/route_names.dart';

import 'package:firedrop/models/video_model.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:firedrop/presentation/providers/video_providers.dart';
import 'package:firedrop/presentation/widgets/loading_shimmer.dart';
import 'package:firedrop/presentation/widgets/states/empty_state.dart';
import 'package:firedrop/presentation/widgets/states/error_state.dart';

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {

  void _showAddVideoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddVideoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(videosProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isOrganizer = userAsync.value?.role == UserRole.organizer;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text('Highlights & Streams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.onSurface)),
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              onPressed: _showAddVideoSheet,
              backgroundColor: scheme.primary,
              icon: Icon(Icons.add, color: scheme.onPrimary),
              label: Text('Add Video', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
            )
          : null,
      body: videosAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (videos) {
          if (videos.isEmpty) {
            return const EmptyState(message: 'No videos available right now!');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSizes.space16, AppSizes.space16, AppSizes.space16, 100),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return _VideoCard(video: videos[index], isOrganizer: isOrganizer);
            },
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  final bool isOrganizer;

  const _VideoCard({required this.video, required this.isOrganizer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnailUrl = 'https://img.youtube.com/vi/${video.youtubeVideoId}/maxresdefault.jpg';

    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.videoPlayer, extra: video);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: scheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    thumbnailUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black12,
                        child: const Icon(Icons.video_library, size: 40),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.space8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isOrganizer)
                        Consumer(
                          builder: (context, ref, _) {
                            return IconButton(
                              icon: Icon(Icons.delete_outline, color: scheme.error),
                              onPressed: () {
                                ref.read(videoServiceProvider).deleteVideo(video.id);
                              },
                            );
                          }
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Added on ${DateFormat('d MMM yyyy').format(video.createdAt)}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVideoSheet extends ConsumerStatefulWidget {
  const _AddVideoSheet();

  @override
  ConsumerState<_AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends ConsumerState<_AddVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _videoIdCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _videoIdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception("User not logged in");

        await ref.read(videoServiceProvider).createVideo(
          title: _titleCtrl.text.trim(),
          youtubeVideoId: _videoIdCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          addedByUserId: userId,
        );

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          final scheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add video: $e'), backgroundColor: scheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radius24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.space24,
        top: AppSizes.space24,
        left: AppSizes.space24,
        right: AppSizes.space24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add YouTube Video',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.space24),
            _buildTextField(
              controller: _titleCtrl,
              hintText: 'Video Title',
              icon: Icons.title,
              scheme: scheme,
            ),
            const SizedBox(height: AppSizes.space16),
            _buildTextField(
              controller: _videoIdCtrl,
              hintText: 'YouTube Video ID (e.g. dQw4w9WgXcQ)',
              icon: Icons.video_call,
              scheme: scheme,
            ),
            const SizedBox(height: AppSizes.space16),
            _buildTextField(
              controller: _descCtrl,
              hintText: 'Description',
              icon: Icons.description,
              maxLines: 3,
              scheme: scheme,
            ),
            const SizedBox(height: AppSizes.space32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                      )
                    : const Text(
                        'UPLOAD VIDEO',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    required ColorScheme scheme,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withAlpha(100)),
        prefixIcon: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Required field';
        return null;
      },
    );
  }
}
