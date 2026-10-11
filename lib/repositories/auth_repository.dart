import '../models/user.dart';

abstract interface class AuthRepository {
  Future<({String accessToken, String refreshToken, AppUser user})> login(
      String username, String password);
  Future<({String accessToken, String refreshToken, AppUser user})> register(
      String username, String password, String fullName);
  Future<({String accessToken, String refreshToken})> refresh(
      String refreshToken);
  Future<AppUser> me(String accessToken);
}
