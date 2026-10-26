import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/services/biometric_service.dart';
import 'package:aura_music/core/services/data_reset_service.dart';
import 'package:aura_music/core/services/screen_security_service.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/features/security/data/repositories/security_repository_impl.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';
import 'package:aura_music/features/security/domain/usecases/load_security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/update_security_settings.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';

/// Security & privacy registrations (PRD S20), kept out of
/// [configureDependencies] so the locator file stays small.

/// Registers the security services, repository, use cases and cubit.
void registerSecurityDependencies(GetIt getIt) {
  getIt.registerLazySingleton<ScreenSecurityService>(
    () => const ScreenSecurityService(),
  );
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<DataResetService>(
    () => DataResetService(getIt<AppDatabase>(), getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<SecurityRepository>(
    () => PrefsSecurityRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<LoadSecuritySettings>(
    () => LoadSecuritySettings(getIt<SecurityRepository>()),
  );
  getIt.registerLazySingleton<UpdateSecuritySettings>(
    () => UpdateSecuritySettings(getIt<SecurityRepository>()),
  );
  getIt.registerLazySingleton<SecurityCubit>(
    () => SecurityCubit(
      getIt<LoadSecuritySettings>(),
      getIt<UpdateSecuritySettings>(),
      getIt<BiometricService>(),
      getIt<ScreenSecurityService>(),
    ),
  );
}
