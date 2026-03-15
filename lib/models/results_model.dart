class Standing {
  final String? userId;
  final String? teamId;
  final int placement;
  final int kills;
  final int points;

  Standing({
    this.userId,
    this.teamId,
    required this.placement,
    required this.kills,
    required this.points,
  });

  factory Standing.fromMap(Map<String, dynamic> map) => Standing(
    userId: map['userId'],
    teamId: map['teamId'],
    placement: map['placement'],
    kills: map['kills'],
    points: map['points'],
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'teamId': teamId,
    'placement': placement,
    'kills': kills,
    'points': points,
  };
}

class ResultModel {
  final String id;
  final String tournamentId;
  final String? matchId;
  final List<Standing> standings;
  final bool isProvisional;
  final DateTime? lockedAt;
  final String createdBy;

  ResultModel({
    required this.id,
    required this.tournamentId,
    this.matchId,
    required this.standings,
    required this.isProvisional,
    this.lockedAt,
    required this.createdBy,
  });

  ResultModel copyWith({
    String? id,
    String? tournamentId,
    String? matchId,
    List<Standing>? standings,
    bool? isProvisional,
    DateTime? lockedAt,
    String? createdBy,
  }) {
    return ResultModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      matchId: matchId ?? this.matchId,
      standings: standings ?? this.standings,
      isProvisional: isProvisional ?? this.isProvisional,
      lockedAt: lockedAt ?? this.lockedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory ResultModel.fromMap(Map<String, dynamic> map, String id) {
    return ResultModel(
      id: id,
      tournamentId: map['tournamentId'],
      matchId: map['matchId'],
      standings: (map['standings'] as List)
          .map((e) => Standing.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      isProvisional: map['isProvisional'] ?? true,
      lockedAt: map['lockedAt'] != null
          ? DateTime.parse(map['lockedAt'])
          : null,
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'matchId': matchId,
    'standings': standings.map((e) => e.toMap()).toList(),
    'isProvisional': isProvisional,
    'lockedAt': lockedAt?.toIso8601String(),
    'createdBy': createdBy,
  };
}
