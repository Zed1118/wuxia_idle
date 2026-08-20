import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/synergy_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_occupancy.dart';
import '../../cultivation/application/skill_loadout_resolver.dart';
import '../../cultivation/application/skill_loadout_service.dart';
import '../../cultivation/application/synergy_service.dart';
import '../../inheritance/application/founder_buff_service.dart';
import '../../sect/domain/sect.dart';
import '../domain/battle_state.dart';

/// 持久化玩家角色 → BattleCharacter 的深 Module。
///
/// active roster interface 负责 occupancy filter + 旧 seed fallback；exact roster
/// interface 严格保序且缺失 fail-fast。Isar 读取、autoFill 写回、祖师 buff、
/// 装备/主辅修、伤势与相生均隐藏在 implementation 内。
final class PlayerBattleCharacterAssembler {
  const PlayerBattleCharacterAssembler({required this.isar});

  final Isar isar;

  Future<List<BattleCharacter>> loadActiveRoster() => _assemble();

  Future<List<BattleCharacter>> loadExactRoster(List<int> characterIds) async {
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

  Future<List<BattleCharacter>> _assemble({
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
              entry.kind == ActivityKind.bossGauntlet)
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

    final snapshots = <BattleCharacter>[];
    for (var index = 0; index < players.length && index < 3; index++) {
      final updated =
          await isar.characters.get(players[index].id) ?? players[index];
      snapshots.add(
        await _assembleOne(
          character: updated,
          slotIndex: index,
          founderBuffActive: founderBuffByCharacter[players[index].id] ?? false,
        ),
      );
    }
    return snapshots;
  }

  Future<BattleCharacter> _assembleOne({
    required Character character,
    required int slotIndex,
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
    final base = BattleCharacter.fromCharacter(
      character: character,
      equipped: equipped,
      mainTechnique: mainTechnique,
      numbers: numbers,
      teamSide: 0,
      slotIndex: slotIndex,
      founderBuffActive: founderBuffActive,
      outputMultiplier: heavyInjured
          ? numbers.injury.heavyAttackOutputMultiplier
          : 1.0,
      heavyInjured: heavyInjured,
      lightInjuryStacks: character.lightInjuryStacks,
    );
    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: ownedTechniques,
      techDefLookup: (defId) => GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    return synergy == null
        ? base
        : applySynergy(base, synergy.multipliers, numbers: numbers);
  }

  static BattleCharacter applySynergy(
    BattleCharacter base,
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
