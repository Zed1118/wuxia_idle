import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/skill_unlock_entry.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../battle_record/application/boss_memory_providers.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';
import '../../../shared/strings.dart';
import '../domain/archive_clue.dart';

final zangjuangeCluesProvider = FutureProvider<List<ArchiveClue>>((ref) async {
  final missingEquipmentCount = await _missingEquipmentCount(ref);
  final missingFragmentCount = await _missingFragmentCount();
  final unbrokenBossCycleCount = await _unrecordedBossCount(ref);

  return buildZangjuangeClues(
    missingEquipmentCount: missingEquipmentCount,
    missingFragmentCount: missingFragmentCount,
    unbrokenBossCycleCount: unbrokenBossCycleCount,
  );
});

List<ArchiveClue> buildZangjuangeClues({
  required int missingEquipmentCount,
  required int missingFragmentCount,
  required int unbrokenBossCycleCount,
}) {
  final clues = <ArchiveClue>[];
  if (missingEquipmentCount > 0) {
    clues.add(
      ArchiveClue(
        category: ArchiveClueCategory.equipment,
        title: UiStrings.zangjuangeClueEquipmentTitle,
        summary: UiStrings.zangjuangeClueEquipmentSummary(
          missingEquipmentCount,
        ),
      ),
    );
  }
  if (missingFragmentCount > 0) {
    clues.add(
      ArchiveClue(
        category: ArchiveClueCategory.skillFragment,
        title: UiStrings.zangjuangeClueFragmentTitle,
        summary: UiStrings.zangjuangeClueFragmentSummary(missingFragmentCount),
      ),
    );
  }
  if (unbrokenBossCycleCount > 0) {
    clues.add(
      ArchiveClue(
        category: ArchiveClueCategory.bossCycle,
        title: UiStrings.zangjuangeClueBossCycleTitle,
        summary: UiStrings.zangjuangeClueBossCycleSummary(
          unbrokenBossCycleCount,
        ),
      ),
    );
  }
  return clues;
}

Future<int> _missingEquipmentCount(Ref ref) async {
  if (!GameRepository.isLoaded || IsarSetup.instanceOrNull == null) {
    return 0;
  }
  final entries = await ref.watch(equipmentCatalogListProvider.future);
  final missing = GameRepository.instance.equipmentDefs.length - entries.length;
  return missing < 0 ? 0 : missing;
}

Future<int> _missingFragmentCount() async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return 0;

  final save = await IsarSetup.currentSaveData();
  final collecting = save?.skillUnlockProgress.where(_isCollectingFragment);
  return collecting?.length ?? 0;
}

Future<int> _unrecordedBossCount(Ref ref) async {
  if (!GameRepository.isLoaded || IsarSetup.instanceOrNull == null) {
    return 0;
  }
  final catalog = ref.read(bossCatalogProvider);
  final memories = await ref.watch(bossMemoryListProvider.future);
  final recordedKeys = {for (final memory in memories) memory.bossKey};
  final missing = catalog
      .where((entry) => !recordedKeys.contains(entry.bossKey))
      .length;
  return missing < 0 ? 0 : missing;
}

bool _isCollectingFragment(SkillUnlockEntry entry) {
  return !entry.unlocked && entry.fragmentCount > 0;
}
