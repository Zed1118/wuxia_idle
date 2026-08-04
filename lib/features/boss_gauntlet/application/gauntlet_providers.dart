import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/strings.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import 'gauntlet_service.dart';

part 'gauntlet_providers.g.dart';

/// [GauntletService] provider（断魂庄 · C2.5）。
///
/// 沿 nullable propagation 链（`expedition_providers` 体例）：isar 为 null 时 service
/// 也为 null，widget 端 `service == null` 短路（测试旁路）。[GauntletService.itemDefs]
/// 供 useSupply/close/返还读补给效果与库存重建类型，从 `GameRepository` 注入。
@riverpod
GauntletService? gauntletService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return GauntletService(
    isar,
    itemDefs: GameRepository.instanceOrNull?.itemDefs ?? const {},
  );
}

/// 当前 active 断魂庄会话（总览断魂庄卡 / 整备屏 watch；无会话 → null）。
/// enter/fight/choose/settle/close 写路径后由 caller
/// `ref.invalidate(activeGauntletProvider)` 统一失效。
@riverpod
Future<BossGauntletRun?> activeGauntlet(Ref ref) async {
  final service = ref.watch(gauntletServiceProvider);
  if (service == null) return null;
  return service.activeRun();
}

/// 断魂庄配置（§8.2）。经 provider watch 而非在 widget 构造期直读单例，避开
/// GameRepository 异步加载与控制器 final 字段的竞态（feedback_flutter_async_config
/// _race_controller_final）。未加载 → null，UI 端降级（不显三敌/推荐境界/入庄）。
@riverpod
BossGauntletConfig? gauntletConfig(Ref ref) =>
    GameRepository.instanceOrNull?.bossGauntletConfig;

/// 一种可托管补给的装载信息（装载屏补给栏用）：defId + 显示名 + 当前普通库存持有数。
class GauntletSupplyOption {
  const GauntletSupplyOption({
    required this.defId,
    required this.name,
    required this.owned,
  });

  final String defId;
  final String name;

  /// 普通库存持有数（可装载上界之一，另一上界为剩余补给预算 3-已装）。
  final int owned;
}

/// 装载屏顶部信息（断魂帖库存 + 可托管补给持有量·§7.1）。断魂庄补给类型 = itemDefs 中
/// `gauntletHpHealPct>0 || gauntletQiRestorePct>0` 者（疗伤丹/行囊补给），按 defId 稳定
/// 排序。enter/close 写路径（改库存）后由 caller `ref.invalidate(gauntletLoadoutInfoProvider)`。
class GauntletLoadoutInfo {
  const GauntletLoadoutInfo({
    required this.ticketCount,
    required this.supplies,
    this.clearedCyclesMax = 0,
  });

  final int ticketCount;
  final List<GauntletSupplyOption> supplies;

  /// 已全通最高周目（批 B 周目选择用；含 [SaveData.duanhunFirstClearedAt]
  /// 旧档 cycle1 派生兜底）。
  final int clearedCyclesMax;
}

/// 装载屏信息 provider（断魂帖库存 + 补给持有·§7.1）。
@riverpod
Future<GauntletLoadoutInfo> gauntletLoadoutInfo(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    return const GauntletLoadoutInfo(ticketCount: 0, supplies: []);
  }
  final ticket = await isar.inventoryItems.getByDefId(
    GauntletService.ticketDefId,
  );
  final defs = GameRepository.instanceOrNull?.itemDefs ?? const {};
  final supplies = <GauntletSupplyOption>[];
  for (final entry in defs.entries) {
    final d = entry.value;
    if (d.gauntletHpHealPct > 0 || d.gauntletQiRestorePct > 0) {
      final inv = await isar.inventoryItems.getByDefId(entry.key);
      supplies.add(
        GauntletSupplyOption(
          defId: entry.key,
          name: d.name,
          owned: inv?.quantity ?? 0,
        ),
      );
    }
  }
  supplies.sort((a, b) => a.defId.compareTo(b.defId));
  final save = await isar.saveDatas.get(0);
  return GauntletLoadoutInfo(
    ticketCount: ticket?.quantity ?? 0,
    supplies: supplies,
    clearedCyclesMax: save != null
        ? GauntletService.duanhunClearedCyclesMaxOf(save)
        : 0,
  );
}

