import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// Reports a child's laid-out height so floating chrome (e.g. the bottom bar +
// mini player) can reserve scroll space. SizeChangedLayoutNotifier alone is
// not enough: it deliberately skips the initial layout, so we measure once
// after the first frame and let the notifier cover later resizes.

/// Reports the height of [child] into [height].
final class MeasuredHeight extends HookWidget {
  /// Creates the reporter.
  const MeasuredHeight({super.key, required this.height, required this.child});

  /// Notifier that receives the measured height in logical pixels.
  final ValueNotifier<double> height;

  /// Widget whose height is measured.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = useMemoized(() => GlobalKey());

    void measure() {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.height != height.value) {
        height.value = box.size.height;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => measure());
      return null;
    }, const []);

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => measure());
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: key, child: child),
      ),
    );
  }
}
