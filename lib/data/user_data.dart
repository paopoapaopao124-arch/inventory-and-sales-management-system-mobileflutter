
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class UserData extends ChangeNotifier {
  UserData._();

  static final UserData instance = UserData._();

  static const String _storageKey = 'stocksmart_users_v1';

  final List<AppUser> users = [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final savedUsers = prefs.getString(_storageKey);

    if (savedUsers != null) {
      final decoded = jsonDecode(savedUsers) as List<dynamic>;

      users
        ..clear()
        ..addAll(
          decoded.map(
                (item) => AppUser.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );

    notifyListeners();
  }

  void _validate({
    required String name,
    required String username,
    required String role,
    String? excludeId,
  }) {
    if (name.trim().isEmpty) {
      throw Exception('Please enter the full name.');
    }

    if (username.trim().isEmpty) {
      throw Exception('Please enter a username.');
    }

    const validRoles = ['Admin', 'Staff', 'Customer'];

    if (!validRoles.contains(role)) {
      throw Exception('Please select a valid role.');
    }

    final duplicate = users.any(
          (user) =>
      user.username.toLowerCase() == username.trim().toLowerCase() &&
          user.id != excludeId,
    );

    if (duplicate) {
      throw Exception('That username already exists.');
    }
  }

  Future<void> addUser({
    required String name,
    required String username,
    required String role,
  }) async {
    _validate(
      name: name,
      username: username,
      role: role,
    );

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      username: username.trim(),
      role: role,
    );

    users.add(user);

    try {
      await _save();
    } catch (_) {
      users.removeWhere((item) => item.id == user.id);
      rethrow;
    }
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String username,
    required String role,
    required bool isActive,
  }) async {
    final index = users.indexWhere((user) => user.id == id);

    if (index == -1) {
      throw Exception('User not found.');
    }

    _validate(
      name: name,
      username: username,
      role: role,
      excludeId: id,
    );

    final oldUser = users[index];

    final updatedUser = AppUser(
      id: oldUser.id,
      name: name.trim(),
      username: username.trim(),
      role: role,
      isActive: isActive,
    );

    users[index] = updatedUser;

    try {
      await _save();
    } catch (_) {
      users[index] = oldUser;
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    final index = users.indexWhere((user) => user.id == id);

    if (index == -1) {
      throw Exception('User not found.');
    }

    final removedUser = users.removeAt(index);

    try {
      await _save();
    } catch (_) {
      users.insert(index, removedUser);
      rethrow;
    }
  }

  int get totalUsers => users.length;

  int get activeUsers =>
      users.where((user) => user.isActive).length;

  int get adminCount =>
      users.where((user) => user.role == 'Admin').length;

  int get staffCount =>
      users.where((user) => user.role == 'Staff').length;

  int get customerCount =>
      users.where((user) => user.role == 'Customer').length;
}
