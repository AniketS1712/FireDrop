class RegistrationModel {
  final String id;
  final String tournamentId;
  final String? userId;
  final String? teamId;
  final String paymentStatus; // pending | paid | failed | refunded
  final String? paymentRefId;
  final bool checkInStatus;
  final DateTime registeredAt;

  RegistrationModel({
    required this.id,
    required this.tournamentId,
    this.userId,
    this.teamId,
    required this.paymentStatus,
    this.paymentRefId,
    required this.checkInStatus,
    required this.registeredAt,
  });

  RegistrationModel copyWith({
    String? id,
    String? tournamentId,
    String? userId,
    String? teamId,
    String? paymentStatus,
    String? paymentRefId,
    bool? checkInStatus,
    DateTime? registeredAt,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentRefId: paymentRefId ?? this.paymentRefId,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  factory RegistrationModel.fromMap(Map<String, dynamic> map, String id) {
    return RegistrationModel(
      id: id,
      tournamentId: map['tournamentId'],
      userId: map['userId'],
      teamId: map['teamId'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentRefId: map['paymentRefId'],
      checkInStatus: map['checkInStatus'] ?? false,
      registeredAt: DateTime.parse(map['registeredAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'userId': userId,
    'teamId': teamId,
    'paymentStatus': paymentStatus,
    'paymentRefId': paymentRefId,
    'checkInStatus': checkInStatus,
    'registeredAt': registeredAt.toIso8601String(),
  };
}
