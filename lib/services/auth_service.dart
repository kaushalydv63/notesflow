import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:notesflow/models/user_model.dart';

class AuthService {
  static const String _userKey = 'logged_in_user';
  static const String _registeredUsersKey = 'registered_users';
  final Uuid _uuid = const Uuid();

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_registeredUsersKey) ?? <String>[];
    final normalizedEmail = email.trim().toLowerCase();

    for (final item in list) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      if (map['email']?.toString().toLowerCase() == normalizedEmail) {
        return 'This email is already registered.';
      }
    }

    final newRecord = {
      'id': _uuid.v4(),
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password,
    };

    list.add(jsonEncode(newRecord));
    await prefs.setStringList(_registeredUsersKey, list);
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_registeredUsersKey) ?? <String>[];
    final normalizedEmail = email.trim().toLowerCase();

    for (final item in list) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      if (map['email']?.toString().toLowerCase() == normalizedEmail &&
          map['password'] == password) {
        final user = UserModel.fromJson(map);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        return null;
      }
    }
    return 'Invalid email or password.';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}