import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/party/data/datasources/party_codec.dart';
import 'package:aura_music/features/party/data/datasources/party_permissions.dart';
import 'package:aura_music/features/party/data/datasources/party_transport.dart';
import 'package:aura_music/features/party/data/repositories/party_repository_impl.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_role.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/entities/party_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Listen together (PRD S06): the repository on top of a fake BLE transport.

final class _FakeTransport implements PartyTransport {
  final StreamController<PartyTransportEvent> _events =
      StreamController<PartyTransportEvent>.broadcast();
  final List<Uint8List> sent = [];

  bool ready = true;
  bool hosting = false;
  bool scanning = false;
  bool throwOnHost = false;
  String? joinedId;

  @override
  Stream<PartyTransportEvent> get events => _events.stream;

  void emit(PartyTransportEvent event) => _events.add(event);

  Future<void> close() => _events.close();

  @override
  Future<String> deviceName() async => 'Test Phone';

  @override
  Future<bool> isReady({required bool host}) async => ready;

  @override
  Future<void> host({required String name}) async {
    if (throwOnHost) throw StateError('advertise failed');
    hosting = true;
  }

  @override
  Future<void> startScan() async => scanning = true;

  @override
  Future<void> stopScan() async => scanning = false;

  @override
  Future<void> join(String peerId) async => joinedId = peerId;

  @override
  Future<void> send(Uint8List bytes) async => sent.add(bytes);

  @override
  Future<void> stop() async {
    hosting = false;
    scanning = false;
    joinedId = null;
  }
}

final class _FakePermissions implements PartyPermissionGate {
  bool granted = true;
  bool? askedHost;

  @override
  Future<bool> request({required bool host}) async {
    askedHost = host;
    return granted;
  }
}

