import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';

/// Loads the persisted security settings (PRD S20).

/// Reads the snapshot.
final class LoadSecuritySettings
    implements UseCase<SecuritySettings, NoParams> {
  /// Creates the use case.
  const LoadSecuritySettings(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, SecuritySettings>> call(NoParams params) async {
    final settings = await _repository.load();
    return Right(settings);
  }
}
