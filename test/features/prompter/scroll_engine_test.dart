import 'package:flutter_test/flutter_test.dart';
import 'package:team_teleprompter/features/prompter/services/scroll_engine.dart';

void main() {
  group('ScrollEngine.computeNextOffset', () {
    test('advances offset based on speed and delta', () {
      final next = ScrollEngine.computeNextOffset(
        currentOffset: 100,
        delta: const Duration(milliseconds: 500),
        pixelsPerSecond: 80,
        maxExtent: 1000,
      );

      expect(next, closeTo(140, 0.0001));
    });

    test('caps offset at max extent', () {
      final next = ScrollEngine.computeNextOffset(
        currentOffset: 980,
        delta: const Duration(milliseconds: 500),
        pixelsPerSecond: 100,
        maxExtent: 1000,
      );

      expect(next, 1000);
    });
  });

  group('PrompterPerformanceMonitor', () {
    test('passes acceptance for smooth frame timings', () {
      final monitor = PrompterPerformanceMonitor();
      for (var i = 0; i < 120; i++) {
        monitor.recordFrame(const Duration(milliseconds: 16));
      }

      expect(monitor.averageFps, greaterThanOrEqualTo(55));
      expect(monitor.passesAcceptance, isTrue);
    });

    test('fails acceptance when frame timings are too slow and janky', () {
      final monitor = PrompterPerformanceMonitor();
      for (var i = 0; i < 120; i++) {
        monitor.recordFrame(const Duration(milliseconds: 40));
      }

      expect(monitor.averageFps, lessThan(55));
      expect(monitor.passesAcceptance, isFalse);
    });
  });
}
