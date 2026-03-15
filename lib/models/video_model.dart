import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String youtubeVideoId;
  final String description;
  final String addedByUserId;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.youtubeVideoId,
    required this.description,
    required this.addedByUserId,
    required this.createdAt,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String id) {
    return VideoModel(
      id: id,
      title: map['title'] ?? '',
      youtubeVideoId: map['youtubeVideoId'] ?? '',
      description: map['description'] ?? '',
      addedByUserId: map['addedByUserId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'youtubeVideoId': youtubeVideoId,
    'description': description,
    'addedByUserId': addedByUserId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
