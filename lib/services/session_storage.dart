import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/session.dart';

class SessionStorage {
  static const _sessionKey = 'lifestreak_session';

  final FlutterSecureStorage _secureStorage;

  const SessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Session?> read() async {
    final value = await _secureStorage.read(key: _sessionKey);
    if (value == null || value.isEmpty) return null;
    try {
      return Session.fromStorageValue(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Session session) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: session.toStorageValue(),
    );
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _sessionKey);
  }
}
