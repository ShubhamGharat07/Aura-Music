import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';

/// DTO parser for JioSaavn show payloads (e.g. from `content.getTopShows` or `autocomplete.get`).
final class JiosaavnPodcastModel {
  /// Creates the model.
  const JiosaavnPodcastModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.description,
    this.seasonNumber,
    this.badge,
    this.explicitContent = false,
  });

  /// Parses a show node.
  factory JiosaavnPodcastModel.fromJson(Map<String, dynamic> json) {
    final moreInfo = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rawImage = json['image'] as String? ??
        moreInfo['square_image'] as String? ??
        moreInfo['square_image_url'] as String?;

    final upgradedImage = rawImage != null && rawImage.isNotEmpty
        ? rawImage
            .replaceFirst('http://', 'https://')
            .replaceFirst('150x150', '500x500')
        : null;

    final season = int.tryParse('${moreInfo['season_number'] ?? ''}');

    return JiosaavnPodcastModel(
      id: '${json['id'] ?? ''}',
      title: _cleanText(json['title'] as String?),
      subtitle: _cleanText(json['subtitle'] as String? ?? moreInfo['badge'] as String?),
      imageUrl: upgradedImage,
      description: _cleanText(json['description'] as String? ?? moreInfo['description'] as String?),
      seasonNumber: season,
      badge: moreInfo['badge'] as String?,
      explicitContent: json['explicit_content'] == '1' || json['explicit_content'] == 1,
    );
  }

  /// Parses a list of show nodes.
  static List<JiosaavnPodcastModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnPodcastModel.fromJson)
          .where((m) => m.id.isNotEmpty && m.title.isNotEmpty)
          .toList(growable: false);

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? description;
  final int? seasonNumber;
  final String? badge;
  final bool explicitContent;

  /// Converts to domain entity.
  PodcastShow toEntity() => PodcastShow(
        id: id,
        title: title,
        subtitle: subtitle,
        artUrl: imageUrl,
        description: description,
        latestSeason: seasonNumber,
        badge: badge,
        explicitContent: explicitContent,
      );

  static final RegExp _whitespace = RegExp(r'\s+');

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
