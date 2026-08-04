import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/cycle_realm_gate.dart';

/// 批 B 周目解锁门槛纯函数层（spec 2026-08-01 拍板 #5：顺序解锁 ∩ 配置
/// cap ∩ 境界门槛；远征深度里程碑折算 2026-08-04 拍板）。
void main() {
  const ra = RealmAdvanceConfig(
    tiersPerCycle: 3,
    maxCycle: 3,
    unlockRealmMargin: 1,
    rewardBonusPerCycle: 0.25,
    expeditionDepthMilestones: [20, 40],
  );

  group('meetsRealmGate', () {
    test('cycle1 恒 true（既有内容不回锁）', () {
      expect(
        CycleRealmGate.meetsRealmGate(
          cycle: 1,
          playerMaxTier: RealmTier.xueTu,
          baseEnemyMaxTier: RealmTier.wuSheng,
          ra: ra,
        ),
        isTrue,
      );
    });

    test(
      'margin 语义：需 ≥ 推进后敌境界 - 1（sanLiu 敌 cycle2 → 推进 jueDing，需 ≥ yiLiu）',
      () {
        // sanLiu(1) + 3 = jueDing(4)；margin 1 → 玩家须 ≥ yiLiu(3)。
        expect(
          CycleRealmGate.meetsRealmGate(
            cycle: 2,
            playerMaxTier: RealmTier.yiLiu,
            baseEnemyMaxTier: RealmTier.sanLiu,
            ra: ra,
          ),
          isTrue,
        );
        expect(
          CycleRealmGate.meetsRealmGate(
            cycle: 2,
            playerMaxTier: RealmTier.erLiu,
            baseEnemyMaxTier: RealmTier.sanLiu,
            ra: ra,
          ),
          isFalse,
        );
      },
    );

    test('推进 clamp 武圣后再减 margin（sanLiu 敌 cycle3 名义 +6 越顶 → 按武圣算门槛）', () {
      // sanLiu(1) + 6 = 7 > wuSheng(6) → clamp 武圣；margin 1 → 须 ≥ zongShi(5)。
      expect(
        CycleRealmGate.meetsRealmGate(
          cycle: 3,
          playerMaxTier: RealmTier.zongShi,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        isTrue,
      );
      expect(
        CycleRealmGate.meetsRealmGate(
          cycle: 3,
          playerMaxTier: RealmTier.jueDing,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        isFalse,
      );
    });
  });

  group('unlockedCycleCap', () {
    test('未通 cycle1 → cap 1（顺序解锁）', () {
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 0,
          playerMaxTier: RealmTier.wuSheng,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        1,
      );
    });

    test('通 cycle1 + 境界够 → cap 2；通 cycle2 + 境界够 → cap 3', () {
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 1,
          playerMaxTier: RealmTier.wuSheng,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        2,
      );
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 2,
          playerMaxTier: RealmTier.wuSheng,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        3,
      );
    });

    test('通 cycle1 但境界不够 → 仍 cap 1（境界门槛截断）', () {
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 1,
          playerMaxTier: RealmTier.sanLiu,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        1,
      );
    });

    test('cap 封顶 maxCycle（cleared 溢出也不越界）', () {
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 99,
          playerMaxTier: RealmTier.wuSheng,
          baseEnemyMaxTier: RealmTier.sanLiu,
          ra: ra,
        ),
        3,
      );
    });

    test('empty 配置 → cap 恒 1（fixture 零回归）', () {
      expect(
        CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: 5,
          playerMaxTier: RealmTier.wuSheng,
          baseEnemyMaxTier: RealmTier.xueTu,
          ra: RealmAdvanceConfig.empty,
        ),
        1,
      );
    });
  });

  group('expeditionClearedEquivalent（深度里程碑折算）', () {
    test('深度 < 首里程碑 → 0；≥[0] → 1；≥[1] → 2；里程碑单调消费', () {
      expect(
        CycleRealmGate.expeditionClearedEquivalent(
          maxDepth: 19,
          milestones: ra.expeditionDepthMilestones,
        ),
        0,
      );
      expect(
        CycleRealmGate.expeditionClearedEquivalent(
          maxDepth: 20,
          milestones: ra.expeditionDepthMilestones,
        ),
        1,
      );
      expect(
        CycleRealmGate.expeditionClearedEquivalent(
          maxDepth: 40,
          milestones: ra.expeditionDepthMilestones,
        ),
        2,
      );
    });

    test('空里程碑表 → 恒 0（远征不开高周目）', () {
      expect(
        CycleRealmGate.expeditionClearedEquivalent(
          maxDepth: 999,
          milestones: const [],
        ),
        0,
      );
    });
  });

  group('maxEnemyTierOf', () {
    test('取敌集最高境界；空集返学徒', () {
      final enemies = [
        EnemyDef.fromYaml({
          'id': 'e1',
          'name': '甲',
          'realmTier': 'sanLiu',
          'realmLayer': 'qiMeng',
          'school': 'gangMeng',
          'baseHp': 100,
          'baseAttack': 10,
          'baseSpeed': 100,
          'skillIds': const <String>[],
          'iconPath': 'assets/enemies/thug_a.png',
        }),
        EnemyDef.fromYaml({
          'id': 'e2',
          'name': '乙',
          'realmTier': 'erLiu',
          'realmLayer': 'qiMeng',
          'school': 'gangMeng',
          'baseHp': 100,
          'baseAttack': 10,
          'baseSpeed': 100,
          'skillIds': const <String>[],
          'iconPath': 'assets/enemies/thug_a.png',
        }),
      ];
      expect(CycleRealmGate.maxEnemyTierOf(enemies), RealmTier.erLiu);
      expect(CycleRealmGate.maxEnemyTierOf(const []), RealmTier.xueTu);
    });
  });
}
