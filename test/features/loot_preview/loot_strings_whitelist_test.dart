// test/features/loot_preview/loot_strings_whitelist_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('掉落传闻词条不含网游稀有词 + 不含百分号', () {
    final strings = [
      UiStrings.lootBucketChangKeDe,
      UiStrings.lootBucketOuKeDe,
      UiStrings.lootBucketShaoYouRenDe,
      UiStrings.lootBucketJiangHuChuanWen,
      UiStrings.lootBucketShouTongBiDe,
      UiStrings.lootSummaryPrefix,
      UiStrings.lootRumorDialogTitle,
      UiStrings.lootNoFixedDrop,
      UiStrings.lootAboveRealmHint,
      UiStrings.lootTowerFirstClearOnlyFooter,
    ];
    const banned = ['传奇', '史诗', 'SSR', 'SR', 'legendary', 'epic', '%'];
    for (final s in strings) {
      for (final b in banned) {
        expect(s.toLowerCase().contains(b.toLowerCase()), false,
            reason: '词条「$s」含禁用词「$b」');
      }
    }
  });
}
