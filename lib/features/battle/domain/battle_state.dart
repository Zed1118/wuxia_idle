import '../../../data/defs/boss_phase_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../data/numbers_config.dart';
import 'damage_calculator.dart';
import 'derived_stats.dart';

// P1.1 候选 3-b:resonanceStages 查找的 orElse fallback(防御性,正常情况不触发,
// numbers.yaml 4 stage 全配)。
const _shengShuFallback = ResonanceStageConfig(
  stage: ResonanceStage.shengShu,
  minBattleCount: 0,
  maxBattleCount: 0,
  bonusMultiplier: 1.0,
);

/// 波A build gate:按流派匹配破招技(canInterrupt && style == school),
/// 旧档 5 槽全空 fallback 路径用,与 P0.5「广发破势」行为等价升级。
/// school null(无主修流派)→ null,不带破招技。
Iterable<SkillDef>? _matchingInterruptSkill(
  GameRepository repo,
  TechniqueSchool? school,
) {
  if (school == null) return null;
  for (final s in repo.skillDefs.values) {
    if (s.canInterrupt && s.style == school) return [s];
  }
  return null;
}

/// 玩家方 teamSide(fromCharacter 唯一在 _playerToBattle 以 0 调用)。
const _playerTeamSide = 0;

/// 战斗最终结局（phase1_tasks.md T11 §635）。
enum BattleResult { leftWin, rightWin, draw }

