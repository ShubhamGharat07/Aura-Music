import 'dart:convert';
import 'dart:typed_data';

import 'package:aura_music/core/utils/track_json.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Wire codec for listen together (PRD S06).
//
// A BLE notification carries at most ~180 bytes on iOS, so a message travels
// as one or more frames:
//
//     [0xA5][seq lo][seq hi][chunk index][chunk count][payload …]
//
// The `seq` lets the receiver drop a half-received message instead of splicing
// two of them together. JSON keys are single letters and a shared track drops
// its `stream` url: the guest resolves its own stream, which keeps a snapshot
// small and avoids handing a short-lived signed URL to another device.

/// Encodes and decodes party messages.
abstract final class PartyCodec {
  /// Leading byte of every frame.
  static const int magic = 0xA5;

  /// Bytes of frame header before the payload.
  static const int headerSize = 6;

  /// Payload carried per frame: sits inside the ~182 bytes an iOS
  /// notification allows, and inside any negotiated Android MTU.
  static const int maxFramePayload = 160;

  /// A message larger than this is refused (never sent by this app).
  static const int maxMessageBytes = 32 * 1024;

  /// Splits [message] into frames stamped with [seq].
  static List<Uint8List> encode(PartyMessage message, {required int seq}) {
    final bytes = utf8.encode(jsonEncode(_toJson(message)));
    final count = (bytes.length + maxFramePayload - 1) ~/ maxFramePayload;
    return [
      for (var index = 0; index < count; index++)
        _frame(seq: seq, index: index, count: count, payload: bytes),
    ];
  }

  /// Decodes a complete reassembled message, or null when it is unrecognised
  /// or malformed.
  static PartyMessage? decode(Uint8List payload) {
    if (payload.isEmpty || payload.length > maxMessageBytes) return null;
    try {
      final json = jsonDecode(utf8.decode(payload));
      if (json is! Map<String, dynamic>) return null;
      return switch (json['k']) {
        's' => PartyStateMessage(_snapshot(json)),
        'p' => PartyTickMessage(
          index: (json['i'] as num?)?.toInt() ?? 0,
          position: Duration(milliseconds: (json['p'] as num?)?.toInt() ?? 0),
          playing: json['t'] == 1,
        ),
        'h' => PartyHelloMessage(json['d'] as String? ?? 'Nearby device'),
        'b' => const PartyByeMessage(),
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  static Uint8List _frame({
    required int seq,
    required int index,
    required int count,
    required List<int> payload,
  }) {
    final start = index * maxFramePayload;
    final end = start + maxFramePayload > payload.length
        ? payload.length
        : start + maxFramePayload;
    final frame = Uint8List(headerSize + end - start);
    frame[0] = magic;
    frame[1] = seq & 0xFF;
    frame[2] = (seq >> 8) & 0xFF;
    frame[3] = index;
    frame[4] = count;
    frame.setRange(headerSize, frame.length, payload, start);
    return frame;
  }

  static Map<String, Object?> _toJson(PartyMessage message) =>
      switch (message) {
        PartyStateMessage(:final snapshot) => {
          'k': 's',
          'i': snapshot.index,
          'p': snapshot.position.inMilliseconds,
          't': snapshot.playing ? 1 : 0,
          'sh': snapshot.shuffle ? 1 : 0,
          'r': snapshot.repeat.name,
          'q': [for (final track in snapshot.queue) _track(track)],
        },
        PartyTickMessage(:final index, :final position, :final playing) => {
          'k': 'p',
          'i': index,
          'p': position.inMilliseconds,
          't': playing ? 1 : 0,
        },
        PartyHelloMessage(:final name) => {'k': 'h', 'd': name},
        PartyByeMessage() => const {'k': 'b'},
      };

  static Map<String, dynamic> _track(Track track) =>
      trackToJson(track)..remove('stream');

  static PartySnapshot _snapshot(Map<String, dynamic> json) {
    final queue = <Track>[];
    for (final item in json['q'] as List<dynamic>? ?? const []) {
      if (item is Map<String, dynamic>) {
        // Streams are never shared: the follower resolves its own.
        queue.add(trackFromJson({...item, 'stream': null}));
      }
    }
    return PartySnapshot(
      queue: queue,
      index: (json['i'] as num?)?.toInt() ?? 0,
      position: Duration(milliseconds: (json['p'] as num?)?.toInt() ?? 0),
      playing: json['t'] == 1,
      shuffle: json['sh'] == 1,
      repeat: _repeat(json['r']),
    );
  }

  static RepeatMode _repeat(Object? raw) {
    for (final mode in RepeatMode.values) {
      if (mode.name == raw) return mode;
    }
    return RepeatMode.off;
  }
}

/// Reassembles frames produced by [PartyCodec.encode] into messages.
///
/// Frames arrive in order and duplicates are ignored, so a chunk that never
/// showed up only costs the message it belonged to: the next sequence value
/// starts a fresh set. Guest → host messages are a single frame, which is why
/// the host can share one assembler between several guests.
final class PartyFrameAssembler {
  int? _seq;
  List<Uint8List?> _parts = const [];

  /// Feeds one received frame; returns the message once its last chunk has
  /// arrived, or null while chunks are still missing.
  PartyMessage? add(Uint8List frame) {
    if (frame.length <= PartyCodec.headerSize) return null;
    if (frame[0] != PartyCodec.magic) return null;
    final seq = frame[1] | (frame[2] << 8);
    final index = frame[3];
    final count = frame[4];
    if (count == 0 || index >= count) return null;
    if (_seq != seq) {
      _seq = seq;
      _parts = List<Uint8List?>.filled(count, null);
    } else if (_parts.length != count) {
      return null;
    }
    if (_parts[index] != null) return null;
    _parts[index] = frame.sublist(PartyCodec.headerSize);
    for (final part in _parts) {
      if (part == null) return null;
    }
    return PartyCodec.decode(_join());
  }

  /// Forgets a partially received message (used when the link restarts).
  void reset() {
    _seq = null;
    _parts = const [];
  }

  Uint8List _join() {
    var total = 0;
    for (final part in _parts) {
      total += part?.length ?? 0;
    }
    final bytes = Uint8List(total);
    var offset = 0;
    for (final part in _parts) {
      if (part == null) continue;
      bytes.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return bytes;
  }
}
