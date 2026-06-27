import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/skill_unlock_entry.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../tower/application/tower_providers.dart';
import '../../../shared/strings.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';
import '../domain/archive_clue.dart';

final zangjuangeCluesProvider = FutureProvider<List<ArchiveClue>>((ref) async {
  final missingEquipmentCount = await _missingEquipmentCount(ref);
  final missingFragmentCount = await _missingFragmentCount();
  final unbrokenBossCycleCount = await _unbrokenBossCycleCount(ref);

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

int countUnbrokenBossCycles({
  required Iterable<String> clearedChapterCycleKeys,
  required int maxCycleMainline,
  required int towerMaxClearedCycle,
  required int maxCycleTower,
}) {
  final mainlineCount = _highestMainlineCycles(
    clearedChapterCycleKeys,
  ).values.where((cycle) => cycle > 0 && cycle < maxCycleMainline).length;
  final towerCount =
      towerMaxClearedCycle > 0 && towerMaxClearedCycle < maxCycleTower ? 1 : 0;
  return mainlineCount + towerCount;
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

Future<int> _unbrokenBossCycleCount(Ref ref) async {
  if (!GameRepository.isLoaded || IsarSetup.instanceOrNull == null) {
    return 0;
  }
  final mainline = await ref.watch(mainlineProgressProvider.future);
  final tower = await ref.watch(towerProgressProvider.future);
  final cycleConfig = GameRepository.instance.numbers.cycleEvolution;
  return countUnbrokenBossCycles(
    clearedChapterCycleKeys: mainline.clearedChapterCycleKeys,
    maxCycleMainline: cycleConfig.maxCycleMainline,
    towerMaxClearedCycle: tower.maxClearedCycle,
    maxCycleTower: cycleConfig.maxCycleTower,
  );
}

bool _isCollectingFragment(SkillUnlockEntry entry) {
  return !entry.unlocked && entry.fragmentCount > 0;
}

Map<String, int> _highestMainlineCycles(Iterable<String> keys) {
  final result = <String, int>{};
  for (final key in keys) {
    final hash = key.lastIndexOf('#');
    if (hash <= 0 || hash == key.length - 1) continue;
    final chapterKey = key.substring(0, hash);
    if (!chapterKey.startsWith('ch')) continue;
    final cycle = int.tryParse(key.substring(hash + 1));
    if (cycle == null) continue;
    final previous = result[chapterKey] ?? 0;
    if (cycle > previous) result[chapterKey] = cycle;
  }
  return result;
}
