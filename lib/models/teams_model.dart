import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String tournamentId;
  final String name;
  final String organizerID;
  final List<String> members;
  final String? inviteCode;
  final String? ign;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.members,
    this.inviteCode,
    this.ign,
    required this.createdAt,
    required this.organizerID,
    required this.updatedAt,
  });

  TeamModel copyWith({
    String? name,
    List<String>? members,
    String? inviteCode,
    String? ign,
  }) {
    return TeamModel(
      id: id,
      tournamentId: tournamentId,
      name: name ?? this.name,
      organizerID: organizerID,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      ign: ign ?? this.ign,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      tournamentId: map['tournamentId'] ?? '',
      name: map['name'],
      organizerID: map['organizerID'],
      members: List<String>.from(map['members'] ?? []),
      inviteCode: map['inviteCode'] ?? '',
      ign: map['ign'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'name': name,
    'members': members,
    'organizerID': organizerID,
    'inviteCode': inviteCode,
    'ign': ign,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
