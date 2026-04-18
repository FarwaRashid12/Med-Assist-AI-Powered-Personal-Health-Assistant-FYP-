import 'package:hive/hive.dart';
import '../models/family_profile_model.dart';

class FamilyRepository {
  static const String boxName = 'family_profiles_box';

  Future<Box<FamilyProfileModel>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<FamilyProfileModel>(boxName);
    }
    return Hive.box<FamilyProfileModel>(boxName);
  }

  Future<void> addFamilyMember(FamilyProfileModel member) async {
    final box = await _getBox();
    await box.put(member.id, member);
  }

  Future<List<FamilyProfileModel>> getFamilyMembers(String parentUserId) async {
    final box = await _getBox();
    final all = box.values.where((p) => p.parentUserId == parentUserId).toList();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all;
  }

  Future<void> deleteFamilyMember(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
