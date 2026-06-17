// test/features/loot_preview/drop_rumor_bucket_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';

void main() {
  group('bucketOf · 主线上下文(isFirstClearGated=false)', () {
    test('1.0 → 常可得', () {
      expect(bucketOf(1.0, isFirstClearGated: false), DropRumorBucket.changKeDe);
    });
    test('0.99 / 0.30 → 偶可得（>=0.30 闭下界）', () {
      expect(bucketOf(0.99, isFirstClearGated: false), DropRumorBucket.ouKeDe);
      expect(bucketOf(0.30, isFirstClearGated: false), DropRumorBucket.ouKeDe);
    });
    test('0.2999 / 0.08 → 少有人得（>=0.08 闭下界）', () {
      expect(bucketOf(0.2999, isFirstClearGated: false), DropRumorBucket.shaoYouRenDe);
      expect(bucketOf(0.08, isFirstClearGated: false), DropRumorBucket.shaoYouRenDe);
    });
    test('0.0799 → 江湖传闻', () {
      expect(bucketOf(0.0799, isFirstClearGated: false), DropRumorBucket.jiangHuChuanWen);
    });
    test('0.0 → 江湖传闻', () {
      expect(bucketOf(0.0, isFirstClearGated: false), DropRumorBucket.jiangHuChuanWen);
    });
  });

  group('bucketOf · 塔层上下文(isFirstClearGated=true)', () {
    test('1.0 → 首通必得（取代常可得）', () {
      expect(bucketOf(1.0, isFirstClearGated: true), DropRumorBucket.shouTongBiDe);
    });
    test('<1.0 仍按概率分桶', () {
      expect(bucketOf(0.30, isFirstClearGated: true), DropRumorBucket.ouKeDe);
      expect(bucketOf(0.08, isFirstClearGated: true), DropRumorBucket.shaoYouRenDe);
      expect(bucketOf(0.05, isFirstClearGated: true), DropRumorBucket.jiangHuChuanWen);
    });
  });
}
