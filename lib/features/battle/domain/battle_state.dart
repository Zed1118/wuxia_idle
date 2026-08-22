import '../../../data/defs/boss_phase_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/stage_win_condition.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/numbers_config.dart';
import '../../combat_shared/domain/damage_calculator.dart';
import '../../../shared/battle_shared/battle_result.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_builder.dart';

// 2026-08-19 共享层拆分迁移批:BattleResult 已迁 lib/shared/battle_shared/battle_result.dart,
// re-export 保持存量 63 处 `import battle_state.dart` 消费方口径不破。
export '../../../shared/battle_shared/battle_result.dart' show BattleResult;

/// attackPowerMultiplier 的来源，用于战报解释乘区。
enum AttackPowerMultiplierSource { jianghuEnmity, terrain, formation }

/// 一次战斗动作（phase1_tasks.md T11 §638-645）。
///
/// 用于动画播放与事件日志（T13 / T15）。一旦写入 [BattleState.actionLog] 即不再修改。
class BattleAction {
  final int tick;
  final int actorId;
  final int? targetId;
  final SkillDef? skill;
  final AttackResult? attackResult;
  final String description;

  /// B3 破招:本动作是否打断了目标蓄力(canInterrupt 技命中蓄力中目标)。
  /// 表现层据此弹「破！」题字 overlay(纯读元数据,不参与战斗结算)。
  final bool interrupted;

  /// 本动作通过破防(defenseBreakPct>0 命中,非破招)打开破绽窗口;破招开窗用
  /// interrupted 区分,二者互斥——表现层据此分别题字「破绽」/「破!」。
  final bool openedBreakWindow;

  /// 第七阶段批二 ①:本动作触发了 Boss 转阶段时,记录进入的新阶段 index(null=未转阶段)。
  /// 表现层据此弹转阶段题字 overlay(纯读元数据,不参与战斗结算)。
  final int? bossPhaseTransitionTo;

  /// 第七阶段批二 ①:转阶段题字 UiStrings key(BossPhaseDef.titleKey 透传;
  /// null=该阶段不题字或非转阶段动作)。
  final String? bossPhaseTitleKey;

  /// 第七阶段批二 ②:本动作命中了目标的弱点流派(受伤乘子 >1.0)。
  /// 表现层据此弹「会心」glyph(纯读元数据,不参与结算)。default false;
  /// Task 7 由 caller 据守方 schoolDamageTakenMult 设置,本批仅加字段。
  final bool weaknessHit;

  /// 本动作结算当刻是否令目标由存活变为阵亡。
  ///
  /// 必须随动作写入快照，不能由战报回查目标的最终状态，否则目标在后续动作中
  /// 阵亡时，早先的普通命中也会被追溯误标为“击杀”。
  final bool defeatedTarget;

  /// 第八阶段 §2.1:本次破招被掩护护法代吃(目标由被护 Boss 重定向为护法)。
  /// targetId 已是护法;表现层/战报据此标注「掩护代吃」(纯读元数据,不参与结算)。
  final bool guardIntercepted;

  /// 第八阶段 §2.2:合击动作的搭档护法 charId(null=非合击)。actorId=主发起
  /// 护法,[attackResult] 仅主发起者那份(保真不伪造合成 result)。
  final int? coopStrikePartnerId;

  /// 第八阶段 §2.2:合击合并总伤害(两护法各自公式伤害求和,一次扣血;
  /// null=非合击)。战报直读此值,不从 attackResult 重算(那只是主发起者份)。
  final int? coopStrikeTotalDamage;

  const BattleAction({
    required this.tick,
    required this.actorId,
    this.targetId,
    this.skill,
    this.attackResult,
    required this.description,
    this.interrupted = false,
    this.openedBreakWindow = false,
    this.bossPhaseTransitionTo,
    this.bossPhaseTitleKey,
    this.weaknessHit = false,
    this.defeatedTarget = false,
    this.guardIntercepted = false,
    this.coopStrikePartnerId,
    this.coopStrikeTotalDamage,
  });

  @override
  String toString() =>
      'BattleAction(tick=$tick, actor=$actorId, target=$targetId, '
      'skill=${skill?.id}, dmg=${attackResult?.finalDamage}, "$description")';
}

