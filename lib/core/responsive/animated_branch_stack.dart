import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/theme/tokens.dart';

/// Slides and fades tab navigators without discarding their route stacks.
final class AnimatedBranchStack extends HookWidget {
  /// Creates the animated branch container.
  const AnimatedBranchStack({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = AppDurations.medium,
  }) : assert(children.length > 0, 'At least one branch is required.');

  /// Active branch index.
  final int currentIndex;

  /// Branch navigators, in branch order.
  final List<Widget> children;

  /// Fade and slide duration.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final previousIndex = usePrevious(currentIndex) ?? currentIndex;
    final direction = currentIndex >= previousIndex ? 1 : -1;
    final instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Branch(
            key: ValueKey<int>(i),
            active: i == currentIndex,
            travel: 0.05 * direction,
            duration: instant ? Duration.zero : duration,
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
    required this.travel,
    required this.duration,
    required this.child,
  });

  final bool active;
  final double travel;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(initialValue: 1);
    final opacity = useRef(Tween<double>(begin: 0, end: active ? 1 : 0));
    final offset = useRef(Tween<Offset>(begin: Offset.zero, end: Offset.zero));

    useEffect(() {
      final target = active ? 1.0 : 0.0;
      if (duration == Duration.zero) {
        opacity.value = Tween(begin: target, end: target);
        offset.value = Tween(begin: Offset.zero, end: Offset.zero);
        controller.value = 1;
      } else if (opacity.value.end != target) {
        final fromOpacity = opacity.value.evaluate(controller);
        final fromOffset = fromOpacity == 0 && active
            ? Offset(travel, 0)
            : offset.value.evaluate(controller);
        opacity.value = Tween(begin: fromOpacity, end: target);
        offset.value = Tween(
          begin: fromOffset,
          end: active ? Offset.zero : Offset(-travel, 0),
        );
        controller.value = 0;
        controller.animateTo(1, duration: duration, curve: AppCurves.inOut);
      }
      return null;
    }, [active, duration]);

    return AnimatedBuilder(
      animation: controller,
      child: ExcludeFocus(
        excluding: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: IgnorePointer(
            ignoring: !active,
            child: TickerMode(
              enabled: active,
              child: HeroMode(enabled: active, child: child),
            ),
          ),
        ),
      ),
      builder: (context, child) => Offstage(
        offstage: !active && controller.isCompleted,
        child: FadeTransition(
          opacity: opacity.value.animate(controller),
          child: SlideTransition(
            position: offset.value.animate(controller),
            textDirection: Directionality.of(context),
            child: child,
          ),
        ),
      ),
    );
  }
}
