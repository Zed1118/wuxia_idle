import '../domain/battle_state.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/technique_def.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../cultivation/application/cultivation_service.dart';
import '../../dispel/application/dispel_service.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../../features/equipment/application/drop_service.dart';

/// 战斗结算服务的汇总返回（phase2_tasks T26 §324-356）。
///
/// **副作用已 in-place 写到** [Equipment.battleCount] / [Technique.skillUsageCount]
/// / [Technique.cultivationProgress] 等字段；这里只汇总"发生了什么"供 UI 展示
/// 和 caller 决定如何持久化（写 Isar / 发 GameEvent）。
class BattleResolutionResult {
  /// `battleCount` 被 +1 的装备 id 列表，含三件参战装备。caller 据此 Isar
  /// `putAll` 写回。
  final List<int> updatedEquipmentIds;

  /// `techniqueId → {skillId → 本次累加的次数}`。覆盖主修 + 辅修两种心法；
  /// caller 据此 Isar `putAll` 写回所有出现在此 map 中的 Technique。
  final Map<int, Map<String, int>> skillUsageIncrements;

  /// `characterId → 主修升层合并结果`。
  ///
  /// 一场战斗主修可能跨多次 [CultivationService.recordSkillUsage] 调用（多个
  /// skill），这里合并为单一事件：`oldLayer` 是开战时的层，`newLayer` 是结算
  /// 后的层，`layersGained` 是跨越层数累加。`didLevelUp = layersGained > 0`。
  final Map<int, CultivationProgressResult> cultivationEvents;

  /// 关卡掉落（T27 DropService 结果）。装备 `ownerCharacterId == null` 入背包。
  /// 战败路径恒为 `DropResult(equipments: [], items: [])`。
  final DropResult dropResult;

  /// Phase 4 W10：Boss 关战败时每个有主修的参战角色的被动散功结果。
  /// 胜利 / 普通关战败时**恒为空 map**。
  /// 见 [DispelService.applyDefeatPenalty]。
  final Map<int, DefeatPenaltyResult> defeatPenaltyByCharacter;

  /// M6:心魔关战败时每个有主修参战角色的惩罚结果。胜利/非心魔关恒空 map。
  final Map<int, InnerDemonPenaltyResult> innerDemonPenaltyByCharacter;

  /// P1 #42 Phase 2:本场战斗内 `resonanceStage` 跨档晋升的装备 id 列表。
  /// caller 用于 GameEvent #7 resonanceUpgraded 写入。仅 `resolve` 传入
  /// `numbersConfig` 时填充,否则恒空。
  final List<int> resonanceUpgradedEquipmentIds;

  const BattleResolutionResult({
    required this.updatedEquipmentIds,
    required this.skillUsageIncrements,
    required this.cultivationEvents,
    required this.dropResult,
    this.defeatPenaltyByCharacter = const {},
    this.innerDemonPenaltyByCharacter = const {},
    this.resonanceUpgradedEquipmentIds = const [],
  });

  @override
  String toString() =>
      'BattleResolutionResult(eq=${updatedEquipmentIds.length}, '
      'tech=${skillUsageIncrements.length}, '
      'levelUp=${cultivationEvents.values.where((e) => e.didLevelUp).length}, '
      'drops=$dropResult, '
      'defeatPenalty=${defeatPenaltyByCharacter.length})';
}

/// 战斗结算 hooks（phase2_tasks T26 §324-356）。
///
/// 设计原则（与同期 service 一致）：
///   - **in-place 修改 [Equipment] / [Technique]**：与 EnhancementService /
///     CultivationService / DispelService 风格一致（Isar @collection 本就 mutable）
///   - **不写 Isar**：副作用归 caller（typically Isar `writeTxn` 包一层）
///   - **最小依赖**：不接整个 GameRepository，需要的 def 通过注入函数查询
///   - **升层联动 [CultivationService.recordSkillUsage]**：不重新实现升层逻辑
///   - **战败也结算**（spec §338，GDD §6.4 没说必须胜利才涨）
class BattleResolutionService {
  BattleResolutionService._();

