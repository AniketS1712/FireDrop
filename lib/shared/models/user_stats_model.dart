class UserStatsModel {
  final String uid;
  final int matchesPlayed;
  final int wins;
  final int totalKills;
  final int earnings;

  UserStatsModel({
    required this.uid,
    required this.matchesPlayed,
    required this.wins,
    required this.totalKills,
    required this.earnings,
  });

  UserStatsModel copyWith({
    int? matchesPlayed,
    int? wins,
    int? totalKills,
    int? earnings,
  }) {
    return UserStatsModel(
      uid: uid,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      totalKills: totalKills ?? this.totalKills,
      earnings: earnings ?? this.earnings,
    );
  }

  factory UserStatsModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserStatsModel(
      uid: uid,
      matchesPlayed: map['matchesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      totalKills: map['totalKills'] ?? 0,
      earnings: map['earnings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'matchesPlayed': matchesPlayed,
    'wins': wins,
    'totalKills': totalKills,
    'earnings': earnings,
  };
}
