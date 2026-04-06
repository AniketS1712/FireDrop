import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/shared/models/leaderboard_template.dart';

/// A single standing row from the published leaderboard.
class PublishedStanding {
  final String teamId;
  final String teamName;
  final String leaderId;
  final int position;
  final int kills;
  final int totalPoints;
  final int rank;

  const PublishedStanding({
    required this.teamId,
    required this.teamName,
    required this.leaderId,
    required this.position,
    required this.kills,
    required this.totalPoints,
    required this.rank,
  });

  factory PublishedStanding.fromMap(Map<String, dynamic> map) {
    return PublishedStanding(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      leaderId: map['leaderId'] ?? '',
      position: (map['position'] as int?) ?? 0,
      kills: (map['kills'] as int?) ?? 0,
      totalPoints: (map['totalPoints'] as int?) ?? 0,
      rank: (map['rank'] as int?) ?? 0,
    );
  }
}

/// Wraps the entire published leaderboard document.
class PublishedLeaderboard {
  final String tournamentId;
  final bool isPublished;
  final List<PublishedStanding> standings;
  final DateTime? updatedAt;
  final LeaderboardTemplate template;

  const PublishedLeaderboard({
    required this.tournamentId,
    required this.isPublished,
    required this.standings,
    this.updatedAt,
    this.template = LeaderboardTemplate.classic,
  });

  factory PublishedLeaderboard.fromMap(
    Map<String, dynamic> map,
    String tournamentId,
  ) {
    final rawStandings = (map['standings'] as List?) ?? [];
    final standings = rawStandings
        .map((s) => PublishedStanding.fromMap(Map<String, dynamic>.from(s)))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    DateTime? updatedAt;
    final raw = map['updatedAt'];
    if (raw is Timestamp) updatedAt = raw.toDate();

    final templateStr = map['template'] as String? ?? 'classic';
    final template = LeaderboardTemplate.values.firstWhere(
      (e) => e.name == templateStr,
      orElse: () => LeaderboardTemplate.classic,
    );

    return PublishedLeaderboard(
      tournamentId: tournamentId,
      isPublished: map['isPublished'] ?? false,
      standings: standings,
      updatedAt: updatedAt,
      template: template,
    );
  }
}

// ─── Riverpod stream provider ─────────────────────────────────────────────────

/// Streams the published leaderboard document for [tournamentId].
/// Emits null if no document exists yet.
final publishedLeaderboardProvider =
    StreamProvider.family<PublishedLeaderboard?, String>((ref, tournamentId) {
  return FirebaseFirestore.instance
      .collection('leaderboards')
      .doc(tournamentId)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return PublishedLeaderboard.fromMap(snap.data()!, tournamentId);
  });
});
