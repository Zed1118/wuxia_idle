import '../../../shared/strings.dart';
import '../domain/archive_clue.dart';

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
        summary: UiStrings.zangjuangeClueFragmentSummary(
          missingFragmentCount,
        ),
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
