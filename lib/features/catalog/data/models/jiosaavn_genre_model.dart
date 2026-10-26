// JioSaavn mood / genre channel DTO (PRD 5.1 data layer).

/// One entry of `browse_discover` inside `webapi.getLaunchData`.
///
/// The catalog mixes real mood/genre channels with podcast, promo and
/// seasonality collections, so the raw sub-type and tag keys are kept here and
/// the filtering rules live in [JiosaavnRemoteDataSource.genres].
final class JiosaavnGenreModel {
  /// Creates a genre model.
  const JiosaavnGenreModel({
    required this.id,
    this.title,
    this.imageUrl,
    this.subType,
    this.tagKeys = const <String>[],
  });

  /// Parses a browse entry (`more_info.tags` may be a map or an array).
  factory JiosaavnGenreModel.fromJson(Map<String, dynamic> json) {
    final info = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final tags = info['tags'];
    return JiosaavnGenreModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String?,
      imageUrl: json['image'] as String?,
      subType: info['sub_type'] as String?,
      tagKeys: tags is Map<String, dynamic>
          ? tags.keys.toList(growable: false)
          : const <String>[],
    );
  }

  /// Parses a JSON array of browse entries (missing / malformed tolerated).
  static List<JiosaavnGenreModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnGenreModel.fromJson)
          .toList(growable: false);

  /// Raw JioSaavn channel id.
  final String id;

  /// Channel title.
  final String? title;

  /// Artwork URL (`150x150`).
  final String? imageUrl;

  /// Catalog sub-type (`mood`, `genre`, `music_plus`, …).
  final String? subType;

  /// Tag groups on the channel (`mood`, `genre`, `situation`, `seasonality`).
  final List<String> tagKeys;

  /// Trimmed title (the catalog pads some titles with spaces).
  String get rawTitle => (title ?? '').trim();

  /// True for a mood / genre channel that is safe to show as a filter chip:
  /// a mood or genre sub-type, a usable title, and no seasonality tag (year,
  /// decade and occasion collections are promos rather than moods).
  bool get isBrowsable =>
      (subType == _moodSubType || subType == _genreSubType) &&
      rawTitle.isNotEmpty &&
      !tagKeys.contains(_seasonalityTag);

  /// True when the channel carries a genuine [mood]/[genre] tag, as opposed to
  /// a `situation` tag. Used to list the real moods first.
  bool get isTaggedMoodOrGenre =>
      tagKeys.contains(_moodTag) || tagKeys.contains(_genreTag);

  static const String _moodSubType = 'mood';
  static const String _genreSubType = 'genre';
  static const String _moodTag = 'mood';
  static const String _genreTag = 'genre';
  static const String _seasonalityTag = 'seasonality';
}
