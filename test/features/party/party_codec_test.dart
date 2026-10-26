import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/party/data/datasources/party_codec.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Listen together (PRD S06) wire codec.

Track _track(int index) => Track(
  id: 't$index',
  title: 'Track $index',
  artist: 'Artist $index',
  album: 'Album $index',
  artUrl: 'https://art.example/$index.jpg',
  duration: const Duration(minutes: 3),
  streamUrl: 'https://stream.example/$index',
);

List<Track> _queue(int count) => [for (var i = 0; i < count; i++) _track(i)];

/// Feeds every frame to a fresh assembler and returns the last message.
PartyMessage? _reassemble(List<Uint8List> frames) {
  final assembler = PartyFrameAssembler();
  PartyMessage? message;
  for (final frame in frames) {
    message = assembler.add(frame) ?? message;
  }
  return message;
}

void main() {
  test('a state message survives a round trip', () {
    final snapshot = PartySnapshot(
      queue: _queue(2),
      index: 1,
      position: const Duration(seconds: 42),
      playing: true,
      shuffle: true,
      repeat: RepeatMode.all,
    );

    final message = _reassemble(
      PartyCodec.encode(PartyStateMessage(snapshot), seq: 1),
    );

    expect(message, isA<PartyStateMessage>());
    final decoded = (message! as PartyStateMessage).snapshot;
    expect(decoded.queue.map((t) => t.id), snapshot.queue.map((t) => t.id));
    expect(decoded.index, 1);
    expect(decoded.position, const Duration(seconds: 42));
    expect(decoded.playing, isTrue);
    expect(decoded.shuffle, isTrue);
    expect(decoded.repeat, RepeatMode.all);
  });

  test('a shared track never carries its stream url', () {
    final snapshot = PartySnapshot(queue: _queue(1), index: 0);

    final frames = PartyCodec.encode(PartyStateMessage(snapshot), seq: 1);
    final decoded = _reassemble(frames)! as PartyStateMessage;

    expect(snapshot.queue.first.streamUrl, isNotNull);
    expect(decoded.snapshot.queue.first.streamUrl, isNull);
  });

  test('a long queue is split into frames and reassembled', () {
    final snapshot = PartySnapshot(queue: _queue(40), index: 12, playing: true);

    final frames = PartyCodec.encode(PartyStateMessage(snapshot), seq: 7);

    expect(frames.length, greaterThan(1));
    for (final frame in frames) {
      expect(
        frame.length,
        lessThanOrEqualTo(PartyCodec.headerSize + PartyCodec.maxFramePayload),
      );
      expect(frame[0], PartyCodec.magic);
    }
    final decoded = _reassemble(frames)! as PartyStateMessage;
    expect(decoded.snapshot.queue.length, 40);
    expect(decoded.snapshot.index, 12);
  });

  test('chunks that arrive out of order still reassemble', () {
    final frames = PartyCodec.encode(
      PartyStateMessage(PartySnapshot(queue: _queue(40), index: 3)),
      seq: 9,
    );

    final assembler = PartyFrameAssembler();
    PartyMessage? message;
    for (final frame in frames.reversed) {
      message = assembler.add(frame) ?? message;
    }

    expect(message, isA<PartyStateMessage>());
    expect((message! as PartyStateMessage).snapshot.queue.length, 40);
  });

  test('a repeated chunk is ignored instead of splicing the payload', () {
    final frames = PartyCodec.encode(
      PartyStateMessage(PartySnapshot(queue: _queue(30), index: 0)),
      seq: 4,
    );

    final assembler = PartyFrameAssembler();
    PartyMessage? message;
    for (final frame in [...frames, frames.first]) {
      message = assembler.add(frame) ?? message;
    }

    expect(message, isA<PartyStateMessage>());
    expect((message! as PartyStateMessage).snapshot.queue.length, 30);
  });

  test('a half-received message is dropped when the next one starts', () {
    final assembler = PartyFrameAssembler();
    final partial = PartyCodec.encode(
      PartyStateMessage(PartySnapshot(queue: _queue(40), index: 0)),
      seq: 1,
    );
    expect(assembler.add(partial.first), isNull);

    final next = PartyCodec.encode(const PartyHelloMessage('Pixel'), seq: 2);

    expect(assembler.add(next.single), const PartyHelloMessage('Pixel'));
  });

  test('a new link forgets a partially received message', () {
    final assembler = PartyFrameAssembler();
    final frames = PartyCodec.encode(
      PartyStateMessage(PartySnapshot(queue: _queue(40), index: 0)),
      seq: 5,
    );
    assembler.add(frames.first);

    assembler.reset();

    PartyMessage? message;
    for (final frame in frames) {
      message = assembler.add(frame) ?? message;
    }
    expect(message, isA<PartyStateMessage>());
  });

  test('garbage frames decode to nothing', () {
    final assembler = PartyFrameAssembler();

    expect(assembler.add(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7])), isNull);
    expect(assembler.add(Uint8List.fromList([PartyCodec.magic])), isNull);
    expect(
      assembler.add(
        Uint8List.fromList([
          PartyCodec.magic, 0, 0, 0, 1, // a well-formed frame …
          0xFF, 0xFE, 0xFD, // … with a payload that is not JSON.
        ]),
      ),
      isNull,
    );
  });

  test('hello, bye and tick messages survive a round trip', () {
    expect(
      _reassemble(
        PartyCodec.encode(const PartyHelloMessage('Pixel 7'), seq: 1),
      ),
      const PartyHelloMessage('Pixel 7'),
    );
    expect(
      _reassemble(PartyCodec.encode(const PartyByeMessage(), seq: 2)),
      const PartyByeMessage(),
    );
    expect(
      _reassemble(
        PartyCodec.encode(
          const PartyTickMessage(
            index: 2,
            position: Duration(seconds: 7),
            playing: false,
          ),
          seq: 3,
        ),
      ),
      const PartyTickMessage(
        index: 2,
        position: Duration(seconds: 7),
        playing: false,
      ),
    );
  });
}
