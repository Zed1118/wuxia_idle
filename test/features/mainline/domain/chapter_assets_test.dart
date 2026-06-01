import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/chapter_assets.dart';

void main() {
  group('chapterCoverPath', () {
    test('个位章 → 两位补零路径', () {
      expect(chapterCoverPath(1), 'assets/scenes/chapter_01_cover.png');
      expect(chapterCoverPath(6), 'assets/scenes/chapter_06_cover.png');
    });

    test('两位章不重复补零', () {
      expect(chapterCoverPath(12), 'assets/scenes/chapter_12_cover.png');
    });
  });

  group('stageNarrativePath', () {
    test('stageId → assets/scenes/narrative_<id>.png', () {
      expect(stageNarrativePath('stage_01_01'),
          'assets/scenes/narrative_stage_01_01.png');
      expect(stageNarrativePath('stage_06_05'),
          'assets/scenes/narrative_stage_06_05.png');
    });
  });
}
