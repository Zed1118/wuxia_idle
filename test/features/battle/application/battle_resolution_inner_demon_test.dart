import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/battle_resolution.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// M6 Task 4：BattleResolutionService.resolve 心魔关战败分支验收。
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
  // Fixture builders（体例沿 battle_resolution_test.dart）
  // ──────────────────────────────────────────────────────────────────────────

  final t = DateTime(2026, 6, 16);

  Character buildCharacter({
    required int id,
    required int? mainTechId,
    int internalForce = 8000,
    int internalForceMax = 10000,
  }) {
    final attrs = Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5;
    final ch = Character.create(
      name: '测试角色_$id',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: attrs,
      rarity: RarityTier.xunChang,
      lineageRole: LineageRole.disciple,
      createdAt: t,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechId,
    )..id = id;
    ch.internalForce = internalForce;
    return ch;
  }

  Technique buildTechnique({
    required int id,
    required int ownerCharId,
    required String defId,
    CultivationLayer layer = CultivationLayer.chuKui,
    int progress = 800,
    int progressToNext = 1000,
  }) =>
      Technique.create(
        defId: defId,
        ownerCharacterId: ownerCharId,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: t,
        cultivationLayer: layer,
        cultivationProgress: progress,
        cultivationProgressToNext: progressToNext,
      )..id = id;

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
        defenseRate: 0.05,
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

  TechniqueDef buildTechDef({required String id, List<String> skillIds = const []}) =>
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

  StageDef buildInnerDemonStage() => const StageDef(
        id: 'inner_demon_01',
        name: '心魔关·启蒙',
        stageType: StageType.innerDemon,
        chapterIndex: 1,
        requiredRealm: RealmTier.wuSheng,
        enemyTeam: [],
        isBossStage: false,
        dropTable: [],
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );

  StageDef buildMainlineStage({bool isBossStage = false}) => StageDef(
        id: 'stage_test',
        name: '普通关',
        stageType: StageType.mainline,
        chapterIndex: 1,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: isBossStage,
        dropTable: const [],
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );

  DropService dropSvc() => DropService(
        equipmentDefLookup: (id) =>
            throw StateError('test: eqDef not expected for $id'),
        now: () => t,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // M6 Task 4 · 心魔关战败惩罚分支
  // ──────────────────────────────────────────────────────────────────────────

  group('M6 Task 4 · 心魔关战败 → innerDemonPenaltyByCharacter', () {
    test('心魔关战败施加心魔惩罚 + 余毒，且不触发 Boss 散功', () {
      final ch = buildCharacter(id: 1, mainTechId: 200, internalForce: 8000);
      final mainTech = buildTechnique(
        id: 200,
        ownerCharId: 1,
        defId: 'tech_main',
        layer: CultivationLayer.chuKui,
        progress: 800,
        progressToNext: 1000,
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
        equipmentsByCharacter: const {},
        techniquesByCharacter: {1: [mainTech]},
        stageDef: buildInnerDemonStage(),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      // 心魔惩罚 entry 存在
      expect(
        result.innerDemonPenaltyByCharacter[ch.id],
        isNotNull,
        reason: '心魔关战败应产生 innerDemonPenaltyByCharacter entry',
      );
      // 非 Boss 关，Boss 散功不触发
      expect(
        result.defeatPenaltyByCharacter,
        isEmpty,
        reason: '心魔关 isBossStage=false，不触发 Boss 散功',
      );
      // 余毒已写入角色
      expect(
        ch.innerDemonResidueHoursRemaining,
        greaterThan(0),
        reason: 'applyFailurePenalty 应写 innerDemonResidueHoursRemaining',
      );
      // 内力已被削减（numbersConfig.innerDemon.failurePenalty.internalForceMultiplier < 1.0）
      final penalty = result.innerDemonPenaltyByCharacter[ch.id]!;
      expect(penalty.internalForceBefore, 8000);
      expect(penalty.internalForceAfter, lessThan(8000));
      // progress 也被削减
      expect(penalty.progressBefore, 800);
      expect(penalty.progressAfter, lessThanOrEqualTo(800));
      // residueHoursApplied > 0
      expect(penalty.residueHoursApplied, greaterThan(0));
    });

    test('心魔关胜利：innerDemonPenaltyByCharacter 恒空', () {
      final ch = buildCharacter(id: 1, mainTechId: 200, internalForce: 8000);
      final mainTech = buildTechnique(
        id: 200,
        ownerCharId: 1,
        defId: 'tech_main',
      );
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
        stageDef: buildInnerDemonStage(),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id),
        dropService: dropSvc(),
        isVictory: true,
        numbersConfig: numbersCfg,
      );

      expect(result.innerDemonPenaltyByCharacter, isEmpty,
          reason: '心魔关胜利不施加惩罚');
      expect(ch.innerDemonResidueHoursRemaining, 0,
          reason: '胜利不写余毒');
      expect(ch.internalForce, 8000, reason: '胜利不削内力');
    });

    test('普通关战败：innerDemonPenaltyByCharacter 恒空（非 innerDemon stageType）', () {
      final ch = buildCharacter(id: 1, mainTechId: 200, internalForce: 6000);
      final mainTech = buildTechnique(
        id: 200,
        ownerCharId: 1,
        defId: 'tech_main',
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
        equipmentsByCharacter: const {},
        techniquesByCharacter: {1: [mainTech]},
        stageDef: buildMainlineStage(isBossStage: false),
        rng: DefaultRng(seed: 1),
        progressToNextMap: progressMap,
        techniqueDefLookup: (id) => buildTechDef(id: id),
        dropService: dropSvc(),
        isVictory: false,
        numbersConfig: numbersCfg,
      );

      expect(result.innerDemonPenaltyByCharacter, isEmpty,
          reason: '普通关不触发心魔惩罚');
      expect(ch.internalForce, 6000, reason: '普通关不动内力');
    });
  });
}
