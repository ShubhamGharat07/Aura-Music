import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Random 256-bit DB key in Keystore/Keychain (PRD 9.2).
/// Drift + SQLCipher open the encrypted DB with this key (Phase 1).

/// Manages the encrypted-database key.
final class SecureKeyService {
  /// Creates the service.
  SecureKeyService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _keyName = 'aura.db_key';
  Future<String>? _pending;

  /// Returns the existing key or generates + stores a new one.
  Future<String> getOrCreateKey() => _pending ??= _readOrCreate();

  Future<String> _readOrCreate() async {
    try {
      final existing = await _storage.read(key: _keyName);
      if (existing != null && existing.isNotEmpty) return existing;
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      final key = base64UrlEncode(bytes);
      await _storage.write(key: _keyName, value: key);
      return key;
    } finally {
      _pending = null;
    }
  }
}
