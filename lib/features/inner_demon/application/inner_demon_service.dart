import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../shared/strings.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/inner_demon_def.dart';

/// 心魔关战败惩罚结果（in-place 改 ch.internalForce + mainTech.cultivationProgress
/// 已发生，此处汇总供 UI 展示 / 测试断言）。与 DispelService.DefeatPenaltyResult
/// 区别：心魔惩罚 layer 不回退（spec「不跌破当前层起点」自动满足）。
class InnerDemonPenaltyResult {
  final int internalForceBefore;
  final int internalForceAfter;
  final int progressBefore;
  final int progressAfter;
  final double residueHoursApplied;
  const InnerDemonPenaltyResult({
    required this.internalForceBefore,
    required this.internalForceAfter,
    required this.progressBefore,
    required this.progressAfter,
    required this.residueHoursApplied,
  });
}

/// 心魔系统 application 层（1.0 P2.2 §12.1）。
///
/// **已实装**：[isLayerLocked] 升层 unlock 拦截（Batch 2.2.A）、
/// [buildMirrorEnemyTeam] 镜像敌队构造（Batch 2.2.B）、
/// [applyFailurePenalty] 战败惩罚 + 余毒（M6，2026-06-16）。
///
/// 设计要点（memory `feedback_avoid_over_engineer_abstraction`）：
///   - 全部静态方法（无 mutable state，无需 Riverpod provider 持有）
///   - 不直接读 Isar / GameRepository（caller 注入 def + clearedStageIds）→
///     test 易，hook closure 易构造
///   - 非 wuSheng tier 短路 → 不影响 Demo + Ch4-6 主线升层路径
class InnerDemonService {
  InnerDemonService._();

