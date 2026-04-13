import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagle_esports/core/constant/app_enums.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String avatarUrl;
  final bool isBanned;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    required this.isBanned,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? gameUid,
    String? avatarUrl,
    bool? isBanned,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role != null
          ? UserRole.values.firstWhere((e) => e.name == role)
          : this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBanned: isBanned ?? this.isBanned,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.byName(map['role']),
      avatarUrl: map['avatarUrl'],
      isBanned: map['isBanned'] ?? false,
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'avatarUrl': avatarUrl,
    'isBanned': isBanned,
    'fcmToken': fcmToken,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
