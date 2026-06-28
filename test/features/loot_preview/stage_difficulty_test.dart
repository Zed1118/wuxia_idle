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
    expect(
      v(RealmTier.sanLiu, RealmTier.wuSheng),
      DifficultyVerdict.comfortable,
    );
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

  group('StagePreparationSummary', () {
    StagePreparationSummary s(RealmTier rec, RealmTier? player) =>
        StagePreparationSummary.assess(recommended: rec, playerTier: player);

    test('无出战角色 → 提示先派人', () {
      final summary = s(RealmTier.xueTu, null);

      expect(summary.focus, StagePreparationFocus.assignCharacter);
      expect(summary.verdict, isNull);
      expect(summary.realmGap, 0);
    });

    test('同阶或高阶 → 已可挑战', () {
      expect(
        s(RealmTier.erLiu, RealmTier.erLiu).focus,
        StagePreparationFocus.ready,
      );
      expect(
        s(RealmTier.erLiu, RealmTier.yiLiu).focus,
        StagePreparationFocus.ready,
      );
    });

    test('低 1 阶 → 优先装备/心法补强', () {
      final summary = s(RealmTier.erLiu, RealmTier.sanLiu);

      expect(summary.focus, StagePreparationFocus.polishLoadout);
      expect(summary.realmGap, 1);
      expect(summary.verdict, DifficultyVerdict.risky);
    });

    test('低 2+ 阶 → 优先闭关突破', () {
      final summary = s(RealmTier.yiLiu, RealmTier.xueTu);

      expect(summary.focus, StagePreparationFocus.realmBreakthrough);
      expect(summary.realmGap, 3);
      expect(summary.verdict, DifficultyVerdict.deadly);
    });
  });
}
