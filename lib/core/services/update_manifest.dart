/// One APK declared in the release's update.json.
final class UpdateAsset {
  const UpdateAsset._(
    this.name,
    this.abi,
    this.size,
    this.sha256,
    this.versionCode,
  );

  final String name;
  final String abi;
  final int size;
  final String sha256;
  final int? versionCode;

  static const _abis = {
    'universal',
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
    'x86',
  };
  static final _name = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,95}\.apk$');
  static final _digest = RegExp(r'^[a-fA-F0-9]{64}$');
  static const maxApkSize = 512 * 1024 * 1024;

  static UpdateAsset parse(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid APK entry');
    }
    final name = json['name'];
    final abi = json['abi'];
    final size = json['size'];
    final digest = json['sha256'];
    final code = json['versionCode'];
    if (name is! String ||
        !_name.hasMatch(name) ||
        abi is! String ||
        !_abis.contains(abi) ||
        size is! int ||
        size <= 0 ||
        size > maxApkSize ||
        digest is! String ||
        !_digest.hasMatch(digest) ||
        (code != null && !_validCode(code))) {
      throw const FormatException('Invalid APK metadata');
    }
    return UpdateAsset._(name, abi, size, digest.toLowerCase(), code as int?);
  }

  Map<String, Object> toJson() => {
    'name': name,
    'abi': abi,
    'size': size,
    'sha256': sha256,
    'versionCode': ?versionCode,
  };
}

/// Stable release metadata published next to the signed APKs.
final class UpdateManifest {
  const UpdateManifest._(this.versionCode, this.versionName, this.assets);

  final int versionCode;
  final String versionName;
  final List<UpdateAsset> assets;

  static UpdateManifest parse(Map<String, dynamic> json) {
    final code = json['versionCode'];
    final name = json['versionName'];
    final entries = json['assets'];
    if (!_validCode(code) ||
        name is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name) ||
        entries is! List<dynamic> ||
        entries.isEmpty ||
        entries.length > 5) {
      throw const FormatException('Invalid update manifest');
    }
    final assets = entries.map(UpdateAsset.parse).toList(growable: false);
    if (assets.map((asset) => asset.abi).toSet().length != assets.length ||
        assets.map((asset) => asset.name).toSet().length != assets.length) {
      throw const FormatException('Duplicate APK metadata');
    }
    return UpdateManifest._(code as int, name, assets);
  }

  int codeFor(UpdateAsset asset) => asset.versionCode ?? versionCode;

  UpdateAsset? select(
    List<String> supportedAbis, {
    required bool Function(UpdateAsset) matchesRelease,
  }) {
    for (final abi in [...supportedAbis, 'universal']) {
      for (final asset in assets) {
        if (asset.abi == abi && matchesRelease(asset)) return asset;
      }
    }
    return null;
  }
}

bool _validCode(Object? code) => code is int && code > 0 && code <= 2100000000;
