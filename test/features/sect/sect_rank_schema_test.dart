import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/sect/domain/sect_rank.dart';

/// P4.1 §12.2 B4 R5.5 sectRank schema 不破七阶锁(spec p4_1_sect_management_spec §7)。
///
/// GDD §5.3 三系锁死仅约束「境界 ↔ 装备阶 ↔ 心法阶」三系。`SectRank` 是组织层
/// 阶位(初入 / 内门 / 长老 · 3 阶),与修炼七阶 [RealmTier] schema 隔离 → **不开**
/// 新七阶 anti-pattern · 不破 §5.3 锁。
void main() {
  test('R5.5 SectRank.values.length == 3(三阶 ≠ 七阶)', () {
    expect(SectRank.values.length, 3);
    expect(SectRank.values, [
      SectRank.initiate,
      SectRank.inner,
      SectRank.elder,
    ]);
  });

  test('R5.5 SectRank 与 RealmTier schema 隔离(无 layer 嵌套 · 无名字撞型)', () {
    // RealmTier 七阶在 enums.dart · SectRank 三阶在 sect_rank.dart,
    // 类型不通(SectRank 不在 RealmTier.values 集合内)。
    expect(RealmTier.values.length, 7);
    final sectRankNames = SectRank.values.map((e) => e.name).toSet();
    final realmTierNames = RealmTier.values.map((e) => e.name).toSet();
    expect(sectRankNames.intersection(realmTierNames), isEmpty,
        reason: 'SectRank 三阶名不与 RealmTier 七阶撞');
  });
}
