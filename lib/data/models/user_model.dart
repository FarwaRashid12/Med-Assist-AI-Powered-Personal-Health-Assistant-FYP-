import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String passwordHash;

  @HiveField(4)
  final String? phone;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? profileImagePath;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.phone,
    required this.createdAt,
    this.profileImagePath,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      passwordHash: '', // Not stored in Firestore for Firebase Auth users
      phone: map['phone'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      profileImagePath: map['profileImagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': createdAt,
      'profileImagePath': profileImagePath,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? phone,
    DateTime? createdAt,
    String? profileImagePath,
  }) {
    // ... rest of copyWith ...
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
