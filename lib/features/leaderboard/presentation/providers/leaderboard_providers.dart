import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagle_esports/shared/models/leaderboard_entry.dart';
import 'package:eagle_esports/shared/models/leaderboard_template.dart';
import 'package:eagle_esports/shared/models/teams_model.dart';
import 'package:eagle_esports/shared/models/users_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Stream of teams for a tournament ────────────────────────────────────────

final tournamentTeamsProvider = StreamProvider.family<List<TeamModel>, String>((
  ref,
  tournamentId,
) {
  return FirebaseFirestore.instance
      .collection('teams')
      .where('tournamentId', isEqualTo: tournamentId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => TeamModel.fromMap(d.data(), d.id)).toList(),
      );
});

// ─── Fetch a single user display name (leader) ───────────────────────────────

final userByIdProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists || doc.data() == null) return null;
  return UserModel.fromMap(doc.data()!, doc.id);
});

// ─── Leaderboard save service ─────────────────────────────────────────────────

class LeaderboardService {
  static final _db = FirebaseFirestore.instance;

  /// Saves / overwrites the leaderboard for [tournamentId].
  ///
  /// Stores a document at  leaderboards/{tournamentId}  with:
  ///   - standings: list of {teamId, teamName, position, kills, totalPoints, rank}
  ///   - updatedAt: server timestamp
  static Future<void> saveLeaderboard({
    required String tournamentId,
    required String createdByUid,
    required List<LeaderboardEntry> entries,
    required bool isPublished,
    LeaderboardTemplate template = LeaderboardTemplate.classic,
  }) async {
    final sorted = List<LeaderboardEntry>.from(entries)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    // Assign ranks (ties share the same rank)
    int rank = 1;
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].totalPoints < sorted[i - 1].totalPoints) {
        rank = i + 1;
      }
      sorted[i].rank = rank;
    }

    final standings = sorted
        .map(
          (e) => {
            'teamId': e.teamId,
            'teamName': e.teamName,
            'leaderId': e.leaderId,
            'position': e.position,
            'kills': e.kills,
            'totalPoints': e.totalPoints,
            'rank': e.rank,
          },
        )
        .toList();

    await _db.collection('leaderboards').doc(tournamentId).set({
      'tournamentId': tournamentId,
      'createdBy': createdByUid,
      'standings': standings,
      'isPublished': isPublished,
      'template': template.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches an existing leaderboard document if one already exists.
  static Future<Map<String, dynamic>?> fetchLeaderboard(
    String tournamentId,
  ) async {
    final doc = await _db.collection('leaderboards').doc(tournamentId).get();
    return doc.exists ? doc.data() : null;
  }
}

final leaderboardServiceProvider = Provider((_) => LeaderboardService());
