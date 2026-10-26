import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/catalog/data/models/jiosaavn_album_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_artist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_genre_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_playlist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';

void main() {
  group('JiosaavnSongModel', () {
    test('parses id, title variants and the more_info block', () {
      final model = JiosaavnSongModel.fromJson(<String, dynamic>{
        'id': 'abc',
        'title': 'Neon Horizon',
        'image': 'http://c.saavncdn.com/x-150x150.jpg',
        'more_info': <String, dynamic>{
          'duration': '215',
          'album': 'Nightfall',
          'encrypted_media_url': 'enc',
          '320kbps': 'true',
          'artistMap': <String, dynamic>{
            'primary_artists': <dynamic>[
              <String, dynamic>{'id': '1', 'name': 'Aurora Skies'},
              <String, dynamic>{'id': '2', 'name': 'Nova'},
            ],
          },
        },
      });

      expect(model.id, 'abc');
      expect(model.rawTitle, 'Neon Horizon');
      expect(model.info.durationSeconds, 215);
      expect(model.info.album, 'Nightfall');
      expect(model.info.encryptedMediaUrl, 'enc');
      expect(model.info.prefers320, isTrue);
      expect(model.info.artistNames, <String>['Aurora Skies', 'Nova']);
    });

    test(
      'falls back through name / song and tolerates a missing more_info',
      () {
        final model = JiosaavnSongModel.fromJson(<String, dynamic>{
          'id': 'z',
          'song': 'Plain',
        });

        expect(model.rawTitle, 'Plain');
        expect(model.info.durationSeconds, 0);
        expect(model.info.prefers320, isTrue);
        expect(model.info.artistNames, isEmpty);
      },
    );

    test('reads 320kbps=false as a lower-quality preference', () {
      final model = JiosaavnSongModel.fromJson(<String, dynamic>{
        'id': 'x',
        'more_info': <String, dynamic>{'320kbps': 'false'},
      });

      expect(model.info.prefers320, isFalse);
    });

    test('reads the top-level play_count and defaults to 0', () {
      final model = JiosaavnSongModel.fromJson(<String, dynamic>{
        'id': 'x',
        'play_count': '6713502',
      });

      expect(model.playCount, 6713502);
      expect(
        JiosaavnSongModel.fromJson(<String, dynamic>{'id': 'y'}).playCount,
        0,
      );
    });

    test('listFrom skips malformed entries and non-lists', () {
      final models = JiosaavnSongModel.listFrom(<dynamic>[
        <String, dynamic>{'id': 'a'},
        'nope',
        <String, dynamic>{'id': 'b'},
      ]);

      expect(models.map((m) => m.id), <String>['a', 'b']);
      expect(JiosaavnSongModel.listFrom(null), isEmpty);
    });
  });

  group('JiosaavnAlbumModel', () {
    test('prefers more_info.release_date and reads song_count', () {
      final model = JiosaavnAlbumModel.fromJson(<String, dynamic>{
        'id': 'al1',
        'title': 'Nightfall',
        'year': '2019',
        'more_info': <String, dynamic>{
          'release_date': '2021-08-13',
          'song_count': '9',
          'artistMap': <String, dynamic>{
            'primary_artists': <dynamic>[
              <String, dynamic>{'id': '1', 'name': 'Aurora Skies'},
            ],
          },
        },
      });

      expect(model.id, 'al1');
      expect(model.resolvedYear, 2021);
      expect(model.songCount, 9);
      expect(model.artistNames, <String>['Aurora Skies']);
    });

    test('resolvedYear falls back to the top-level year field', () {
      final model = JiosaavnAlbumModel.fromJson(<String, dynamic>{
        'id': 'al2',
        'year': '2019',
      });

      expect(model.resolvedYear, 2019);
      expect(model.songCount, isNull);
    });

    test('album detail parses the ordered song list', () {
      final detail = JiosaavnAlbumDetailModel.fromJson(<String, dynamic>{
        'id': 'al1',
        'title': 'Bhediya',
        'list': <dynamic>[
          <String, dynamic>{'id': 's1', 'title': 'Thumkeshwari'},
        ],
      });

      expect(detail.album.title, 'Bhediya');
      expect(detail.songs.single.id, 's1');
    });
  });

  group('JiosaavnArtistModel', () {
    test('artistId wins over id and name falls back to title', () {
      final model = JiosaavnArtistModel.fromJson(<String, dynamic>{
        'id': 'ignored',
        'artistId': 'ar1',
        'name': 'Arijit Singh',
        'role': 'Singer',
      });

      expect(model.id, 'ar1');
      expect(model.rawName, 'Arijit Singh');
      expect(model.role, 'Singer');
    });

    test('artist detail joins the bio and parses top content', () {
      final detail = JiosaavnArtistDetailModel.fromJson(<String, dynamic>{
        'artistId': 'ar1',
        'name': 'Arijit Singh',
        'follower_count': '1000',
        'bio': <dynamic>['Eclectic', 'singer.'],
        'topSongs': <dynamic>[
          <String, dynamic>{'id': 's1', 'title': 'Kesariya'},
        ],
        'topAlbums': <dynamic>[
          <String, dynamic>{'id': 'al1', 'title': 'Brahmastra'},
        ],
      });

      expect(detail.followerCount, 1000);
      expect(detail.bio, 'Eclectic singer.');
      expect(detail.topSongs.single.title, 'Kesariya');
      expect(detail.albums.single.title, 'Brahmastra');
    });

    test('an empty bio becomes null', () {
      final detail = JiosaavnArtistDetailModel.fromJson(<String, dynamic>{
        'artistId': 'a',
        'bio': <dynamic>[],
      });

      expect(detail.bio, isNull);
    });
  });

  group('JiosaavnPlaylistModel', () {
    test('reads songCount from list_count / numsongs / more_info', () {
      expect(
        JiosaavnPlaylistModel.fromJson(<String, dynamic>{
          'id': 'p',
          'list_count': '20',
        }).songCount,
        20,
      );
      expect(
        JiosaavnPlaylistModel.fromJson(<String, dynamic>{
          'id': 'p',
          'numsongs': '7',
        }).songCount,
        7,
      );
      expect(
        JiosaavnPlaylistModel.fromJson(<String, dynamic>{
          'id': 'p',
          'more_info': <String, dynamic>{'song_count': '3'},
        }).songCount,
        3,
      );
    });

    test('playlist detail parses the ordered song list', () {
      final detail = JiosaavnPlaylistDetailModel.fromJson(<String, dynamic>{
        'id': 'pl1',
        'title': 'Love',
        'list': <dynamic>[
          <String, dynamic>{'id': 's1', 'title': 'Song'},
        ],
      });

      expect(detail.playlist.title, 'Love');
      expect(detail.songs.single.title, 'Song');
    });
  });

  group('JiosaavnGenreModel', () {
    JiosaavnGenreModel entry(
      String subType,
      Object? tags, {
      String? title = 'Chill',
    }) => JiosaavnGenreModel.fromJson(<String, dynamic>{
      'id': 16,
      'title': title,
      'image': 'http://c.saavncdn.com/g-150x150.jpg',
      'more_info': <String, dynamic>{'sub_type': subType, 'tags': tags},
    });

    test('parses a browse entry and trims the padded title', () {
      final genre = entry('mood', <String, dynamic>{
        'mood': <dynamic>['Chill'],
      }, title: '  Chill ');

      expect(genre.id, '16');
      expect(genre.rawTitle, 'Chill');
      expect(genre.isBrowsable, isTrue);
      expect(genre.isTaggedMoodOrGenre, isTrue);
    });

    test(
      'keeps situation channels but drops podcasts, seasonality and untitled',
      () {
        expect(entry('music_plus', <dynamic>[]).isBrowsable, isFalse);
        expect(
          entry('mood', <String, dynamic>{
            'seasonality': <dynamic>['1990s'],
          }).isBrowsable,
          isFalse,
        );
        expect(entry('genre', null, title: '   ').isBrowsable, isFalse);
        expect(
          entry('genre', <String, dynamic>{
            'situation': <dynamic>['Party'],
          }).isBrowsable,
          isTrue,
        );
      },
    );

    test('listFrom skips malformed entries and non-lists', () {
      final models = JiosaavnGenreModel.listFrom(<dynamic>[
        <String, dynamic>{'id': 'a'},
        'nope',
        <String, dynamic>{'id': 'b'},
      ]);

      expect(models.map((m) => m.id), <String>['a', 'b']);
      expect(JiosaavnGenreModel.listFrom(null), isEmpty);
    });
  });
}
