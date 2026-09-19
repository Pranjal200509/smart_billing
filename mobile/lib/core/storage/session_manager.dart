import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'user_role';
  static const String _keyCustomerId = 'customer_id';
  static const String _keyCustomBaseUrl = 'custom_base_url';

  static Future<String?> getCustomBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomBaseUrl);
  }

  static Future<void> setCustomBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_keyCustomBaseUrl);
    } else {
      await prefs.setString(_keyCustomBaseUrl, url.trim());
    }
  }

  static Future<void> saveSession({
    required String token,
    required int userId,
    required String fullName,
    required String email,
    required String role,
    String? customerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
    if (customerId != null) {
      await prefs.setString(_keyCustomerId, customerId);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFullName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomerId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  /// Validates JWT payload expiration locally without making any network calls
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = jsonDecode(decodedString);
      if (payloadMap is Map && payloadMap.containsKey('exp')) {
        final expSeconds = payloadMap['exp'] as num;
        final expDate = DateTime.fromMillisecondsSinceEpoch(expSeconds.toInt() * 1000);
        return DateTime.now().isAfter(expDate);
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;
      if (isTokenExpired(token)) {
        await clearSession();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'ROLE_ADMIN';
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}

