import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/album/domain/usecases/get_album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

/// Album load state.

/// Album status.
enum AlbumStatus {
  /// Fetch in flight.
  loading,

  /// Album ready.
  ready,

  /// Load failed.
  error,
}

/// Immutable album state.
final class AlbumState extends Equatable {
  /// Creates the state.
  const AlbumState({
    this.status = AlbumStatus.loading,
    this.detail,
    this.error,
  });

  /// Current status.
  final AlbumStatus status;

  /// Loaded album (when ready).
  final AlbumDetail? detail;

  /// Error message (when [status] is [AlbumStatus.error]).
  final String? error;

  @override
  List<Object?> get props => [status, detail, error];
}

/// Loads an album via [GetAlbum].
final class AlbumCubit extends Cubit<AlbumState> {
  /// Creates the cubit.
  AlbumCubit(this._getAlbum) : super(const AlbumState());

  final GetAlbum _getAlbum;

  /// Loads (or reloads) the album for [id].
  Future<void> load(String id) async {
    emit(const AlbumState());
    final result = await _getAlbum(id);
    result.fold(
      (failure) =>
          emit(AlbumState(status: AlbumStatus.error, error: failure.message)),
      (detail) => emit(AlbumState(status: AlbumStatus.ready, detail: detail)),
    );
  }
}
