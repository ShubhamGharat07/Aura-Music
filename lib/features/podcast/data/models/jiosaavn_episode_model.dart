import 'package:aura_music/core/utils/des_ecb.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';

/// DTO parser for JioSaavn episode payloads (from `show.getAllEpisodes`).
final class JiosaavnEpisodeModel {
  /// Creates the model.
  const JiosaavnEpisodeModel({
    required this.id,
    required this.title,
    this.showId,
    this.showTitle,
    this.subtitle,
    this.imageUrl,
    this.description,
    this.durationSeconds = 0,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.encryptedMediaUrl,
  });

  /// JioSaavn public CDN symmetric DES/ECB key.
  static const String _desKey = '38346591';
  static final RegExp _qualitySuffix = RegExp(r'_(48|96|160|320)\.');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Parses an episode JSON object.
  factory JiosaavnEpisodeModel.fromJson(Map<String, dynamic> json) {
    final moreInfo = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rawImage = json['image'] as String? ??
        moreInfo['square_image_url'] as String? ??
        moreInfo['square_image'] as String?;

    final upgradedImage = rawImage != null && rawImage.isNotEmpty
        ? rawImage
            .replaceFirst('http://', 'https://')
            .replaceFirst('150x150', '500x500')
        : null;

    final duration = int.tryParse('${moreInfo['duration'] ?? ''}') ?? 0;
    final seasonNum = int.tryParse('${moreInfo['season_no'] ?? moreInfo['season_number'] ?? ''}');
    final episodeNum = int.tryParse('${moreInfo['episode_number'] ?? moreInfo['sequence_number'] ?? ''}');

    return JiosaavnEpisodeModel(
      id: '${json['id'] ?? ''}',
      title: _cleanText(json['title'] as String?),
      showId: '${moreInfo['show_id'] ?? ''}',
      showTitle: _cleanText(moreInfo['show_title'] as String?),
      subtitle: _cleanText(json['subtitle'] as String? ?? json['header_desc'] as String?),
      imageUrl: upgradedImage,
      description: _cleanText(moreInfo['description'] as String?),
      durationSeconds: duration,
      releaseDate: moreInfo['release_date'] as String?,
      seasonNumber: seasonNum,
      episodeNumber: episodeNum,
      encryptedMediaUrl: moreInfo['encrypted_media_url'] as String?,
    );
  }

  /// Parses a list of episode JSON objects.
  static List<JiosaavnEpisodeModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnEpisodeModel.fromJson)
          .where((m) => m.id.isNotEmpty && m.title.isNotEmpty)
          .toList(growable: false);

  final String id;
  final String title;
  final String? showId;
  final String? showTitle;
  final String? subtitle;
  final String? imageUrl;
  final String? description;
  final int durationSeconds;
  final String? releaseDate;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? encryptedMediaUrl;

  /// Decrypts media url to high-bitrate 320 kbps stream URL.
  String? get resolvedStreamUrl {
    if (encryptedMediaUrl == null || encryptedMediaUrl!.isEmpty) return null;
    final decrypted = DesEcb.decryptBase64ToString(encryptedMediaUrl!, _desKey);
    if (decrypted.isEmpty) return null;
    return decrypted
        .replaceFirst('http://', 'https://')
        .replaceFirst(_qualitySuffix, '_320.');
  }

  /// Converts to domain entity.
  PodcastEpisode toEntity() => PodcastEpisode(
        id: id,
        title: title,
        showId: showId,
        showTitle: showTitle,
        subtitle: subtitle,
        artUrl: imageUrl,
        description: description,
        duration: Duration(seconds: durationSeconds),
        releaseDate: releaseDate,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        streamUrl: resolvedStreamUrl,
      );

  static String _cleanText(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    var text = raw;
    if (text.contains('&')) {
      text = text
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }
    return text.replaceAll(_whitespace, ' ').trim();
  }
}
