enum ArchiveClueCategory { equipment, skillFragment, bossCycle }

enum ArchiveClueTargetKind { stage, towerFloor, bossRecord, none }

class ArchiveClue {
  const ArchiveClue({
    required this.category,
    required this.title,
    required this.summary,
    this.targetKind = ArchiveClueTargetKind.none,
    this.targetId,
  });

  final ArchiveClueCategory category;
  final String title;
  final String summary;
  final ArchiveClueTargetKind targetKind;
  final String? targetId;
}
