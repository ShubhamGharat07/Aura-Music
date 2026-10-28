import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/usecases/discover_party.dart';
import 'package:aura_music/features/party/domain/usecases/host_party.dart';
import 'package:aura_music/features/party/domain/usecases/join_party.dart';
import 'package:aura_music/features/party/domain/usecases/leave_party.dart';
import 'package:aura_music/features/party/domain/usecases/publish_party_state.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_messages.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_session.dart';
import 'package:aura_music/features/party/presentation/bloc/party_event.dart';
import 'package:aura_music/features/party/presentation/bloc/party_state.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';

// Listen together (PRD S06): the host is authoritative, guests follow.
//
// The host mirrors every change of the global [PlayerBloc] onto the link, sends
// a position tick every few seconds while playing, and answers a newly attached
// guest with the full state. A guest applies what it receives to its own player
// and corrects drift on each tick, which is what keeps both devices on the same
// second of the same song without sharing the audio stream itself.

/// Orchestrates a party session on top of the global player.
final class PartyBloc extends Bloc<PartyEvent, PartyState> {
  /// Creates the bloc, wiring the repository streams and the local player.
  PartyBloc(
    this._watchSession,
    this._watchMessages,
    this._host,
    this._discover,
    this._join,
    this._publish,
    this._leave, {
    required PlayerBloc player,
    Duration publishInterval = AppConstants.partyPublishInterval,
  }) : _player = player,
       _publishInterval = publishInterval,
       super(const PartyState()) {
    on<PartyHostRequested>(_onHost);
    on<PartyDiscoveryToggled>(_onDiscover);
    on<PartyJoinRequested>(_onJoin);
    on<PartyLeaveRequested>(_onLeave, transformer: sequential());
    on<PartySessionChanged>(_onSessionChanged);
    on<PartyMessageReceived>(_onMessage);
    on<PartyPlayerChanged>(_onPlayerChanged, transformer: droppable());
    on<PartyTickElapsed>(_onTickElapsed, transformer: droppable());
    _sessionSub = _watchSession().listen(
      (session) => add(PartySessionChanged(session)),
    );
    _messageSub = _watchMessages().listen(
      (message) => add(PartyMessageReceived(message)),
    );
    _playerSub = _player.stream.listen((_) => add(const PartyPlayerChanged()));
  }

  final WatchPartySession _watchSession;
  final WatchPartyMessages _watchMessages;
  final HostParty _host;
  final DiscoverParty _discover;
  final JoinParty _join;
  final PublishPartyState _publish;
  final LeaveParty _leave;
  final PlayerBloc _player;
  final Duration _publishInterval;
  late final StreamSubscription<Object?> _sessionSub;
  late final StreamSubscription<Object?> _messageSub;
  late final StreamSubscription<Object?> _playerSub;
  Timer? _tick;

  /// Last state shared with the guests, so an unchanged queue is only re-sent
  /// as a small tick (and a tick that would say nothing new is skipped).
  PartySnapshot? _shared;

  /// When this device last jumped to the host's position, so a stream that
  /// never fully catches up is not re-seeked on every single tick.
  DateTime? _lastSeek;

  /// Controls a session: start hosting on this device.
  Future<void> _onHost(
    PartyHostRequested event,
    Emitter<PartyState> emit,
  ) async {
    if (state.session.isActive) return;
    emit(state.copyWith(busy: true));
    await _host();
    emit(state.copyWith(busy: false));
  }

  /// Looks for nearby sessions, or stops looking.
  Future<void> _onDiscover(
    PartyDiscoveryToggled event,
    Emitter<PartyState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    await _discover(active: event.active);
    emit(state.copyWith(busy: false));
  }

  /// Follows the session of another device.
  Future<void> _onJoin(
    PartyJoinRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    await _join(event.peer.id);
    emit(state.copyWith(busy: false));
  }

  /// Ends the session (host), leaves it (guest) or stops the scan.
  Future<void> _onLeave(
    PartyLeaveRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    await _leave();
    _shared = null;
    emit(state.copyWith(busy: false));
  }

  /// Mirrors the repository session, and re-shares the host's state whenever
  /// the session changes (a guest attached, left, or announced itself).
  void _onSessionChanged(PartySessionChanged event, Emitter<PartyState> emit) {
    emit(state.copyWith(session: event.session, busy: false));
    if (event.session.isHosting) {
      if (event.session.peers.isEmpty) {
        _stopTick();
      } else {
        _startTick();
      }
      unawaited(_share(forceFull: true));
    } else {
      _stopTick();
      if (!event.session.isActive) {
        _shared = null;
        _lastSeek = null;
      }
    }
  }

  /// Publishes a position tick only while this device is hosting. Idle blocs
  /// keep no timer, so they do not wake up every few seconds for nothing.
  void _startTick() {
    _tick ??= Timer.periodic(
      _publishInterval,
      (_) => add(const PartyTickElapsed()),
    );
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
  }

