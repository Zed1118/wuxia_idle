import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/battle_resolution.dart';
import 'package:wuxia_idle/services/drop_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T26 BattleResolutionService 验收（phase2_tasks T26 §324-356）。
void main() {
  late Map<CultivationLayer, int> progressMap;
  late NumbersConfig numbersCfg;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    progressMap = repo.numbers.cultivationProgressToNext;
    numbersCfg = repo.numbers;
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Fixture builders
  // ──────────────────────────────────────────────────────────────────────────

  final t = DateTime(2026, 5, 11);

  Character buildCharacter({
    required int id,
    required int? mainTechId,
    String name = '测试角色',
  }) {
    final attrs = Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5;
    return Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: attrs,
      rarity: RarityTier.xunChang,
      lineageRole: LineageRole.disciple,
      createdAt: t,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechId,
    )..id = id;
  }

  Equipment buildEquipment({
    required int id,
    required EquipmentSlot slot,
    int battleCount = 0,
  }) =>
      Equipment.create(
        defId: 'eq_test',
        tier: EquipmentTier.xunChang,
        slot: slot,
        obtainedAt: t,
        obtainedFrom: '测试',
        battleCount: battleCount,
      )..id = id;

  Technique buildTechnique({
    required int id,
    required int ownerCharId,
    required String defId,
    TechniqueRole role = TechniqueRole.main,
    CultivationLayer layer = CultivationLayer.chuKui,
    int progress = 0,
    int progressToNext = 100,
  }) =>
      Technique.create(
        defId: defId,
        ownerCharacterId: ownerCharId,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        role: role,
        learnedAt: t,
        cultivationLayer: layer,
        cultivationProgress: progress,
        cultivationProgressToNext: progressToNext,
      )..id = id;

  /// 极简 SkillDef 占位（only id 被读到）
  SkillDef buildSkill(String id) => SkillDef(
        id: id,
        name: id,
        description: 'd',
        type: SkillType.normalAttack,
        powerMultiplier: 500,
        internalForceCost: 0,
        cooldownTurns: 0,
        requiresManualTrigger: false,
        visualEffect: 'a',
      );

  /// 极简 BattleCharacter（只用到 characterId 验证 participation）
  BattleCharacter buildBattleChar(int charId, int slot) => BattleCharacter(
        characterId: charId,
        name: 'c$charId',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 1000,
        currentHp: 1000,
        maxInternalForce: 500,
        currentInternalForce: 500,
        speed: 100,
        criticalRate: 0.1,
        evasionRate: 0.1,
        totalEquipmentAttack: 100,
        mainCultivationLayer: CultivationLayer.chuKui,
        availableSkills: const [],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: slot,
      );

  BattleAction buildAction({
    required int actorId,
    SkillDef? skill,
    int tick = 1,
  }) =>
      BattleAction(
        tick: tick,
        actorId: actorId,
        skill: skill,
        description: 'a',
      );

  TechniqueDef buildTechDef({
    required String id,
    required List<String> skillIds,
  }) =>
      TechniqueDef(
        id: id,
        name: id,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        description: 'd',
        skillIds: skillIds,
        internalForceGrowthBonus: 1.0,
        speedBonus: 0,
        acquireSourceTags: const [],
      );

  StageDef buildStage({
    List<DropEntry> dropTable = const [],
    bool isBossStage = false,
  }) =>
      StageDef(
        id: 'stage_test',
        name: '测试关',
        stageType: StageType.mainline,
        chapterIndex: 1,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: isBossStage,
        dropEquipmentDefIds: const [],
        dropItemDefIds: const [],
        dropTable: dropTable,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );

  /// DropService 默认 mock：空 dropTable 时不会被调到底；有则用 fake def
  DropService dropSvc({EquipmentDef? eqDef}) => DropService(
        equipmentDefLookup: (id) =>
            eqDef ??
            (throw StateError('test eqDef not provided for $id')),
        now: () => t,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // 1. 装备 battleCount++：参战三件 +1
  // ──────────────────────────────────────────────────────────────────────────

  test('装备 battleCount++：武器/护甲/饰品三件 +1', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon, battleCount: 5);
    final a = buildEquipment(id: 101, slot: EquipmentSlot.armor, battleCount: 0);
    final ac = buildEquipment(id: 102, slot: EquipmentSlot.accessory, battleCount: 99);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 10,
      result: BattleResult.leftWin,
      actionLog: const [],
    );

    final result = BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: {1: [w, a, ac]},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
      dropService: dropSvc(),
    );

    expect(w.battleCount, 6);
    expect(a.battleCount, 1);
    expect(ac.battleCount, 100);
    expect(result.updatedEquipmentIds, [100, 101, 102]);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. 战败也结算（spec §338）
  // ──────────────────────────────────────────────────────────────────────────

  test('战败 (rightWin) 也涨：装备 +1 + 心法 progress 累加', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final skill = buildSkill('skill_main_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.rightWin, // 战败
      actionLog: [
        buildAction(actorId: 1, skill: skill),
        buildAction(actorId: 1, skill: skill),
      ],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: {1: [w]},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) =>
          buildTechDef(id: id, skillIds: const ['skill_main_a']),
      dropService: dropSvc(),
    );

    expect(w.battleCount, 1);
    expect(mainTech.cultivationProgress, 2);
    expect(mainTech.skillUsageCount.countOf('skill_main_a'), 2);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. 主修升层：跨 chuKui → xiaoCheng
  // ──────────────────────────────────────────────────────────────────────────

  test('主修跨层：progress 99 + 2 → xiaoCheng layersGained=1', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(
      id: 200,
      ownerCharId: 1,
      defId: 'tech_main',
      progress: 99,
      progressToNext: 100,
    );
    final skill = buildSkill('skill_main_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1, skill: skill),
        buildAction(actorId: 1, skill: skill),
      ],
    );

    final result = BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) =>
          buildTechDef(id: id, skillIds: const ['skill_main_a']),
      dropService: dropSvc(),
    );

    expect(mainTech.cultivationLayer, CultivationLayer.xiaoCheng);
    expect(mainTech.cultivationProgress, 1); // 99+2 - 100 = 1
    expect(mainTech.cultivationProgressToNext, 250);
    final ev = result.cultivationEvents[1]!;
    expect(ev.didLevelUp, isTrue);
    expect(ev.oldLayer, CultivationLayer.chuKui);
    expect(ev.newLayer, CultivationLayer.xiaoCheng);
    expect(ev.layersGained, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. 辅修累加但不升层
  // ──────────────────────────────────────────────────────────────────────────

  test('辅修：skillUsageCount.increment 但 cultivationProgress 不动', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final assistTech = buildTechnique(
      id: 201,
      ownerCharId: 1,
      defId: 'tech_assist',
      role: TechniqueRole.assist,
      progress: 50,
    );
    final assistSkill = buildSkill('skill_assist_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1, skill: assistSkill),
        buildAction(actorId: 1, skill: assistSkill),
        buildAction(actorId: 1, skill: assistSkill),
      ],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech, assistTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) {
        if (id == 'tech_main') {
          return buildTechDef(id: id, skillIds: const ['skill_main_a']);
        }
        return buildTechDef(id: id, skillIds: const ['skill_assist_a']);
      },
      dropService: dropSvc(),
    );

    expect(assistTech.skillUsageCount.countOf('skill_assist_a'), 3);
    expect(assistTech.cultivationProgress, 50, reason: '辅修不升层 progress 不动');
    expect(mainTech.skillUsageCount.countOf('skill_assist_a'), 0);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. actionLog skill==null 不计入（普通行动）
  // ──────────────────────────────────────────────────────────────────────────

  test('action.skill == null 不计入修炼度', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final skill = buildSkill('skill_main_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1), // skill=null
        buildAction(actorId: 1, skill: skill),
        buildAction(actorId: 1), // skill=null
      ],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) =>
          buildTechDef(id: id, skillIds: const ['skill_main_a']),
      dropService: dropSvc(),
    );

    expect(mainTech.skillUsageCount.countOf('skill_main_a'), 1);
    expect(mainTech.cultivationProgress, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 6. 多角色独立累积
  // ──────────────────────────────────────────────────────────────────────────

  test('多角色独立累积：char1 vs char2 skillUsage / battleCount 不串', () {
    final ch1 = buildCharacter(id: 1, mainTechId: 200, name: 'c1');
    final ch2 = buildCharacter(id: 2, mainTechId: 300, name: 'c2');
    final w1 = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
    final w2 = buildEquipment(id: 200, slot: EquipmentSlot.weapon);
    final tech1 = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final tech2 = buildTechnique(id: 300, ownerCharId: 2, defId: 'tech_main');
    final skill = buildSkill('skill_main_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0), buildBattleChar(2, 1)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1, skill: skill),
        buildAction(actorId: 1, skill: skill),
        buildAction(actorId: 2, skill: skill),
      ],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch1, ch2],
      equipmentsByCharacter: {1: [w1], 2: [w2]},
      techniquesByCharacter: {1: [tech1], 2: [tech2]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) =>
          buildTechDef(id: id, skillIds: const ['skill_main_a']),
      dropService: dropSvc(),
    );

    expect(w1.battleCount, 1);
    expect(w2.battleCount, 1);
    expect(tech1.cultivationProgress, 2);
    expect(tech2.cultivationProgress, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 7. 未参战角色不动：未传入 participating 即不算
  // ──────────────────────────────────────────────────────────────────────────

  test('未参战角色：未传入 participatingCharacters 时装备/心法不动', () {
    final ch1 = buildCharacter(id: 1, mainTechId: 200);
    final benchEq = buildEquipment(id: 999, slot: EquipmentSlot.weapon, battleCount: 7);
    final w1 = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
    final tech1 = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: const [],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch1],
      equipmentsByCharacter: {1: [w1]},
      techniquesByCharacter: {1: [tech1]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
      dropService: dropSvc(),
    );

    expect(benchEq.battleCount, 7, reason: '板凳角色装备不该动');
    expect(w1.battleCount, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 8. 防御 assert：participating 含未出场角色 → StateError
  // ──────────────────────────────────────────────────────────────────────────

  test('防御 assert：participating 含未在 finalState 出场的角色 → StateError', () {
    final ghost = buildCharacter(id: 999, mainTechId: 200, name: '幽灵');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)], // 不含 id=999
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: const [],
    );

    expect(
      () => BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ghost],
        equipmentsByCharacter: const {},
        techniquesByCharacter: const {},
        stageDef: buildStage(),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
      ),
      throwsStateError,
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 9. DropService 联动：必掉装备 + 必掉物品入 DropResult
  // ──────────────────────────────────────────────────────────────────────────

  test('DropService 联动：dropTable 必掉 → DropResult 含装备 + 物品', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: const [],
    );

    final eqDef = const EquipmentDef(
      id: 'eq_drop_test',
      name: '掉落装备',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 50,
      baseAttackMax: 60,
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 5,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: '',
    );

    final result = BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(dropTable: const [
        EquipmentDrop(equipmentDefId: 'eq_drop_test', dropChance: 1.0),
        ItemDrop(
          inventoryItemDefId: 'item_x',
          quantityMin: 2,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ]),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
      dropService: dropSvc(eqDef: eqDef),
    );

    expect(result.dropResult.equipments.length, 1);
    expect(result.dropResult.equipments.first.defId, 'eq_drop_test');
    expect(result.dropResult.equipments.first.ownerCharacterId, isNull);
    expect(result.dropResult.items.length, 1);
    expect(result.dropResult.items.first.defId, 'item_x');
    expect(result.dropResult.items.first.quantity, 2);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 10. 主修多 skill 合并升层结果
  // ──────────────────────────────────────────────────────────────────────────

  test('主修多 skill 合并：oldLayer = 战前层，newLayer = 战后层', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(
      id: 200,
      ownerCharId: 1,
      defId: 'tech_main',
      progress: 99,
      progressToNext: 100,
    );
    final skillA = buildSkill('skill_main_a');
    final skillB = buildSkill('skill_main_b');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        // skill_main_a 1 次 → chuKui 升 xiaoCheng (progress 99+1=100 触发升层, 余 0)
        buildAction(actorId: 1, skill: skillA),
        // skill_main_b 250 次 → xiaoCheng 升 zhongCheng
        for (int i = 0; i < 250; i++)
          buildAction(actorId: 1, skill: skillB, tick: 10 + i),
      ],
    );

    final result = BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) => buildTechDef(
        id: id,
        skillIds: const ['skill_main_a', 'skill_main_b'],
      ),
      dropService: dropSvc(),
    );

    final ev = result.cultivationEvents[1]!;
    expect(ev.oldLayer, CultivationLayer.chuKui, reason: '战前快照');
    expect(ev.newLayer, CultivationLayer.zhongCheng, reason: '战后跨 2 层');
    expect(ev.layersGained, 2);
    expect(mainTech.cultivationLayer, CultivationLayer.zhongCheng);
    expect(mainTech.skillUsageCount.countOf('skill_main_a'), 1);
    expect(mainTech.skillUsageCount.countOf('skill_main_b'), 250);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 11. skillId 不属于该角色任何心法 → 忽略
  // ──────────────────────────────────────────────────────────────────────────

  test('skill 不属于该角色任何心法 → 忽略，不抛错也不计入', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final strangeSkill = buildSkill('skill_unknown');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1, skill: strangeSkill),
      ],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) =>
          buildTechDef(id: id, skillIds: const ['skill_main_a']),
      dropService: dropSvc(),
    );

    expect(mainTech.cultivationProgress, 0);
    expect(mainTech.skillUsageCount, isEmpty);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 12. 平局也结算
  // ──────────────────────────────────────────────────────────────────────────

  test('平局 (draw) 也结算', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.draw,
      actionLog: const [],
    );

    BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: {1: [w]},
      techniquesByCharacter: {1: [mainTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
      dropService: dropSvc(),
    );

    expect(w.battleCount, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 13. skillUsageIncrements 汇总正确
  // ──────────────────────────────────────────────────────────────────────────

  test('skillUsageIncrements 汇总：主修 + 辅修分别 by techniqueId', () {
    final ch = buildCharacter(id: 1, mainTechId: 200);
    final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
    final assistTech = buildTechnique(
      id: 201,
      ownerCharId: 1,
      defId: 'tech_assist',
      role: TechniqueRole.assist,
    );
    final mainSkill = buildSkill('skill_main_a');
    final assistSkill = buildSkill('skill_assist_a');

    final state = BattleState(
      leftTeam: [buildBattleChar(1, 0)],
      rightTeam: const [],
      tick: 5,
      result: BattleResult.leftWin,
      actionLog: [
        buildAction(actorId: 1, skill: mainSkill),
        buildAction(actorId: 1, skill: mainSkill),
        buildAction(actorId: 1, skill: assistSkill),
      ],
    );

    final result = BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: [ch],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {1: [mainTech, assistTech]},
      stageDef: buildStage(),
      rng: DefaultRng(seed: 1),
      progressToNextMap: progressMap,
      techniqueDefLookup: (id) {
        if (id == 'tech_main') {
          return buildTechDef(id: id, skillIds: const ['skill_main_a']);
        }
        return buildTechDef(id: id, skillIds: const ['skill_assist_a']);
      },
      dropService: dropSvc(),
    );

    expect(result.skillUsageIncrements[200], {'skill_main_a': 2});
    expect(result.skillUsageIncrements[201], {'skill_assist_a': 1});
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Phase 4 W10：战败结算扩展（Boss 关被动散功）
  // ──────────────────────────────────────────────────────────────────────────

  group('Phase 4 W10 · Boss 战败被动散功 hook', () {
    test('Boss 战败：主修触发 applyDefeatPenalty + 内力 ×0.5 + progress ×0.5', () {
      final ch = buildCharacter(id: 1, mainTechId: 200);
      ch.internalForce = 8000;
      final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
      final mainTech = buildTechnique(
        id: 200,
        ownerCharId: 1,
        defId: 'tech_main',
        layer: CultivationLayer.yuanMan,
        progress: 1500,
        progressToNext: 1500,
      );
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.rightWin,
        actionLog: const [],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: {1: [w]},
        techniquesByCharacter: {1: [mainTech]},
        stageDef: buildStage(isBossStage: true),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      expect(result.defeatPenaltyByCharacter.length, 1);
      final p = result.defeatPenaltyByCharacter[1]!;
      expect(p.internalForceBefore, 8000);
      expect(p.internalForceAfter, 4000);
      expect(p.oldLayer, CultivationLayer.yuanMan);
      expect(p.newLayer, CultivationLayer.daCheng);
      expect(p.layersRolledBack, 1);
      expect(ch.internalForce, 4000);
      expect(mainTech.cultivationProgress, 750);
      expect(mainTech.cultivationLayer, CultivationLayer.daCheng);
      // role 不动，下次战斗仍按主修走
      expect(mainTech.role, TechniqueRole.main);
      // 战败也算 battleCount（spec §338 沿用）
      expect(w.battleCount, 1);
      // 不掉装备 / 物品
      expect(result.dropResult.isEmpty, isTrue);
    });

    test('普通关战败：不触发散功，dropResult 空，battleCount 仍 ++', () {
      final ch = buildCharacter(id: 1, mainTechId: 200);
      ch.internalForce = 5000;
      final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
      final mainTech = buildTechnique(
        id: 200,
        ownerCharId: 1,
        defId: 'tech_main',
        layer: CultivationLayer.daCheng,
        progress: 800,
        progressToNext: 900,
      );
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.rightWin,
        actionLog: const [],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: {1: [w]},
        techniquesByCharacter: {1: [mainTech]},
        stageDef: buildStage(isBossStage: false), // 普通关
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      expect(result.defeatPenaltyByCharacter, isEmpty);
      expect(ch.internalForce, 5000); // 不动
      expect(mainTech.cultivationProgress, 800);
      expect(mainTech.cultivationLayer, CultivationLayer.daCheng);
      expect(w.battleCount, 1); // 普通战败也累 battleCount
      expect(result.dropResult.isEmpty, isTrue);
    });

    test('胜利路径：defeatPenaltyByCharacter 恒空（不论 isBossStage）', () {
      final ch = buildCharacter(id: 1, mainTechId: 200);
      ch.internalForce = 5000;
      final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.leftWin,
        actionLog: const [],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: const {},
        techniquesByCharacter: {1: [mainTech]},
        stageDef: buildStage(isBossStage: true),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
        // isVictory 默认 true，无 numbersConfig 也合法
      );

      expect(result.defeatPenaltyByCharacter, isEmpty);
      expect(ch.internalForce, 5000);
    });

    test('Boss 战败 + numbersConfig=null → ArgumentError', () {
      final ch = buildCharacter(id: 1, mainTechId: 200);
      final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.rightWin,
        actionLog: const [],
      );

      expect(
        () => BattleResolutionService.resolve(
          finalState: state,
          participatingCharacters: [ch],
          equipmentsByCharacter: const {},
          techniquesByCharacter: {1: [mainTech]},
          stageDef: buildStage(isBossStage: true),
          rng: DefaultRng(seed: 1),
          progressToNextMap: progressMap,
          techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
          dropService: dropSvc(),
          isVictory: false,
          // 故意不传 numbersConfig
        ),
        throwsArgumentError,
      );
    });

    test('Phase 4 W11 #32: stageDef=null + victory → dropResult 空 + battleCount/skillUsage 仍累', () {
      // 爬塔 victory 路径体例：service 不内部 roll drops（stageDef=null），caller
      // 自己处理（rollTowerRewards 外层）。但 battleCount/skillUsage 副作用必须照走。
      final ch = buildCharacter(id: 1, mainTechId: 200);
      ch.internalForce = 5000;
      final w = buildEquipment(id: 100, slot: EquipmentSlot.weapon);
      final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
      final skill = buildSkill('skill_main_a');
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.leftWin,
        actionLog: [
          buildAction(actorId: 1, skill: skill),
          buildAction(actorId: 1, skill: skill),
        ],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: {1: [w]},
        techniquesByCharacter: {1: [mainTech]},
        // stageDef 故意不传（null）
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) =>
            buildTechDef(id: id, skillIds: const ['skill_main_a']),
        dropService: dropSvc(),
        isVictory: true,
      );

      expect(result.dropResult.isEmpty, isTrue,
          reason: 'stageDef=null 时 service 不内部 roll drops');
      expect(w.battleCount, 1, reason: '装备 battleCount 仍累');
      expect(mainTech.cultivationProgress, 2,
          reason: '心法 progress 仍累（每次 +1）');
      expect(result.defeatPenaltyByCharacter, isEmpty);
    });

    test('Phase 4 W11 #32: stageDef=null + defeat → 不触发 Boss 散功（无 isBossStage 信号）', () {
      // tower defeat 路径不走 stage Boss 战败散功（用户决策 ① 只 stage Boss 触发）
      final ch = buildCharacter(id: 1, mainTechId: 200);
      ch.internalForce = 5000;
      final mainTech = buildTechnique(id: 200, ownerCharId: 1, defId: 'tech_main');
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.rightWin,
        actionLog: const [],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: const {},
        techniquesByCharacter: {1: [mainTech]},
        // stageDef=null + isVictory=false：不进 Boss 散功分支
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      expect(result.defeatPenaltyByCharacter, isEmpty);
      expect(ch.internalForce, 5000, reason: 'tower defeat 不动玩家内力');
    });

    test('Boss 战败 + 角色无主修：跳过该角色，无 entry 写入 map', () {
      final ch = buildCharacter(id: 1, mainTechId: null);
      ch.internalForce = 6000;
      final state = BattleState(
        leftTeam: [buildBattleChar(1, 0)],
        rightTeam: const [],
        tick: 5,
        result: BattleResult.rightWin,
        actionLog: const [],
      );

      final result = BattleResolutionService.resolve(
        finalState: state,
        participatingCharacters: [ch],
        equipmentsByCharacter: const {},
        techniquesByCharacter: const {},
        stageDef: buildStage(isBossStage: true),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id, skillIds: const []),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      expect(result.defeatPenaltyByCharacter, isEmpty);
      expect(ch.internalForce, 6000);
    });
  });
}
