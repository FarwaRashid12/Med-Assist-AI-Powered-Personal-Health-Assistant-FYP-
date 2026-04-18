import 'package:hive/hive.dart';

part 'family_profile_model.g.dart';

@HiveType(typeId: 4)
class FamilyProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentUserId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String relation;

  @HiveField(4)
  final DateTime createdAt;

  FamilyProfileModel({
    required this.id,
    required this.parentUserId,
    required this.name,
    required this.relation,
    required this.createdAt,
  });
}
