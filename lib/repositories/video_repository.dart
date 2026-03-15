import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedrop/models/video_model.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _videos => _firestore.collection('videos');

  Future<void> addVideo(VideoModel video) async {
    await _videos.doc(video.id).set(video.toMap());
  }

  Future<void> deleteVideo(String videoId) async {
    await _videos.doc(videoId).delete();
  }

  Stream<List<VideoModel>> getVideosStream() {
    return _videos.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map(
        (doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
      ).toList(),
    );
  }
}