/// 单个入场候选（装载屏择人 1-3 用）：角色 + 可入场性标注（§5.1）。
class GauntletCandidate {
  const GauntletCandidate({
    required this.character,
    required this.occupied,
    required this.hasMainTechnique,
  });

  final Character character;

  /// 已被其它活动（闭关/远征/断魂庄）占用 → 不可入场（UI 标灰）。
  final bool occupied;

  /// 已修主修 → 可入场前置（`enter` 硬拦未修者）。未修 UI 标灰引导研习（§5.7）。
  final bool hasMainTechnique;

  /// 满足入场前置：未被占用且已修主修。
  bool get selectable => !occupied && hasMainTechnique;
}

/// 整备屏单成员展示（§7.2）：角色名 + 生命/真气/阵亡/冷却招数。
class GauntletMemberView {
  const GauntletMemberView({
    required this.characterId,
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.currentQi,
    required this.maxQi,
    required this.downed,
    required this.cooldownCount,
  });

  final int characterId;
  final String name;
  final int currentHp;
  final int maxHp;
  final int currentQi;
  final int maxQi;
  final bool downed;

  /// 冷却中招数（快照 `skillCooldownKeys` 长度）。
  final int cooldownCount;
}

/// 整备屏单条托管补给展示（§7.2）：栏位下标 + 名 + 剩余份数 + 是否疗伤（须择目标）。
class GauntletSupplyRemainView {
  const GauntletSupplyRemainView({
    required this.index,
    required this.defId,
    required this.name,
    required this.remaining,
    required this.isHeal,
  });

  final int index;
  final String defId;
  final String name;

  /// 剩余可用 = 装入 − 已用。
  final int remaining;

  /// 疗伤类（`gauntletHpHealPct>0`）→ 使用须择存活目标；行囊补给恢复全体不择目标。
  final bool isHeal;
}

/// 整备屏组合视图（§7.2）：当前关次 + 三成员状态（含角色名·Character 查表）+ 托管补给
/// 剩余。仅 interlude 相位有意义（非 interlude 返 null，UI 不渲染整备）。
class GauntletInterludeView {
  const GauntletInterludeView({
    required this.stage,
    required this.members,
    required this.supplies,
  });

  final int stage;
  final List<GauntletMemberView> members;
  final List<GauntletSupplyRemainView> supplies;
}

/// 整备屏视图 provider（§7.2）。active 会话且相位 = interlude 时组合成员名/状态 +
/// 托管补给剩余；否则 null（UI 不渲染整备主体）。角色名经 Character 查表（快照只存
/// characterId）；补给名/疗伤判定经 itemDefs。
@riverpod
Future<GauntletInterludeView?> gauntletInterludeView(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  final service = ref.watch(gauntletServiceProvider);
  if (service == null) return null;
  final run = await service.activeRun();
  if (run == null || run.sessionPhase != GauntletPhase.interlude) return null;

  final members = <GauntletMemberView>[];
  for (final m in run.members) {
    final ch = await isar.characters.get(m.characterId);
    members.add(
      GauntletMemberView(
        characterId: m.characterId,
        name: ch?.name ?? UiStrings.gauntletMemberFallbackName,
        currentHp: m.currentHp,
        maxHp: m.maxHp,
        currentQi: m.currentQi,
        maxQi: m.maxQi,
        downed: m.isDowned,
        cooldownCount: m.skillCooldownKeys.length,
      ),
    );
  }

  final defs = GameRepository.instanceOrNull?.itemDefs ?? const {};
  final supplies = <GauntletSupplyRemainView>[];
  for (var i = 0; i < run.escrowItemDefIds.length; i++) {
    final defId = run.escrowItemDefIds[i];
    final def = defs[defId];
    supplies.add(
      GauntletSupplyRemainView(
        index: i,
        defId: defId,
        name: def?.name ?? defId,
        remaining: run.escrowLoadedQty[i] - run.escrowUsedQty[i],
        isHeal: (def?.gauntletHpHealPct ?? 0) > 0,
      ),
    );
  }

  return GauntletInterludeView(
    stage: run.currentStage,
    members: members,
    supplies: supplies,
  );
}

