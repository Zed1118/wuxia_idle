import 'package:isar_community/isar.dart';

import '../../core/domain/character.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/attribute_effect_policy.dart';
import '../../core/domain/equipment.dart';
import '../../core/domain/save_data.dart';
import '../../core/domain/skill_usage_entry.dart';
import '../../core/domain/technique.dart';
import '../../data/defs/synergy_def.dart';
import '../../data/defs/skill_def.dart';
import '../../data/game_repository.dart';
import '../../data/numbers_config.dart';
import 'combatant_snapshot.dart';
import 'combatant_skill_loadout.dart';
import 'player_combatant_snapshot_builder.dart';
import '../../features/activity/application/character_occupancy_service.dart';
import '../../features/activity/domain/activity_occupancy.dart';
import '../../features/cultivation/application/skill_loadout_resolver.dart';
import '../../features/cultivation/application/skill_loadout_service.dart';
import '../../features/cultivation/application/synergy_service.dart';
import '../../features/inheritance/application/founder_buff_service.dart';
import '../../features/sect/domain/sect.dart';

/// 持久化玩家角色 → [CombatantSnapshot] 的深 Module。
///
/// active roster interface 负责 occupancy filter + 旧 seed fallback；exact roster
/// interface 严格保序且缺失 fail-fast。Isar 读取、autoFill 写回、祖师 buff、
/// 装备/主辅修、伤势与相生均隐藏在 implementation 内。
final class PlayerCombatantSnapshotAssembler {
  const PlayerCombatantSnapshotAssembler({required this.isar});

  final Isar isar;

  Future<List<CombatantSnapshot>> loadActiveRoster() => _assemble();

  Future<List<CombatantSnapshot>> loadExactRoster(
    List<int> characterIds,
  ) async {
    if (characterIds.isEmpty) {
      throw ArgumentError.value(
        characterIds,
        'characterIds',
        'must not be empty',
      );
    }
    if (characterIds.toSet().length != characterIds.length) {
      throw ArgumentError.value(
        characterIds,
        'characterIds',
        'must not contain duplicates',
      );
    }
    return _assemble(characterIds: characterIds, strictExact: true);
  }

  Future<List<CombatantSnapshot>> _assemble({
    List<int>? characterIds,
    bool strictExact = false,
  }) async {
    final save = await isar.saveDatas.get(0);
    var ids = characterIds ?? save?.activeCharacterIds ?? const <int>[];
    var dispatched = const <int>{};
    if (characterIds == null) {
      final occupancy = await CharacterOccupancyService(isar).snapshot();
      dispatched = <int>{
        for (final entry in occupancy.entries)
          if (entry.kind == ActivityKind.expedition ||
              entry.kind == ActivityKind.bossGauntlet ||
              entry.kind == ActivityKind.lightFoot ||
              entry.kind == ActivityKind.massBattle)
            ...entry.characterIds,
      };
      if (dispatched.isNotEmpty) {
        ids = [
          for (final id in ids)
            if (!dispatched.contains(id)) id,
        ];
      }
    }

    final players = <Character>[];
    for (final characterId in ids) {
      final character = await isar.characters.get(characterId);
      if (character != null) players.add(character);
    }
    if (strictExact && players.length != ids.length) {
      final foundIds = {for (final player in players) player.id};
      final missingIds = [
        for (final id in ids)
          if (!foundIds.contains(id)) id,
      ];
      throw StateError('Player roster character ids not found: $missingIds');
    }
    if (players.isEmpty) {
      final all = await isar.characters.where().findAll();
      Character? fallback;
      for (final character in all) {
        if (!dispatched.contains(character.id)) {
          fallback = character;
          break;
        }
      }
      if (fallback == null) {
        throw StateError('StageBattleSetup: Isar 没有任何 Character（先跑 P1 种子）');
      }
      players.add(fallback);
    }

    final founderBuff = FounderBuffService(isar);
    final numbers = GameRepository.instance.numbers;
    final sect = await isar.sects.get(1);
    final playerSectId = sect?.id;
    final founderBuffByCharacter = <int, bool>{};
    for (final character in players) {
      founderBuffByCharacter[character.id] = await founderBuff.isBuffActiveFor(
        target: character,
        numbers: numbers,
        playerSectId: playerSectId,
      );
    }

    final loadout = SkillLoadoutService(isar);
    final resolver = SkillLoadoutResolver(isar: isar);
    final repository = GameRepository.instance;
    for (final character in players) {
      final sources = await resolver.resolve(
        character,
        repository: repository,
        numbers: numbers,
      );
      await loadout.applyAutoFill(
        characterId: character.id,
        mainTechniqueSkills: sources.mainTechniqueSkills,
        assistTechniqueSkills: sources.assistTechniqueSkills,
        jointSkill: sources.jointSkill,
        ultimatePowerThreshold: numbers.loadoutUltimatePowerThreshold,
        interruptSkills: sources.interruptSkills,
        lineageRole: character.lineageRole,
        isFounder: character.isFounder,
      );
    }

    final snapshots = <CombatantSnapshot>[];
    for (var index = 0; index < players.length; index++) {
      final updated =
          await isar.characters.get(players[index].id) ?? players[index];
      snapshots.add(
        await _assembleOne(
          character: updated,
          founderBuffActive: founderBuffByCharacter[players[index].id] ?? false,
        ),
      );
    }
    return snapshots;
  }