/// 战斗中的角色快照（phase1_tasks.md T11 §600）。
///
/// **immutable**：每次状态变化通过 [copyWith] 产生新对象，Riverpod 监听只在引用
/// 变化时触发，避免无限重建（phase1_tasks T11 §654）。
///
/// **不持有 Equipment / Technique 引用**（phase1_tasks T11 §657）：派生属性在
/// [fromCharacter] 时一次性算好缓存，战斗过程中不再回查 Isar 数据，避免误改持久化对象。
class BattleCharacter {
  final int characterId;
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final TechniqueSchool school;

  final int maxHp;
  final int currentHp;

  /// Effective snapshot of persistent cultivated power; never spent in battle.
  final int internalForce;

  /// Bounded per-battle resource.
  final int maxQi;
  final int currentQi;
  final double qiGainMultiplier;
  final double qiCostReductionPct;
  final bool autoUltimate;

  final int speed;
  final double criticalRate;
  final double evasionRate;

  /// 守方防御率(GDD §5.5,应用项为 `1 - defenseRate`)。
  ///
  /// W18-A1.2 从 numbers.yaml `defenseRateByTier[realmTier]` 派生 base 值,
  /// [StageBattleSetup.applySynergy] 命中相生时加法注入 `defensePct`,
  /// battle_engine 用 `defender.defenseRate` 替代查 numbers.yaml(view layer
  /// 缓存 + synergy 加成共存)。
  final double defenseRate;

  /// 已穿装备的攻击合计（已应用强化 × 共鸣 × 开锋）。战斗中不变，伤害公式
  /// 基础项直接读这个值，避免每 tick 回算（phase1_tasks T11 §657 派生快照）。
  final int totalEquipmentAttack;

  /// 主修心法当前修炼度层（战斗中不变，决定伤害倍率 1.0~3.0）。
  final CultivationLayer mainCultivationLayer;

  final List<SkillDef> availableSkills;
  final Map<String, int> skillCooldowns;

  /// 可玩性 P1a:进场快照的 per-skill 累积放招次数(来源 owner Technique.skillUsageCount)。
  /// 用于战中派生招式熟练度倍率。敌人路径不填(默认空 → 全 0 → 1.0 倍率)。
  final Map<String, int> skillUses;
  final List<String> activeBuffs;

  final int actionPoint;
  final bool isAlive;
  final int teamSide;
  final int slotIndex;

  /// 阴柔克灵巧附带内伤 debuff 槽(CLAUDE.md §12.1 #7 v1.4)。
  /// null = 无 debuff;非 null = 守方下 [InternalInjurySlot.remainingTurns] 次
  /// 自己出手时每次承受 [InternalInjurySlot.damagePerTick] 固定伤害。
  final InternalInjurySlot? internalInjury;

  /// P1.1 候选 3-c:任一武器 resonanceStage 达到 hasSwordSongEffect=true 阶
  /// (xinJianTongLing 心剑通灵)时为 true。该角色暴击时 damage_popup 旁
  /// 追加「✦剑鸣」浮字(纯文字降级,VFX 留 Phase 5+ 美术阶段)。
  /// fromCharacter 自动算;NPC 走 _enemyToBattle 默认 false。
  final bool swordSongResonanceActive;

  /// M4 Stage 3 美术(2026-05-21):敌方头像 png 路径(EnemyDef.iconPath 直接注入)。
  /// 玩家方/师徒 NPC 暂为 null(走 character_avatar 首字降级)。
  /// widget 层走 errorBuilder fallback,无图时降级到 _FirstGlyphAvatar。
  final String? iconPath;

  /// 攻击力倍率(P3.1.B 子批 · 2026-05-24)。base 公式末端乘项,default=1.0 表示
  /// 无修饰。[LightFootStrategy._bake] 在 runToEnd 入口烘焙 terrain `damageMultiplier`
  /// 到本字段(双方对等),damage_calculator 计算时直接读用。
  ///
  /// **不进 base 求和**(不与 totalEquipmentAttack 累加),独立维度乘项。
  /// **沿 critRate/evasionRate/defenseRate 体例**:default-safe,所有非 lightfoot
  /// 战斗路径自动得 1.0(fromCharacter / _enemyToBattle 不 expose)。
  final double attackPowerMultiplier;

  /// [attackPowerMultiplier] 的解释来源。null 表示无需在战报中展示专名。
  final AttackPowerMultiplierSource? attackPowerMultiplierSource;

  /// 战斗输出乘数(默认 1.0)，用于重伤或心魔机制等临时状态。
  /// 独立末端乘，可与 attackPowerMultiplier 组合。
  final double outputMultiplier;

