import 'dart:convert';
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
      if (_sessionStartTime != null &&
          DateTime.now().difference(_sessionStartTime!).inHours >= 2) {
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

  Future<void> register(
      String username, String password, String fullName) async {
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
