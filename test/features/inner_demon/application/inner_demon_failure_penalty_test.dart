import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';

/// M6 心魔关战败惩罚纯逻辑（applyFailurePenalty）TDD 验收。
///
/// 冻结规则：
///   - 永久内力不扣，改为临时内息紊乱
///   - 主修修炼度与 cultivationLayer 均保持不变
///   - ch.innerBreathDisorderHoursRemaining 受上限约束
void main() {
  /// 构造最简 Character，含 internalForce / internalForceMax /
  /// innerDemonResidueHoursRemaining（沿 dispel_service_test.dart 体例）。
  Character newChar({
    int internalForce = 1000,
    int internalForceMax = 1000,
    double residueHoursRemaining = 0,
  }) {
    final c = Character.create(
      name: '测试者',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 6, 16),
      internalForce: internalForce,
      internalForceMax: internalForceMax,
      innerBreathDisorderHoursRemaining: residueHoursRemaining,
    );
    c.id = 1;
    return c;
  }

  /// 构造最简 Technique（沿 dispel_service_test.dart 体例）。
  Technique newTech({
    CultivationLayer layer = CultivationLayer.daCheng,
    int progress = 200,
    int progressToNext = 500,
  }) {
    final t = Technique.create(
      defId: 'tech_1',
      ownerCharacterId: 1,
      tier: TechniqueTier.mingJiaGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 6, 16),
      cultivationLayer: layer,
      cultivationProgress: progress,
      cultivationProgressToNext: progressToNext,
    );
    t.id = 1;
    return t;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 永久内力保护
  // ────────────────────────────────────────────────────────────────────────────

  group('永久内力保护', () {
    test('心魔战败不扣永久内力', () {
      final ch = newChar(internalForce: 1000, internalForceMax: 1000);
      final tech = newTech(progress: 200);

      final r = InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(ch.internalForce, 1000);
      expect(r.internalForceAfter, 1000);
      expect(r.internalForceBefore, 1000);
      expect(ch.innerBreathDisorderHoursRemaining, 8);
    });

    test('低于旧地板的已有内力也不被重写', () {
      final ch = newChar(internalForce: 520, internalForceMax: 1000);
      final tech = newTech(progress: 200);

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(ch.internalForce, 520);
    });

    test('已有低于历史地板的内力也保持不变', () {
      final ch = newChar(internalForce: 500, internalForceMax: 1000);
      final tech = newTech(progress: 100);

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(ch.internalForce, 500);
    });

    test('奇数内力保持原值', () {
      final ch = newChar(internalForce: 1001, internalForceMax: 1000);
      final tech = newTech(progress: 100);

      final r = InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(r.internalForceAfter, 1001);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 主修修炼度与层级保持不变
  // ────────────────────────────────────────────────────────────────────────────

  group('主修修炼度与层级保持不变', () {
    test('主修 progress 与 layer 都保持原值', () {
      final ch = newChar();
      final tech = newTech(layer: CultivationLayer.daCheng, progress: 200);

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(tech.cultivationProgress, 200);
      expect(tech.cultivationLayer, CultivationLayer.daCheng);
    });

    test('非整十 progress 不再经过倍率或 floor', () {
      final ch = newChar();
      final tech = newTech(layer: CultivationLayer.xiaoCheng, progress: 101);

      final r = InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(tech.cultivationProgress, 101);
      expect(r.progressAfter, 101);
      expect(r.progressBefore, 101);
    });

    test('最低层（chuKui）的 progress 与 layer 均不变', () {
      final ch = newChar();
      final tech = newTech(layer: CultivationLayer.chuKui, progress: 50);

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(tech.cultivationProgress, 50);
      expect(tech.cultivationLayer, CultivationLayer.chuKui);
    });

    test('高层（yuanMan）的 progress、阈值与 layer 均不变', () {
      final ch = newChar();
      final tech = newTech(
        layer: CultivationLayer.yuanMan,
        progress: 100,
        progressToNext: 1500,
      );

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(tech.cultivationProgress, 100);
      expect(tech.cultivationProgressToNext, 1500);
      expect(tech.cultivationLayer, CultivationLayer.yuanMan);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 内息紊乱 hours 写入
  // ────────────────────────────────────────────────────────────────────────────

  group('内息紊乱 hours 写入', () {
    test('紊乱设为 residueHours 参数值', () {
      final ch = newChar(residueHoursRemaining: 0);
      final tech = newTech();

      final r = InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(ch.innerBreathDisorderHoursRemaining, 8.0);
      expect(r.residueHoursApplied, 8.0);
    });

    test('再败叠加但受本次上限约束', () {
      final ch = newChar(residueHoursRemaining: 3);
      final tech = newTech();

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(ch.innerBreathDisorderHoursRemaining, 8.0);
    });

    test('自定义 residueHours（非 8）：写入正确', () {
      final ch = newChar();
      final tech = newTech();

      InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 12,
      );

      expect(ch.innerBreathDisorderHoursRemaining, 12.0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // InnerDemonPenaltyResult 汇总字段
  // ────────────────────────────────────────────────────────────────────────────

  group('InnerDemonPenaltyResult 汇总字段', () {
    test('before/after 全字段正确', () {
      final ch = newChar(internalForce: 1000, internalForceMax: 1000);
      final tech = newTech(progress: 200);

      final r = InnerDemonService.applyFailurePenalty(
        ch: ch,
        mainTech: tech,
        residueHours: 8,
      );

      expect(r.internalForceBefore, 1000);
      expect(r.internalForceAfter, 1000);
      expect(r.progressBefore, 200);
      expect(r.progressAfter, 200);
      expect(r.residueHoursApplied, 8.0);
    });
  });
}
