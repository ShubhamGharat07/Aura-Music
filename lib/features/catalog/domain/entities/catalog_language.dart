import 'package:equatable/equatable.dart';

/// Catalog language filter (PRD S03).

/// A language offered by the catalog.
///
/// The API filters content by language (`languages=<code>`) and ships no
/// endpoint that lists them (`content.getLanguages` is unsupported), so the
/// supported set is declared here — the same approach the official clients
/// take. Only the filter is local: every song still comes from the API.
final class CatalogLanguage extends Equatable {
  /// Creates a catalog language.
  const CatalogLanguage({required this.code, required this.name});

  /// Value sent as `languages=<code>`.
  final String code;

  /// Display name.
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// Catalog languages verified against the live API, most likely first.
const List<CatalogLanguage> kCatalogLanguages = <CatalogLanguage>[
  CatalogLanguage(code: 'hindi', name: 'Hindi'),
  CatalogLanguage(code: 'english', name: 'English'),
  CatalogLanguage(code: 'punjabi', name: 'Punjabi'),
  CatalogLanguage(code: 'marathi', name: 'Marathi'),
  CatalogLanguage(code: 'tamil', name: 'Tamil'),
  CatalogLanguage(code: 'telugu', name: 'Telugu'),
  CatalogLanguage(code: 'bengali', name: 'Bengali'),
  CatalogLanguage(code: 'kannada', name: 'Kannada'),
  CatalogLanguage(code: 'malayalam', name: 'Malayalam'),
  CatalogLanguage(code: 'gujarati', name: 'Gujarati'),
  CatalogLanguage(code: 'bhojpuri', name: 'Bhojpuri'),
  CatalogLanguage(code: 'urdu', name: 'Urdu'),
  CatalogLanguage(code: 'haryanvi', name: 'Haryanvi'),
  CatalogLanguage(code: 'rajasthani', name: 'Rajasthani'),
  CatalogLanguage(code: 'odia', name: 'Odia'),
  CatalogLanguage(code: 'assamese', name: 'Assamese'),
];