  /// 出版美术 B2:此角色是否为 Boss(EnemyDef.isBoss 透传)。true 时
  /// CharacterAvatar 走金色加粗描边。玩家方恒 false。
  final bool isBoss;

  /// P0 破招:此单位的招牌技 id(仅 Boss 配置;null=不蓄力)。
  final String? chargeSkillId;

  /// P0 破招:运行时——当前正在蓄力的招(null=未蓄力)。
  final SkillDef? chargingSkill;

  /// P0 破招:蓄力剩余 tick(0=未蓄力)。
  final int chargeTicksRemaining;

  /// P0 破招:踉跄剩余 tick(0=未踉跄)。
  final int staggerTicksRemaining;

  /// 波A interrupt_power_pct(方向 b):本次踉跄的有效减防比例
  /// (= base × (1 + 放招者该破招技当阶 power_pct),破招结算时写入,
  /// 踉跄结束清 null)。null=用 numbers 基础值(兼容直接构造的测试 fixture)。
  final double? staggerDefenseDownOverride;

  /// 第七阶段批二 ①:当前 Boss 阶段下标(默认 0=起始阶段;非 Boss 恒 0)。
  /// 运行时随血量跌破 [bossPhases] 下一阶段阈值由 strategy 推进(merge 解锁招 + 记事件)。
  final int bossPhaseIndex;

  /// 第七阶段批二 ①:Boss 阶段定义列表(阈值/aiMode/机制/题字),
  /// null=单阶段旧行为(非 Boss / 未配 bossPhases)。strategy 只读不改。
  final List<BossPhaseDef>? bossPhases;

  /// 第七阶段批二 ①:与 [bossPhases] 下标对齐的「进入该阶段并入 availableSkills 的招」
  /// 预解析结果(setup 期把 unlockSkillIds → SkillDef,避免战中回查 GameRepository)。
  /// phase 0(起始)条目通常为空列表。null=非 Boss / 未配。
  final List<List<SkillDef>>? bossPhaseUnlockSkills;

  /// 第七阶段批二 ②:本单位按攻方流派的弱点/抗性受伤乘子(EnemyDef 透传,
  /// 玩家/NPC 恒空)。key=攻方流派,value>1.0 弱点/<1.0 抗性。default const {}。
  /// Task 7 由 DefaultGroundStrategy 据攻方流派查此表 → DamageCalculator
  /// `defenderSchoolDamageMult`;本批仅加字段,无 caller 消费(零行为变更)。
  final Map<TechniqueSchool, double> schoolDamageTakenMult;

  /// 第七阶段批三:角色师徒定位(玩家方透传 [Character.lineageRole];敌人/NPC 恒 null)。
  /// battle_ai 据此给 junior(二弟子)「优先盯蓄力敌」控场目标偏好。default null=无差异、零回归。
  final LineageRole? lineageRole;

  /// 开锋破甲穿透率（全身装备 pierce 槽求和，烘焙自 fromCharacter）。0=无破甲。
  final double forgingPiercePct;

  /// 开锋吸血率（全身装备 lifesteal 槽求和，烘焙自 fromCharacter）。0=无吸血。
  final double forgingLifestealPct;

  /// 护法结界(floor30):敌人源 def id(仅敌方填充；玩家方 null)。护法结界据此
  /// 判定护法存活（EnemyDef.id 透传，见 spec 2026-07-01-floor30-guardian-ward）。
  final String? enemyDefId;

  /// 护法结界:本单位(主 Boss)承伤乘子；null=非结界单位/无结界。
  final double? guardianWardMult;

  /// 护法结界:守护本单位的护法 def id 集合（空=无结界）。
  final List<String> guardianDefIds;

  /// 脆弱窗口(终局机制型 Boss):窗口外承伤乘子；null=无机制（旧行为，全额受伤）。
  /// 由 StageBattleSetup 从 EnemyDef.vulnerability 灌入。
  final double? vulnerabilityMult;

  /// 第八阶段:协同 Boss 掩护开关(EnemyDef.guardInterceptsInterrupt 透传;
  /// 玩家方恒 false)。true 且蓄力中且有 [guardianDefIds] 护法存活 → 我方破招
  /// 被护法代吃(重定向+踉跄),Boss 蓄力不断(spec §2.1);同相位双护法可合击(§2.2)。
  final bool guardInterceptsInterrupt;

