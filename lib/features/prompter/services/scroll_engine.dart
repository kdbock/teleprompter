import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Lightweight monitor for early prompter performance acceptance checks.
class PrompterPerformanceMonitor {
  PrompterPerformanceMonitor({
    this.windowSize = 120,
    this.targetFps = 60,
    this.minimumAcceptedFps = 55,
    this.maxAcceptedJankRate = 0.05,
  });

  final int windowSize;
  final int targetFps;
  final int minimumAcceptedFps;
  final double maxAcceptedJankRate;

  final List<double> _frameTimesMs = <double>[];

  void recordFrame(Duration frameDelta) {
    final frameMs = frameDelta.inMicroseconds / 1000;
    _frameTimesMs.add(frameMs);
    if (_frameTimesMs.length > windowSize) {
      _frameTimesMs.removeAt(0);
    }
  }

  bool get hasSamples => _frameTimesMs.isNotEmpty;

  double get averageFrameTimeMs {
    if (_frameTimesMs.isEmpty) return 0;
    final sum = _frameTimesMs.reduce((a, b) => a + b);
    return sum / _frameTimesMs.length;
  }

  double get averageFps {
    if (_frameTimesMs.isEmpty) return 0;
    final averageMs = averageFrameTimeMs;
    if (averageMs == 0) return 0;
    return 1000 / averageMs;
  }

  double get jankRate {
    if (_frameTimesMs.isEmpty) return 0;
    final thresholdMs = (1000 / targetFps) * 1.5;
    final jankyFrames = _frameTimesMs.where((ms) => ms > thresholdMs).length;
    return jankyFrames / _frameTimesMs.length;
  }

  bool get passesAcceptance {
    if (_frameTimesMs.length < 10) return true;
    return averageFps >= minimumAcceptedFps && jankRate <= maxAcceptedJankRate;
  }

  void reset() {
    _frameTimesMs.clear();
  }
}

class ScrollEngine {
  ScrollEngine({
    required this.scrollController,
    this.initialPixelsPerSecond = 50,
  }) : pixelsPerSecond = initialPixelsPerSecond;

  final ScrollController scrollController;
  final double initialPixelsPerSecond;

  final PrompterPerformanceMonitor monitor = PrompterPerformanceMonitor();

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double pixelsPerSecond;

  bool get isRunning => _ticker?.isActive ?? false;

  void start(TickerProvider vsync) {
    if (isRunning) return;
    _lastElapsed = Duration.zero;
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void pause() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _lastElapsed = Duration.zero;
  }

  void resetToTop() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  void jumpToEnd() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  void updateSpeed(double multiplier) {
    // Base speed tuned for readability at 1x.
    pixelsPerSecond = 50 * multiplier;
  }

  void _onTick(Duration elapsed) {
    if (!scrollController.hasClients) return;

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    monitor.recordFrame(delta);

    final nextOffset = computeNextOffset(
      currentOffset: scrollController.offset,
      delta: delta,
      pixelsPerSecond: pixelsPerSecond,
      maxExtent: scrollController.position.maxScrollExtent,
    );

    scrollController.jumpTo(nextOffset);

    if (nextOffset >= scrollController.position.maxScrollExtent) {
      pause();
    }
  }

  static double computeNextOffset({
    required double currentOffset,
    required Duration delta,
    required double pixelsPerSecond,
    required double maxExtent,
  }) {
    final deltaSeconds = delta.inMicroseconds / 1000000;
    final distance = pixelsPerSecond * deltaSeconds;
    return math.min(currentOffset + distance, maxExtent);
  }

  void dispose() {
    pause();
  }
}
