import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/database/app_database.dart';

/// Wipes every locally stored artefact — database rows, preferences,
/// downloaded files and image caches (PRD S20 "Clear all data").
/// Idempotent; never touches the DB key in secure storage.

/// Local-data wiper.
final class DataResetService {
  /// Creates the service (a custom [downloadsDirectory] is used by tests).
  DataResetService(
    this._db,
    this._prefs, {
    Future<Directory> Function()? downloadsDirectory,
  }) : _downloadsDirectory = downloadsDirectory ?? _defaultDownloadsDirectory;

  final AppDatabase _db;
  final SharedPreferences _prefs;
  final Future<Directory> Function() _downloadsDirectory;

  static Future<Directory> _defaultDownloadsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'downloads'));
  }

  /// Clears all local data.
  Future<void> clearAll() async {
    for (final table in _db.allTables) {
      await _db.delete(table).go();
    }
    await _prefs.clear();
    await _deleteDirectory(await _downloadsDirectory());
    _clearImageCache();
  }

  Future<void> _deleteDirectory(Directory dir) async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  void _clearImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }
}
