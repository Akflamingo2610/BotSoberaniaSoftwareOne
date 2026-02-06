import 'package:shared_preferences/shared_preferences.dart';

import 'position_persistence.dart';

class AppStorage {
  static const _kAuthToken = 'authToken';
  static const _kAssessmentId = 'assessmentId';
  static const _kUserEmail = 'userEmail';
  static const _kUserName = 'userName';
  static const _kLastResultsGeneratedAt = 'lastResultsGeneratedAt';
  static const _kLastQuestionIndexPrefix = 'lastQuestionIndex_';
  static const _kLastViewedPhase = 'lastViewedPhase';

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

  Future<DateTime?> getLastResultsGeneratedAt() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt(_kLastResultsGeneratedAt);
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  Future<void> setLastResultsGeneratedAt(DateTime dt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kLastResultsGeneratedAt, dt.millisecondsSinceEpoch);
  }

  Future<int?> getLastQuestionIndex(String phase) async {
    final syncIndex = getLastIndexSync(phase);
    if (syncIndex != null) return syncIndex;
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('$_kLastQuestionIndexPrefix$phase');
  }

  Future<void> setLastQuestionIndex(String phase, int index) async {
    savePositionSync(phase, index); // Síncrono para web (sobrevive ao fechar aba)
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('$_kLastQuestionIndexPrefix$phase', index);
    await sp.setString(_kLastViewedPhase, phase);
  }

  Future<String?> getLastViewedPhase() async {
    final phaseSync = getLastPhaseSync();
    if (phaseSync != null && phaseSync.isNotEmpty) return phaseSync;
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastViewedPhase);
  }

  /// Retorna índice salvo síncronamente (web) ou null.
  int? getLastQuestionIndexSync(String phase) => getLastIndexSync(phase);

  Future<void> clearAll() async {
    clearPositionSync();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAuthToken);
    await sp.remove(_kAssessmentId);
    await sp.remove(_kUserEmail);
    await sp.remove(_kUserName);
    await sp.remove(_kLastResultsGeneratedAt);
    await sp.remove(_kLastViewedPhase);
    final keys = sp.getKeys().where((k) => k.startsWith(_kLastQuestionIndexPrefix));
    for (final k in keys) {
      await sp.remove(k);
    }
  }
}
