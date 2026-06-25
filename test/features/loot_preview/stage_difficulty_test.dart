import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/loot_preview/domain/stage_difficulty.dart';

/// 第八阶段 B · 关卡推荐境界难度判语(纯逻辑 TDD)。
///
/// 按境界 tier 差档(对齐 §5.5):玩家在推荐之上=碾压/同阶=适中/低 1 阶=偏高/
/// 低 2+ 阶=送死。recommended 用 StageDef/TowerFloorDef 既有 requiredRealm。
void main() {
  DifficultyVerdict v(RealmTier rec, RealmTier player) =>
      StageDifficultyAssessor.assess(recommended: rec, playerTier: player);

  test('玩家高于推荐 → comfortable(碾压)', () {
    expect(v(RealmTier.sanLiu, RealmTier.erLiu), DifficultyVerdict.comfortable);
    expect(v(RealmTier.sanLiu, RealmTier.wuSheng),
        DifficultyVerdict.comfortable);
  });

  test('玩家同阶 → suitable(适中)', () {
    expect(v(RealmTier.erLiu, RealmTier.erLiu), DifficultyVerdict.suitable);
  });

  test('玩家低 1 阶 → risky(偏高)', () {
    expect(v(RealmTier.erLiu, RealmTier.sanLiu), DifficultyVerdict.risky);
  });

  test('玩家低 2 阶 → deadly(送死)', () {
    expect(v(RealmTier.yiLiu, RealmTier.sanLiu), DifficultyVerdict.deadly);
  });

  test('玩家低 3+ 阶 → deadly(基本免疫·送死)', () {
    expect(v(RealmTier.wuSheng, RealmTier.sanLiu), DifficultyVerdict.deadly);
  });

  test('边界:学徒推荐 vs 学徒玩家 → suitable', () {
    expect(v(RealmTier.xueTu, RealmTier.xueTu), DifficultyVerdict.suitable);
  });
}
