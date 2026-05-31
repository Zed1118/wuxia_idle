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
}
