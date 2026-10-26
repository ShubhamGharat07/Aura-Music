import 'package:flutter_hooks/flutter_hooks.dart';

/// Debounces a value (e.g. search query, 300 ms). Ephemeral UI state only;
/// business state stays in BLoCs (PRD 4.1).

/// Returns [value] delayed by [delay]. Updates only after [value] is
/// stable for [delay].
T useDebouncedValue<T>(T value, Duration delay) {
  final debounced = useState(value);
  useEffect(() {
    final timer = Future.delayed(delay, () => debounced.value = value);
    return () => timer.ignore();
  }, [value]);
  return debounced.value;
}
