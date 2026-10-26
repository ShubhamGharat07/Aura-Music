import 'package:get_it/get_it.dart';

import 'package:aura_music/core/services/permission_service.dart';
import 'package:aura_music/features/party/data/datasources/ble_party_transport.dart';
import 'package:aura_music/features/party/data/datasources/party_permissions.dart';
import 'package:aura_music/features/party/data/datasources/party_transport.dart';
import 'package:aura_music/features/party/data/repositories/party_repository_impl.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';
import 'package:aura_music/features/party/domain/usecases/discover_party.dart';
import 'package:aura_music/features/party/domain/usecases/host_party.dart';
import 'package:aura_music/features/party/domain/usecases/join_party.dart';
import 'package:aura_music/features/party/domain/usecases/leave_party.dart';
import 'package:aura_music/features/party/domain/usecases/publish_party_state.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_messages.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_session.dart';
import 'package:aura_music/features/party/presentation/bloc/party_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';

/// Listen together (PRD S06) registrations, kept out of
/// [configureDependencies] so the locator file stays small.

/// Registers the BLE transport, repository, use cases and bloc.
void registerPartyDependencies(GetIt getIt) {
  getIt.registerLazySingleton<PartyTransport>(BlePartyTransport.new);
  getIt.registerLazySingleton<PartyPermissionGate>(
    () => PartyPermissions(getIt<PermissionService>()),
  );
  getIt.registerLazySingleton<PartyRepository>(
    () => PartyRepositoryImpl(
      getIt<PartyTransport>(),
      getIt<PartyPermissionGate>(),
    ),
  );
  getIt.registerLazySingleton<WatchPartySession>(
    () => WatchPartySession(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<WatchPartyMessages>(
    () => WatchPartyMessages(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<HostParty>(
    () => HostParty(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<DiscoverParty>(
    () => DiscoverParty(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<JoinParty>(
    () => JoinParty(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<PublishPartyState>(
    () => PublishPartyState(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<LeaveParty>(
    () => LeaveParty(getIt<PartyRepository>()),
  );
  getIt.registerLazySingleton<PartyBloc>(
    () => PartyBloc(
      getIt<WatchPartySession>(),
      getIt<WatchPartyMessages>(),
      getIt<HostParty>(),
      getIt<DiscoverParty>(),
      getIt<JoinParty>(),
      getIt<PublishPartyState>(),
      getIt<LeaveParty>(),
      player: getIt<PlayerBloc>(),
    ),
  );
}