  /// 第八阶段 §2.2:本次蓄力(掩护相位)内合击已用(运行时;Boss 侧字段,
  /// 每次进入蓄力态时重置 false,合击触发后置 true=每相位一次)。
  final bool coopStrikeUsedInCharge;

  /// 第八阶段 §2.2:护法侧「本 tick 行动拍已被合击消费」标记(运行时;
  /// == 当前 [BattleState.tick] 时 stepOne 弹出直接出队防同拍双花)。
  /// 旧 tick 残值无害——仅与当前 tick 比对,无需清理。
  final int? coopStrikeConsumedAtTick;

  const BattleCharacter({
    required this.characterId,
    required this.name,
    required this.realmTier,
    required this.realmLayer,
    required this.school,
    required this.maxHp,
    required this.currentHp,
    int? internalForce,
    int? maxQi,
    int? currentQi,
    this.qiGainMultiplier = 1.0,
    this.qiCostReductionPct = 0.0,
    this.autoUltimate = false,
    @Deprecated('请使用 maxQi') int? maxInternalForce,
    @Deprecated('请使用 currentQi') int? currentInternalForce,
    required this.speed,
    required this.criticalRate,
    required this.evasionRate,
    required this.defenseRate,
    required this.totalEquipmentAttack,
    required this.mainCultivationLayer,
    required this.availableSkills,
    required this.skillCooldowns,
    this.skillUses = const {},
    required this.activeBuffs,
    required this.actionPoint,
    required this.isAlive,
    required this.teamSide,
    required this.slotIndex,
    this.internalInjury,
    this.swordSongResonanceActive = false,
    this.iconPath,
    this.attackPowerMultiplier = 1.0,
    this.attackPowerMultiplierSource,
    this.outputMultiplier = 1.0,
    this.isBoss = false,
    this.chargeSkillId,
    this.chargingSkill,
    this.chargeTicksRemaining = 0,
    this.staggerTicksRemaining = 0,
    this.staggerDefenseDownOverride,
    this.bossPhaseIndex = 0,
    this.bossPhases,
    this.bossPhaseUnlockSkills,
    this.schoolDamageTakenMult = const {},
    this.lineageRole,
    this.forgingPiercePct = 0.0,
    this.forgingLifestealPct = 0.0,
    this.enemyDefId,
    this.guardianWardMult,
    this.guardianDefIds = const [],
    this.vulnerabilityMult,
    this.guardInterceptsInterrupt = false,
    this.coopStrikeUsedInCharge = false,
    this.coopStrikeConsumedAtTick,
  }) : assert(
         (internalForce != null && maxQi != null && currentQi != null) ||
             (maxInternalForce != null && currentInternalForce != null),
       ),
       internalForce = internalForce ?? currentInternalForce ?? 0,
       maxQi = maxQi ?? maxInternalForce ?? 0,
       currentQi = currentQi ?? currentInternalForce ?? 0;

  @Deprecated('战斗资源已拆为真气，请使用 maxQi')
  int get maxInternalForce => maxQi;

  @Deprecated('战斗资源已拆为真气，请使用 currentQi')
  int get currentInternalForce => currentQi;

