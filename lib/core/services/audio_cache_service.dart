import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// Service responsible for automatically caching streamed audio files to local disk
/// using an LRU (Least Recently Used) cache strategy.
///
/// Enables instant, zero-internet playback when tracks are repeated or played again.
final class AudioCacheService {
  /// Creates the audio cache service.
  ///
  /// [directoryProvider] can be overridden for unit testing.
  AudioCacheService(this._dio, {Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? _defaultDirectory;

  final Dio _dio;
  final Future<Directory> Function() _directoryProvider;
  final Set<String> _inFlight = <String>{};

  static Future<Directory> _defaultDirectory() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'audio_cache'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the path to the cached audio file for [trackId], or null if not cached.
  /// Also updates the file's last modified timestamp for LRU ordering.
  Future<String?> get(String trackId) async {
    try {
      final dir = await _directoryProvider();
      final file = File(p.join(dir.path, _fileNameFor(trackId)));
      if (await file.exists()) {
        final length = await file.length();
        if (length > 1024) {
          // Touch file to update LRU timestamp
          try {
            await file.setLastModified(DateTime.now());
          } on Object {
            // Non-critical if timestamp update fails
          }
          return file.path;
        }
      }
    } on Object {
      // Disk read errors fail gracefully
    }
    return null;
  }

  /// Asynchronously caches [track] from [streamUrl] to local disk in the background.
  ///
  /// Safe to call fire-and-forget: never throws or disrupts audio playback.
  Future<void> cacheTrack(
    Track track, {
    required String streamUrl,
    int maxMb = 512,
  }) async {
    if (streamUrl.isEmpty) return;
    if (_inFlight.contains(track.id)) return;

    try {
      final dir = await _directoryProvider();
      final finalFile = File(p.join(dir.path, _fileNameFor(track.id)));
      if (await finalFile.exists() && (await finalFile.length()) > 1024) {
        return; // Already cached
      }

      _inFlight.add(track.id);
      final partFile = File('${finalFile.path}.part');

      // Download stream to temporary .part file
      await _dio.download(
        streamUrl,
        partFile.path,
        options: Options(
          headers: const <String, String>{
            'Accept': '*/*',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          },
        ),
      );

      if (await partFile.exists()) {
        final length = await partFile.length();
        if (length > 1024) {
          // Atomically finalize file
          if (await finalFile.exists()) {
            await finalFile.delete();
          }
          await partFile.rename(finalFile.path);

          // Enforce LRU disk budget
          await _enforceLruLimit(dir, maxMb);
        } else {
          await partFile.delete();
        }
      }
    } on Object {
      // Background caching errors are silently swallowed
    } finally {
      _inFlight.remove(track.id);
    }
  }

  /// Calculates total bytes currently occupied by cached audio files.
  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _directoryProvider();
      if (!dir.existsSync()) return 0;
      var total = 0;
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.part')) {
          total += file.lengthSync();
        }
      }
      return total;
    } on Object {
      return 0;
    }
  }

  /// Deletes all cached audio files.
  Future<void> clearCache() async {
    try {
      final dir = await _directoryProvider();
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } on Object {
            // Ignore individual delete errors
          }
        }
      }
    } on Object {
      // Ignore directory clear errors
    }
  }

  /// Enforces LRU disk cache limit by pruning oldest-accessed files.
  Future<void> _enforceLruLimit(Directory dir, int maxMb) async {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.endsWith('.part'))
          .toList();

      var totalBytes = 0;
      final fileStats = <(File, DateTime, int)>[];
      for (final file in files) {
        final stat = file.statSync();
        totalBytes += stat.size;
        fileStats.add((file, stat.modified, stat.size));
      }

      final maxBytes = maxMb * 1024 * 1024;
      if (totalBytes > maxBytes) {
        // Sort oldest modified first
        fileStats.sort((a, b) => a.$2.compareTo(b.$2));
        for (final (file, _, size) in fileStats) {
          try {
            file.deleteSync();
            totalBytes -= size;
          } on Object {
            // Continue with other files
          }
          if (totalBytes <= maxBytes * 0.85) break;
        }
      }
    } on Object {
      // Eviction error non-critical
    }
  }

  String _fileNameFor(String trackId) {
    final safe = trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '$safe.m4a';
  }
}