/// 入场候选池（装载屏）：全部可上场非祖师角色（`isFounder==false && isAlive` 一条
/// Isar 查询覆盖 active 门人 + inactive 替补），各标占用/主修态。祖师坐镇不入场
/// （`enter` 硬拦）、亡者排除（§5.1）；已被占用者仍列出但标灰。不做 GameRepository
/// 依赖的排序（保持轻量、可在无 defs 环境测）。enter/settle 写路径后由 caller
/// `ref.invalidate(gauntletCandidatesProvider)` 统一失效。
@riverpod
Future<List<GauntletCandidate>> gauntletCandidates(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  final chars = await isar.characters
      .filter()
      .isFounderEqualTo(false)
      .isAliveEqualTo(true)
      .findAll();
  final occ = await CharacterOccupancyService(isar).snapshot();
  return [
    for (final c in chars)
      GauntletCandidate(
        character: c,
        occupied: occ.isCharacterOccupied(c.id),
        hasMainTechnique: c.mainTechniqueId != null,
      ),
  ];
}

/// 通关三选一奖励屏单个候选卡（§6.2 · #1 wiring Task 2）：命名装备 def 解析后的纯展示
/// 数据（名/阶/位/攻血速区间）。presentation 层经 [EnumL10n] 本地化 tier/slot（DTO
/// 只携原始枚举与数值，localization 归表现层）。
class GauntletRewardCandidate {
  const GauntletRewardCandidate({
    required this.defId,
    required this.name,
    required this.tier,
    required this.slot,
    required this.attackMin,
    required this.attackMax,
    required this.healthMin,
    required this.healthMax,
    required this.speedMin,
    required this.speedMax,
  });

  final String defId;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final int attackMin;
  final int attackMax;
  final int healthMin;
  final int healthMax;
  final int speedMin;
  final int speedMax;
}

/// 通关三选一奖励屏组合视图（§6.2 · #1 wiring Task 2）：首通/重复标 + 三件候选卡。
/// 仅 [GauntletPhase.awaitingRewardChoice] 相位有意义（非该相位/无会话 → null，UI 显
/// 空态）。
class GauntletRewardView {
  const GauntletRewardView({
    required this.isFirstClear,
    required this.candidates,
  });

  final bool isFirstClear;
  final List<GauntletRewardCandidate> candidates;
}

/// 通关三选一奖励屏视图 provider（§6.2 · #1 wiring Task 2）。active 会话且相位 =
/// awaitingRewardChoice 时把 `run.rewardCandidateDefIds` 解析成三件装备卡（名/阶/位/
/// 属性区间经 GameRepository 装备 def 查表）；否则 null（UI 不渲染奖励主体）。装备 def
/// 缺失（防御·加载期红线⑥保证候选引用存在）则跳过该卡。choose 写路径后由 caller
/// `ref.invalidate(gauntletRewardViewProvider)` 统一失效。
@riverpod
Future<GauntletRewardView?> gauntletRewardView(Ref ref) async {
  final service = ref.watch(gauntletServiceProvider);
  if (service == null) return null;
  final run = await service.activeRun();
  if (run == null || run.sessionPhase != GauntletPhase.awaitingRewardChoice) {
    return null;
  }
  final repo = GameRepository.instanceOrNull;
  if (repo == null) return null; // 无装备 def 无法展示卡（生产恒 loaded）
  final candidates = <GauntletRewardCandidate>[];
  for (final defId in run.rewardCandidateDefIds) {
    final def = repo.equipmentDefs[defId];
    if (def == null) continue; // 防御：红线⑥保证候选存在
    candidates.add(
      GauntletRewardCandidate(
        defId: defId,
        name: def.name,
        tier: def.tier,
        slot: def.slot,
        attackMin: def.baseAttackMin,
        attackMax: def.baseAttackMax,
        healthMin: def.baseHealthMin,
        healthMax: def.baseHealthMax,
        speedMin: def.baseSpeedMin,
        speedMax: def.baseSpeedMax,
      ),
    );
  }
  return GauntletRewardView(
    isFirstClear: run.isFirstClearPending,
    candidates: candidates,
  );
}