  /// 从 Isar 实体构造战斗快照（phase1_tasks T11 §651）。
  ///
  /// **Legacy 兼容入口**：派生事实委托给
  /// [PlayerCombatantSnapshotBuilder]，这里只补旧 3v3 runtime 坐标与初始状态。
  ///
  /// - `character.school` 必须非空（无主修角色不应进入战斗）。
  /// - `availableSkills` 从主修心法 [TechniqueDef.skillIds] 解析（辅修不上场招式）。
  /// - `currentHp` 初始 = `maxHp`；`currentInternalForce` 初始 =
  ///   `character.internalForce`（保留当前持有内力，与 GDD §5.3 公式输入一致）。
  /// - `actionPoint` 初始 = 0（time-based 行动制起点）。
  factory BattleCharacter.fromCharacter({
    required Character character,
    required List<Equipment> equipped,
    required Technique mainTechnique,
    required NumbersConfig numbers,
    required int teamSide,
    required int slotIndex,
    bool founderBuffActive = false,
    double outputMultiplier = 1.0,
    bool heavyInjured = false,
    int lightInjuryStacks = 0,
  }) {
    final school = character.school;
    if (school == null) {
      throw StateError(
        'BattleCharacter.fromCharacter: ${character.name} 主修流派为空，'
        '不应进入战斗',
      );
    }
    if (mainTechnique.role != TechniqueRole.main) {
      throw StateError(
        'BattleCharacter.fromCharacter: ${character.name} 传入的 Technique '
        '(defId=${mainTechnique.defId}) role=${mainTechnique.role.name}，'
        '不是 main',
      );
    }
    if (teamSide != 0 && teamSide != 1) {
      throw RangeError.value(teamSide, 'teamSide', '必须为 0 或 1');
    }
    if (slotIndex < 0 || slotIndex > 2) {
      throw RangeError.value(slotIndex, 'slotIndex', '必须 ∈ [0, 2]');
    }
    for (final eq in equipped) {
      if (!eq.isEquippableAtRealm(character.realmTier)) {
        throw StateError(
          'BattleCharacter.fromCharacter: ${character.name} 境界 '
          '${character.realmTier.name} 不能装备 ${eq.defId}(${eq.tier.name})',
        );
      }
    }

    final snapshot = PlayerCombatantSnapshotBuilder.build(
      character: character,
      equipped: equipped,
      mainTechnique: mainTechnique,
      numbers: numbers,
      founderBuffActive: founderBuffActive,
      outputMultiplier: outputMultiplier,
      lightInjuryStacks: lightInjuryStacks,
      includeLegacyPlayerInterruptFallback: teamSide == 0,
    );
    return BattleCharacter(
      characterId: snapshot.characterId,
      name: snapshot.name,
      realmTier: snapshot.realmTier,
      realmLayer: snapshot.realmLayer,
      school: snapshot.school,
      maxHp: snapshot.maxHp,
      currentHp: snapshot.currentHp,
      internalForce: snapshot.internalForce,
      maxQi: snapshot.maxQi,
      currentQi: snapshot.currentQi,
      qiGainMultiplier: snapshot.qiGainMultiplier,
      qiCostReductionPct: snapshot.qiCostReductionPct,
      autoUltimate: snapshot.autoUltimate,
      speed: snapshot.speed,
      criticalRate: snapshot.criticalRate,
      evasionRate: snapshot.evasionRate,
      defenseRate: snapshot.defenseRate,
      totalEquipmentAttack: snapshot.totalEquipmentAttack,
      mainCultivationLayer: snapshot.mainCultivationLayer,
      availableSkills: snapshot.availableSkills,
      skillCooldowns: snapshot.openingSkillCooldowns,
      skillUses: snapshot.skillUses,
      activeBuffs: snapshot.activeBuffs,
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
      swordSongResonanceActive: snapshot.swordSongResonanceActive,
      iconPath: snapshot.iconPath,
      attackPowerMultiplier: snapshot.attackPowerMultiplier,
      outputMultiplier: snapshot.outputMultiplier,
      isBoss: snapshot.isBoss,
      chargeSkillId: snapshot.chargeSkillId,
      bossPhases: snapshot.bossPhases,
      bossPhaseUnlockSkills: snapshot.bossPhaseUnlockSkills,
      schoolDamageTakenMult: snapshot.schoolDamageTakenMult,
      lineageRole: snapshot.lineageRole,
      forgingPiercePct: snapshot.forgingPiercePct,
      forgingLifestealPct: snapshot.forgingLifestealPct,
      enemyDefId: snapshot.enemyDefId,
      guardianWardMult: snapshot.guardianWardMult,
      guardianDefIds: snapshot.guardianDefIds,
      vulnerabilityMult: snapshot.vulnerabilityMult,
      guardInterceptsInterrupt: snapshot.guardInterceptsInterrupt,
    );
  }

