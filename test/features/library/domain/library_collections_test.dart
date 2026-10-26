import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/library/domain/library_collections.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  const tracks = [
    Track(id: '1', title: 'A', artist: 'X', album: 'Alpha'),
    Track(id: '2', title: 'B', artist: 'X', album: 'Alpha'),
    Track(id: '3', title: 'C', artist: 'Y', album: 'Beta'),
    Track(id: '4', title: 'D', artist: 'Y'),
  ];

  test('groupByAlbum groups with an artist subtitle, first-seen order', () {
    final groups = groupByAlbum(tracks);

    expect(groups.map((g) => g.title), ['Alpha', 'Beta', 'Unknown album']);
    expect(groups.first.count, 2);
    expect(groups.first.subtitle, 'X');
    expect(groups.first.tracks.map((t) => t.id), ['1', '2']);
  });

  test('groupByArtist groups by artist and leaves subtitle null', () {
    final groups = groupByArtist(tracks);

    expect(groups.map((g) => g.title), ['X', 'Y']);
    expect(groups.first.tracks.map((t) => t.id), ['1', '2']);
    expect(groups.first.subtitle, isNull);
  });

  test('a blank album falls back to Unknown album', () {
    final groups = groupByAlbum(const [
      Track(id: '9', title: 'Z', artist: 'Q'),
    ]);

    expect(groups.single.title, 'Unknown album');
  });
}
