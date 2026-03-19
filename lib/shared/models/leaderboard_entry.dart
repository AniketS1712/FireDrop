/// Position → points lookup table.
/// Organizers can tweak these values directly here.
///
/// Add as many positions as needed. Any position not in the map
/// defaults to 0 placement points.
const Map<int, int> kPositionPoints = {
  1: 15,
  2: 12,
  3: 10,
  4: 8,
  5: 6,
  6: 5,
  7: 4,
  8: 3,
  9: 2,
  10: 1,
};

/// Per-kill bonus points added to the total score.
const int kKillPoints = 1;

/// A mutable row in the leaderboard spreadsheet.
class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final String leaderId; // organizerID == team leader uid
  final List<String> memberUids; // all member UIDs
  int position; // placement finish (1 = 1st place)
  int kills;

  LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.leaderId,
    required this.memberUids,
    this.position = 0,
    this.kills = 0,
  });

  /// Total score = placement points + (kills × kKillPoints).
  int get totalPoints {
    final placementPts = position > 0 ? (kPositionPoints[position] ?? 0) : 0;
    return placementPts + (kills * kKillPoints);
  }

  /// Ranking label shown in the Rank column (computed after sorting).
  int rank = 0;
}
