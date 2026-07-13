import 'dart:math';

import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

enum ProgressionBuildProfile { undergeared, standard, nearMax }

final class ProgressionBattleObservation {
  const ProgressionBattleObservation({
    required this.stageId,
    required this.profile,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.playerHpStart,
    required this.playerHpEnd,
    required this.playerQiStart,
    required this.playerQiEnd,
    required this.actionRows,
  });

  final String stageId;
  final ProgressionBuildProfile profile;
  final int seed;
  final BattleResult result;
  final int ticks;
  final int playerHpStart;
  final int playerHpEnd;
  final int playerQiStart;
  final int playerQiEnd;
  final int actionRows;
}

ProgressionBattleObservation probeMainlineStage({
  required GameRepository repository,
  required StageDef stage,
  required ProgressionBuildProfile profile,
  required int seed,
}) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      buildProgressionPlayer(
        repository: repository,
        tier: stage.requiredRealm,
        slot: slot,
        isFounder: slot == 0,
        profile: profile,
      ),
  ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repository.numbers,
    maxTicks: 240,
    rng: Random(seed),
  );
  final result = terminal.result;
  if (result == null) {
    throw StateError(
      'progression_probe: ${stage.id}/${profile.name}/seed=$seed '
      '未在 240 ticks 内结束',
    );
  }
  int sumHp(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentHp);
  int sumQi(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentQi);
  return ProgressionBattleObservation(
    stageId: stage.id,
    profile: profile,
    seed: seed,
    result: result,
    ticks: terminal.tick,
    playerHpStart: sumHp(initial.leftTeam),
    playerHpEnd: sumHp(terminal.leftTeam),
    playerQiStart: sumQi(initial.leftTeam),
    playerQiEnd: sumQi(terminal.leftTeam),
    actionRows: terminal.actionLog.length,
  );
}

BattleCharacter buildProgressionPlayer({
  required GameRepository repository,
  required RealmTier tier,
  required int slot,
  required bool isFounder,
  required ProgressionBuildProfile profile,
}) {
  const school = TechniqueSchool.gangMeng;
  final numbers = repository.numbers;
  final realm = repository.getRealm(tier, RealmLayer.huaJing);
  final (
    enhanceRatio,
    battleCount,
    cultivationLayer,
    attributeValue,
    buff,
  ) = switch (profile) {
    ProgressionBuildProfile.undergeared => (
      0.0,
      0,
      CultivationLayer.zhongCheng,
      5,
      false,
    ),
    ProgressionBuildProfile.standard => (
      0.25,
      150,
      CultivationLayer.zhongCheng,
      5,
      false,
    ),
    ProgressionBuildProfile.nearMax => (
      0.5,
      400,
      CultivationLayer.daCheng,
      6,
      true,
    ),
  };
  final enhanceLevel = (realm.absoluteLevel * enhanceRatio).round();

  final equipmentTier = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final slotType in const [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final EquipmentDef def = repository.equipmentDefs.values.firstWhere(
      (value) => value.tier == equipmentTier && value.slot == slotType,
      orElse: () => throw StateError(
        'progression_probe: 无 ${equipmentTier.name}/${slotType.name} 装备',
      ),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime.utc(2026, 7, 13),
        obtainedFrom: 'progression_playtest',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
        forgingSlots: const <ForgingSlot>[],
      ),
    );
  }

  final techniqueTier = RealmUtils.techniqueTierCapOf(tier);
  final TechniqueDef techniqueDef = repository.techniqueDefs.values.firstWhere(
    (value) => value.tier == techniqueTier && value.school == school,
    orElse: () => throw StateError(
      'progression_probe: 无 ${techniqueTier.name}/${school.name} 心法',
    ),
  );
  final ownerId = 7000 + slot;
  final mainTechnique = Technique.create(
    defId: techniqueDef.id,
    ownerCharacterId: ownerId,
    tier: techniqueDef.tier,
    school: techniqueDef.school,
    role: TechniqueRole.main,
    learnedAt: DateTime.utc(2026, 7, 13),
    cultivationLayer: cultivationLayer,
  );
  final attributes = Attributes()
    ..constitution = attributeValue
    ..enlightenment = 5
    ..agility = attributeValue
    ..fortune = 5;
  final character = Character.create(
    name: isFounder ? '成长体检祖师' : '成长体检弟子$slot',
    realmTier: tier,
    realmLayer: RealmLayer.huaJing,
    attributes: attributes,
    rarity: RarityTier.biaoZhun,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime.utc(2026, 7, 13),
    internalForce: realm.internalForceMax,
    internalForceMax: realm.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = ownerId;
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTechnique,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: buff,
  );
}
