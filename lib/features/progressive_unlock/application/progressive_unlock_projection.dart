import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/inner_demon_def.dart';
import '../../../data/defs/light_foot_def.dart';
import '../../../data/defs/mass_battle_def.dart';
import '../../jianghu_map/application/light_foot_location_detail_provider.dart';
import '../../jianghu_map/application/mass_battle_location_detail_provider.dart';
import '../../light_foot/application/light_foot_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mass_battle/application/mass_battle_service.dart';
import '../domain/progressive_unlock.dart';

ProgressiveUnlockSnapshot projectCurrentProgressiveUnlocks({
  required SaveData save,
  required MainlineProgress mainlineProgress,
  required List<Character> activeCharacters,
  required LightFootDef lightFoot,
  required MassBattleDef massBattle,
  required InnerDemonDef innerDemon,
}) {
  if (save.slotId != mainlineProgress.saveDataId) {
    throw StateError('Progressive unlock save and mainline identities differ');
  }
  final activeIds = save.activeCharacterIds.toSet();
  final characterIds = activeCharacters.map((entry) => entry.id).toSet();
  if (activeIds.length != save.activeCharacterIds.length ||
      characterIds.length != activeCharacters.length ||
      activeIds.length != characterIds.length ||
      !activeIds.containsAll(characterIds)) {
    throw StateError(
      'Progressive unlock active character snapshot is incomplete',
    );
  }

  final cleared = mainlineProgress.clearedStageIds.toSet();
  final lightFootOpen = currentLightFootGateOpen(
    config: lightFoot,
    clearedStageIds: cleared,
  );
  final massBattleOpen = currentMassBattleGateOpen(
    config: massBattle,
    clearedStageIds: cleared,
  );
  final journeyOpen = save.jianghuJourneyUnlocked;
  final innerDemonOpen = currentInnerDemonGateOpen(
    config: innerDemon,
    activeCharacters: activeCharacters,
  );

  return ProgressiveUnlockSnapshot({
    // These two production entries are already visible and enabled on a fresh
    // save. U11 records that fact instead of inventing a new chapter gate.
    ProgressiveUnlockId.tower: ProgressiveUnlockState.open,
    ProgressiveUnlockId.discipleScheduling: ProgressiveUnlockState.open,
    ProgressiveUnlockId.lightFoot: resolveProgressiveUnlockState(
      visible: true,
      enabled: lightFootOpen,
    ),
    ProgressiveUnlockId.massBattle: resolveProgressiveUnlockState(
      visible: true,
      enabled: massBattleOpen,
    ),
    ProgressiveUnlockId.expedition: resolveProgressiveUnlockState(
      visible: journeyOpen,
      enabled: journeyOpen,
    ),
    ProgressiveUnlockId.gauntlet: resolveProgressiveUnlockState(
      visible: journeyOpen,
      enabled: journeyOpen,
    ),
    ProgressiveUnlockId.innerDemon: resolveProgressiveUnlockState(
      visible: innerDemonOpen,
      enabled: innerDemonOpen,
    ),
  });
}

bool currentLightFootGateOpen({
  required LightFootDef config,
  required Set<String> clearedStageIds,
}) {
  final stageIds = validatedLightFootLocationStageIds(config);
  final roots = config.unlockTriggers.entries
      .where((entry) => entry.value == stageIds.first)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (roots.length != 1) {
    throw StateError('Light foot progressive unlock has invalid root');
  }
  return clearedStageIds.contains(roots.single) &&
      LightFootService.statusOf(
            stageId: stageIds.first,
            config: config,
            clearedStageIds: clearedStageIds,
          ) !=
          LightFootStageStatus.locked;
}

bool currentMassBattleGateOpen({
  required MassBattleDef config,
  required Set<String> clearedStageIds,
}) {
  final stageIds = validatedMassBattleLocationStageIds(config);
  final roots = config.unlockTriggers.entries
      .where((entry) => entry.value == stageIds.first)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (roots.length != 1) {
    throw StateError('Mass battle progressive unlock has invalid root');
  }
  return clearedStageIds.contains(roots.single) &&
      MassBattleService.statusOf(
            stageId: stageIds.first,
            config: config,
            clearedStageIds: clearedStageIds,
          ) !=
          MassBattleStageStatus.locked;
}

bool currentInnerDemonGateOpen({
  required InnerDemonDef config,
  required List<Character> activeCharacters,
}) {
  if (config.requiredRealmLayer.isEmpty) return false;
  final firstNode = config.requiredRealmLayer.values
      .map((coord) => _absoluteIndex(coord.tier, coord.layer))
      .reduce((a, b) => a < b ? a : b);
  return activeCharacters.any(
    (character) =>
        _absoluteIndex(character.realmTier, character.realmLayer) >= firstNode,
  );
}

int _absoluteIndex(RealmTier tier, RealmLayer layer) =>
    tier.index * RealmLayer.values.length + layer.index;
