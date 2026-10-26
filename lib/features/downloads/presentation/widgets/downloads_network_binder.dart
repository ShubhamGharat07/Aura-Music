import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/services/connectivity_cubit.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';

/// Pauses in-flight downloads when connectivity is lost and resumes only the
/// rows that were paused *because of the network* once it returns.
///
/// User-paused rows are left untouched, so reconnecting never overrides an
/// explicit choice (PRD S14 / connectivity behaviour).
final class DownloadsNetworkBinder extends StatelessWidget {
  /// Wraps [child].
  const DownloadsNetworkBinder({required this.child, super.key});

  /// App subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, bool>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, online) => unawaited(
        context.read<DownloadsCubit>().onConnectivityChanged(online),
      ),
      child: child,
    );
  }
}
