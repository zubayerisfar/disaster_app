import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_info_model.dart';

class FamilyInfoService {
  static const String _key = 'family_info';

  /// Check if family information has been submitted
  Future<bool> hasFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Save family information
  Future<void> saveFamilyInfo(FamilyInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(info.toJson()));
  }

  /// Get saved family information
  Future<FamilyInfo?> getFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    return FamilyInfo.fromJson(jsonDecode(jsonString));
  }

  /// Clear family information (for testing/reset)
  Future<void> clearFamilyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
