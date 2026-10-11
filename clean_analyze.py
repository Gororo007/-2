import os
import re
import subprocess

# 1. Исправленный in_memory_author_repository.dart (.toList() для фильтра по стране)
AUTHOR_REPO_CODE = """import 'package:dio/dio.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class PersistentAuthorRepository implements AuthorRepository {
  final List<Author> _db = [...seedAuthors];

  @override
  Future<PageResult<Author>> find(AuthorQuery q, {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var rows = _db.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((a) =>
          a.lastName.toLowerCase().contains(needle) ||
          a.firstName.toLowerCase().contains(needle) ||
          a.country.toLowerCase().contains(needle)).toList();
    }

    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    return i == -1 ? null : _db[i];
  }

  @override
  Future<Author> create(Author a) async {
    _db.add(a);
    return a;
  }

  @override
  Future<Author> update(Author a) async {
    final i = _db.indexWhere((x) => x.id == a.id);
    if (i != -1) {
      _db[i] = a;
    }
    return a;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    if (i != -1) {
      _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _db.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _db.indexWhere((a) => a.id == id);
    if (i != -1) {
      _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _db.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
"""

# 2. Исправленный auth_notifier.dart (без лишних `!`)
AUTH_NOTIFIER_CODE = """import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_data';
  static const _kLoginTime = 'auth_login_time';

  final SharedPreferences? _prefs;
  final AuthRepository? _api;

  AppUser? _user;
  String? _accessToken;
  DateTime? _sessionStartTime;
  bool _isRestored = false;

  AuthNotifier(this._prefs, this._api);

  AuthNotifier.mock({AppUser? user})
      : _prefs = null,
        _api = null,
        _user = user ??
            const AppUser(
              id: 1,
              username: 'admin',
              fullName: 'Администратор',
              role: Role.admin,
            ),
        _accessToken = 'mock_jwt_token',
        _isRestored = true;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isRestored => _isRestored;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    final prefs = _prefs;
    final api = _api;
    if (prefs == null || api == null) {
      _isRestored = true;
      notifyListeners();
      return;
    }

    final access = prefs.getString(_kAccess);
    final refresh = prefs.getString(_kRefresh);
    final userJson = prefs.getString(_kUser);
    final loginTimeRaw = prefs.getString(_kLoginTime);

    if (loginTimeRaw != null) {
      _sessionStartTime = DateTime.tryParse(loginTimeRaw);
      if (_sessionStartTime != null && DateTime.now().difference(_sessionStartTime!).inHours >= 2) {
        await logout();
        _isRestored = true;
        notifyListeners();
        return;
      }
    }

    if (access != null) {
      _accessToken = access;
      if (userJson != null) {
        try {
          _user = AppUser.fromJson(jsonDecode(userJson));
        } catch (_) {}
      }

      try {
        _user = await api.me(access);
      } on UnauthorizedException {
        if (refresh != null) {
          try {
            await refreshTokens();
          } catch (_) {
            await logout();
          }
        } else {
          await logout();
        }
      } catch (_) {
        // Ошибка сети: сохраняем сессию
      }
    }

    _isRestored = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final api = _api;
    final prefs = _prefs;
    if (api == null || prefs == null) return;
    final res = await api.login(username, password);
    _accessToken = res.accessToken;
    _user = res.user;
    _sessionStartTime = DateTime.now();

    await prefs.setString(_kAccess, res.accessToken);
    await prefs.setString(_kRefresh, res.refreshToken);
    await prefs.setString(_kUser, jsonEncode(res.user.toJson()));
    await prefs.setString(_kLoginTime, _sessionStartTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> register(String username, String password, String fullName) async {
    final api = _api;
    final prefs = _prefs;
    if (api == null || prefs == null) return;
    final res = await api.register(username, password, fullName);
    _accessToken = res.accessToken;
    _user = res.user;
    _sessionStartTime = DateTime.now();

    await prefs.setString(_kAccess, res.accessToken);
    await prefs.setString(_kRefresh, res.refreshToken);
    await prefs.setString(_kUser, jsonEncode(res.user.toJson()));
    await prefs.setString(_kLoginTime, _sessionStartTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    final prefs = _prefs;
    final api = _api;
    if (prefs == null || api == null) throw const UnauthorizedException();
    final refresh = prefs.getString(_kRefresh);
    if (refresh == null) throw const UnauthorizedException();

    final res = await api.refresh(refresh);
    _accessToken = res.accessToken;
    await prefs.setString(_kAccess, res.accessToken);
    await prefs.setString(_kRefresh, res.refreshToken);

    _user = await api.me(res.accessToken);
    await prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = _prefs;
    _user = null;
    _accessToken = null;
    _sessionStartTime = null;
    if (prefs != null) {
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
      await prefs.remove(_kUser);
      await prefs.remove(_kLoginTime);
    }
    notifyListeners();
  }
}
"""

def patch_file(path, pattern, replacement):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"  + Пропатчен: {path}")

def main():
    print("--- Устранение всех замечаний flutter analyze ---")
    
    with open("lib/repositories/in_memory_author_repository.dart", "w", encoding="utf-8") as f:
        f.write(AUTHOR_REPO_CODE)
    print("  + Обновлён: lib/repositories/in_memory_author_repository.dart")

    with open("lib/state/auth_notifier.dart", "w", encoding="utf-8") as f:
        f.write(AUTH_NOTIFIER_CODE)
    print("  + Обновлён: lib/state/auth_notifier.dart")

    # Убираем await перед getAllRaw
    patch_file(
        "lib/repositories/persistent_publisher_repository.dart",
        r"await\s+([a-zA-Z0-9_]+\.getAllRaw\(\))",
        r"\1"
    )

    # Фигурные скобки в inactivity_watcher.dart
    patch_file(
        "lib/core/inactivity_watcher.dart",
        r"if\s*\(_warningShown\)\s*return;",
        "if (_warningShown) {\n      return;\n    }"
    )

    # Фигурные скобки в models/book.dart
    patch_file(
        "lib/models/book.dart",
        r"if\s*\(json\['publisherId'\]\s*!=\s*null\)\s*return\s*\(json\['publisherId'\]\s*as\s*num\)\.toInt\(\);",
        "if (json['publisherId'] != null) {\n        return (json['publisherId'] as num).toInt();\n      }"
    )

    # Защита BuildContext в my_loans_screen.dart
    patch_file(
        "lib/screens/my_loans_screen.dart",
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Срок возврата",
        "if (!mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Срок возврата"
    )
    patch_file(
        "lib/screens/my_loans_screen.dart",
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\('Ошибка продления",
        "if (!mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка продления"
    )

    # Защита BuildContext в admin_users_screen.dart
    patch_file(
        "lib/screens/admin_users_screen.dart",
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Роль успешно",
        "if (!mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Роль успешно"
    )
    patch_file(
        "lib/screens/admin_users_screen.dart",
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\('Ошибка смены",
        "if (!mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка смены"
    )

    # Защита BuildContext в book_list_screen.dart
    patch_file(
        "lib/screens/book_list_screen.dart",
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\(e\.message\)",
        "if (!context.mounted) return;\n                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)"
    )

    print("\nФорматирование кода...")
    subprocess.run(["dart", "format", "lib", "test"], shell=True)
    print("\nГотово!")

if __name__ == "__main__":
    main()