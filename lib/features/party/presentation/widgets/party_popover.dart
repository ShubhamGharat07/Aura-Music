import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/permission_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_button.dart';
import 'package:aura_music/core/ui/glass_popover.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_role.dart';
import 'package:aura_music/features/party/domain/entities/party_status.dart';
import 'package:aura_music/features/party/presentation/bloc/party_bloc.dart';
import 'package:aura_music/features/party/presentation/bloc/party_event.dart';
import 'package:aura_music/features/party/presentation/bloc/party_state.dart';

// Listen together (PRD S06). Opens next to the header's Bluetooth button as a
// popover, so the session controls never hide behind the system navigation bar.

/// Opens the listen together popover above the control behind [anchorContext].
void showPartyPopover(BuildContext anchorContext) {
  final bloc = getIt<PartyBloc>();
  GlassPopover.show(
    anchorContext,
    builder: (_) => BlocProvider<PartyBloc>.value(
      value: bloc,
      child: const PartyPopoverBody(),
    ),
  );
}

/// Controls for hosting or following a party session.
final class PartyPopoverBody extends HookWidget {
  /// Creates the popover body.
  const PartyPopoverBody({super.key});

  @override
  Widget build(BuildContext context) {
    final joining = useState<String?>(null);
    return BlocBuilder<PartyBloc, PartyState>(
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading(),
          SizedBox(height: AppSpacing.lg),
          ..._body(context, state, joining),
        ],
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    PartyState state,
    ValueNotifier<String?> joining,
  ) {
    final bloc = context.read<PartyBloc>();
    final session = state.session;
    final accent = Theme.of(context).colorScheme.primary;
    final busy = state.busy;
    void leave() => bloc.add(const PartyLeaveRequested());
    void discover(bool active) =>
        bloc.add(PartyDiscoveryToggled(active: active));
    void openSettings() => getIt<PermissionService>().openSettings();

    switch (session.status) {
      case PartyStatus.idle:
        return [
          const _Note(
            'Share what is playing with the phones around you. Audio streams on '
            'each device, so everyone keeps the app open.',
          ),
          SizedBox(height: AppSpacing.lg),
          GlassButton(
            label: 'Start a session',
            icon: Icons.bluetooth_rounded,
            expand: true,
            onPressed: busy ? null : () => bloc.add(const PartyHostRequested()),
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Join nearby',
            icon: Icons.bluetooth_searching_rounded,
            filled: false,
            expand: true,
            onPressed: busy ? null : () => discover(true),
          ),
          SizedBox(height: AppSpacing.md),
          const _Note(
            'Both phones need Bluetooth on and this app open.',
            muted: true,
          ),
        ];

      case PartyStatus.hosting:
        final count = session.peers.length;
        return [
          _Status(
            icon: count == 0
                ? Icons.wifi_tethering_rounded
                : Icons.link_rounded,
            label: count == 0
                ? 'Waiting for someone to join…'
                : '$count device${count == 1 ? '' : 's'} connected',
            accent: count == 0 ? accent : AppColors.success,
          ),
          SizedBox(height: AppSpacing.sm),
          _Note(
            count == 0
                ? 'Ask a friend to open the player and tap Join nearby.'
                : 'They follow whatever plays here.',
            muted: true,
          ),
          for (final peer in session.peers)
            _PeerTile(peer: peer, accent: accent),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Stop session',
            icon: Icons.stop_rounded,
            filled: false,
            expand: true,
            onPressed: busy ? null : leave,
          ),
        ];

      case PartyStatus.scanning:
        return [
          _Waiting(label: 'Looking for sessions nearby…'),
          if (session.peers.isEmpty) ...[
            const _Note(
              'No sessions yet. Ask your friend to tap Start a session, then '
              'scan again.',
              muted: true,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          for (final peer in session.peers)
            _PeerTile(
              peer: peer,
              accent: accent,
              onTap: busy
                  ? null
                  : () {
                      joining.value = peer.name;
                      bloc.add(PartyJoinRequested(peer));
                    },
            ),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Scan again',
            icon: Icons.refresh_rounded,
            expand: true,
            onPressed: busy ? null : () => discover(true),
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            filled: false,
            expand: true,
            onPressed: () => discover(false),
          ),
        ];

      case PartyStatus.connecting:
        final target = joining.value;
        return [
          _Waiting(
            label: target == null ? 'Connecting…' : 'Connecting to $target…',
          ),
          const _Note(
            'Keep both phones close. This takes a few seconds.',
            muted: true,
          ),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            filled: false,
            expand: true,
            onPressed: leave,
          ),
        ];

      case PartyStatus.connected:
        return [
          _Status(
            icon: Icons.bluetooth_connected_rounded,
            label: 'Following ${session.hostName ?? 'a nearby session'}',
            accent: AppColors.success,
          ),
          const _Note(
            'Playback follows this session. The audio plays on this phone.',
            muted: true,
          ),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Leave session',
            icon: Icons.link_off_rounded,
            filled: false,
            expand: true,
            onPressed: busy ? null : leave,
          ),
        ];

      case PartyStatus.denied:
        return [
          _Note(
            session.notice ?? 'Bluetooth access is needed for listen together.',
          ),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Open settings',
            icon: Icons.settings_outlined,
            expand: true,
            onPressed: openSettings,
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            filled: false,
            expand: true,
            onPressed: () => _retry(bloc, session.role),
          ),
        ];

      case PartyStatus.unsupported:
      case PartyStatus.failed:
        return [
          _Status(
            icon: Icons.bluetooth_disabled_rounded,
            label: 'Not connected',
            accent: AppColors.error,
          ),
          SizedBox(height: AppSpacing.sm),
          _Note(session.notice ?? 'Listen together is unavailable right now.'),
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            expand: true,
            onPressed: () => _retry(bloc, session.role),
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Open settings',
            icon: Icons.settings_outlined,
            filled: false,
            expand: true,
            onPressed: openSettings,
          ),
        ];
    }
  }

  void _retry(PartyBloc bloc, PartyRole? role) {
    bloc.add(
      role == PartyRole.host
          ? const PartyHostRequested()
          : const PartyDiscoveryToggled(active: true),
    );
  }
}

final class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.bluetooth_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Listen together',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title,
          ),
        ),
        IconButton(
          onPressed: () => GlassPopover.dismiss(context),
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

final class _Note extends StatelessWidget {
  const _Note(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: (muted ? AppTypography.caption : AppTypography.body).copyWith(
      color: muted ? AppColors.textTertiary : AppColors.textSecondary,
    ),
  );
}

final class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: accent),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

final class _Waiting extends StatelessWidget {
  const _Waiting({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 18.w,
            height: 18.w,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.peer, required this.accent, this.onTap});

  final PartyPeer peer;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final joinable = onTap != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        joinable ? Icons.bluetooth_rounded : Icons.phone_android_rounded,
        color: accent,
      ),
      title: Text(peer.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(joinable ? 'Tap to join' : 'Connected'),
      trailing: joinable
          ? Icon(Icons.chevron_right_rounded, color: accent)
          : null,
      onTap: onTap,
    );
  }
}
