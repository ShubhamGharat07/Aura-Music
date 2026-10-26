import 'package:aura_music/features/catalog/domain/entities/album.dart';

/// Card labels for catalog entities (PRD 7.5).

/// Album labels used by grid cards.
extension AlbumCardLabel on Album {
  /// Secondary card line.
  ///
  /// Album feeds (new releases, trending) ship without primary artists, so the
  /// song count is preferred and the catalog language is the fallback; only
  /// when neither is known does the card fall back to the artist.
  String get cardSubtitle {
    final count = songCount ?? 0;
    if (count > 0) return count == 1 ? '1 song' : '$count songs';
    final code = language?.trim() ?? '';
    if (code.isEmpty) return artist;
    return '${code[0].toUpperCase()}${code.substring(1)}';
  }
}
