import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/user.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  ApiAuthRepository(this._dio);

  @override
  Future<({String accessToken, String refreshToken, AppUser user})> login(
          String username, String password) =>
      guard(() async {
        final res = await _dio.post('/auth/login',
            data: {'username': username, 'password': password});
        final d = res.data as Map<String, dynamic>;
        return (
          accessToken: d['accessToken'] as String,
          refreshToken: d['refreshToken'] as String,
          user: AppUser.fromJson(d['user'] as Map<String, dynamic>),
        );
      });

  @override
  Future<({String accessToken, String refreshToken, AppUser user})> register(
          String username, String password, String fullName) =>
      guard(() async {
        final res = await _dio.post('/auth/register', data: {
          'username': username,
          'password': password,
          'fullName': fullName
        });
        final d = res.data as Map<String, dynamic>;
        return (
          accessToken: d['accessToken'] as String,
          refreshToken: d['refreshToken'] as String,
          user: AppUser.fromJson(d['user'] as Map<String, dynamic>),
        );
      });

  @override
  Future<({String accessToken, String refreshToken})> refresh(
          String refreshToken) =>
      guard(() async {
        final res = await _dio
            .post('/auth/refresh', data: {'refreshToken': refreshToken});
        final d = res.data as Map<String, dynamic>;
        return (
          accessToken: d['accessToken'] as String,
          refreshToken: d['refreshToken'] as String,
        );
      });

  @override
  Future<AppUser> me(String accessToken) => guard(() async {
        final res = await _dio.get('/auth/me',
            options:
                Options(headers: {'Authorization': 'Bearer $accessToken'}));
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });
}
