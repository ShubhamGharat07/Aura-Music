import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/des_ecb.dart';

Uint8List hex(String value) {
  final bytes = Uint8List(value.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(value.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

String hexOf(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List pkcs5Pad(Uint8List input) {
  final pad = 8 - (input.length % 8);
  final out = Uint8List(input.length + pad)..setRange(0, input.length, input);
  for (var i = input.length; i < out.length; i++) {
    out[i] = pad;
  }
  return out;
}

void main() {
  test('decrypts the canonical FIPS 46-3 test vector', () {
    final key = hex('133457799BBCDFF1');
    final ciphertext = hex('85E813540F0AB405');
    expect(hexOf(DesEcb.decryptBytes(ciphertext, key)), '0123456789abcdef');
  });

  test('encrypts the canonical FIPS 46-3 test vector', () {
    final key = hex('133457799BBCDFF1');
    final plaintext = hex('0123456789ABCDEF');
    expect(hexOf(DesEcb.encryptBytes(plaintext, key)), '85e813540f0ab405');
  });

  test('round-trips a JioSaavn-style URL through base64 + PKCS5', () {
    const url = 'https://aac.saavncdn.com/123/song_96.mp4';
    final key = Uint8List.fromList(utf8.encode('38346591'));
    final cipher = DesEcb.encryptBytes(
      pkcs5Pad(Uint8List.fromList(utf8.encode(url))),
      key,
    );

    final decrypted = DesEcb.decryptBase64ToString(
      base64.encode(cipher),
      '38346591',
    );

    expect(decrypted, url);
  });

  test('returns empty string for blank or malformed input', () {
    expect(DesEcb.decryptBase64ToString('', '38346591'), '');
    expect(DesEcb.decryptBase64ToString('not-base64!!', '38346591'), '');
  });
}
