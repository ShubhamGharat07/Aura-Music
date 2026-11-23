import 'package:flutter_test/flutter_test.dart';
import 'package:aura_music/core/utils/des_ecb.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/podcast/data/models/jiosaavn_episode_model.dart';
import 'package:aura_music/features/podcast/data/models/jiosaavn_podcast_model.dart';
import 'package:aura_music/features/podcast/data/repositories/podcast_repository_impl.dart';
import 'package:aura_music/features/podcast/domain/usecases/get_podcast_episodes.dart';
import 'package:aura_music/features/podcast/presentation/bloc/podcast_cubit.dart';

import '../../helpers/fake_dio.dart';

void main() {
  group('Podcast Models', () {
    test('JiosaavnPodcastModel parses show JSON and upgrades artwork', () {
      final json = {
        'id': '62',
        'title': 'Talking &amp; Music',
        'subtitle': 'Kirthi Shetty',
        'image': 'http://c.sop.saavncdn.com/show-150x150.jpg',
        'description': 'Description &quot;here&quot;',
        'more_info': {'season_number': '3', 'badge': 'EXCLUSIVE'},
        'explicit_content': '0',
      };

      final model = JiosaavnPodcastModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, '62');
      expect(entity.title, 'Talking & Music');
      expect(entity.subtitle, 'Kirthi Shetty');
      expect(entity.artUrl, 'https://c.sop.saavncdn.com/show-500x500.jpg');
      expect(entity.description, 'Description "here"');
      expect(entity.latestSeason, 3);
      expect(entity.badge, 'EXCLUSIVE');
      expect(entity.explicitContent, isFalse);
    });

    test('JiosaavnEpisodeModel parses episode JSON, decrypts stream URL', () {
      const desKey = '38346591';
      const cdnUrl = 'https://aac.saavncdn.com/123/sample_96.mp4';
      final encrypted = DesEcb.encryptStringToBase64(cdnUrl, desKey);

      final json = {
        'id': 'ep_1',
        'title': 'Episode &quot;One&quot;',
        'subtitle': 'Host Name',
        'image': 'http://c.sop.saavncdn.com/ep-150x150.jpg',
        'more_info': {
          'duration': '180',
          'release_date': '2024-01-01',
          'show_id': '62',
          'show_title': 'Talking Music',
          'season_number': '1',
          'episode_number': '1',
          'encrypted_media_url': encrypted,
        },
      };

      final model = JiosaavnEpisodeModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, 'ep_1');
      expect(entity.title, 'Episode "One"');
      expect(entity.showTitle, 'Talking Music');
      expect(entity.duration, const Duration(seconds: 180));
      expect(entity.streamUrl, contains('_320.mp4'));

      // Check conversion to playable Track
      final track = entity.toTrack();
      expect(track.id, 'podcast:ep_1');
      expect(track.title, 'Episode "One"');
      expect(track.artist, 'Host Name');
      expect(track.album, 'Talking Music');
      expect(track.duration, const Duration(seconds: 180));
      expect(track.streamUrl, entity.streamUrl);
    });
  });

  group('PodcastRepositoryImpl', () {
    const baseUrl = 'https://www.jiosaavn.com';

    PodcastRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
        PodcastRepositoryImpl(
          JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
        );

    test('getTopPodcasts returns parsed shows', () async {
      final adapter = FakeHttpAdapter(
        (options) async => switch (options.queryParameters['__call']) {
          'content.getTopShows' => jsonResponse({
            'data': [
              {
                'id': '62',
                'title': 'Talking Music',
                'image': 'https://c.sop.saavncdn.com/Talking-Music-500x500.jpg',
              },
            ],
          }),
          _ => jsonResponse(const {}),
        },
      );

      final result = await repoWith(adapter).getTopPodcasts(limit: 10);
      final shows = result.getOrElse((_) => fail('expected Right'));

      expect(shows, hasLength(1));
      expect(shows.first.id, '62');
      expect(shows.first.title, 'Talking Music');
    });

    test('searchPodcasts uses autocomplete shows', () async {
      final adapter = FakeHttpAdapter(
        (options) async => switch (options.queryParameters['__call']) {
          'autocomplete.get' => jsonResponse({
            'shows': {
              'data': [
                {'id': '309070', 'title': 'The Ranveer Show'},
              ],
            },
          }),
          _ => jsonResponse(const {}),
        },
      );

      final result = await repoWith(adapter).searchPodcasts('ranveer');
      final shows = result.getOrElse((_) => fail('expected Right'));

      expect(shows, hasLength(1));
      expect(shows.first.id, '309070');
      expect(shows.first.title, 'The Ranveer Show');
    });
  });

  group('PodcastCubit', () {
    test('emits loading then ready when episodes fetch succeeds', () async {
      final adapter = FakeHttpAdapter(
        (options) async => switch (options.queryParameters['__call']) {
          'show.getAllEpisodes' => jsonResponse([
            {
              'id': 'ep1',
              'title': 'Ep 1',
              'more_info': {
                'duration': '120',
                'show_id': '62',
                'show_title': 'Show 62',
              },
            },
          ]),
          _ => jsonResponse(const []),
        },
      );

      final remote = JiosaavnRemoteDataSource(
        dioWithAdapter(adapter, baseUrl: 'https://www.jiosaavn.com'),
      );
      final repo = PodcastRepositoryImpl(remote);
      final useCase = GetPodcastEpisodes(repo);
      final cubit = PodcastCubit(useCase);

      expect(
        cubit.stream,
        emitsInOrder([
          isA<PodcastState>().having(
            (s) => s.status,
            'status',
            PodcastStatus.loading,
          ),
          isA<PodcastState>()
              .having((s) => s.status, 'status', PodcastStatus.ready)
              .having((s) => s.episodes, 'episodes', hasLength(1)),
        ]),
      );

      await cubit.load('62');
      await cubit.close();
    });
  });
}