  BattleCharacter copyWith({
    int? characterId,
    String? name,
    RealmTier? realmTier,
    RealmLayer? realmLayer,
    TechniqueSchool? school,
    int? maxHp,
    int? currentHp,
    int? internalForce,
    int? maxQi,
    int? currentQi,
    double? qiGainMultiplier,
    double? qiCostReductionPct,
    bool? autoUltimate,
    @Deprecated('请使用 maxQi') int? maxInternalForce,
    @Deprecated('请使用 currentQi') int? currentInternalForce,
    int? speed,
    double? criticalRate,
    double? evasionRate,
    double? defenseRate,
    int? totalEquipmentAttack,
    CultivationLayer? mainCultivationLayer,
    List<SkillDef>? availableSkills,
    Map<String, int>? skillCooldowns,
    Map<String, int>? skillUses,
    List<String>? activeBuffs,
    int? actionPoint,
    bool? isAlive,
    int? teamSide,
    int? slotIndex,
    Object? internalInjury = _unset,
    bool? swordSongResonanceActive,
    Object? iconPath = _unset,
    double? attackPowerMultiplier,
    Object? attackPowerMultiplierSource = _unset,
    double? outputMultiplier,
    bool? isBoss,
    Object? chargeSkillId = _unset,
    Object? chargingSkill = _unset,
    int? chargeTicksRemaining,
    int? staggerTicksRemaining,
    Object? staggerDefenseDownOverride = _unset,
    int? bossPhaseIndex,
    Object? bossPhases = _unset,
    Object? bossPhaseUnlockSkills = _unset,
    Map<TechniqueSchool, double>? schoolDamageTakenMult,
    LineageRole? lineageRole,
    double? forgingPiercePct,
    double? forgingLifestealPct,
    String? enemyDefId,
    double? guardianWardMult,
    List<String>? guardianDefIds,
    double? vulnerabilityMult,
    bool? guardInterceptsInterrupt,
    bool? coopStrikeUsedInCharge,
    Object? coopStrikeConsumedAtTick = _unset,
  }) {
    return BattleCharacter(
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      realmTier: realmTier ?? this.realmTier,
      realmLayer: realmLayer ?? this.realmLayer,
      school: school ?? this.school,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      internalForce: internalForce ?? this.internalForce,
      maxQi: maxQi ?? maxInternalForce ?? this.maxQi,
      currentQi: currentQi ?? currentInternalForce ?? this.currentQi,
      qiGainMultiplier: qiGainMultiplier ?? this.qiGainMultiplier,
      qiCostReductionPct: qiCostReductionPct ?? this.qiCostReductionPct,
      autoUltimate: autoUltimate ?? this.autoUltimate,
      speed: speed ?? this.speed,
      criticalRate: criticalRate ?? this.criticalRate,
      evasionRate: evasionRate ?? this.evasionRate,
      defenseRate: defenseRate ?? this.defenseRate,
      totalEquipmentAttack: totalEquipmentAttack ?? this.totalEquipmentAttack,
      mainCultivationLayer: mainCultivationLayer ?? this.mainCultivationLayer,
      availableSkills: availableSkills ?? this.availableSkills,
      skillCooldowns: skillCooldowns ?? this.skillCooldowns,
      skillUses: skillUses ?? this.skillUses,
      activeBuffs: activeBuffs ?? this.activeBuffs,
      actionPoint: actionPoint ?? this.actionPoint,
      isAlive: isAlive ?? this.isAlive,
      teamSide: teamSide ?? this.teamSide,
      slotIndex: slotIndex ?? this.slotIndex,
      internalInjury: identical(internalInjury, _unset)
          ? this.internalInjury
          : internalInjury as InternalInjurySlot?,
      swordSongResonanceActive:
          swordSongResonanceActive ?? this.swordSongResonanceActive,
      iconPath: identical(iconPath, _unset)
          ? this.iconPath
          : iconPath as String?,
      attackPowerMultiplier:
          attackPowerMultiplier ?? this.attackPowerMultiplier,
      attackPowerMultiplierSource:
          identical(attackPowerMultiplierSource, _unset)
          ? this.attackPowerMultiplierSource
          : attackPowerMultiplierSource as AttackPowerMultiplierSource?,
      outputMultiplier: outputMultiplier ?? this.outputMultiplier,
      isBoss: isBoss ?? this.isBoss,
      chargeSkillId: identical(chargeSkillId, _unset)
          ? this.chargeSkillId
          : chargeSkillId as String?,
      chargingSkill: identical(chargingSkill, _unset)
          ? this.chargingSkill
          : chargingSkill as SkillDef?,
      chargeTicksRemaining: chargeTicksRemaining ?? this.chargeTicksRemaining,
      staggerTicksRemaining:
          staggerTicksRemaining ?? this.staggerTicksRemaining,
      staggerDefenseDownOverride: identical(staggerDefenseDownOverride, _unset)
          ? this.staggerDefenseDownOverride
          : staggerDefenseDownOverride as double?,
      bossPhaseIndex: bossPhaseIndex ?? this.bossPhaseIndex,
      bossPhases: identical(bossPhases, _unset)
          ? this.bossPhases
          : bossPhases as List<BossPhaseDef>?,
      bossPhaseUnlockSkills: identical(bossPhaseUnlockSkills, _unset)
          ? this.bossPhaseUnlockSkills
          : bossPhaseUnlockSkills as List<List<SkillDef>>?,
      schoolDamageTakenMult:
          schoolDamageTakenMult ?? this.schoolDamageTakenMult,
      lineageRole: lineageRole ?? this.lineageRole,
      forgingPiercePct: forgingPiercePct ?? this.forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct ?? this.forgingLifestealPct,
      enemyDefId: enemyDefId ?? this.enemyDefId,
      guardianWardMult: guardianWardMult ?? this.guardianWardMult,
      guardianDefIds: guardianDefIds ?? this.guardianDefIds,
      vulnerabilityMult: vulnerabilityMult ?? this.vulnerabilityMult,
      guardInterceptsInterrupt:
          guardInterceptsInterrupt ?? this.guardInterceptsInterrupt,
      coopStrikeUsedInCharge:
          coopStrikeUsedInCharge ?? this.coopStrikeUsedInCharge,
      coopStrikeConsumedAtTick: identical(coopStrikeConsumedAtTick, _unset)
          ? this.coopStrikeConsumedAtTick
          : coopStrikeConsumedAtTick as int?,
    );
  }

