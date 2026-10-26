import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';

/// Wraps the app with the lock overlay (PRD S20). The app re-locks after the
/// configured grace period in the background; lifecycle events raised by the
/// biometric prompt itself are ignored so unlocking cannot loop.

/// App-lock gate.
final class AppLockGate extends HookWidget {
  /// Creates the gate.
  const AppLockGate({super.key, required this.child});

  /// The gated subtree (the navigator).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SecurityCubit>();
    final state = context.watch<SecurityCubit>().state;
    final backgroundedAt = useRef<DateTime?>(null);

    useEffect(() {
      final listener = AppLifecycleListener(
        onPause: () => _markBackgrounded(cubit, backgroundedAt),
        onHide: () => _markBackgrounded(cubit, backgroundedAt),
        onResume: () => _maybeRelock(cubit, backgroundedAt),
        onShow: () => _maybeRelock(cubit, backgroundedAt),
      );
      return listener.dispose;
    }, const []);

    useEffect(() {
      if (state.locked && !state.authenticating) cubit.unlock();
      return null;
    }, [state.locked]);

    return Stack(
      children: [
        child,
        if (state.locked)
          _LockOverlay(
            authenticating: state.authenticating,
            onUnlock: cubit.unlock,
          ),
      ],
    );
  }

  void _markBackgrounded(SecurityCubit cubit, ObjectRef<DateTime?> at) {
    if (cubit.state.authenticating || !cubit.state.settings.appLock) return;
    at.value = DateTime.now();
  }

  void _maybeRelock(SecurityCubit cubit, ObjectRef<DateTime?> at) {
    final started = at.value;
    at.value = null;
    if (started == null) return;
    if (cubit.state.authenticating || !cubit.state.settings.appLock) return;
    final grace = cubit.state.settings.lockTimeout.duration;
    if (DateTime.now().difference(started) >= grace) cubit.lock();
  }
}

final class _LockOverlay extends StatelessWidget {
  const _LockOverlay({required this.authenticating, required this.onUnlock});

  final bool authenticating;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56.r,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 16.w),
            Text('Aura Music is locked', style: theme.textTheme.titleLarge),
            SizedBox(height: 8.w),
            Text('Unlock to continue', style: theme.textTheme.bodyMedium),
            SizedBox(height: 24.w),
            FilledButton.icon(
              onPressed: authenticating ? null : onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
