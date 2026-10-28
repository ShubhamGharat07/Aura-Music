import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in frame-timing probe for physical-device profiling.
///
/// Enable with `--dart-define=AURA_PERF_LOG=true` in a profile build. It
/// registers a single [SchedulerBinding.addTimingsCallback] listener and logs
/// p50/p95 build + raster timings every [_window] frames, plus the worst
/// frames. Disabled (and therefore zero-cost) in every normal build.
abstract final class PerformanceProbe {
  /// Whether profiling output was requested at compile time.
  static const bool enabled = bool.fromEnvironment('AURA_PERF_LOG');

  /// Frames per report (about two seconds at 60 Hz).
  static const int _window = 120;

  /// 60 Hz frame budget in microseconds.
  static const int _budgetUs = 16667;

  static final List<FrameTiming> _frames = <FrameTiming>[];
  static bool _installed = false;

  /// Installs the callback once. Safe to call more than once.
  static void install() {
    if (!enabled || _installed) return;
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
    if (_frames.length < _window) return;
    final batch = List<FrameTiming>.of(_frames);
    _frames.clear();
    _report(batch);
  }

  static void _report(List<FrameTiming> frames) {
    final build = <int>[];
    final raster = <int>[];
    final work = <int>[];
    final dropped = <FrameTiming>[];
    for (final frame in frames) {
      final buildUs = frame.buildDuration.inMicroseconds;
      final rasterUs = frame.rasterDuration.inMicroseconds;
      final workUs = buildUs + rasterUs;
      build.add(buildUs);
      raster.add(rasterUs);
      work.add(workUs);
      if (workUs > _budgetUs) dropped.add(frame);
    }
    debugPrint(
      '[AURA_PERF] frames=${frames.length} '
      'build p50=${_pct(build, 0.5)} p95=${_pct(build, 0.95)} '
      'max=${_max(build)} | '
      'raster p50=${_pct(raster, 0.5)} p95=${_pct(raster, 0.95)} '
      'max=${_max(raster)} | '
      'work p95=${_pct(work, 0.95)} max=${_max(work)} | '
      'overBudget=${dropped.length}',
    );
    for (final frame in dropped) {
      debugPrint(
        '[AURA_PERF] slow frame=${frame.frameNumber} '
        'build=${frame.buildDuration.inMicroseconds} '
        'raster=${frame.rasterDuration.inMicroseconds} '
        'work=${frame.buildDuration.inMicroseconds + frame.rasterDuration.inMicroseconds}',
      );
    }
  }

  static int _pct(List<int> values, double percentile) {
    final sorted = List<int>.of(values)..sort();
    final index = ((sorted.length - 1) * percentile).round();
    return sorted[index];
  }

  static int _max(List<int> values) {
    var max = 0;
    for (final value in values) {
      if (value > max) max = value;
    }
    return max;
  }
}