  /// 执行结算。
  ///
  /// [participatingCharacters] 必须**只包含**出现在 [finalState] 双方某队的
  /// 角色（spec §333 "未参战角色不算"）。fail-fast 拒绝多余角色。
  ///
  /// [equipmentsByCharacter] / [techniquesByCharacter] 由 caller 从 Isar 查好
  /// 传入；service in-place 修改但不写回。允许 caller 只传部分（某角色心法槽
  /// 没满 3 件、装备槽缺武器等都 OK）。
  ///
  /// [techniqueDefLookup] 用于判定 `actionLog` 里某 skillId 归属哪本心法
  /// （遍历该角色 techniques，命中 `TechniqueDef.skillIds.contains(skillId)`
  /// 的第一本即归属）。
  ///
  /// [progressToNextMap] 透传给 [CultivationService]，避免双方都接整个
  /// NumbersConfig。
  static BattleResolutionResult resolve({
    required BattleState finalState,
    required List<Character> participatingCharacters,
    required Map<int, List<Equipment>> equipmentsByCharacter,
    required Map<int, List<Technique>> techniquesByCharacter,
    required Rng rng,
    required Map<CultivationLayer, int> progressToNextMap,
    required TechniqueDef Function(String defId) techniqueDefLookup,
    required DropService dropService,
    StageDef? stageDef,
    bool isVictory = true,
    NumbersConfig? numbersConfig,
  }) {
    _assertAllParticipated(finalState, participatingCharacters);

    // 1. 反推 actionLog：actor → {skillId: 使用次数}
    final skillCountsByActor = <int, Map<String, int>>{};
    for (final action in finalState.actionLog) {
      final skillId = action.skill?.id;
      if (skillId == null) continue; // 普通行动（无 skill）不计入修炼度
      skillCountsByActor
          .putIfAbsent(action.actorId, () => <String, int>{})
          .update(skillId, (v) => v + 1, ifAbsent: () => 1);
    }

    final updatedEquipmentIds = <int>[];
    final skillUsageIncrements = <int, Map<String, int>>{};
    final cultivationEvents = <int, CultivationProgressResult>{};
    // P1 #42 Phase 2:#7 resonanceUpgraded — battleCount++ 前后 stage 跨档则记录。
    // numbersConfig 非 null 时才 detect(victory 路径 caller 传,defeat 路径不关心)。
    final resonanceUpgradedEquipmentIds = <int>[];

    // 2. 对每个参战角色：装备 battleCount++ + 心法 skillUsageCount + 主修升层
    final resonanceNumbers = numbersConfig;
    for (final ch in participatingCharacters) {
      // 2a. 装备 battleCount++
      final equips = equipmentsByCharacter[ch.id] ?? const <Equipment>[];
      for (final eq in equips) {
        final stageBefore = resonanceNumbers != null
            ? eq.resonanceStage(resonanceNumbers)
            : null;
        eq.battleCount += 1;
        if (resonanceNumbers != null && stageBefore != null) {
          final stageAfter = eq.resonanceStage(resonanceNumbers);
          if (stageAfter != stageBefore) {
            resonanceUpgradedEquipmentIds.add(eq.id);
          }
        }
        updatedEquipmentIds.add(eq.id);
      }

      // 2b/2c. 心法累积（主修走 CultivationService，辅修仅 increment）
      final techs = techniquesByCharacter[ch.id] ?? const <Technique>[];
      final usedSkills =
          skillCountsByActor[ch.id] ?? const <String, int>{};
      _accumulateSkillUsage(
        character: ch,
        techniques: techs,
        usedSkills: usedSkills,
        progressToNextMap: progressToNextMap,
        techniqueDefLookup: techniqueDefLookup,
        skillUsageIncrements: skillUsageIncrements,
        cultivationEvents: cultivationEvents,
      );
    }

    // 3. 掉落（战败不掉；victory + stageDef==null 时 caller 自处理 drops 不在此 roll）
    final dropResult = (isVictory && stageDef != null)
        ? dropService.rollDrops(stageDef, rng)
        : const DropResult(equipments: [], items: []);

    // 4. Phase 4 W10：Boss 关战败 → 对每个有主修的参战角色应用被动散功
    // tower 路径 stageDef=null 时 defeat 永远不进此分支（Boss 战败散功仅主线触发）。
    // 心魔关(stageType==innerDemon)虽 isBossStage=true，但走下方独立心魔惩罚分支，
    // 此处必须排除，否则两分支同时命中 → 内力双扣 + 修炼度双回退（双重惩罚 bug）。
    final defeatPenalty = <int, DefeatPenaltyResult>{};
    if (!isVictory &&
        stageDef != null &&
        stageDef.isBossStage &&
        stageDef.stageType != StageType.innerDemon) {
      if (numbersConfig == null) {
        throw ArgumentError(
          'BattleResolutionService.resolve: Boss 关战败必须传 numbersConfig '
          '（用于 DispelService.applyDefeatPenalty 的 defeatBoss* 系数）',
        );
      }
      for (final ch in participatingCharacters) {
        final mainTechId = ch.mainTechniqueId;
        if (mainTechId == null) continue;
        final techs = techniquesByCharacter[ch.id] ?? const <Technique>[];
        final mainTech = _findById(techs, mainTechId);
        if (mainTech == null) continue;
        defeatPenalty[ch.id] = DispelService.applyDefeatPenalty(
          ch: ch,
          mainTech: mainTech,
          n: numbersConfig,
        );
      }
    }

    // M6:心魔关战败 → 对每个有主修参战角色应用心魔失败惩罚 + 余毒。
    // 与 Boss 散功互斥:心魔关 isBossStage=true,故由上方 Boss 分支显式排除
    // stageType==innerDemon 来保证互斥(本分支独占)。stageDef=null(tower) 不进。
    final innerDemonPenalty = <int, InnerDemonPenaltyResult>{};
    if (!isVictory &&
        stageDef != null &&
        stageDef.stageType == StageType.innerDemon &&
        numbersConfig != null) {
      final idDef = numbersConfig.innerDemon;
      for (final ch in participatingCharacters) {
        final mainTechId = ch.mainTechniqueId;
        if (mainTechId == null) continue;
        final techs = techniquesByCharacter[ch.id] ?? const <Technique>[];
        final mainTech = _findById(techs, mainTechId);
        if (mainTech == null) continue;
        innerDemonPenalty[ch.id] = InnerDemonService.applyFailurePenalty(
          ch: ch,
          mainTech: mainTech,
          penalty: idDef.failurePenalty,
          residueHours: idDef.failurePenalty.debuffClearViaRetreatHours.toDouble(),
        );
      }
    }

    return BattleResolutionResult(
      updatedEquipmentIds: updatedEquipmentIds,
      skillUsageIncrements: skillUsageIncrements,
      cultivationEvents: cultivationEvents,
      dropResult: dropResult,
      defeatPenaltyByCharacter: defeatPenalty,
      innerDemonPenaltyByCharacter: innerDemonPenalty,
      resonanceUpgradedEquipmentIds: resonanceUpgradedEquipmentIds,
    );
  }

