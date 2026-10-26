import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/connectivity_cubit.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Slim offline banner pinned above the tab content (PRD Section 15).
final class OfflineBanner extends StatelessWidget {
  /// Creates the banner.
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, online) {
        if (online) return const SizedBox.shrink();
        return GlassSurface.fake(
          borderRadius: 12.r,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined, size: 16.r),
              SizedBox(width: 8.w),
              const Text('Offline'),
            ],
          ),
        );
      },
    );
  }
}