void main() {
  late _FakeTransport transport;
  late _FakePermissions permissions;
  late PartyRepositoryImpl repository;
  late List<PartySession> sessions;
  late StreamSubscription<PartySession> sessionSub;

  const tracks = [
    Track(id: 'a', title: 'A', artist: 'X', duration: Duration(minutes: 3)),
    Track(id: 'b', title: 'B', artist: 'Y', duration: Duration(minutes: 3)),
  ];

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    transport = _FakeTransport();
    permissions = _FakePermissions();
    repository = PartyRepositoryImpl(transport, permissions);
    sessions = [];
    sessionSub = repository.watch().listen(sessions.add);
  });

  tearDown(() async {
    await sessionSub.cancel();
    await transport.close();
  });

  test('hosting advertises and reports a hosting session', () async {
    await repository.host();
    await settle();

    expect(transport.hosting, isTrue);
    expect(sessions.last.role, PartyRole.host);
    expect(sessions.last.status, PartyStatus.hosting);
    expect(permissions.askedHost, isTrue);
  });

  test('a refused Bluetooth permission reports a denied session', () async {
    permissions.granted = false;

    await repository.host();
    await settle();

    expect(transport.hosting, isFalse);
    expect(sessions.last.status, PartyStatus.denied);
    expect(sessions.last.notice, isNotNull);
  });

  test('a radio that cannot be used reports an unsupported session', () async {
    transport.ready = false;

    await repository.discover(active: true);
    await settle();

    expect(sessions.last.role, PartyRole.guest);
    expect(sessions.last.status, PartyStatus.unsupported);
  });

  test('a failed advertisement reports a failed session', () async {
    transport.throwOnHost = true;

    await repository.host();
    await settle();

    expect(sessions.last.status, PartyStatus.failed);
    expect(sessions.last.notice, 'advertise failed');
  });

  test('discovery lists the nearby sessions it sees', () async {
    await repository.discover(active: true);
    await settle();
    expect(sessions.last.status, PartyStatus.scanning);

    transport.emit(
      const PartyPeersChanged([
        PartyPeer(id: 'p1', name: 'Pixel 7', rssi: -40),
      ]),
    );
    await settle();

    expect(sessions.last.peers, const [
      PartyPeer(id: 'p1', name: 'Pixel 7', rssi: -40),
    ]);

    await repository.discover(active: false);
    await settle();

    expect(transport.scanning, isFalse);
    expect(sessions.last.status, PartyStatus.idle);
  });

  test('joining follows the host and announces this device', () async {
    await repository.join('p1');
    await settle();

    expect(transport.joinedId, 'p1');
    expect(sessions.last.status, PartyStatus.connecting);

    // The hello went out on the link …
    final hello = _decodeAll(transport.sent).single;
    expect(hello, const PartyHelloMessage('Test Phone'));

    transport.emit(const PartyLinkUp(peerId: 'p1', name: 'Pixel 7'));
    await settle();

    expect(sessions.last.status, PartyStatus.connected);
    expect(sessions.last.hostName, 'Pixel 7');
    expect(sessions.last.isFollowing, isTrue);
  });

  test('a dropped link reports the session as failed', () async {
    await repository.join('p1');
    await settle();

    transport.emit(const PartyLinkDown(reason: 'The host stopped sharing.'));
    await settle();

    expect(sessions.last.status, PartyStatus.failed);
    expect(sessions.last.notice, 'The host stopped sharing.');
  });

  test('incoming bytes are decoded into messages', () async {
    final incoming = <PartyMessage>[];
    final sub = repository.watchMessages().listen(incoming.add);
    addTearDown(sub.cancel);

    final frames = PartyCodec.encode(
      PartyStateMessage(PartySnapshot(queue: tracks, index: 1, playing: true)),
      seq: 1,
    );
    for (final frame in frames) {
      transport.emit(PartyDataReceived(frame));
    }
    await settle();

    expect(incoming.length, 1);
    final message = incoming.single as PartyStateMessage;
    expect(message.snapshot.index, 1);
    expect(message.snapshot.playing, isTrue);
  });

  test('a guest that announces itself is listed as connected', () async {
    await repository.host();
    await settle();

    transport.emit(PartySubscribersChanged(subscribed: true));
    for (final frame in PartyCodec.encode(
      const PartyHelloMessage('Pixel 7'),
      seq: 1,
    )) {
      transport.emit(PartyDataReceived(frame));
    }
    await settle();

    expect(sessions.last.isHosting, isTrue);
    expect(sessions.last.peers.map((peer) => peer.name), ['Pixel 7']);

    transport.emit(const PartySubscribersChanged(subscribed: false));
    await settle();

    expect(sessions.last.peers, isEmpty);
  });

  test(
    'a published snapshot travels as frames the other side decodes',
    () async {
      await repository.host();
      await settle();
      transport.sent.clear();

      final snapshot = PartySnapshot(
        queue: tracks,
        index: 1,
        position: const Duration(seconds: 30),
        playing: true,
      );
      await repository.publish(snapshot, full: true);

      final message = _decodeAll(transport.sent).single as PartyStateMessage;
      expect(message.snapshot.queue.map((t) => t.id), ['a', 'b']);
      expect(message.snapshot.index, 1);
      expect(message.snapshot.position, const Duration(seconds: 30));
      expect(message.snapshot.playing, isTrue);
    },
  );

  test('publishing is a no-op before hosting', () async {
    await repository.publish(
      const PartySnapshot(queue: tracks, index: 0),
      full: true,
    );

    expect(transport.sent, isEmpty);
  });

  test('leaving ends the session and tells the other side', () async {
    await repository.host();
    await settle();
    transport.emit(const PartyLinkUp(peerId: 'p1', name: 'Pixel 7'));
    await settle();
    transport.sent.clear();

    await repository.leave();
    await settle();

    expect(_decodeAll(transport.sent).single, const PartyByeMessage());
    expect(transport.hosting, isFalse);
    expect(sessions.last.status, PartyStatus.idle);
  });
}

/// Decodes every frame the transport sent, in order.
List<PartyMessage> _decodeAll(List<Uint8List> frames) {
  final assembler = PartyFrameAssembler();
  final messages = <PartyMessage>[];
  for (final frame in frames) {
    final message = assembler.add(frame);
    if (message != null) messages.add(message);
  }
  return messages;
}