  /// Reacts to a message from the other side of the link.
  void _onMessage(PartyMessageReceived event, Emitter<PartyState> emit) {
    switch (event.message) {
      case PartyStateMessage(:final snapshot):
        if (!state.session.isFollowing) return;
        _applySnapshot(snapshot);
      case PartyTickMessage(:final index, :final position, :final playing):
        if (!state.session.isFollowing) return;
        _correctDrift(index: index, position: position, playing: playing);
      case PartyHelloMessage():
        if (!state.session.isHosting) return;
        unawaited(_share(forceFull: true));
      case PartyByeMessage():
        // The other side is gone: the link tears itself down, which flips the
        // session back to idle on both roles.
        if (state.session.isFollowing) unawaited(_leave());
    }
  }

  /// Host: shares the local player state on every change.
  Future<void> _onPlayerChanged(
    PartyPlayerChanged event,
    Emitter<PartyState> emit,
  ) async {
    if (!state.session.isHosting) return;
    await _share(forceFull: false);
  }

  /// Host: keeps the guests' position honest between changes.
  Future<void> _onTickElapsed(
    PartyTickElapsed event,
    Emitter<PartyState> emit,
  ) async {
    if (!state.session.isHosting) return;
    await _share(forceFull: false);
  }

  /// Sends the host's state: the whole queue when its shape changed (or when
  /// [forceFull], because a guest just joined and needs it), otherwise a
  /// position tick. A tick that carries nothing new is skipped.
  Future<void> _share({required bool forceFull}) async {
    final snapshot = _snapshot();
    if (snapshot == null) return;
    if (!forceFull && _isRedundant(snapshot)) return;
    final full = forceFull || _shared?.shapeKey != snapshot.shapeKey;
    _shared = snapshot;
    await _publish(snapshot, full: full);
  }

  /// True when the guests already know everything [snapshot] would tell them.
  bool _isRedundant(PartySnapshot snapshot) {
    final shared = _shared;
    if (shared == null) return false;
    if (shared.shapeKey != snapshot.shapeKey ||
        shared.playing != snapshot.playing) {
      return false;
    }
    return (shared.position - snapshot.position).abs() <=
        AppConstants.partySyncTolerance;
  }

  /// Current player state as a party snapshot, or null when nothing is loaded.
  PartySnapshot? _snapshot() {
    final player = _player.state;
    if (player.queue.isEmpty) return null;
    return PartySnapshot(
      queue: player.queue,
      index: player.currentIndex,
      position: _player.controller.position.value,
      playing: player.isPlaying,
      shuffle: player.shuffle,
      repeat: player.repeat,
    );
  }

  /// Guest: replaces the local queue with what the host is playing.
  void _applySnapshot(PartySnapshot snapshot) {
    if (snapshot.isEmpty) return;
    // A fresh track may be corrected straight away.
    _lastSeek = null;
    _player.add(
      PlayerSnapshotApplied(
        tracks: snapshot.queue,
        index: snapshot.index,
        position: snapshot.position,
        playing: snapshot.playing,
        shuffle: snapshot.shuffle,
        repeat: snapshot.repeat,
      ),
    );
  }

  /// Guest: nudges the local player back onto the host's position and
  /// transport. A tick for another index is ignored: the host always sends the
  /// full state when the track changes.
  void _correctDrift({
    required int index,
    required Duration position,
    required bool playing,
  }) {
    final player = _player.state;
    if (player.queue.isEmpty || index != player.currentIndex) return;
    // A loading (or still idle) track is not obeying the transport yet:
    // toggling here fights the load, and the load already starts at the
    // position the host sent.
    if (player.status == PlaybackStatus.idle ||
        player.status == PlaybackStatus.loading) {
      return;
    }
    if (player.isPlaying != playing) {
      _player.add(const PlayerPlayPauseToggled());
      // Transport first, position on the next tick: doing both at once makes
      // the guest stutter.
      return;
    }
    final drift = (_player.controller.position.value - position).abs();
    if (drift <= AppConstants.partySyncTolerance) return;
    // One tick lands per [AppConstants.partyPublishInterval]. Re-seeking on
    // every one of them (which happens when a stream simply cannot catch up)
    // restarts the audio over and over, so a correction is only allowed once
    // the previous one had time to settle.
    final lastSeek = _lastSeek;
    final now = DateTime.now();
    if (lastSeek != null &&
        now.difference(lastSeek) < AppConstants.partyPublishInterval) {
      return;
    }
    _lastSeek = now;
    _player.add(PlayerSeekRequested(position));
  }

  @override
  Future<void> close() async {
    _tick?.cancel();
    await _sessionSub.cancel();
    await _messageSub.cancel();
    await _playerSub.cancel();
    return super.close();
  }
}
