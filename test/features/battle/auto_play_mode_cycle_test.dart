import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// D1 · cycle 维度接入后，isCleared 纯逻辑测试。
///
/// 完全无 Isar、无 Widget、纯函数验证。
/// - 测 isCleared-per-cycle 语义。
void main() {
  group('MainlineProgress.clearedStageCycleKeys per-cycle isCleared 语义', () {
    /// 辅助：按 cycleKey `stageId#cycle` 判定某关某周目是否已通关。
    /// 此即 D1 在 _StageBattleHostState 里使用的逻辑。
    bool isClearedForCycle(
      MainlineProgress progress,
      String stageId,
      int cycle,
    ) {
      return progress.clearedStageCycleKeys.contains('$stageId#$cycle');
    }

    test('cycle1 已通关 → isCleared=true', () {
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageCycleKeys = ['stage_x#1'];
      expect(isClearedForCycle(p, 'stage_x', 1), isTrue);
    });

    test('cycle2 未通关 → isCleared=false', () {
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageCycleKeys = ['stage_x#1'];
      expect(isClearedForCycle(p, 'stage_x', 2), isFalse);
    });

    test('cycle2 已通关 → isCleared=true', () {
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageCycleKeys = ['stage_x#1', 'stage_x#2'];
      expect(isClearedForCycle(p, 'stage_x', 2), isTrue);
    });

    test('空 clearedStageCycleKeys → 全部 false', () {
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageCycleKeys = [];
      expect(isClearedForCycle(p, 'stage_01_01', 1), isFalse);
    });

    test('不同 stageId 不互相影响', () {
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageCycleKeys = ['stage_a#1'];
      expect(isClearedForCycle(p, 'stage_b', 1), isFalse);
    });

    test('cycle=1 默认对应 D1 零回归：已迁移老存档含 stageId#1 → isCleared=true', () {
      // A3 migration 把 clearedStageIds 转换为 clearedStageCycleKeys 中的 #1 条目。
      // 此处只验语义一致：有 id#1 则 cycle1 已通。
      final p = MainlineProgress()
        ..saveDataId = 1
        ..clearedStageIds = ['stage_01_01']
        ..clearedStageCycleKeys = ['stage_01_01#1'];
      expect(isClearedForCycle(p, 'stage_01_01', 1), isTrue);
    });
  });
}
