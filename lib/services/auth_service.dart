import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _password = 'era987';
  static const String _authKey = 'is_authenticated';
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String password) async {
    if (password == _password) {
      await _storage.write(key: _authKey, value: 'true');
      return true;
    }
    return false;
  }

  Future<bool> isAuthenticated() async {
    final value = await _storage.read(key: _authKey);
    return value == 'true';
  }

  Future<void> logout() async {
    await _storage.delete(key: _authKey);
  }
}