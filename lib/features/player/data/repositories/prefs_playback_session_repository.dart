import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/utils/track_json.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/domain/repositories/playback_session_repository.dart';

/// [PlaybackSessionRepository] backed by [SharedPreferences] and the shared
/// [trackToJson] / [trackFromJson] codec.
///
/// Reads are defensive: a partially written or corrupt payload decodes to
/// `null` so a bad snapshot can never block startup. The JSON keys are kept
/// short because this is rewritten every few seconds while playing.
final class PrefsPlaybackSessionRepository
    implements PlaybackSessionRepository {
  /// Creates the repository.
  const PrefsPlaybackSessionRepository(this._prefs);

  /// Storage key (also wiped by `DataResetService.clearAll`).
  static const String key = 'player.session';

  final SharedPreferences _prefs;

  @override
  Future<PlaybackSession?> read() async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final queue = <Track>[];
      for (final item in decoded['q'] as List<dynamic>? ?? const []) {
        if (item is Map<String, dynamic>) queue.add(trackFromJson(item));
      }
      if (queue.isEmpty) return null;
      return PlaybackSession(
        queue: queue,
        index: (decoded['i'] as num?)?.toInt() ?? 0,
        position: Duration(milliseconds: (decoded['p'] as num?)?.toInt() ?? 0),
        shuffle: decoded['sh'] == true,
        repeat: _repeat(decoded['r']),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(PlaybackSession session) async {
    if (session.isEmpty) return clear();
    await _prefs.setString(
      key,
      jsonEncode({
        'q': session.queue.map(trackToJson).toList(),
        'i': session.index,
        'p': session.position.inMilliseconds,
        'sh': session.shuffle,
        'r': session.repeat.name,
      }),
    );
  }

  @override
  Future<void> clear() => _prefs.remove(key);

  RepeatMode _repeat(Object? raw) {
    for (final mode in RepeatMode.values) {
      if (mode.name == raw) return mode;
    }
    return RepeatMode.off;
  }
}
