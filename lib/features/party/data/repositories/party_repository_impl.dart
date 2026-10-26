import 'dart:async';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/data/datasources/party_codec.dart';
import 'package:aura_music/features/party/data/datasources/party_permissions.dart';
import 'package:aura_music/features/party/data/datasources/party_transport.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_role.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/entities/party_status.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// [PartyRepository] on top of a [PartyTransport].
///
/// Every outcome the user can act on (permission refused, radio off, a link
/// that dropped) is published through [watch] as a [PartyStatus] plus a
/// [PartySession.notice], so the sheet has a single source of truth. The
/// returned `Either` therefore only carries failures that are not already
/// reflected in the session, and the caller may ignore it.
///
/// A tick or a snapshot sent with nobody attached is not an error: the link is
/// simply idle, and the next change or tick delivers.
final class PartyRepositoryImpl implements PartyRepository {
  /// Creates the repository and starts listening to [transport].
  PartyRepositoryImpl(this._transport, this._permissions) {
    // Lives as long as the app: the repository is registered as a singleton.
    _transport.events.listen(_onTransportEvent);
  }

  final PartyTransport _transport;
  final PartyPermissionGate _permissions;
  final PartyFrameAssembler _assembler = PartyFrameAssembler();
  final StreamController<PartySession> _sessions =
      StreamController<PartySession>.broadcast();
  final StreamController<PartyMessage> _messages =
      StreamController<PartyMessage>.broadcast();
  PartySession _session = const PartySession();
  int _seq = 0;

