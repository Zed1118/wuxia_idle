import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/zangjuange/domain/archive_clue.dart';

void main() {
  test('archive clue carries category and target metadata', () {
    const clue = ArchiveClue(
      category: ArchiveClueCategory.equipment,
      title: '缺少兵器',
      summary: '传闻可在边塞关卡寻得。',
      targetKind: ArchiveClueTargetKind.stage,
      targetId: 'stage_04_03',
    );

    expect(clue.category, ArchiveClueCategory.equipment);
    expect(clue.targetKind, ArchiveClueTargetKind.stage);
    expect(clue.targetId, 'stage_04_03');
  });
}
