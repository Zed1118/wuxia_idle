import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
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

/// 心魔系统 application 层（1.0 P2.2 §12.1，Batch 2.2.A vertical slice）。
///
/// **Batch 2.2.A 范围**：仅 [isLayerLocked] 静态判定（unlock 拦截）。
/// 镜像 enemy 构造 / victory 记录 / 失败惩罚等留 Batch 2.2.B。
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
  static List<BattleCharacter> buildMirrorEnemyTeam({
    required List<BattleCharacter> playerTeam,
    required String stageId,
    required InnerDemonDef innerDemonDef,
  }) {
    final buff = innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0;
    final caps = innerDemonDef.mirrorCaps;

    return [
      for (var i = 0; i < playerTeam.length && i < 3; i++)
        _mirror(playerTeam[i], buff: buff, caps: caps, slotIndex: i),
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
  }) {
    final maxHp =
        (src.maxHp * (1 + buff)).round().clamp(1, caps.hpMax);
    final maxIf = (src.maxInternalForce * (1 + buff))
        .round()
        .clamp(1, caps.internalForceMax);
    final attack = (src.totalEquipmentAttack * (1 + buff))
        .round()
        .clamp(0, caps.attackPowerMax);

    return src.copyWith(
      characterId: -(slotIndex + 1),
      name: UiStrings.innerDemonMirrorName(src.name),
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxIf,
      currentInternalForce: maxIf,
      totalEquipmentAttack: attack,
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
      internalInjury: null,
      iconPath: null,
    );
  }
}