/// attackPowerMultiplier 的来源，用于战报解释乘区。
enum AttackPowerMultiplierSource { jianghuEnmity }

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
  final int maxInternalForce;
  final int currentInternalForce;

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

  /// M6 心魔余毒:战斗输出乘数(默认 1.0=无)。余毒在身玩家角色 stage_battle_setup
  /// 设为 residue_debuff.battle_output_multiplier(0.95)。独立末端乘,可乘性组合
  /// (不与 attackPowerMultiplier 的 SET 语义冲突)。damage_calculator 末端乘 mainDamage。
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

  const BattleCharacter({
    required this.characterId,
    required this.name,
    required this.realmTier,
    required this.realmLayer,
    required this.school,
    required this.maxHp,
    required this.currentHp,
    required this.maxInternalForce,
    required this.currentInternalForce,
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
  });

  /// 从 Isar 实体构造战斗快照（phase1_tasks T11 §651）。
  ///
  /// **单一入口**：所有派生属性（maxHp / speed / criticalRate / evasionRate）
  /// 走 [CharacterDerivedStats]，[NumbersConfig] 一次注入，避免战斗过程中不同
  /// 字段口径不一致。
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

    final maxHp = CharacterDerivedStats.maxHp(
      character,
      equipped,
      numbers,
      founderBuffActive: founderBuffActive,
    );
    final maxIf = CharacterDerivedStats.internalForceMaxWithLineage(
      character,
      equipped,
      numbers,
      founderBuffActive: founderBuffActive,
      heavyInjured: heavyInjured,
    );
    final speed = CharacterDerivedStats.speed(
      character,
      equipped,
      mainTechnique,
      numbers,
      lightInjuryStacks: lightInjuryStacks,
    );
    final critRate = CharacterDerivedStats.criticalRate(
      character,
      numbers,
      founderBuffActive: founderBuffActive,
    );
    final evRate = CharacterDerivedStats.evasionRate(character, numbers);
    final defRate = RealmUtils.defenseRateOf(character.realmTier);
    final totalEqAtk = equipped.fold<int>(
      0,
      (sum, e) =>
          sum + CharacterDerivedStats.effectiveEquipmentAttack(e, numbers),
    );
    final forgingPiercePct = CharacterDerivedStats.forgingAggregatePct(
      equipped,
      ForgingSlotType.pierce,
    );
    final forgingLifestealPct = CharacterDerivedStats.forgingAggregatePct(
      equipped,
      ForgingSlotType.lifesteal,
    );

    final techDef = GameRepository.instance.getTechnique(mainTechnique.defId);
    // P1b 藏经阁:availableSkills = 6 装配槽非空技能(主修×2 / 辅修 / 共鸣 / 大招 /
    // 奇遇)。getSkill 共享 skillDefs Map(skills.yaml + encounter_skills.yaml
    // 加载合并),encounter skill 与心法招式 runtime 同型(SkillDef)。joint 现在走
    // resonanceSkillId 槽,不再走 hasJointSkillUnlocked 特殊注入。
    final repo = GameRepository.instance;
    final loadoutIds = <String?>[
      character.mainSkillId1,
      character.mainSkillId2,
      character.assistSkillId,
      character.resonanceSkillId,
      character.ultimateSkillId,
      character.equippedEncounterSkillId,
      character.keySkillId,
    ];
    var skills = <SkillDef>[
      for (final id in loadoutIds)
        if (id != null && repo.skillDefs.containsKey(id)) repo.getSkill(id),
    ];
    // 兼容兜底:5 个心法槽全空(从未 autoFill,旧存档/旧测试 fixture)→ fallback
    // 回「主修心法全招 + 奇遇」,保持旧行为不破。autoFill(Task5 进战斗前调)补满
    // 槽后,正常玩法自然走装配。
    final allLoadoutSlotsEmpty =
        character.mainSkillId1 == null &&
        character.mainSkillId2 == null &&
        character.assistSkillId == null &&
        character.resonanceSkillId == null &&
        character.ultimateSkillId == null;
    if (allLoadoutSlotsEmpty) {
      skills = <SkillDef>[
        ...techDef.skillIds.map((id) => repo.getSkill(id)),
        if (character.equippedEncounterSkillId != null &&
            repo.skillDefs.containsKey(character.equippedEncounterSkillId!))
          repo.getSkill(character.equippedEncounterSkillId!),
        // 波A build gate 兜底等价:旧档未 autoFill 时,玩家方自动带本流派
        // 破招技(与旧「广发破势」行为等价升级,流派不匹配则无,见 §1.4)。
        if (teamSide == _playerTeamSide && character.keySkillId == null)
          ...?_matchingInterruptSkill(repo, school),
      ];
    }
    final skillIds = <String>{for (final s in skills) s.id};
    for (final eq in equipped) {
      for (final slot in eq.forgingSlots) {
        if (!slot.unlocked ||
            slot.type != ForgingSlotType.specialSkill ||
            slot.specialSkillId == null) {
          continue;
        }
        final skill = repo.skillDefs[slot.specialSkillId!];
        if (skill == null ||
            !skill.canEquipAtRealm(character.realmTier) ||
            skillIds.contains(skill.id)) {
          continue;
        }
        skills.add(skill);
        skillIds.add(skill.id);
      }
    }
    // P1.1 候选 3-c:玩家方/师徒 NPC 任一武器 resonanceStage 达到 hasSwordSongEffect
    // 阶(numbers.yaml `resonance.stages` 心剑通灵)→ swordSongResonanceActive,
    // xinJianTongLing 阶玩家暴击附带剑鸣浮字(buff,不是技能)。
    var swordSongActive = false;
    for (final e in equipped) {
      if (e.slot != EquipmentSlot.weapon) continue;
      final stage = e.resonanceStage(numbers);
      final cfg = numbers.resonanceStages.firstWhere(
        (c) => c.stage == stage,
        orElse: () => _shengShuFallback,
      );
      if (cfg.hasSwordSongEffect) swordSongActive = true;
    }
    // 波A build gate:P0.5「破势广发」已拆——破招技走 keySkillId 第 7 装配槽
    // (上方 loadoutIds 已含),装配 gate 见 SkillLoadoutService(canInterrupt &&
    // style == school)。旧档 5 槽全空走上方 fallback 自动带本流派破招技。

    return BattleCharacter(
      characterId: character.id,
      name: character.name,
      realmTier: character.realmTier,
      realmLayer: character.realmLayer,
      school: school,
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxIf,
      currentInternalForce: maxIf, // P0:战斗内力进场满(每场预算 · 与敌方对称)
      speed: speed,
      criticalRate: critRate,
      evasionRate: evRate,
      defenseRate: defRate,
      totalEquipmentAttack: totalEqAtk,
      mainCultivationLayer: mainTechnique.cultivationLayer,
      availableSkills: List.unmodifiable(skills),
      skillCooldowns: const {},
      skillUses: {
        for (final sk in skills)
          sk.id: mainTechnique.skillUsageCount.countOf(sk.id),
      },
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
      swordSongResonanceActive: swordSongActive,
      iconPath: character.portraitPath,
      outputMultiplier: outputMultiplier,
      lineageRole: character.lineageRole,
      forgingPiercePct: forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct,
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
    int? maxInternalForce,
    int? currentInternalForce,
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
    String? iconPath,
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
  }) {
    return BattleCharacter(
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      realmTier: realmTier ?? this.realmTier,
      realmLayer: realmLayer ?? this.realmLayer,
      school: school ?? this.school,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      maxInternalForce: maxInternalForce ?? this.maxInternalForce,
      currentInternalForce: currentInternalForce ?? this.currentInternalForce,
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
      iconPath: iconPath ?? this.iconPath,
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
    );
  }

  @override
  String toString() =>
      'BattleCharacter(id=$characterId, name=$name, '
      '${realmTier.name}/${realmLayer.name}, ${school.name}, '
      'hp=$currentHp/$maxHp, if=$currentInternalForce/$maxInternalForce, '
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
/// [BattleEngine.requestUltimate] 写入；该角色下次行动时由 [BattleAI.decide]
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

  BattleState({
    required this.leftTeam,
    required this.rightTeam,
    required this.tick,
    required this.result,
    required this.actionLog,
    this.pendingUltimates = const {},
    this.pendingTargets = const {},
    this.actorQueue = const [],
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
  }) {
    return BattleState(
      leftTeam: List.unmodifiable(leftTeam),
      rightTeam: List.unmodifiable(rightTeam),
      tick: 0,
      result: null,
      actionLog: const [],
      pendingUltimates: const {},
      pendingTargets: const {},
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
    );
  }

  @override
  String toString() =>
      'BattleState(tick=$tick, left=${leftTeam.length}, '
      'right=${rightTeam.length}, result=${result?.name ?? "ongoing"}, '
      'actions=${actionLog.length})';
}

const Object _unset = Object();
