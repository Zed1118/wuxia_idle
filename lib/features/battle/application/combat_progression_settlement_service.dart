import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/application/progression_gate_service.dart';
import '../../cultivation/domain/advancement_entry.dart';
import '../../equipment/domain/resonance_upgrade_notice.dart';
import '../../event/application/game_event_service.dart';
import '../../tutorial/application/tutorial_service.dart';

class BossVictoryEventContext {
  final String stageId;
  final String stageName;
  final String bossName;
  final List<Equipment> warbornEquipment;

  const BossVictoryEventContext({
    required this.stageId,
    required this.stageName,
    required this.bossName,
    required this.warbornEquipment,
  });
}

class CombatProgressionSettlementService {
  final GameRepository repository;

  const CombatProgressionSettlementService(this.repository);

  List<AdvancementEntry> applyExperience({
    required List<Character> characters,
    required int experienceReward,
    required Set<String> clearedStageIds,
  }) {
    if (experienceReward <= 0) return const [];
    final innerDemonDef = repository.numbers.innerDemon;
    final releaseCap = repository.numbers.progressionReleaseCap;
    return [
      for (final character in characters)
        AdvancementEntry(
          characterId: character.id,
          chName: character.name,
          result: CharacterAdvancementService.applyExperience(
            character,
            experienceReward,
            realmLookup: repository.getRealm,
            isLayerLocked: (tier, layer) =>
                ProgressionGateService.isLayerLocked(
                  nextTier: tier,
                  nextLayer: layer,
                  releaseCap: releaseCap,
                  realmLookup: repository.getRealm,
                  innerDemonDef: innerDemonDef,
                  clearedStageIds: clearedStageIds,
                ),
          ),
        ),
    ];
  }

  Future<List<ResonanceUpgradeNotice>> recordCommonEvents({
    required Isar isar,
    required List<Character> characters,
    required Map<int, List<Equipment>> equipmentsByCharacter,
    required Iterable<int> resonanceUpgradedEquipmentIds,
    required List<AdvancementEntry> advancements,
    required int? founderId,
    required BossVictoryEventContext? bossVictory,
  }) async {
    final events = GameEventService(isar);
    final tutorial = TutorialService(isar);
    final charactersById = {
      for (final character in characters) character.id: character,
    };
    final equipmentById = {
      for (final equipment in equipmentsByCharacter.values.expand(
        (list) => list,
      ))
        equipment.id: equipment,
    };
    final notices = <ResonanceUpgradeNotice>[];

    for (final equipmentId in resonanceUpgradedEquipmentIds) {
      final equipment = equipmentById[equipmentId];
      if (equipment == null) continue;
      final def = repository.getEquipment(equipment.defId);
      final stage = equipment.resonanceStage(repository.numbers);
      // 无可归属角色(装备无主且无祖师)时跳过事件记录,不写 characterId=0
      // 的幽灵行;UI notice 与事件记录解耦,仍然返回。
      final eventCharacterId = equipment.ownerCharacterId ?? founderId;
      if (eventCharacterId != null) {
        await events.recordResonanceUpgraded(
          characterId: eventCharacterId,
          equipmentId: equipment.id,
          equipmentName: def.name,
          newStage: stage.index + 1,
        );
      }
      notices.add(
        ResonanceUpgradeNotice(equipmentName: def.name, newStage: stage),
      );
    }

    for (final entry in advancements.where(
      (entry) => entry.result.didAdvance,
    )) {
      final character = charactersById[entry.characterId];
      if (character == null) {
        throw StateError('advancement character ${entry.characterId} 不存在');
      }
      await events.recordRealmBreakthrough(
        character: character,
        result: entry.result,
      );
      if (founderId != null && character.id == founderId) {
        await tutorial.advanceForRealmBreakthrough(entry.result.tierAfter);
      }
    }

    if (founderId != null && bossVictory != null) {
      await events.recordBossDefeated(
        characterId: founderId,
        stageId: bossVictory.stageId,
        stageName: bossVictory.stageName,
        bossName: bossVictory.bossName,
        warbornEquipment: bossVictory.warbornEquipment,
      );
    }

    return List.unmodifiable(notices);
  }
}