  Future<CombatantSnapshot> _assembleOne({
    required Character character,
    required bool founderBuffActive,
  }) async {
    final equipped = <Equipment>[];
    for (final equipmentId in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (equipmentId == null) continue;
      final equipment = await isar.equipments.get(equipmentId);
      if (equipment != null) equipped.add(equipment);
    }
    if (character.mainTechniqueId == null) {
      throw StateError('角色 ${character.name} 未修主修，无法进入战斗');
    }
    final mainTechnique = await isar.techniques.get(character.mainTechniqueId!);
    if (mainTechnique == null) {
      throw StateError(
        '角色 ${character.name} mainTechniqueId='
        '${character.mainTechniqueId} 在 Isar 中找不到',
      );
    }
    final ownedTechniques = <Technique>[mainTechnique];
    for (final assistId in character.assistTechniqueIds) {
      final assist = await isar.techniques.get(assistId);
      if (assist != null) ownedTechniques.add(assist);
    }

    final numbers = GameRepository.instance.numbers;
    final heavyInjured = character.injuryHoursRemaining > 0;
    final base = PlayerCombatantSnapshotBuilder.build(
      character: character,
      equipped: equipped,
      mainTechnique: mainTechnique,
      numbers: numbers,
      founderBuffActive: founderBuffActive,
      outputMultiplier: heavyInjured
          ? numbers.injury.heavyAttackOutputMultiplier
          : 1.0,
      lightInjuryStacks: character.lightInjuryStacks,
    );
    final skillsById = {
      for (final skill in base.availableSkills) skill.id: skill,
    };
    final mainDef = GameRepository.instance.getTechnique(mainTechnique.defId);
    SkillDef? basicAttack;
    for (final skillId in mainDef.skillIds) {
      final skill = GameRepository.instance.skillDefs[skillId];
      if (skill?.type == SkillType.normalAttack) {
        basicAttack = skill;
        break;
      }
    }
    if (basicAttack == null) {
      throw StateError('角色 ${character.name} 的主修 ${mainTechnique.defId} 缺普通攻击');
    }
    final withLoadout = base.copyWith(
      skillUses: {
        ...base.skillUses,
        basicAttack.id:
            base.skillUses[basicAttack.id] ??
            AttributeEffectPolicy(numbers.attributeEffects).effectiveUsageCount(
              rawUses: mainTechnique.skillUsageCount.countOf(basicAttack.id),
              enlightenment: character.attributes.enlightenment,
            ),
      },
      skillLoadout: CombatantSkillLoadout(
        basicAttack: basicAttack,
        main1: skillsById[character.mainSkillId1],
        main2: skillsById[character.mainSkillId2],
        assist: skillsById[character.assistSkillId],
        resonance: skillsById[character.resonanceSkillId],
        ultimate: skillsById[character.ultimateSkillId],
        encounter: skillsById[character.equippedEncounterSkillId],
        key: skillsById[character.keySkillId],
      ),
    );
    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: ownedTechniques,
      techDefLookup: (defId) => GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    return synergy == null
        ? withLoadout
        : applySynergy(withLoadout, synergy.multipliers, numbers: numbers);
  }

  static CombatantSnapshot applySynergy(
    CombatantSnapshot base,
    SynergyMultipliers multipliers, {
    NumbersConfig? numbers,
  }) {
    final redLines =
        (numbers ?? GameRepository.instance.numbers).combat.redLines;
    var maxHp = (base.maxHp * (1 + multipliers.hpPct)).round();
    if (maxHp > redLines.playerHpMax) maxHp = redLines.playerHpMax;
    final speed = (base.speed * (1 + multipliers.speedPct)).round();
    final attack = (base.totalEquipmentAttack * (1 + multipliers.attackPct))
        .round();
    var internalForce =
        (base.internalForce * (1 + multipliers.internalForceMaxPct)).round();
    if (internalForce > redLines.internalForceMax) {
      internalForce = redLines.internalForceMax;
    }
    final defenseRate = (base.defenseRate + multipliers.defensePct).clamp(
      0.0,
      redLines.combinedRateCap,
    );
    return base.copyWith(
      maxHp: maxHp,
      currentHp: maxHp,
      speed: speed,
      totalEquipmentAttack: attack,
      internalForce: internalForce,
      defenseRate: defenseRate,
    );
  }
}
