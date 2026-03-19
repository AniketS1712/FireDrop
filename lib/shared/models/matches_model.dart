class MatchModel {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final int matchNumber;
  final DateTime scheduledTime;
  final String roomId;
  final String password;
  final String status; // pending | live | finished

  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.matchNumber,
    required this.scheduledTime,
    required this.roomId,
    required this.password,
    required this.status,
  });

  MatchModel copyWith({
    String? id,
    String? tournamentId,
    int? roundNumber,
    int? matchNumber,
    DateTime? scheduledTime,
    String? roomId,
    String? password,
    String? status,
  }) {
    return MatchModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundNumber: roundNumber ?? this.roundNumber,
      matchNumber: matchNumber ?? this.matchNumber,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      roomId: roomId ?? this.roomId,
      password: password ?? this.password,
      status: status ?? this.status,
    );
  }

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      tournamentId: map['tournamentId'],
      roundNumber: map['roundNumber'],
      matchNumber: map['matchNumber'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      roomId: map['roomId'] ?? '',
      password: map['password'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'roundNumber': roundNumber,
    'matchNumber': matchNumber,
    'scheduledTime': scheduledTime.toIso8601String(),
    'roomId': roomId,
    'password': password,
    'status': status,
  };
}
