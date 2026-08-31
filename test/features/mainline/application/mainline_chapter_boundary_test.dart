import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_chapter_boundary.dart';

import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('普通章末解析当前章卷尾与下一章首关，章内关卡不冒充边界', () {
    expect(
      resolveMainlineChapterBoundary(
        repository: repository,
        completedStage: repository.getStage('stage_01_04'),
      ),
      isNull,
    );

    final boundary = resolveMainlineChapterBoundary(
      repository: repository,
      completedStage: repository.getStage('stage_01_05'),
    );
    expect(boundary, isNotNull);
    expect(boundary!.completedChapterIndex, 1);
    expect(boundary.completedStageId, 'stage_01_05');
    expect(boundary.nextChapterIndex, 2);
    expect(boundary.nextChapterFirstStage!.id, 'stage_02_01');
    expect(boundary.isFinalChapter, isFalse);
  });

  test('stage_21_05 是终章边界且没有下一章', () {
    final boundary = resolveMainlineChapterBoundary(
      repository: repository,
      completedStage: repository.getStage('stage_21_05'),
    );
    expect(boundary, isNotNull);
    expect(boundary!.completedChapterIndex, 21);
    expect(boundary.nextChapterIndex, isNull);
    expect(boundary.nextChapterFirstStage, isNull);
    expect(boundary.isFinalChapter, isTrue);
  });
}
