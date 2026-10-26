import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global connectivity state (PRD 4.1). `true` = online.
/// UI shows the slim offline glass banner when false (Section 15).

/// Emits connectivity as a bool. Subscribed once in [AuraApp].
final class ConnectivityCubit extends Cubit<bool> {
  /// Creates the cubit and starts listening.
  ConnectivityCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(true) {
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    _checkInitial();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _checkInitial() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onChanged(results);
    } catch (_) {
      // Keep default (online); banner only appears on confirmed offline.
    }
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);
    if (online != state) emit(online);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
