import 'package:shared_preferences/shared_preferences.dart';

/// PRD §5 / §22 — pilot settings persistence.
///
/// Stores the `TRICYKAB_API_BASE` chosen by the operator on first launch and
/// the most recent driver auth token so cold-starts go straight back to home.
class AppSettings {
  AppSettings._(this._prefs);

  static const String _kApiBase = 'tricykab_api_base';
  static const String _kAccessToken = 'tricykab_access_token';
  static const String _kRefreshToken = 'tricykab_refresh_token';
  static const String _kPhone = 'tricykab_last_phone';

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }

  String get apiBase => _prefs.getString(_kApiBase)?.trim() ?? '';

  Future<void> setApiBase(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      await _prefs.remove(_kApiBase);
    } else {
      await _prefs.setString(_kApiBase, cleaned);
    }
  }

  String? get accessToken => _prefs.getString(_kAccessToken);

  Future<void> setAccessToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_kAccessToken);
    } else {
      await _prefs.setString(_kAccessToken, token);
    }
  }

  String? get refreshToken => _prefs.getString(_kRefreshToken);

  Future<void> setRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_kRefreshToken);
    } else {
      await _prefs.setString(_kRefreshToken, token);
    }
  }

  String? get lastPhone => _prefs.getString(_kPhone);

  Future<void> setLastPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      await _prefs.remove(_kPhone);
    } else {
      await _prefs.setString(_kPhone, phone);
    }
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
  }
}
