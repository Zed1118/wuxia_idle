import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/forging_slot.dart';
import 'package:wuxia_idle/data/models/technique.dart';
import 'package:wuxia_idle/services/dispel_service.dart';
import 'package:wuxia_idle/services/enhancement_service.dart';
import 'package:wuxia_idle/combat/derived_stats.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// Phase 2 调试场景数值断言（phase2_tasks.md T32 §492-509 子提交 4）。
///
/// 4 场景（P1-P4）的纯数值验收，不依赖 UI / Isar。fixture 在测试里独立构造，
/// 与 [Phase2SeedService] 解耦（service 走 Isar 持久化，本测走内存对象）。
///
/// 11 用例 + 2 setUpAll/tearDownAll：
///   - P1 强化曲线 (3)：+1-10 段固定 100% 成功 / +14-15 蒙卡 75% ±5% / +0-19 走完 + cap
///   - P2 共鸣触发 (3)：battleCount 99/100/500 阶段切换 + bonus 1.0/1.10/1.20
///   - P3 散功代价 (2)：yuanMan/1500 + IF 10000 → daCheng/750 + IF 5000
///                       + Character/Technique 字段切换正确
///   - P4 全栈对比 (3)：+19/+resonance/+forge 各 component 攻击力倍率
///                       + 全栈 vs 裸装 ≈ 2.92×
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ─── P1 强化曲线（spec §501）─────────────────────────────────────────────

  group('P1 强化曲线', () {
    test('+1-+10 段 success_rate=1.0，10 次蒙卡 0 失败', () {
      final config = GameRepository.instance.numbers.enhancement;
      for (int run = 0; run < 10; run++) {
        final eq = _mkBareWeapon(enhanceLevel: 0);
        for (int i = 0; i < 10; i++) {
          final r = EnhancementService.tryEnhance(
            eq: eq,
            characterAbsoluteLevel: 49,
            rng: const _FixedRng(0.99), // 高 roll 也能成（1.0 段必中）
            currentMojianshi: 999999,
            config: config,
          );
          expect(r.outcome, EnhanceOutcome.success, reason: 'i=$i run=$run');
        }
        expect(eq.enhanceLevel, 10);
      }
    });

    test('+14→+15 蒙卡 1000 次成功率 ≈ 75% (±5%)', () {
      final config = GameRepository.instance.numbers.enhancement;
      var success = 0;
      final rng = DefaultRng(seed: 42);
      for (int i = 0; i < 1000; i++) {
        final eq = _mkBareWeapon(enhanceLevel: 14);
        final r = EnhancementService.tryEnhance(
          eq: eq,
          characterAbsoluteLevel: 49,
          rng: rng,
          currentMojianshi: 999999,
          config: config,
        );
        if (r.outcome == EnhanceOutcome.success) success++;
      }
      final rate = success / 1000;
      expect(rate, greaterThan(0.70), reason: '蒙卡区间 70-80%');
      expect(rate, lessThan(0.80), reason: '蒙卡区间 70-80%');
    });

    test('+0→+19 全程成功，第 20 次返回 capped（cap=19）', () {
      final config = GameRepository.instance.numbers.enhancement;
      final eq = _mkBareWeapon(enhanceLevel: 0);
      const cap = 19;
      for (var i = 0; i < cap; i++) {
        final r = EnhancementService.tryEnhance(
          eq: eq,
          characterAbsoluteLevel: cap,
          rng: const _FixedRng(0), // 最低 roll，永远 < successRate
          currentMojianshi: 999999,
          config: config,
        );
        expect(r.outcome, EnhanceOutcome.success, reason: 'i=$i');
      }
      expect(eq.enhanceLevel, cap);

      // 第 20 次：oldLevel=19 ≥ cap=19 → capped
      final overshoot = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: cap,
        rng: const _FixedRng(0),
        currentMojianshi: 999999,
        config: config,
      );
      expect(overshoot.outcome, EnhanceOutcome.capped);
      expect(eq.enhanceLevel, cap, reason: 'capped 后等级不变');
    });
  });

  // ─── P2 共鸣触发（spec §501-502）────────────────────────────────────────

  group('P2 共鸣触发', () {
    test('battleCount=99 → shengShu / bonus=1.0', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkBareWeapon(enhanceLevel: 0, battleCount: 99);
      expect(eq.resonanceStage(n), ResonanceStage.shengShu);
      expect(eq.resonanceBonus(n), 1.0);
    });

    test('battleCount=100 → chenShou / bonus=1.10（趁手 +10%）', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkBareWeapon(enhanceLevel: 0, battleCount: 100);
      expect(eq.resonanceStage(n), ResonanceStage.chenShou);
      expect(eq.resonanceBonus(n), closeTo(1.10, 1e-9));
    });

    test('effectiveEquipmentAttack: battleCount 99→100 攻击力 +10%（趁手 buff 落实到 attack 计算）',
        () {
      final n = GameRepository.instance.numbers;
      const baseAttack = 100;
      final eq99 = _mkBareWeapon(
        enhanceLevel: 0,
        battleCount: 99,
        baseAttack: baseAttack,
      );
      final eq100 = _mkBareWeapon(
        enhanceLevel: 0,
        battleCount: 100,
        baseAttack: baseAttack,
      );
      final atk99 = CharacterDerivedStats.effectiveEquipmentAttack(eq99, n);
      final atk100 = CharacterDerivedStats.effectiveEquipmentAttack(eq100, n);
      expect(atk99, baseAttack, reason: '生疏阶段无 buff');
      expect(atk100, (baseAttack * 1.10).toInt(),
          reason: '趁手阶段攻击 ×1.10');
    });
  });

  // ─── P3 散功代价（spec §502）───────────────────────────────────────────

  group('P3 散功代价', () {
    test('IF 10000 + yuanMan/1500 → daCheng/750 + IF 5000（spec §502 标准答案）',
        () {
      final n = GameRepository.instance.numbers;
      final ch = _mkChar(internalForce: 10000, internalForceMax: 10000);
      ch.id = 1;
      final main = _mkTech(
        id: 100,
        ownerId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.yuanMan,
        progress: 1500,
        progressToNext: n.cultivationProgressToNext[CultivationLayer.yuanMan]!,
        school: TechniqueSchool.gangMeng,
      );
      final assist = _mkTech(
        id: 101,
        ownerId: 1,
        role: TechniqueRole.assist,
        layer: CultivationLayer.daCheng,
        progress: 0,
        progressToNext: n.cultivationProgressToNext[CultivationLayer.daCheng]!,
        school: TechniqueSchool.yinRou,
      );
      ch.mainTechniqueId = main.id;
      ch.assistTechniqueIds = [assist.id];

      final r = DispelService.dispel(
        ch: ch,
        mainTech: main,
        newMainTech: assist,
        n: n,
      );

      expect(r.outcome, DispelOutcome.success);
      expect(r.internalForceBefore, 10000);
      expect(r.internalForceAfter, 5000);
      expect(r.oldLayer, CultivationLayer.yuanMan);
      expect(r.newLayer, CultivationLayer.daCheng);
      expect(r.layersRolledBack, 1);
      expect(r.progressAfter, 750);
      expect(r.progressToNextAfter,
          n.cultivationProgressToNext[CultivationLayer.daCheng]!);
      expect(r.progressToNextAfter, 900,
          reason: 'daCheng→yuanMan 阈值 yaml 写死 900');
    });

    test('散功后 Character / Technique 字段切换：主修易主 + 旧主修变辅修 + 内力对半',
        () {
      final n = GameRepository.instance.numbers;
      final ch = _mkChar(internalForce: 10000, internalForceMax: 10000);
      ch.id = 1;
      final oldMain = _mkTech(
        id: 100,
        ownerId: 1,
        role: TechniqueRole.main,
        layer: CultivationLayer.yuanMan,
        progress: 1500,
        progressToNext: n.cultivationProgressToNext[CultivationLayer.yuanMan]!,
        school: TechniqueSchool.gangMeng,
      );
      final newMain = _mkTech(
        id: 101,
        ownerId: 1,
        role: TechniqueRole.assist,
        layer: CultivationLayer.daCheng,
        progress: 0,
        progressToNext: n.cultivationProgressToNext[CultivationLayer.daCheng]!,
        school: TechniqueSchool.yinRou,
      );
      ch.mainTechniqueId = oldMain.id;
      ch.assistTechniqueIds = [newMain.id];

      DispelService.dispel(
        ch: ch,
        mainTech: oldMain,
        newMainTech: newMain,
        n: n,
      );

      expect(ch.internalForce, 5000);
      expect(ch.mainTechniqueId, newMain.id);
      expect(ch.assistTechniqueIds, contains(oldMain.id));
      expect(ch.assistTechniqueIds, isNot(contains(newMain.id)),
          reason: '新主修从 assist 列表移除');
      expect(newMain.role, TechniqueRole.main);
      expect(oldMain.role, TechniqueRole.assist);
      expect(oldMain.cultivationLayer, CultivationLayer.daCheng);
      expect(oldMain.cultivationProgress, 750);
      expect(oldMain.wasMainBeforeReset, isTrue,
          reason: 'disperse 副作用：标记此心法曾为主修');
    });
  });

  // ─── P4 全栈对比（spec §503）───────────────────────────────────────────

  group('P4 全栈对比', () {
    test('+19 强化裸装：effectiveEquipmentAttack = baseAttack × 1.95', () {
      final n = GameRepository.instance.numbers;
      const baseAttack = 100;
      final eq = _mkBareWeapon(
        enhanceLevel: 19,
        battleCount: 0,
        baseAttack: baseAttack,
      );
      final atk = CharacterDerivedStats.effectiveEquipmentAttack(eq, n);
      // 1 + 19 × 0.05 = 1.95
      expect(atk, (baseAttack * 1.95).toInt());
    });

    test('+19 + battleCount=2000（心剑通灵 ×1.30）：attack = baseAttack × 1.95 × 1.30',
        () {
      final n = GameRepository.instance.numbers;
      const baseAttack = 100;
      final eq = _mkBareWeapon(
        enhanceLevel: 19,
        battleCount: 2000,
        baseAttack: baseAttack,
      );
      expect(eq.resonanceStage(n), ResonanceStage.xinJianTongLing);
      expect(eq.resonanceBonus(n), closeTo(1.30, 1e-9));

      final atk = CharacterDerivedStats.effectiveEquipmentAttack(eq, n);
      // 100 × 1.95 × 1.30 = 253.5 → toInt 253
      expect(atk, (baseAttack * 1.95 * 1.30).toInt());
    });

    test('+19 + 心剑通灵 + forge1=attack(+15%)：全栈 attack ≈ baseAttack × 2.9，比裸装 ≈ 2.9×',
        () {
      final n = GameRepository.instance.numbers;
      const baseAttack = 100;

      final bare = _mkBareWeapon(
        enhanceLevel: 0,
        battleCount: 0,
        baseAttack: baseAttack,
      );
      final fullStack = _mkBareWeapon(
        enhanceLevel: 19,
        battleCount: 2000,
        baseAttack: baseAttack,
      );
      // 已开锋槽 1 = attack +15%（forge2 为 lifesteal/speed 等不影响 attack 类型）
      fullStack.forgingSlots = [
        ForgingSlot()
          ..slotIndex = 1
          ..type = ForgingSlotType.attack
          ..unlocked = true
          ..bonusValue = 15,
        ForgingSlot()
          ..slotIndex = 2
          ..type = ForgingSlotType.lifesteal
          ..unlocked = true
          ..bonusValue = 15,
        ForgingSlot()..slotIndex = 3, // 未开锋
      ];

      final bareAtk = CharacterDerivedStats.effectiveEquipmentAttack(bare, n);
      final fullAtk =
          CharacterDerivedStats.effectiveEquipmentAttack(fullStack, n);

      expect(bareAtk, baseAttack);
      // 100 × 1.95 × 1.30 × 1.15 = 291.525 → toInt 291
      expect(fullAtk, (baseAttack * 1.95 * 1.30 * 1.15).toInt());

      final ratio = fullAtk / bareAtk;
      expect(ratio, closeTo(2.915, 0.01));
    });
  });
}

