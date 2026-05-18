import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/isar_setup.dart';

/// 新手引导进度服务(P1 #42 Phase 2 §10 P1.x)。
///
/// 读写 [SaveData.tutorialStep],按 GDD §10.1 八档时间锚点中关卡进度递增:
/// - step 0 = 初始(未通任何 stage)
/// - step 1 = stage_01_01 cleared(战斗 + 装备掉落)
/// - step 2 = stage_01_02 cleared(装备强化 + 共鸣)
/// - step 3 = stage_01_03 cleared(心法主修)
/// - step 4 = stage_01_04 cleared(三流派克制)
/// - step 5 = stage_01_05 cleared(Ch1 通关,闭关 + 师徒解锁)
///
/// step 6-8(师徒 / 奇遇 / 装备开锋)留 P1.y / Ch2 实装。
///
/// **设计纪律**:
/// - **caller 持锁**(对齐 [GameEventService] 体例):本服务方法不开 `writeTxn`,
///   由 caller 的 `isar.writeTxn` 包裹,保证多表写入原子性(memory
///   `feedback_isar_pitfalls` §1 防嵌套 writeTxn 死锁)。
/// - **幂等 + 防回退**:[advanceToStep] 若 currentStep >= targetStep no-op,
///   保证多次调用 / 重复通关 / 顺序通关与跳关后回头通低关 step 不会回退。
/// - **不持 ref**(memory `feedback_riverpod_closure_ref_disposed`):
///   service 是纯函数式 wrapper,不依赖 Riverpod。
class TutorialService {
  final Isar isar;

  TutorialService(this.isar);

  /// Ch1 stage_id → tutorialStep 映射(本批 5 → step 1-5)。
  /// 后续章 / 高阶系统(师徒 / 奇遇 / 装备开锋)留 P1.y 扩。
  static const Map<String, int> _ch1StageToStep = {
    'stage_01_01': 1,
    'stage_01_02': 2,
    'stage_01_03': 3,
    'stage_01_04': 4,
    'stage_01_05': 5,
  };

  /// 读当前 [SaveData.tutorialStep](默认 0)。
  ///
  /// SaveData 未初始化(test 路径 / 全新存档)→ 0。
  Future<int> getCurrentStep() async {
    final save = await isar.saveDatas
        .filter()
        .slotIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    return save?.tutorialStep ?? 0;
  }

  /// 推进 [SaveData.tutorialStep] 到 `targetStep`(若 currentStep < targetStep)。
  ///
  /// 幂等 + 防回退:currentStep >= targetStep 时 no-op,不写 Isar。
  /// SaveData 未初始化时 no-op(test / 全新存档兜底)。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法。
  Future<void> advanceToStep(int targetStep) async {
    final save = await isar.saveDatas
        .filter()
        .slotIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    if (save == null) return;
    if (save.tutorialStep >= targetStep) return;
    save.tutorialStep = targetStep;
    await isar.saveDatas.put(save);
  }

  /// 主线关卡通关 hook(stage_01_0X → step X)。
  ///
  /// 非 Ch1 stage(stage_02_* / 爬塔 / debug)→ no-op。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法,
  /// 与 `MainlineProgress.clearedStageIds` 同事务原子写入。
  Future<void> advanceForStageCleared(String stageId) async {
    final targetStep = _ch1StageToStep[stageId];
    if (targetStep == null) return;
    await advanceToStep(targetStep);
  }
}
