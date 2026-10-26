import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';

/// Persists a new security settings snapshot (PRD S20).

/// Writes the snapshot.
final class UpdateSecuritySettings implements UseCase<Unit, SecuritySettings> {
  /// Creates the use case.
  const UpdateSecuritySettings(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SecuritySettings params) async {
    await _repository.save(params);
    return const Right(unit);
  }
}
