import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper untuk penyimpanan token Sanctum secara aman di device.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'sanctum_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_nama';
  static const _keyUsername = 'username';
  static const _keyLevelUser = 'level_user';

  // ── Token ──────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> deleteToken() => _storage.delete(key: _keyToken);

  // ── User Info ──────────────────────────────────────────────────────────────
  static Future<void> saveUser({
    required String idUser,
    required String nama,
    required String username,
    required String levelUser,
  }) async {
    await _storage.write(key: _keyUserId, value: idUser);
    await _storage.write(key: _keyUserName, value: nama);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyLevelUser, value: levelUser);
  }

  static Future<Map<String, String?>> getUser() async => {
        'id_user':    await _storage.read(key: _keyUserId),
        'nama':       await _storage.read(key: _keyUserName),
        'username':   await _storage.read(key: _keyUsername),
        'level_user': await _storage.read(key: _keyLevelUser),
      };

  // ── Clear All ──────────────────────────────────────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();
}
