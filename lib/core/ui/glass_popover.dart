import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

// Liquid-glass popover (PRD 7.5 overlays). A sheet rises from a screen edge,
// which on an edge-to-edge phone can land behind the system navigation bar;
// this opens beside the control that triggered it instead, so it always stays
// inside the safe area.

/// Glass card anchored to the widget that opened it.
abstract final class GlassPopover {
  /// Space kept between the anchor and the card.
  static const double _gap = 8;

  /// Smallest useful card height before the content starts scrolling.
  static const double _minHeight = 140;

  /// Strength of the dim layer behind the card.
  static const double _scrim = 0.4;

  /// Closes the popover [context] lives in, when it is inside one.
  ///
  /// Used by the card's own content (a close button); a tap outside and the
  /// system back gesture close it as well.
  static void dismiss(BuildContext context) =>
      _PopoverScope.maybeOf(context)?.call();

  /// Shows [builder] in a glass card anchored to the widget behind
  /// [anchorContext].
  ///
  /// The card prefers the room above the anchor and flips below when there is
  /// not enough of it, staying inside the safe area either way. Content taller
  /// than the room available scrolls inside the card. It is dismissed by a tap
  /// outside, by the system back gesture, and when the route that owns
  /// [anchorContext] goes away.
  static void show(
    BuildContext anchorContext, {
    required WidgetBuilder builder,
    double width = 300,
    double maxHeight = 420,
  }) {
    final overlay = Overlay.maybeOf(anchorContext, rootOverlay: true);
    final anchorBox = anchorContext.findRenderObject();
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null ||
        anchorBox is! RenderBox ||
        overlayBox is! RenderBox) {
      return;
    }
    if (!anchorBox.hasSize || !overlayBox.hasSize) return;

    final view = overlayBox.size;
    final safe = MediaQuery.viewPaddingOf(anchorContext);
    final inset = AppSpacing.md;
    final anchor =
        anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
        anchorBox.size;
    final cardWidth = math.min(
      width,
      view.width - safe.left - safe.right - 2 * inset,
    );
    final left = (anchor.right - cardWidth)
        .clamp(
          safe.left + inset,
          math.max(
            safe.left + inset,
            view.width - safe.right - inset - cardWidth,
          ),
        )
        .toDouble();
    final above = anchor.top - safe.top - _gap;
    final below = view.height - safe.bottom - anchor.bottom - _gap;
    final opensUp = above >= below;
    final cardHeight = math.min(
      maxHeight,
      math.max(_minHeight, opensUp ? above : below),
    );

    late final OverlayEntry entry;
    LocalHistoryEntry? history;
    var cardGone = false;
    void removeCard() {
      if (cardGone) return;
      cardGone = true;
      entry.remove();
    }

    void dismiss() {
      final local = history;
      history = null;
      removeCard();
      local?.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _GlassPopover(
        left: left,
        top: opensUp ? null : anchor.bottom + _gap,
        bottom: opensUp ? view.height - anchor.top + _gap : null,
        width: cardWidth,
        maxHeight: cardHeight,
        opensUp: opensUp,
        onClosed: dismiss,
        child: builder(anchorContext),
      ),
    );

    final route = ModalRoute.of(anchorContext);
    if (route != null) {
      history = LocalHistoryEntry(
        onRemove: () {
          // The route handled it: drop the card, without touching the entry
          // that the route has already detached.
          history = null;
          removeCard();
        },
        impliesAppBarDismissal: false,
      );
      route.addLocalHistoryEntry(history!);
    }
    overlay.insert(entry);
  }
}

/// Exposes the open card's dismiss to its own content.
final class _PopoverScope extends InheritedWidget {
  const _PopoverScope({required this.onDismiss, required super.child});

  final VoidCallback onDismiss;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PopoverScope>()?.onDismiss;

  @override
  bool updateShouldNotify(_PopoverScope oldWidget) =>
      oldWidget.onDismiss != onDismiss;
}

final class _GlassPopover extends HookWidget {
  const _GlassPopover({
    required this.child,
    required this.left,
    required this.top,
    required this.bottom,
    required this.width,
    required this.maxHeight,
    required this.opensUp,
    required this.onClosed,
  });

  final Widget child;
  final double left;
  final double? top;
  final double? bottom;
  final double width;
  final double maxHeight;
  final bool opensUp;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 150),
    );
    final animation = controller.drive(CurveTween(curve: AppCurves.out));
    useEffect(() {
      controller.forward();
      return null;
    }, [controller]);

    void close() {
      if (controller.status == AnimationStatus.reverse ||
          controller.status == AnimationStatus.dismissed) {
        return;
      }
      controller.reverse().whenComplete(onClosed);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: ColoredBox(
                color: AppColors.bg.withValues(alpha: GlassPopover._scrim),
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          bottom: bottom,
          width: width,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              alignment: opensUp ? Alignment.bottomRight : Alignment.topRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: GlassSurface(
                  borderRadius: AppRadius.card,
                  tier: GlassTier.high,
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: _PopoverScope(
                    onDismiss: close,
                    child: SingleChildScrollView(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
