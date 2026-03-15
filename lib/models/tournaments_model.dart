import 'package:firedrop/core/constant/app_enums.dart';

enum GameMode { solo, duo, squad }

class PrizeDistribution {
  final int first;
  final int second;
  final int third;

  const PrizeDistribution({
    required this.first,
    required this.second,
    required this.third,
  });

  factory PrizeDistribution.fromMap(Map<String, dynamic> map) {
    return PrizeDistribution(
      first: map['first'] ?? 0,
      second: map['second'] ?? 0,
      third: map['third'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'first': first,
    'second': second,
    'third': third,
  };
}

class RoomDetails {
  final String? roomId;
  final String? password;

  const RoomDetails({this.roomId, this.password});

  factory RoomDetails.fromMap(Map<String, dynamic> map) {
    return RoomDetails(roomId: map['roomId'], password: map['password']);
  }

  Map<String, dynamic> toMap() => {'roomId': roomId, 'password': password};
}

class TournamentModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  final GameMode gameMode;
  final int entryFee;
  final int prizePool;
  final PrizeDistribution prizeDistribution;
  final int maxSlots;

  final String organizerId;
  final TournamentStatus status;

  final DateTime startTime;
  final RoomDetails? roomDetails;

  final String rulesText;
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.gameMode,
    required this.entryFee,
    required this.prizePool,
    required this.prizeDistribution,
    required this.maxSlots,
    required this.organizerId,
    required this.status,
    required this.startTime,
    this.roomDetails,
    required this.rulesText,
    required this.createdAt,
  });

  // ================= COPY WITH =================

  TournamentModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    GameMode? gameMode,
    int? entryFee,
    int? prizePool,
    PrizeDistribution? prizeDistribution,
    int? maxSlots,
    String? organizerId,
    TournamentStatus? status,
    DateTime? startTime,
    RoomDetails? roomDetails,
    String? rulesText,
    DateTime? createdAt,
  }) {
    return TournamentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      gameMode: gameMode ?? this.gameMode,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      prizeDistribution: prizeDistribution ?? this.prizeDistribution,
      maxSlots: maxSlots ?? this.maxSlots,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      roomDetails: roomDetails ?? this.roomDetails,
      rulesText: rulesText ?? this.rulesText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ================= FROM MAP =================

  factory TournamentModel.fromMap(Map<String, dynamic> map, String id) {
    return TournamentModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',

      gameMode: GameMode.values.firstWhere(
        (e) => e.name == map['gameMode'],
        orElse: () => GameMode.solo,
      ),

      entryFee: map['entryFee'] ?? 0,
      prizePool: map['prizePool'] ?? 0,
      prizeDistribution: PrizeDistribution.fromMap(
        Map<String, dynamic>.from(map['prizeDistribution'] ?? {}),
      ),

      maxSlots: map['maxSlots'] ?? 0,
      organizerId: map['organizerId'] ?? '',

      status: TournamentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TournamentStatus.upcoming,
      ),

      startTime: _parseDate(map['startTime']),
      roomDetails: map['roomDetails'] != null
          ? RoomDetails.fromMap(Map<String, dynamic>.from(map['roomDetails']))
          : null,

      rulesText: map['rulesText'] ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  // ================= TO MAP =================

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'gameMode': gameMode.name,
    'entryFee': entryFee,
    'prizePool': prizePool,
    'prizeDistribution': prizeDistribution.toMap(),
    'maxSlots': maxSlots,
    'organizerId': organizerId,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'roomDetails': roomDetails?.toMap(),
    'rulesText': rulesText,
    'createdAt': createdAt.toIso8601String(),
  };

  // ================= HELPERS =================

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  bool get isUpcoming => status == TournamentStatus.upcoming;
  bool get isLive => status == TournamentStatus.live;
  bool get isCompleted => status == TournamentStatus.completed;
}
