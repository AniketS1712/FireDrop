import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/video_model.dart';
import 'package:eagle_esports/features/video/data/repositories/video_repository.dart';
import 'package:eagle_esports/features/video/data/services/video_service.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository();
});

final videoServiceProvider = Provider<VideoService>((ref) {
  final repo = ref.watch(videoRepositoryProvider);
  return VideoService(repo);
});

final videosProvider = StreamProvider<List<VideoModel>>((ref) {
  final service = ref.watch(videoServiceProvider);
  return service.getVideos();
});
