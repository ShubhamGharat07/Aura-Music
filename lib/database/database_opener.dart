import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:aura_music/core/services/secure_key_service.dart';

/// Opens Aura's local database (PRD 9.2 / 9.13).
///
/// On Android and iOS the database is encrypted at rest with the SQLite3
/// Multiple Ciphers build using the SQLCipher 4 scheme (`PRAGMA key`). The 256-bit key
/// lives in the Keystore/Keychain via [SecureKeyService]. A database created
/// before encryption was introduced is re-encrypted once in place with
/// `PRAGMA rekey`.
///
/// Desktop builds and tests stay plaintext (the AppDatabase tests pass their
/// own in-memory executor anyway).
QueryExecutor openAuraDatabase({
  Future<String> Function()? keyProvider,
  Future<Directory> Function()? directory,
}) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return driftDatabase(name: 'aura');
  }
  final readKey = keyProvider ?? SecureKeyService().getOrCreateKey;
  final resolveDirectory = directory ?? getApplicationDocumentsDirectory;
  return LazyDatabase(() async {
    final dir = await resolveDirectory();
    final tempPath = (await getTemporaryDirectory()).path;
    sqlite.sqlite3.tempDirectory = tempPath;
    final file = File(p.join(dir.path, 'aura.sqlite'));
    final key = await readKey();
    await _encryptLegacyDatabase(file, key);
    await _discardUnreadableDatabase(file, key);
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        sqlite.sqlite3.tempDirectory = tempPath;
        db.execute(_cipherPragma);
        db.execute(_legacyPragma);
        db.execute("PRAGMA key = '${_escape(key)}';");
      },
    );
  });
}

String _escape(String value) => value.replaceAll("'", "''");

/// SQLCipher 4 scheme (PRD 9.2), provided by the SQLite3 Multiple Ciphers build.
const String _cipherPragma = "PRAGMA cipher = 'sqlcipher';";
const String _legacyPragma = 'PRAGMA legacy = 4;';

/// True when [file] still uses the SQLite header, i.e. it was written before
/// encryption was introduced.
Future<bool> _isPlaintext(File file) async {
  if (!await file.exists()) return false;
  final handle = await file.open();
  try {
    final header = await handle.read(16);
    return header.length == 16 &&
        utf8.decode(header, allowMalformed: true) == 'SQLite format 3\u0000';
  } finally {
    await handle.close();
  }
}

/// Re-encrypts a legacy plaintext database in place. On failure the plaintext
/// files are removed so local data never stays unencrypted; the app then starts
/// with a fresh encrypted database.
Future<void> _encryptLegacyDatabase(File file, String key) async {
  if (!await _isPlaintext(file)) return;
  final db = sqlite.sqlite3.open(file.path);
  try {
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    db.execute(_cipherPragma);
    db.execute(_legacyPragma);
    db.execute("PRAGMA rekey = '${_escape(key)}';");
  } on Object {
    db.close();
    await _deleteDatabaseFiles(file);
    return;
  }
  db.close();
  for (final suffix in const ['-wal', '-shm']) {
    final sidecar = File('${file.path}$suffix');
    if (await sidecar.exists()) await sidecar.delete();
  }
}

Future<void> _discardUnreadableDatabase(File file, String key) async {
  if (!await file.exists()) return;
  final db = sqlite.sqlite3.open(file.path);
  var unreadable = false;
  try {
    db.execute(_cipherPragma);
    db.execute(_legacyPragma);
    db.execute("PRAGMA key = '${_escape(key)}';");
    db.select('SELECT count(*) FROM sqlite_master;');
  } on sqlite.SqliteException catch (error) {
    if (error.resultCode != 26) rethrow;
    unreadable = true;
  } finally {
    db.close();
  }
  if (unreadable) await _quarantineDatabaseFiles(file);
}

Future<void> _quarantineDatabaseFiles(File file) async {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final candidate = File('${file.path}$suffix');
    if (!await candidate.exists()) continue;
    try {
      await candidate.rename('${candidate.path}.corrupt-$stamp');
    } on Object {
      await candidate.delete();
    }
  }
}

Future<void> _deleteDatabaseFiles(File file) async {
  for (final path in [
    file.path,
    '${file.path}-wal',
    '${file.path}-shm',
    '${file.path}-journal',
  ]) {
    final candidate = File(path);
    if (await candidate.exists()) await candidate.delete();
  }
}
