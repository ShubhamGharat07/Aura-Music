import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Offline home (PRD S03): network sections are replaced by a banner plus
/// Downloads / Liked / History shortcuts that work without a connection.

/// Offline fallback body.
final class HomeOffline extends StatelessWidget {
  /// Creates the offline fallback.
  const HomeOffline({super.key, required this.padding});

  /// Horizontal inset from the window class.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSurface.fake(
            borderRadius: AppRadius.chip,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
            child: Row(
              children: [
                Icon(Icons.wifi_off_outlined, size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('You are offline — showing your local music'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.w),
          Text('Available offline', style: AppTypography.title),
          SizedBox(height: 8.w),
          _OfflineTile(
            title: 'Downloads',
            subtitle: 'Play without a connection',
            icon: Icons.download_outlined,
            route: AppRoutes.downloads,
          ),
          SizedBox(height: 12.w),
          _OfflineTile(
            title: 'Liked songs',
            subtitle: 'Saved tracks',
            icon: Icons.favorite_outline,
            route: AppRoutes.liked,
          ),
          SizedBox(height: 12.w),
          const _OfflineTile(
            title: 'History',
            subtitle: 'Recently played',
            icon: Icons.history,
            route: AppRoutes.history,
          ),
        ],
      ),
    );
  }
}

final class _OfflineTile extends StatelessWidget {
  const _OfflineTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.all(12.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () => context.push(route),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
