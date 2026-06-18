import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/auto_play_mode.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

void main() {
  group('isFirstClear', () {
    test('cycleKey 不在 clearedStageCycleKeys → 首通 true', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_02#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 1), isTrue);
    });
    test('cycleKey 已在 → 非首通 false', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_03#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 1), isFalse);
    });
    test('同关不同周目各自独立', () {
      final p = MainlineProgress()..clearedStageCycleKeys = ['stage_01_03#1'];
      expect(MainlineProgressService.isFirstClear(p, 'stage_01_03', 2), isTrue,
          reason: '周目2 未通 → 仍首通');
    });
  });

  group('resolveAutoPlayModeWithFirstClear', () {
    test('首通 → 强制 interactive(无视 global auto)', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: true, override: null, globalDefault: true);
      expect(m, AutoPlayMode.interactive);
    });
    test('已通 + global auto → auto', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: false, override: null, globalDefault: true);
      expect(m, AutoPlayMode.auto);
    });
    test('已通 + per-stage override interactive → interactive', () {
      final m = resolveAutoPlayModeWithFirstClear(
          isFirstClear: false, override: false, globalDefault: true);
      expect(m, AutoPlayMode.interactive);
    });
  });
}
