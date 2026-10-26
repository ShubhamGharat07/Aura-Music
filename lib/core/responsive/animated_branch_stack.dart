import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Cross-fades the four tab stacks when the bottom navigation changes branch
/// (PRD 8.2 motion). Every branch stays mounted, so scroll positions, search
/// text and Cubits survive tab switches; only the active branch paints, which
/// keeps hidden tabs off the raster thread (0-jank budget).
final class AnimatedBranchStack extends StatelessWidget {
  /// Creates the animated branch container.
  const AnimatedBranchStack({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  }) : assert(children.length > 0, 'At least one branch is required.');

  /// Active branch index ([StatefulNavigationShell.currentIndex]).
  final int currentIndex;

  /// Branch navigators, in branch order.
  final List<Widget> children;

  /// Fade/slide duration; slightly slow so the change reads as a transition.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effective = reduceMotion ? Duration.zero : duration;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Branch(
            key: ValueKey<int>(i),
            active: i == currentIndex,
            duration: effective,
            child: children[i],
          ),
      ],
    );
  }
}

final class _Branch extends HookWidget {
  const _Branch({
    super.key,
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: duration,
      initialValue: active ? 1 : 0,
    );
    final hidden = useState(!active);

    useEffect(() {
      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.dismissed && !active) {
          hidden.value = true;
        }
      }

      controller.addStatusListener(onStatus);
      if (active) {
        hidden.value = false;
        controller.animateTo(1, curve: Curves.easeOutCubic);
      } else {
        controller.animateTo(0, curve: Curves.easeOutCubic);
      }
      return () => controller.removeStatusListener(onStatus);
    }, [active]);

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(curved);

    return Offstage(
      offstage: !active && hidden.value,
      child: TickerMode(
        // Keep ticking while fading out so the exit animation can reach
        // `dismissed` and park the branch offstage.
        enabled: active || !hidden.value,
        child: IgnorePointer(
          ignoring: !active,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(position: rise, child: child),
          ),
        ),
      ),
    );
  }
}
