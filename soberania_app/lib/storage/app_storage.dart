import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _kAuthToken = 'authToken';
  static const _kAssessmentId = 'assessmentId';
  static const _kUserEmail = 'userEmail';
  static const _kUserName = 'userName';

  Future<String?> getAuthToken() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_kAuthToken);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setAuthToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAuthToken, token);
  }

  Future<void> clearAuthToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAuthToken);
  }

  Future<int?> getAssessmentId() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt(_kAssessmentId);
    return v;
  }

  Future<void> setAssessmentId(int id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kAssessmentId, id);
  }

  Future<String?> getUserEmail() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserEmail);
  }

  Future<void> setUserEmail(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserEmail, email);
  }

  Future<String?> getUserName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserName);
  }

  Future<void> setUserName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserName, name);
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAuthToken);
    await sp.remove(_kAssessmentId);
    await sp.remove(_kUserEmail);
    await sp.remove(_kUserName);
  }
}