  @override
  String toString() =>
      'BattleCharacter(id=$characterId, name=$name, '
      '${realmTier.name}/${realmLayer.name}, ${school.name}, '
      'hp=$currentHp/$maxHp, innerForce=$internalForce, qi=$currentQi/$maxQi, '
      'spd=$speed, crit=${criticalRate.toStringAsFixed(2)}, '
      'ap=$actionPoint, alive=$isAlive, team=$teamSide#$slotIndex'
      '${internalInjury != null ? ", injury=$internalInjury" : ""})';
}

/// 阴柔克灵巧附带内伤 debuff 槽(CLAUDE.md §12.1 #7 v1.4 决议)。
///
/// 命中且 attacker=yinRou / defender=lingQiao 时,在守方身上施加内伤槽。
/// 守方下 [remainingTurns] 次自己出手时,每次承受 [damagePerTick] 固定伤害
/// (穿透防御率,可致死)。同源刷新(覆盖):重复触发重置 remainingTurns + 不叠层。
class InternalInjurySlot {
  /// 剩余结算次数(每次守方自己出手扣 1)。
  final int remainingTurns;

  /// 每次结算扣的固定伤害(numbers.yaml `yin_rou_internal_injury.damage_per_tick`)。
  final int damagePerTick;

  const InternalInjurySlot({
    required this.remainingTurns,
    required this.damagePerTick,
  });

  @override
  String toString() =>
      'InternalInjurySlot(turns=$remainingTurns, dmg=$damagePerTick)';

  @override
  bool operator ==(Object other) =>
      other is InternalInjurySlot &&
      other.remainingTurns == remainingTurns &&
      other.damagePerTick == damagePerTick;

  @override
  int get hashCode => Object.hash(remainingTurns, damagePerTick);
}

/// 战斗整体状态（phase1_tasks.md T11 §625 + T12 §698）。
///
/// **immutable**。每 tick 通过 [copyWith] 推进，Riverpod 通过引用变化触发监听。
/// `result == null` 表示战斗仍在进行；非空表示已结束。
///
/// `pendingUltimates`：玩家手动按下大招按钮时由
/// [DefaultGroundStrategy.requestUltimate] 写入；该角色下次行动时由 [BattleAI.decide]
/// 优先消费（内力够 + CD 0 时一定使用），然后由引擎从 map 中移除。
class BattleState {
  final List<BattleCharacter> leftTeam;
  final List<BattleCharacter> rightTeam;
  final int tick;
  final BattleResult? result;
  final List<BattleAction> actionLog;
  final Map<int, SkillDef> pendingUltimates;

  /// 半手动战斗 P0 步骤3a:玩家对 [pendingUltimates] 中手动技指定的目标
  /// (charId → 目标 charId)。[BattleAI.decide] 消费该指定目标(优先于
  /// 默认「血最低」);与 [pendingUltimates] 同生命周期(行动后一并移除)。
  /// 未指定的手动技不入此 map(走 AI 默认选目标)。
  final Map<int, int> pendingTargets;

