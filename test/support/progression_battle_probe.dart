import 'dart:math';

import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
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

const progressionBattleMaxTicks = 240;

final class ProgressionPlayerBuild {
  ProgressionPlayerBuild({
    required this.character,
    required List<Equipment> equipped,
    required this.mainTechnique,
    required this.battleCharacter,
  }) : equipped = List.unmodifiable(equipped);

  final Character character;
  final List<Equipment> equipped;
  final Technique mainTechnique;
  final BattleCharacter battleCharacter;
}

final class ProgressionBattleRun {
  const ProgressionBattleRun({required this.initial, required this.terminal});

  final BattleState initial;
  final BattleState terminal;
}

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
  final run = runProgressionMainlineStage(
    repository: repository,
    stage: stage,
    profile: profile,
    seed: seed,
  );
  int sumHp(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentHp);
  int sumQi(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentQi);
  return ProgressionBattleObservation(
    stageId: stage.id,
    profile: profile,
    seed: seed,
    result: run.terminal.result!,
    ticks: run.terminal.tick,
    playerHpStart: sumHp(run.initial.leftTeam),
    playerHpEnd: sumHp(run.terminal.leftTeam),
    playerQiStart: sumQi(run.initial.leftTeam),
    playerQiEnd: sumQi(run.terminal.leftTeam),
    actionRows: run.terminal.actionLog.length,
  );
}

/// Whether a draw at [maxTicks] is the runner's unfinished-battle fallback.
///
/// A rules draw can also finish exactly on the boundary when both teams are
/// annihilated. The default ground strategy only uses its tick-cap fallback
/// while both teams still have a living character.
bool isUnfinishedAtTickCap(BattleState terminal, {required int maxTicks}) =>
    terminal.tick >= maxTicks &&
    terminal.result == BattleResult.draw &&
    terminal.leftTeam.any((character) => character.isAlive) &&
    terminal.rightTeam.any((character) => character.isAlive);

ProgressionBattleRun runProgressionMainlineStage({
  required GameRepository repository,
  required StageDef stage,
  required ProgressionBuildProfile profile,
  required int seed,
  int maxTicks = progressionBattleMaxTicks,
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
    maxTicks: maxTicks,
    rng: Random(seed),
  );
  if (isUnfinishedAtTickCap(terminal, maxTicks: maxTicks)) {
    throw StateError(
      'progression_probe: stage=${stage.id} profile=${profile.name} '
      'seed=$seed reached maxTicks=$maxTicks with draw',
    );
  }
  return ProgressionBattleRun(initial: initial, terminal: terminal);
}

BattleCharacter buildProgressionPlayer({
  required GameRepository repository,
  required RealmTier tier,
  required int slot,
  required bool isFounder,
  required ProgressionBuildProfile profile,
}) => buildProgressionPlayerBuild(
  repository: repository,
  tier: tier,
  slot: slot,
  isFounder: isFounder,
  profile: profile,
).battleCharacter;

ProgressionPlayerBuild buildProgressionPlayerBuild({
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
  final ownerId = 7000 + slot;

  final equipmentTier = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final slotType in const [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    // 保留旧诊断的代表样本：按 repository/yaml 插入顺序取首个同阶同槽 def。
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
        ownerCharacterId: ownerId,
        battleCount: battleCount,
      ),
    );
  }

  final techniqueTier = RealmUtils.techniqueTierCapOf(tier);
  // 同上，保留旧诊断按 repository/yaml 插入顺序选择的首本刚猛心法。
  final TechniqueDef techniqueDef = repository.techniqueDefs.values.firstWhere(
    (value) => value.tier == techniqueTier && value.school == school,
    orElse: () => throw StateError(
      'progression_probe: 无 ${techniqueTier.name}/${school.name} 心法',
    ),
  );
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
    rarity: profile == ProgressionBuildProfile.nearMax
        ? RarityTier.ziYou
        : RarityTier.biaoZhun,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime.utc(2026, 7, 13),
    internalForce: realm.internalForceMax,
    internalForceMax: realm.internalForceMax,
    experienceToNextLayer: realm.experienceToNext,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = ownerId;
  final battleCharacter = BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTechnique,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: buff,
  );
  return ProgressionPlayerBuild(
    character: character,
    equipped: equipped,
    mainTechnique: mainTechnique,
    battleCharacter: battleCharacter,
  );
}