  /// 玩家升 layer 时心魔关 unlock 拦截判定。
  ///
  /// **拦截规则**：
  ///   1. [nextTier] 非 [RealmTier.wuSheng] → false（不影响 Demo 7 阶 + Ch4-6
  ///      主线，Ch6 mainline_06_05 victory 跨 tier 升 wuSheng·qiMeng 自动通过）
  ///   2. [nextLayer] == [RealmLayer.qiMeng]（跨 tier 升 wuSheng 起步层） → false
  ///   3. wuSheng 内 layer N→N+1（N ∈ qiMeng..huaJing）：找 innerDemonDef
  ///      `required_realm_layer` 中 `(wuSheng, prevLayer=N)` 对应的拦截关 →
  ///      该 stage_id ∉ [clearedStageIds] → true（拦截）
  ///   4. 无对应拦截关配置（fixture 不带 inner_demon 段 / 配置不全） → false
  ///
  /// **不处理 wuSheng·dengFeng → 飞升**（next == null 时 advancement_service
  /// 直接 break，本 hook 不被调用；飞升前置 inner_demon_07 留 P2.3 spec 接管）。
  static bool isLayerLocked({
    required RealmTier nextTier,
    required RealmLayer nextLayer,
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    if (nextTier != RealmTier.wuSheng) return false;

    final layers = RealmLayer.values;
    final nextIdx = layers.indexOf(nextLayer);
    if (nextIdx <= 0) return false; // qiMeng 是 wuSheng 起步层（跨 tier 升入）

    final prevLayer = layers[nextIdx - 1];

    for (final entry in innerDemonDef.requiredRealmLayer.entries) {
      if (entry.value.tier == RealmTier.wuSheng &&
          entry.value.layer == prevLayer) {
        return !clearedStageIds.contains(entry.key);
      }
    }

    return false;
  }

  /// 心魔关右队镜像 enemy team 构造（Batch 2.2.B）。
  ///
  /// 深拷贝 [playerTeam] 为右队，按 [stageId] 查 mirror_buff_per_stage 强化
  /// maxHp / maxInternalForce / totalEquipmentAttack ×(1+buff)，clamp §5.4 红线
  /// `mirror_caps`（HP ≤20k / IF ≤15k / attack ≤2k）。
  ///
  /// **重置字段**：
  ///   - `characterId` → `-(slotIndex+1)`（避与玩家 Isar autoIncrement 冲突，
  ///     沿 StageBattleSetup 现有约定）
  ///   - `name` → `'心魔·<原名>'`
  ///   - `currentHp` / `currentInternalForce` → 满值（镜像开战满血满内力）
  ///   - `skillCooldowns` / `activeBuffs` → 空（镜像不继承玩家战中状态 + 不继承
  ///     founderBuff，避免「玩家镜像比玩家自己更强」的双重 buff）
  ///   - `actionPoint` → 0
  ///   - `teamSide` → 1（右队）
  ///   - `slotIndex` → 对应玩家 slot
  ///   - `internalInjury` → null（开战无内伤）
  ///   - `iconPath` → null（Batch 2.3 美术再决定，先走 character_avatar 首字降级）
  ///
  /// **保留字段**：realmTier / realmLayer / school / speed / criticalRate /
  /// evasionRate / defenseRate / mainCultivationLayer / availableSkills /
  /// swordSongResonanceActive（=「与自己一模一样的对手」语义）。
  ///
  /// **inner_demon_07 双镜像处理**（spec §一 末关）：当前实装为单副本 +20%
  /// （与 inner_demon_06 同强化）。BattleState slot ∈ [0,2] 限 3v3，6 副本超
  /// 上限；真正的双镜像（6v3 / 连战）留 Batch 2.5 R5 红线测时讨论。
  ///
  /// **终局机制型 Boss 批次3 · 脆弱窗口注入（05/06）**：当 [stageId] 在
  /// `mirrorVulnerabilityPerStage` 有配置时（仅 05/06），把该关的
  /// `outOfWindowDamageMult` 注入镜像 `vulnerabilityMult`（窗口外承伤减免），
  /// 并把 [mirrorChargeSkill] 注入镜像 `chargeSkillId` + `availableSkills`
  /// （周期性蓄力开窗，CD 复发）。这是**有意的机制化心魔进阶形态**，非纯镜像：
  /// 削弱「秒杀」，逼玩家在蓄力/踉跄窗口内爆发。01-04/07 无 vuln 配置 → 维持
  /// 纯镜像（[mirrorChargeSkill] 传入也不注入，只对有 vuln 条目的关生效）。
  ///
  /// [InnerDemonService] 保持纯函数（不读 Isar/GameRepository），故 SkillDef
  /// 由 caller（StageBattleSetup）解析后注入。缺省 [mirrorChargeSkill] 时
  /// （现有 callsite / 单测 fixture）不注入蓄力技 → 零回归。
  static List<BattleCharacter> buildMirrorEnemyTeam({
    required List<BattleCharacter> playerTeam,
    required String stageId,
    required InnerDemonDef innerDemonDef,
    SkillDef? mirrorChargeSkill,
  }) {
    final buff = innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0;
    final caps = innerDemonDef.mirrorCaps;
    final vuln = innerDemonDef.mirrorVulnerabilityPerStage[stageId];

    // 脆弱窗口是「vuln 减伤 + 蓄力技开窗」的**耦合机制**：二者必须原子注入。
    // 只注 vuln 不注蓄力技 → 镜像永不进蓄力态 → vulnerabilityMultOf 永远返窗口外
    // 减伤 → 永久免疫无解（footgun，实测 balance R5.1 纯镜像 callsite 会踩）。
    // 故仅当 caller 同时提供 [mirrorChargeSkill] 时注入（生产 StageBattleSetup
    // 恒解析并传入）；未提供（旧 callsite / 纯镜像 balance 测）→ 退化纯镜像。
    // fromYaml 已强制「配 vuln 必配 mirror_charge_skill_id」，此处是 service 层
    // 的二次防御。
    final injectMechanic = vuln != null && mirrorChargeSkill != null;

    return [
      for (var i = 0; i < playerTeam.length && i < 3; i++)
        _mirror(
          playerTeam[i],
          buff: buff,
          caps: caps,
          slotIndex: i,
          vulnerabilityMult: injectMechanic ? vuln.outOfWindowDamageMult : null,
          chargeSkill: injectMechanic ? mirrorChargeSkill : null,
        ),
    ];
  }

  /// 心魔关战败惩罚（M6）。对单个**有主修**的参战角色调用一次。
  ///
  /// in-place 改：
  ///   - ch.internalForce = max(floor(old × internalForceMultiplier),
  ///                            floor(internalForceMax × internalForceFloorPct))
  ///   - mainTech.cultivationProgress = floor(old × mainCultivationMultiplier)
  ///     （cultivationLayer / cultivationProgressToNext 不动 → 不跌破当前层起点）
  ///   - ch.innerDemonResidueHoursRemaining = residueHours（再败刷新，不叠加）
  ///   - 辅修不动（subCultivationMultiplier=1.00，不触碰辅修字段）
  ///
  /// Isar 持久化由 caller 负责（沿 DispelService.applyDefeatPenalty 体例）。
  static InnerDemonPenaltyResult applyFailurePenalty({
    required Character ch,
    required Technique mainTech,
    required InnerDemonFailurePenalty penalty,
    required double residueHours,
  }) {
    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;

    final floor =
        (ch.internalForceMax * penalty.internalForceFloorPct).floor();
    final scaled =
        (ch.internalForce * penalty.internalForceMultiplier).floor();
    ch.internalForce = scaled < floor ? floor : scaled;

    // §5.4 惩罚单向下调：主修系数必 ≤ 1.0（内力侧已有地板兜底，progress 侧无
    // 上限守卫，此 assert 防 numbers.yaml 误配 >1.0 反涨修炼度）。
    assert(
      penalty.mainCultivationMultiplier <= 1.0,
      'mainCultivationMultiplier 必 ≤ 1.0（惩罚不得反涨修炼度）',
    );
    mainTech.cultivationProgress =
        (mainTech.cultivationProgress * penalty.mainCultivationMultiplier)
            .floor();

    ch.innerDemonResidueHoursRemaining = residueHours;

    return InnerDemonPenaltyResult(
      internalForceBefore: ifBefore,
      internalForceAfter: ch.internalForce,
      progressBefore: progressBefore,
      progressAfter: mainTech.cultivationProgress,
      residueHoursApplied: residueHours,
    );
  }

  static BattleCharacter _mirror(
    BattleCharacter src, {
    required double buff,
    required InnerDemonMirrorCaps caps,
    required int slotIndex,
    double? vulnerabilityMult,
    SkillDef? chargeSkill,
  }) {
    final maxHp =
        (src.maxHp * (1 + buff)).round().clamp(1, caps.hpMax);
    final maxIf = (src.maxInternalForce * (1 + buff))
        .round()
        .clamp(1, caps.internalForceMax);
    final attack = (src.totalEquipmentAttack * (1 + buff))
        .round()
        .clamp(0, caps.attackPowerMax);

    // 脆弱窗口机制关（05/06）：追加蓄力技进 availableSkills（去重），否则
    // battle_ai._pickSkill 只迭代 availableSkills，永远选不到 chargeSkillId，
    // 蓄力=死机制、窗口永不开=永久免疫无解（镜像 stage_battle_setup.dart:448
    // 识破 pattern）。
    final skills =
        chargeSkill != null && !src.availableSkills.any((s) => s.id == chargeSkill.id)
            ? [...src.availableSkills, chargeSkill]
            : src.availableSkills;

    return src.copyWith(
      characterId: -(slotIndex + 1),
      name: UiStrings.innerDemonMirrorName(src.name),
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxIf,
      currentInternalForce: maxIf,
      totalEquipmentAttack: attack,
      availableSkills: skills,
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
      internalInjury: null,
      iconPath: null,
      vulnerabilityMult: vulnerabilityMult,
      chargeSkillId: chargeSkill?.id,
    );
  }
}
