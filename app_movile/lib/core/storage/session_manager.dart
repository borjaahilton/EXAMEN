import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyServerUrl = 'server_url';

  Future<void> saveSession({required String token, required UserModel user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.nombre);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserRole, user.rol);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    final nombre = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);
    final rol = prefs.getString(_keyUserRole);

    if (id != null && nombre != null && email != null && rol != null) {
      return UserModel(id: id, nombre: nombre, email: email, rol: rol);
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }
}