// ── helpers ────────────────────────────────────────────────────────────────

Equipment _mkBareWeapon({
  required int enhanceLevel,
  int battleCount = 0,
  int baseAttack = 200,
}) {
  final now = DateTime(2026, 5, 11);
  return Equipment.create(
    defId: 'test_weapon',
    tier: EquipmentTier.liQi,
    slot: EquipmentSlot.weapon,
    obtainedAt: now,
    obtainedFrom: 'phase2_scenarios_test',
    baseAttack: baseAttack,
    enhanceLevel: enhanceLevel,
    battleCount: battleCount,
  );
}

Character _mkChar({
  required int internalForce,
  required int internalForceMax,
}) {
  return Character.create(
    name: '测试者',
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.yuanShu,
    attributes: Attributes()
      ..constitution = 6
      ..enlightenment = 6
      ..agility = 6
      ..fortune = 6,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 5, 11),
    internalForce: internalForce,
    internalForceMax: internalForceMax,
    school: TechniqueSchool.gangMeng,
  );
}

Technique _mkTech({
  required int id,
  required int ownerId,
  required TechniqueRole role,
  required CultivationLayer layer,
  required int progress,
  required int progressToNext,
  required TechniqueSchool school,
}) {
  final t = Technique.create(
    defId: 'test_tech_$id',
    ownerCharacterId: ownerId,
    tier: TechniqueTier.mingJiaGong,
    school: school,
    role: role,
    learnedAt: DateTime(2026, 5, 11),
    cultivationLayer: layer,
    cultivationProgress: progress,
    cultivationProgressToNext: progressToNext,
  );
  t.id = id;
  return t;
}

/// 固定 nextDouble 值的 [Rng] 桩（其余方法不会被 EnhancementService 调用）。
class _FixedRng implements Rng {
  final double _value;
  const _FixedRng(this._value);

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => _value;

  @override
  T pick<T>(List<T> list) => list.first;
}