  /// 防御性 assert：所有 participating character 必须在 finalState 中出现。
  /// 反向（finalState 中的角色未在 participating 里）不强制，因为 caller 可能
  /// 只关心 player 队，敌方不结算。
  static void _assertAllParticipated(
    BattleState finalState,
    List<Character> participatingCharacters,
  ) {
    final liveIds = <int>{
      ...finalState.leftTeam.map((c) => c.characterId),
      ...finalState.rightTeam.map((c) => c.characterId),
    };
    for (final c in participatingCharacters) {
      if (!liveIds.contains(c.id)) {
        throw StateError(
          'BattleResolutionService: participatingCharacters 含未出现在 '
          'finalState 双方阵容的角色 id=${c.id} name=${c.name}',
        );
      }
    }
  }

  /// 对单个角色的 [usedSkills] 累积到心法。主修走 [CultivationService.recordSkillUsage]
  /// (skillUsageCount + cultivationProgress + 升层一次完成)，辅修仅 increment。
  ///
  /// 合并主修多次调用为单个 [CultivationProgressResult]：oldLayer 取开战时的层，
  /// newLayer 取最后一次调用后的层，layersGained 累加。
  static void _accumulateSkillUsage({
    required Character character,
    required List<Technique> techniques,
    required Map<String, int> usedSkills,
    required Map<CultivationLayer, int> progressToNextMap,
    required TechniqueDef Function(String defId) techniqueDefLookup,
    required Map<int, Map<String, int>> skillUsageIncrements,
    required Map<int, CultivationProgressResult> cultivationEvents,
  }) {
    if (usedSkills.isEmpty) return;

    final mainTechId = character.mainTechniqueId;
    final mainTech = mainTechId == null
        ? null
        : _findById(techniques, mainTechId);

    CultivationLayer? mainStartLayer;
    var mainLayersGained = 0;
    CultivationProgressResult? lastMainResult;

    for (final entry in usedSkills.entries) {
      final skillId = entry.key;
      final count = entry.value;

      // 找 skill 属于哪本心法（遍历 character 的所有 technique，主修优先）
      final owner = _findOwnerTechnique(
        techniques: techniques,
        skillId: skillId,
        mainTechId: mainTechId,
        techniqueDefLookup: techniqueDefLookup,
      );
      // 波B:standalone 招(破招技/奇遇招/真解残页,不属任何心法 def)计入主修
      // 账本(skillUsageCount 仅 increment,不推进修炼度——修炼度语义仍只归
      // 本心法招式)。BattleCharacter.fromCharacter 的 skillUses 快照读的就是
      // 主修 skillUsageCount,此处不落账则 standalone 招熟练度永远初识(波A 残留)。
      if (owner == null) {
        if (mainTech == null) continue;
        mainTech.skillUsageCount.increment(skillId, count);
        skillUsageIncrements
            .putIfAbsent(mainTech.id, () => <String, int>{})
            .update(skillId, (v) => v + count, ifAbsent: () => count);
        continue;
      }

      if (mainTech != null && owner.id == mainTech.id) {
        // 主修：调 CultivationService，一次性 skillUsage++ + progress++ + 升层
        mainStartLayer ??= mainTech.cultivationLayer;
        final r = CultivationService.recordSkillUsage(
          tech: mainTech,
          skillId: skillId,
          progressToNextMap: progressToNextMap,
          delta: count,
        );
        mainLayersGained += r.layersGained;
        lastMainResult = r;
      } else {
        // 辅修：仅 skillUsageCount.increment，不升层
        owner.skillUsageCount.increment(skillId, count);
      }

      skillUsageIncrements
          .putIfAbsent(owner.id, () => <String, int>{})
          .update(skillId, (v) => v + count, ifAbsent: () => count);
    }

    if (mainTech != null && lastMainResult != null) {
      cultivationEvents[character.id] = CultivationProgressResult(
        didLevelUp: mainLayersGained > 0,
        oldLayer: mainStartLayer!,
        newLayer: lastMainResult.newLayer,
        layersGained: mainLayersGained,
        currentProgress: lastMainResult.currentProgress,
        currentProgressToNext: lastMainResult.currentProgressToNext,
      );
    }
  }

  static Technique? _findById(List<Technique> techniques, int id) {
    for (final t in techniques) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// 找 skillId 归属的心法：主修优先（若主修 def 含此 skill），否则遍历辅修。
  /// 找到第一本即返回。
  static Technique? _findOwnerTechnique({
    required List<Technique> techniques,
    required String skillId,
    required int? mainTechId,
    required TechniqueDef Function(String) techniqueDefLookup,
  }) {
    // 主修优先
    if (mainTechId != null) {
      final main = _findById(techniques, mainTechId);
      if (main != null) {
        final mainDef = techniqueDefLookup(main.defId);
        if (mainDef.skillIds.contains(skillId)) return main;
      }
    }
    // 辅修
    for (final t in techniques) {
      if (t.id == mainTechId) continue;
      final def = techniqueDefLookup(t.defId);
      if (def.skillIds.contains(skillId)) return t;
    }
    return null;
  }
}
