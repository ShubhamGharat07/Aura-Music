import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/error/failures.dart';

/// Runs [run] and maps any data-layer [AppException] to a domain [Failure]
/// (PRD 5.1 boundary). Keeps repository impls free of repetitive try/catch.

/// Guards a remote call, returning `Right(value)` or `Left(failure)`.
Future<Either<Failure, T>> guardRemote<T>(Future<T> Function() run) async {
  try {
    return Right(await run());
  } on NetworkException catch (error) {
    return Left(NetworkFailure(error.message));
  } on ServerException catch (error) {
    return Left(ServerFailure(error.message));
  } on AppException catch (error) {
    return Left(UnknownFailure(error.message));
  }
}
