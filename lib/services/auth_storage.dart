import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

const _kTokenKey = 'auth_token';

/// Token 本地持久化工具，启动时恢复登录态。
class AuthStorage {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    ApiClient.instance.setToken(token);
  }

  Future<bool> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setToken(token);
      return true;
    }
    return false;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    ApiClient.instance.logout();
  }
}
