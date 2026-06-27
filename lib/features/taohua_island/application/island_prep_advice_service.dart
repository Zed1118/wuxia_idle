import '../../../shared/strings.dart';
import '../../zangjuange/domain/archive_clue.dart';
import '../domain/island_prep_advice.dart';

class IslandPrepAdviceService {
  const IslandPrepAdviceService._();

  static List<IslandPrepAdvice> fromClues(Iterable<ArchiveClue> clues) {
    return [
      for (final clue in clues)
        switch (clue.category) {
          ArchiveClueCategory.equipment => IslandPrepAdvice(
            kind: IslandPrepAdviceKind.equipment,
            title: UiStrings.islandPrepEquipmentTitle,
            body: UiStrings.islandPrepEquipmentBody,
            sourceId: clue.targetId,
          ),
          ArchiveClueCategory.skillFragment => IslandPrepAdvice(
            kind: IslandPrepAdviceKind.skillFragment,
            title: UiStrings.islandPrepFragmentTitle,
            body: UiStrings.islandPrepFragmentBody,
            sourceId: clue.targetId,
          ),
          ArchiveClueCategory.bossCycle => IslandPrepAdvice(
            kind: IslandPrepAdviceKind.bossCycle,
            title: UiStrings.islandPrepBossCycleTitle,
            body: UiStrings.islandPrepBossCycleBody,
            sourceId: clue.targetId,
            priority: IslandPrepAdvicePriority.high,
          ),
        },
    ];
  }
}
