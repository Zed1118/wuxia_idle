import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_setup.dart';

/// 新手引导进度服务(P1 #42 Phase 2 §10 P1.x + P1.y)。
///
/// 读写 [SaveData.tutorialStep] + [SaveData.tutorialHintsRead],
/// 按 GDD §10.1 八档时间锚点中关卡进度递增 + §7.1/§7.2/§6.5 业务门槛:
/// - step 0 = 初始(未通任何 stage)
/// - step 1 = stage_01_01 cleared(战斗 + 装备掉落)
/// - step 2 = stage_01_02 cleared(装备强化 + 共鸣)
/// - step 3 = stage_01_03 cleared(心法主修)
/// - step 4 = stage_01_04 cleared(三流派克制)
/// - step 5 = stage_01_05 cleared(Ch1 通关,闭关 + 师徒解锁)
/// - step 6 = 主角境界突破到一流(GDD §7.1 收徒门槛,P1.y)
/// - step 7 = 第 1 次奇遇触发(GDD §7.2 武学领悟,P1.y)
/// - step 8 = 第 1 次装备 enhanceLevel ≥10(GDD §6.5 开锋阶段锚点,P1.y)
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

  /// 主角境界突破 hook(到一流即推 step 6,GDD §7.1 收徒门槛,P1.y)。
  ///
  /// `tierAfter.index < RealmTier.yiLiu.index` 时 no-op(学徒 / 三流不触发);
  /// 一流及以上首次命中即推 step 6,后续命中靠 [advanceToStep] 单调性 no-op。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法,
  /// 与 `recordRealmBreakthrough` 同事务原子。
  Future<void> advanceForRealmBreakthrough(RealmTier tierAfter) async {
    if (tierAfter.index < RealmTier.yiLiu.index) return;
    await advanceToStep(6);
  }

  /// 第 1 次奇遇触发 hook(推 step 7,GDD §7.2 武学领悟,P1.y)。
  ///
  /// 第 2 次及以后靠 [advanceToStep] 单调性 no-op,无需独立"first"字段。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法,
  /// 与 `recordAdventureTriggered` 同事务原子。
  Future<void> advanceForFirstAdventure() async {
    await advanceToStep(7);
  }

  /// 第 1 次装备 `enhanceLevel >= 10` hook(推 step 8,GDD §6.5 开锋锚点,P1.y)。
  ///
  /// caller 在 `EnhancementService.persistResult` 内判 success outcome 且
  /// `eq.enhanceLevel >= 10` 后 inline 调用。第 2 次及以后靠 [advanceToStep]
  /// 单调性 no-op,无需独立"first"字段。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法,
  /// 与 `equipments.put(eq)` 同事务原子。
  Future<void> advanceForFirstEnhanceLevel10() async {
    await advanceToStep(8);
  }

  /// banner 已读状追加 hook(P1.y)。
  ///
  /// 玩家点击 `TutorialBannerCard` 后调用,把 [step] 追加进
  /// [SaveData.tutorialHintsRead]。值域校验 `step ∈ {6, 7, 8}` —— 越界静默 no-op
  /// (调用方该是表驱动 [TutorialHintDef],越界视为编码错误兜底)。
  /// 重复追加同 step 也 no-op(单调追加,不删)。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法。
  Future<void> markHintRead(int step) async {
    if (step < 6 || step > 8) return;
    final save = await isar.saveDatas
        .filter()
        .slotIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    if (save == null) return;
    if (save.tutorialHintsRead.contains(step)) return;
    save.tutorialHintsRead = [...save.tutorialHintsRead, step];
    await isar.saveDatas.put(save);
  }

  /// 读当前 [SaveData.tutorialHintsRead](默认 `[]`)。P1.y banner 隐藏判定用。
  Future<List<int>> getHintsRead() async {
    final save = await isar.saveDatas
        .filter()
        .slotIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    return save?.tutorialHintsRead ?? const [];
  }
}
