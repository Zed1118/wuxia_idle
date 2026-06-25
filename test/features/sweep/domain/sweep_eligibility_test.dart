import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_eligibility.dart';

/// T2 一键扫荡门槛纯逻辑红线测。
/// 语义：扫荡只在「本周目该单位所有关卡已首通」时可用（守 §5.7 先手工通关）。
void main() {
  group('SweepEligibility.forChapter', () {
    const chapterStageIds = [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
      'stage_01_05',
    ];

    test('本周目该章全关已通 → 可扫', () {
      final keys = [
        for (final id in chapterStageIds) '$id#1',
      ];
      expect(
        SweepEligibility.forChapter(
          clearedStageCycleKeys: keys,
          cycle: 1,
          chapterStageIds: chapterStageIds,
        ),
        isTrue,
      );
    });

    test('章内仅部分关已通 → 不可扫', () {
      final keys = ['stage_01_01#1', 'stage_01_02#1', 'stage_01_03#1'];
      expect(
        SweepEligibility.forChapter(
          clearedStageCycleKeys: keys,
          cycle: 1,
          chapterStageIds: chapterStageIds,
        ),
        isFalse,
      );
    });

    test('空章(无关卡)→ 不可扫(防 every 空集真值陷阱)', () {
      expect(
        SweepEligibility.forChapter(
          clearedStageCycleKeys: const [],
          cycle: 1,
          chapterStageIds: const [],
        ),
        isFalse,
      );
    });

    test('新周目(cycle2)但只有 cycle1 通关键 → 本周目不可扫(周目重置语义)', () {
      final cycle1Keys = [
        for (final id in chapterStageIds) '$id#1',
      ];
      expect(
        SweepEligibility.forChapter(
          clearedStageCycleKeys: cycle1Keys,
          cycle: 2,
          chapterStageIds: chapterStageIds,
        ),
        isFalse,
      );
    });
  });

  group('SweepEligibility.forTower', () {
    test('本周目整塔 30 层已通 → 可扫', () {
      expect(
        SweepEligibility.forTower(highestClearedFloor: 30, floorCount: 30),
        isTrue,
      );
    });

    test('仅通到 29 层 → 不可扫', () {
      expect(
        SweepEligibility.forTower(highestClearedFloor: 29, floorCount: 30),
        isFalse,
      );
    });

    test('floorCount 非法(0)→ 不可扫(防越界真值)', () {
      expect(
        SweepEligibility.forTower(highestClearedFloor: 0, floorCount: 0),
        isFalse,
      );
    });
  });
}