  /// 半手动战斗 P0 步骤3b:本 tick 内待行动的 actor 队列(已按
  /// `DefaultGroundStrategy._actorOrder` 排序)。**瞬态、不落盘**——重放靠同
  /// seed + 同 stepOne 序列重建,不需序列化。
  ///
  /// 语义:tick 边界(队列空)时,`stepOne` 推进全员 AP/CD + 排序 + 填充本字段
  /// (不结算 actor);随后每次 `stepOne` 弹出队首一个 actor 结算。队列为空 =
  /// 处于 tick 边界(`tick()` 进/出此状态时队列恒空,故所有整 tick 路径不受影响)。
  /// 每项 `(charId, teamSide)` 唯一定位一个 [BattleCharacter](characterId 可能
  /// 跨队重号,故带 teamSide)。
  final List<({int charId, int teamSide})> actorQueue;

  /// 本场战斗胜负条件（终局机制型 Boss 批次3）。null = defeatAll（击败全部敌人
  /// 即胜，现状语义）。surviveTicks 型由 strategy 在 tick 边界判定——
  /// tick≥N 且左队存活 → leftWin（与「右队全灭→leftWin」并存，任一即胜）。
  /// 由 [BattleState.initial] 从 StageDef.winCondition 灌入，全程不变。
  final StageWinCondition? winCondition;

  BattleState({
    required this.leftTeam,
    required this.rightTeam,
    required this.tick,
    required this.result,
    required this.actionLog,
    this.pendingUltimates = const {},
    this.pendingTargets = const {},
    this.actorQueue = const [],
    this.winCondition,
  }) {
    assert(_assertUniqueIds(leftTeam, 'leftTeam'));
    assert(_assertUniqueIds(rightTeam, 'rightTeam'));
  }

  /// P3.2.C 修法 ① · sentinel 防御:同 team characterId 必须唯一,防
  /// `_findById` 只返第 1 个匹配 → 同 team 仅首角色行动的 bug。仅 debug 模式生效。
  static bool _assertUniqueIds(List<BattleCharacter> team, String side) {
    if (team.isEmpty) return true;
    final ids = <int>{};
    for (final c in team) {
      if (!ids.add(c.characterId)) {
        throw AssertionError(
          'BattleState: $side characterId=${c.characterId} 重复 '
          '(team size=${team.length} unique=${ids.length})· '
          'sentinel/test autoIncrement 漏给 id 触发 P3.2.C 故障模式',
        );
      }
    }
    return true;
  }

  /// 战斗起始状态（tick=0，无动作日志，result=null，pendingUltimates 空）。
  factory BattleState.initial({
    required List<BattleCharacter> leftTeam,
    required List<BattleCharacter> rightTeam,
    StageWinCondition? winCondition,
  }) {
    return BattleState(
      leftTeam: List.unmodifiable(leftTeam),
      rightTeam: List.unmodifiable(rightTeam),
      tick: 0,
      result: null,
      actionLog: const [],
      pendingUltimates: const {},
      pendingTargets: const {},
      winCondition: winCondition,
    );
  }

  bool get isFinished => result != null;

  /// 按角色 id 在 left/right 两队查找；找不到返 null。
  BattleCharacter? characterById(int id) {
    for (final c in leftTeam) {
      if (c.characterId == id) return c;
    }
    for (final c in rightTeam) {
      if (c.characterId == id) return c;
    }
    return null;
  }

  BattleState copyWith({
    List<BattleCharacter>? leftTeam,
    List<BattleCharacter>? rightTeam,
    int? tick,
    Object? result = _unset,
    List<BattleAction>? actionLog,
    Map<int, SkillDef>? pendingUltimates,
    Map<int, int>? pendingTargets,
    List<({int charId, int teamSide})>? actorQueue,
    StageWinCondition? winCondition,
  }) {
    return BattleState(
      leftTeam: leftTeam ?? this.leftTeam,
      rightTeam: rightTeam ?? this.rightTeam,
      tick: tick ?? this.tick,
      result: identical(result, _unset) ? this.result : result as BattleResult?,
      actionLog: actionLog ?? this.actionLog,
      pendingUltimates: pendingUltimates ?? this.pendingUltimates,
      pendingTargets: pendingTargets ?? this.pendingTargets,
      actorQueue: actorQueue ?? this.actorQueue,
      winCondition: winCondition ?? this.winCondition,
    );
  }

  @override
  String toString() =>
      'BattleState(tick=$tick, left=${leftTeam.length}, '
      'right=${rightTeam.length}, result=${result?.name ?? "ongoing"}, '
      'actions=${actionLog.length})';
}

const Object _unset = Object();
