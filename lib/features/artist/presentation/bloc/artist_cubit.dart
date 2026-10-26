import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/artist/domain/usecases/get_artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

/// Artist load state.

/// Artist status.
enum ArtistStatus {
  /// Fetch in flight.
  loading,

  /// Artist ready.
  ready,

  /// Load failed.
  error,
}

/// Immutable artist state.
final class ArtistState extends Equatable {
  /// Creates the state.
  const ArtistState({
    this.status = ArtistStatus.loading,
    this.detail,
    this.error,
  });

  /// Current status.
  final ArtistStatus status;

  /// Loaded artist (when ready).
  final ArtistDetail? detail;

  /// Error message (when [status] is [ArtistStatus.error]).
  final String? error;

  @override
  List<Object?> get props => [status, detail, error];
}

/// Loads an artist page via [GetArtist].
final class ArtistCubit extends Cubit<ArtistState> {
  /// Creates the cubit.
  ArtistCubit(this._getArtist) : super(const ArtistState());

  final GetArtist _getArtist;

  /// Loads (or reloads) the artist for [id].
  Future<void> load(String id) async {
    emit(const ArtistState());
    final result = await _getArtist(id);
    result.fold(
      (failure) =>
          emit(ArtistState(status: ArtistStatus.error, error: failure.message)),
      (detail) => emit(ArtistState(status: ArtistStatus.ready, detail: detail)),
    );
  }
}
