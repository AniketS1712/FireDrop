import 'package:uuid/uuid.dart';
import 'package:firedrop/shared/models/video_model.dart';
import 'package:firedrop/features/video/data/repositories/video_repository.dart';

class VideoService {
  final VideoRepository _repository;

  VideoService(this._repository);

  Future<void> createVideo({
    required String title,
    required String youtubeVideoId,
    required String description,
    required String addedByUserId,
  }) async {
    final video = VideoModel(
      id: const Uuid().v4(),
      title: title,
      youtubeVideoId: youtubeVideoId,
      description: description,
      addedByUserId: addedByUserId,
      createdAt: DateTime.now(),
    );
    await _repository.addVideo(video);
  }

  Future<void> deleteVideo(String videoId) async {
    await _repository.deleteVideo(videoId);
  }

  Stream<List<VideoModel>> getVideos() {
    return _repository.getVideosStream();
  }
}
