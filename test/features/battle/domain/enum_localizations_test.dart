import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';

void main() {
  group('EnumL10n.bossMemorySource', () {
    test('BossMemorySource 显示名穷尽', () {
      expect(EnumL10n.bossMemorySource(BossMemorySource.mainline), '主线征程');
      expect(EnumL10n.bossMemorySource(BossMemorySource.tower), '爬塔问鼎');
    });

    test('所有 BossMemorySource 值都有非空映射(全覆盖红线)', () {
      for (final s in BossMemorySource.values) {
        expect(
          EnumL10n.bossMemorySource(s),
          isNotEmpty,
          reason: '$s 缺少中文映射',
        );
      }
    });
  });
}
