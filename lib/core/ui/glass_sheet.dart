import 'package:flutter/material.dart';

import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Glass bottom sheet / dialog helper (PRD 7.5 overlays).
/// Compact: full-width bottom sheet. Medium+: centered sheet max 560.
/// Expanded+: callers may prefer a popover or a page-level panel.
abstract final class GlassSheet {
  /// Shows the [builder] as a glass sheet tailored to the window class.
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) {
    final sizeClass = WindowSizeClass.of(context);
    final wide = sizeClass.isMediumUp;
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: wide ? const BoxConstraints(maxWidth: 560) : null,
      builder: (context) => GlassSurface(
        borderRadius: AppRadius.sheet,
        tier: GlassTier.high,
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: builder(context),
      ),
    );
  }
}
