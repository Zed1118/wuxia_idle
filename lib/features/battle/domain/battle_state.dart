import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
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

/// 战斗最终结局（phase1_tasks.md T11 §635）。
enum BattleResult { leftWin, rightWin, draw }

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

  const BattleAction({
    required this.tick,
    required this.actorId,
    this.targetId,
    this.skill,
    this.attackResult,
    required this.description,
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

  /// 出版美术 B2:此角色是否为 Boss(EnemyDef.isBoss 透传)。true 时
  /// CharacterAvatar 走金色加粗描边。玩家方恒 false。
  final bool isBoss;

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
    required this.activeBuffs,
    required this.actionPoint,
    required this.isAlive,
    required this.teamSide,
    required this.slotIndex,
    this.internalInjury,
    this.swordSongResonanceActive = false,
    this.iconPath,
    this.attackPowerMultiplier = 1.0,
    this.isBoss = false,
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
    );
    final speed = CharacterDerivedStats.speed(
      character,
      equipped,
      mainTechnique,
      numbers,
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
      (sum, e) => sum + CharacterDerivedStats.effectiveEquipmentAttack(e, numbers),
    );

    final techDef =
        GameRepository.instance.getTechnique(mainTechnique.defId);
    // 主修 3 招(GDD §4.2 主修绑定);C-W14-3-A:角色装备的奇遇 skill 作为
    // 第 4 招(可选)。getSkill 共享 skillDefs Map(skills.yaml + encounter_skills.yaml
    // 加载合并),encounter skill 与心法招式 runtime 同型(SkillDef)。
    final skills = <SkillDef>[
      ...techDef.skillIds.map((id) => GameRepository.instance.getSkill(id)),
    ];
    final encSkillId = character.equippedEncounterSkillId;
    if (encSkillId != null) {
      skills.add(GameRepository.instance.getSkill(encSkillId));
    }
    // P1.1 候选 3-b:玩家方/师徒 NPC 任一武器 resonanceStage 达到 unlocksJointSkill
    // 阶(numbers.yaml `resonance.stages` 默契/心剑通灵)→ 注入 joint_skill 作为
    // 第 4/5 招。GDD §6.4 共鸣度满级解锁「人剑合一」。fromCharacter 唯一 caller
    // 是 _playerToBattle,敌人走 _enemyToBattle 不享。test fixture 缺
    // skill_joint_skill 时 silent skip(containsKey 守护)。
    // P1.1 候选 3-c:同段查 weapon stage cfg.hasSwordSongEffect →
    // swordSongResonanceActive,xinJianTongLing 阶玩家暴击附带剑鸣浮字。
    var hasJointSkillUnlocked = false;
    var swordSongActive = false;
    for (final e in equipped) {
      if (e.slot != EquipmentSlot.weapon) continue;
      final stage = e.resonanceStage(numbers);
      final cfg = numbers.resonanceStages
          .firstWhere((c) => c.stage == stage, orElse: () => _shengShuFallback);
      if (cfg.unlocksJointSkill) hasJointSkillUnlocked = true;
      if (cfg.hasSwordSongEffect) swordSongActive = true;
    }
    if (hasJointSkillUnlocked) {
      final repo = GameRepository.instance;
      if (repo.skillDefs.containsKey('skill_joint_skill')) {
        skills.add(repo.getSkill('skill_joint_skill'));
      }
    }

    return BattleCharacter(
      characterId: character.id,
      name: character.name,
      realmTier: character.realmTier,
      realmLayer: character.realmLayer,
      school: school,
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxIf,
      currentInternalForce: character.internalForce,
      speed: speed,
      criticalRate: critRate,
      evasionRate: evRate,
      defenseRate: defRate,
      totalEquipmentAttack: totalEqAtk,
      mainCultivationLayer: mainTechnique.cultivationLayer,
      availableSkills: List.unmodifiable(skills),
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
      swordSongResonanceActive: swordSongActive,
      iconPath: character.portraitPath,
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
    List<String>? activeBuffs,
    int? actionPoint,
    bool? isAlive,
    int? teamSide,
    int? slotIndex,
    Object? internalInjury = _unset,
    bool? swordSongResonanceActive,
    String? iconPath,
    double? attackPowerMultiplier,
    bool? isBoss,
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
      totalEquipmentAttack:
          totalEquipmentAttack ?? this.totalEquipmentAttack,
      mainCultivationLayer:
          mainCultivationLayer ?? this.mainCultivationLayer,
      availableSkills: availableSkills ?? this.availableSkills,
      skillCooldowns: skillCooldowns ?? this.skillCooldowns,
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
      isBoss: isBoss ?? this.isBoss,
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

  BattleState({
    required this.leftTeam,
    required this.rightTeam,
    required this.tick,
    required this.result,
    required this.actionLog,
    this.pendingUltimates = const {},
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
    );
  }

  bool get isFinished => result != null;

  BattleState copyWith({
    List<BattleCharacter>? leftTeam,
    List<BattleCharacter>? rightTeam,
    int? tick,
    Object? result = _unset,
    List<BattleAction>? actionLog,
    Map<int, SkillDef>? pendingUltimates,
  }) {
    return BattleState(
      leftTeam: leftTeam ?? this.leftTeam,
      rightTeam: rightTeam ?? this.rightTeam,
      tick: tick ?? this.tick,
      result: identical(result, _unset) ? this.result : result as BattleResult?,
      actionLog: actionLog ?? this.actionLog,
      pendingUltimates: pendingUltimates ?? this.pendingUltimates,
    );
  }

  @override
  String toString() =>
      'BattleState(tick=$tick, left=${leftTeam.length}, '
      'right=${rightTeam.length}, result=${result?.name ?? "ongoing"}, '
      'actions=${actionLog.length})';
}

const Object _unset = Object();
