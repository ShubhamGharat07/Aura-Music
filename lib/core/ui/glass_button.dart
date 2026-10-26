import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Glass button (PRD 8.3). Filled uses the accent; ghost is borderless.
final class GlassButton extends StatelessWidget {
  /// Creates a glass button.
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
    this.expand = false,
    this.tier = GlassTier.high,
  });

  /// Button label.
  final String label;

  /// Tap callback (null = disabled).
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Filled (accent) vs ghost (glass outline).
  final bool filled;

  /// Expands to fill available width.
  final bool expand;

  /// Glass tier.
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final accent = Theme.of(context).colorScheme.primary;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.r),
          SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    final button = Material(
      color: filled && enabled
          ? accent.withValues(alpha: 0.9)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
    if (filled) return button;
    return GlassSurface(
      borderRadius: AppRadius.pill,
      tier: tier,
      child: button,
    );
  }
}