  @override
  Stream<PartySession> watch() {
    // Replays the current session first, and attaches to the live stream
    // synchronously, so nothing can be emitted in between and lost.
    final controller = StreamController<PartySession>();
    controller.add(_session);
    final sub = _sessions.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  @override
  Stream<PartyMessage> watchMessages() => _messages.stream;

  @override
  Future<Either<Failure, Unit>> host() async {
    if (!await _ensureAllowed(host: true)) return const Right(unit);
    _emit(
      const PartySession(role: PartyRole.host, status: PartyStatus.hosting),
    );
    try {
      await _transport.host(name: await _transport.deviceName());
      return const Right(unit);
    } on Object catch (error) {
      // Stopped while starting: the failure belongs to a session the user has
      // already left, so it must not bring the controls back.
      if (_session.role != PartyRole.host) return const Right(unit);
      _emit(
        PartySession(
          role: PartyRole.host,
          status: PartyStatus.failed,
          notice: _reason(error),
        ),
      );
      return Left(UnknownFailure(_reason(error)));
    }
  }

  @override
  Future<Either<Failure, Unit>> discover({required bool active}) async {
    if (!active) {
      await _transport.stopScan();
      _emit(const PartySession());
      return const Right(unit);
    }
    if (!await _ensureAllowed(host: false)) return const Right(unit);
    _emit(
      const PartySession(role: PartyRole.guest, status: PartyStatus.scanning),
    );
    try {
      await _transport.startScan();
      return const Right(unit);
    } on Object catch (error) {
      if (_session.role != PartyRole.guest) return const Right(unit);
      _emit(_failed(_reason(error)));
      return Left(UnknownFailure(_reason(error)));
    }
  }

  @override
  Future<Either<Failure, Unit>> join(String peerId) async {
    if (!await _ensureAllowed(host: false)) return const Right(unit);
    _emit(
      const PartySession(role: PartyRole.guest, status: PartyStatus.connecting),
    );
    try {
      await _transport.join(peerId);
      // Announces this device, which also asks the host for the current state:
      // a snapshot can be published before the subscription is in place.
      await _send(PartyHelloMessage(await _transport.deviceName()));
      return const Right(unit);
    } on Object catch (error) {
      // Cancelled mid-connect (or already following another host): a link that
      // failed after the fact must not turn the controls back on.
      if (_session.role != PartyRole.guest) return const Right(unit);
      _emit(_failed(_reason(error)));
      return Left(UnknownFailure(_reason(error)));
    }
  }

  @override
  Future<Either<Failure, Unit>> publish(
    PartySnapshot snapshot, {
    required bool full,
  }) async {
    if (!_session.isHosting || snapshot.isEmpty) return const Right(unit);
    try {
      await _send(
        full
            ? PartyStateMessage(snapshot)
            : PartyTickMessage(
                index: snapshot.index,
                position: snapshot.position,
                playing: snapshot.playing,
              ),
      );
      return const Right(unit);
    } on Object {
      // No guest is subscribed (yet): the next tick or change delivers.
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, Unit>> leave() async {
    if (_session.isHosting || _session.isConnected) {
      try {
        await _send(const PartyByeMessage());
      } on Object {
        // The other side already went away.
      }
    }
    try {
      await _transport.stop();
    } on Object {
      // Nothing left to tear down.
    } finally {
      _assembler.reset();
      _emit(const PartySession());
    }
    return const Right(unit);
  }

  /// Requests the role's permissions and checks the radio, emitting the
  /// matching session when the device cannot take part.
  Future<bool> _ensureAllowed({required bool host}) async {
    final role = host ? PartyRole.host : PartyRole.guest;
    if (!await _permissions.request(host: host)) {
      _emit(
        PartySession(
          role: role,
          status: PartyStatus.denied,
          notice: 'Allow Bluetooth access to use listen together.',
        ),
      );
      return false;
    }
    if (!await _transport.isReady(host: host)) {
      _emit(
        PartySession(
          role: role,
          status: PartyStatus.unsupported,
          notice: 'Bluetooth is off or unavailable on this device.',
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _send(PartyMessage message) async {
    final frames = PartyCodec.encode(message, seq: _seq);
    _seq = (_seq + 1) & 0xFFFF;
    for (final frame in frames) {
      await _transport.send(frame);
    }
  }

  void _onTransportEvent(PartyTransportEvent event) {
    switch (event) {
      case PartyPeersChanged(:final peers):
        // Scan results keep dripping in for a moment after the scan is stopped
        // (and after a join). Only the scanning status consumes them: letting
        // them through would drag a connected guest back to the scanner and
        // drop it out of "following" mid-song.
        if (!_session.isScanning) return;
        _emit(_session.copyWith(peers: peers));
      case PartySubscribersChanged(:final subscribed):
        if (_session.role != PartyRole.host) return;
        // Also nudges the host's listener to re-share its state with the
        // device that just attached.
        _emit(_session.copyWith(peers: subscribed ? _session.peers : const []));
      case PartyLinkUp(:final name):
        // Only a pending join reacts: a link that finishes connecting after the
        // user cancelled (or while hosting) must stay ignored.
        if (!_session.isConnecting) return;
        _emit(
          _session.copyWith(
            status: PartyStatus.connected,
            hostName: name,
            peers: const [],
          ),
        );
      case PartyLinkDown(:final reason):
        // A drop only matters while this device is the one holding the guest
        // link; a session that is already idle (or hosting) must not be
        // resurrected into a failure by a late event from an old link.
        if (!_session.isConnecting && !_session.isFollowing) return;
        _emit(
          _session.copyWith(
            status: PartyStatus.failed,
            notice: reason ?? 'The session ended.',
          ),
        );
      case PartyDataReceived(:final bytes):
        _onData(bytes);
      case PartyTransportFailure(:final message):
        _emit(_failed(message));
    }
  }

  void _onData(Uint8List bytes) {
    final message = _assembler.add(bytes);
    if (message == null) return;
    if (_session.role == PartyRole.host && message is PartyHelloMessage) {
      final guest = PartyPeer(id: message.name, name: message.name);
      if (!_session.peers.any((peer) => peer.id == guest.id)) {
        _emit(_session.copyWith(peers: [..._session.peers, guest]));
      }
    }
    _messages.add(message);
  }

  PartySession _failed(String reason) => PartySession(
    role: _session.role,
    status: PartyStatus.failed,
    notice: reason,
  );

  String _reason(Object error) {
    final text = error is StateError
        ? error.message.toString()
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }

  void _emit(PartySession session) {
    _session = session;
    if (!_sessions.isClosed) _sessions.add(session);
  }
}
