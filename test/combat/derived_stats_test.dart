import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/combat/derived_stats.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// RealmUtils 单元测试（phase1_tasks T08）。
///
/// 复用 game_repository_test 的 fileLoader 范式：直接 File IO 加载 data/*.yaml，
/// `flutter test` cwd = 项目根。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  group('RealmUtils.absoluteLevelOf', () {
    test('zongShi/huaJing 是绝对层 41', () {
      expect(
        RealmUtils.absoluteLevelOf(RealmTier.zongShi, RealmLayer.huaJing),
        41,
      );
    });

    test('xueTu/qiMeng 是 1，wuSheng/dengFeng 是 49（首尾边界）', () {
      expect(
        RealmUtils.absoluteLevelOf(RealmTier.xueTu, RealmLayer.qiMeng),
        1,
      );
      expect(
        RealmUtils.absoluteLevelOf(RealmTier.wuSheng, RealmLayer.dengFeng),
        49,
      );
    });
  });

  group('RealmUtils.realmDiffModifier', () {
    test('同大境界 → (1.0, 1.0)', () {
      final m = RealmUtils.realmDiffModifier(RealmTier.yiLiu, RealmTier.yiLiu);
      expect(m.$1, 1.0);
      expect(m.$2, 1.0);
    });

    test('差 1 大境界（高打低）→ (1.4, 0.7)', () {
      final m = RealmUtils.realmDiffModifier(RealmTier.erLiu, RealmTier.sanLiu);
      expect(m.$1, 1.4);
      expect(m.$2, 0.7);
    });

    test('差 1 大境界（低打高，绝对值取 1）→ (1.4, 0.7)', () {
      // 函数返回 yaml 段原值，"高打低用 attacker / 低打高用 defender" 由上层选。
      final m = RealmUtils.realmDiffModifier(RealmTier.sanLiu, RealmTier.erLiu);
      expect(m.$1, 1.4);
      expect(m.$2, 0.7);
    });

    test('差 2 大境界 → (2.5, 0.3)', () {
      final m = RealmUtils.realmDiffModifier(RealmTier.yiLiu, RealmTier.sanLiu);
      expect(m.$1, 2.5);
      expect(m.$2, 0.3);
    });

    test('差 3 大境界（低打高）→ (1.0, 0.05)，attacker 走数据层兜底 1.0', () {
      final m =
          RealmUtils.realmDiffModifier(RealmTier.sanLiu, RealmTier.jueDing);
      expect(m.$1, 1.0,
          reason: 'GDD §5.5：碾压无须放大，attacker=1.0（数据层与公式层语义统一）');
      expect(m.$2, 0.05);
    });

    test('差 6（最大跨距，xueTu vs wuSheng）→ (1.0, 0.05)', () {
      final m =
          RealmUtils.realmDiffModifier(RealmTier.xueTu, RealmTier.wuSheng);
      expect(m.$1, 1.0);
      expect(m.$2, 0.05);
    });
  });

  group('RealmUtils.internalForceMaxOf', () {
    test('xueTu/qiMeng 是 500（红线下限）', () {
      expect(
        RealmUtils.internalForceMaxOf(RealmTier.xueTu, RealmLayer.qiMeng),
        500,
      );
    });

    test('wuSheng/dengFeng = 15000（红线上限，GDD §5.2）', () {
      expect(
        RealmUtils.internalForceMaxOf(RealmTier.wuSheng, RealmLayer.dengFeng),
        15000,
      );
    });
  });

  group('RealmUtils.defenseRateOf', () {
    test('yiLiu = 0.20', () {
      expect(RealmUtils.defenseRateOf(RealmTier.yiLiu), 0.20);
    });

    test('xueTu = 0.05 / wuSheng = 0.35（首尾边界）', () {
      expect(RealmUtils.defenseRateOf(RealmTier.xueTu), 0.05);
      expect(RealmUtils.defenseRateOf(RealmTier.wuSheng), 0.35);
    });
  });

  group('RealmUtils.equipmentTierCapOf', () {
    test('xueTu → xunChang / yiLiu → liQi / wuSheng → shenWu（三系锁死）', () {
      expect(RealmUtils.equipmentTierCapOf(RealmTier.xueTu),
          EquipmentTier.xunChang);
      expect(
          RealmUtils.equipmentTierCapOf(RealmTier.yiLiu), EquipmentTier.liQi);
      expect(RealmUtils.equipmentTierCapOf(RealmTier.wuSheng),
          EquipmentTier.shenWu);
    });
  });

  group('RealmUtils.maxEnhanceLevelOf', () {
    test('强化等级上限 = absoluteLevel', () {
      final c = Character.create(
        name: '测试',
        realmTier: RealmTier.zongShi,
        realmLayer: RealmLayer.huaJing,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(RealmUtils.maxEnhanceLevelOf(c), 41);
    });

    test('xueTu/qiMeng 角色强化等级上限 = 1', () {
      final c = Character.create(
        name: '新人',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.yongCai,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(RealmUtils.maxEnhanceLevelOf(c), 1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // T09 · CharacterDerivedStats
  // ────────────────────────────────────────────────────────────────────────

  group('CharacterDerivedStats.maxHp（5 战例公式实现验证）', () {
    test('战例 A：xueTu/qiMeng 山贼 内力500/根骨5/装备0 → 3850', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        internalForce: 500,
        constitution: 5,
      );
      expect(CharacterDerivedStats.maxHp(c, [], n), 3850);
    });

    test('战例 B：erLiu/yuanShu 内力3000/根骨6/装备血500 → 6600', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.erLiu,
        layer: RealmLayer.yuanShu,
        internalForce: 3000,
        constitution: 6,
      );
      final eq = _mkEquip(baseHealth: 500);
      expect(CharacterDerivedStats.maxHp(c, [eq], n), 6600);
      // numbers.yaml validation_examples.b/c 的 max_hp 注释已对齐公式真实值
      // (b=6600, c=6180)，由清账冲刺修正；公式实现保持权威。
    });

    test('战例 C：erLiu/ruMen 内力2400/根骨6/装备血500 → 6180', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.erLiu,
        layer: RealmLayer.ruMen,
        internalForce: 2400,
        constitution: 6,
      );
      final eq = _mkEquip(baseHealth: 500);
      expect(CharacterDerivedStats.maxHp(c, [eq], n), 6180);
      // numbers.yaml 已修正 expected=6180 与公式对齐。
    });

    test('战例 D：yiLiu/qiMeng 内力3800/根骨6/装备血1100 → 7760', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.yiLiu,
        layer: RealmLayer.qiMeng,
        internalForce: 3800,
        constitution: 6,
      );
      final eq = _mkEquip(baseHealth: 1100);
      expect(CharacterDerivedStats.maxHp(c, [eq], n), 7760);
    });

    test('战例 E：wuSheng/dengFeng 内力15000/根骨10/装备血3000 → 19500（≤红线 20000）', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.dengFeng,
        internalForce: 15000,
        constitution: 10,
      );
      final eq = _mkEquip(baseHealth: 3000);
      final hp = CharacterDerivedStats.maxHp(c, [eq], n);
      expect(hp, 19500);
      expect(hp, lessThanOrEqualTo(20000), reason: 'GDD §5.2 玩家血量红线');
    });
  });

  group('CharacterDerivedStats.speed', () {
    test('base 100 + 身法10*8 + 装备速度0 + ruMenGong speed_bonus 0 = 180', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        internalForce: 500,
        agility: 10,
      );
      final tech = _mkTech(tier: TechniqueTier.ruMenGong);
      expect(CharacterDerivedStats.speed(c, [], tech, n), 180);
    });

    test('mingJiaGong 主修 → +10 速度（speed_bonus 来自 yaml techniques.tiers）', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.erLiu,
        layer: RealmLayer.yuanShu,
        internalForce: 3000,
        agility: 10,
      );
      final tech = _mkTech(tier: TechniqueTier.mingJiaGong);
      // 100 + 10*8 + 0 + 10 = 190
      expect(CharacterDerivedStats.speed(c, [], tech, n), 190);
    });

    test('chuanShuoShenGong 主修 → +60 速度（武圣最高阶）', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.dengFeng,
        internalForce: 15000,
        agility: 10,
      );
      final tech = _mkTech(tier: TechniqueTier.chuanShuoShenGong);
      // 100 + 80 + 0 + 60 = 240
      expect(CharacterDerivedStats.speed(c, [], tech, n), 240);
    });
  });

  group('CharacterDerivedStats.criticalRate', () {
    test('身法 5 / 无流派 → 0.05 + 5*0.005 = 0.075', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        internalForce: 500,
        agility: 5,
      );
      expect(CharacterDerivedStats.criticalRate(c, n), closeTo(0.075, 1e-9));
    });

    test('身法 5 / 灵巧流派 → 0.05+0.025+0.20 = 0.275', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        internalForce: 500,
        agility: 5,
        school: TechniqueSchool.lingQiao,
      );
      expect(CharacterDerivedStats.criticalRate(c, n), closeTo(0.275, 1e-9));
    });

    test('身法 100 + 灵巧流派 → clamp 到 max_rate 0.50（不能超）', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.dengFeng,
        internalForce: 15000,
        agility: 100,
        school: TechniqueSchool.lingQiao,
      );
      // 0.05 + 100*0.005 + 0.20 = 0.75 → clamp 0.50
      expect(CharacterDerivedStats.criticalRate(c, n), 0.50);
    });
  });

  group('CharacterDerivedStats.evasionRate', () {
    test('身法 5 → 0.015', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        internalForce: 500,
        agility: 5,
      );
      expect(CharacterDerivedStats.evasionRate(c, n), closeTo(0.015, 1e-9));
    });

    test('身法 100 → clamp 到 max_rate 0.30', () {
      final n = GameRepository.instance.numbers;
      final c = _mkChar(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.dengFeng,
        internalForce: 15000,
        agility: 100,
      );
      // 100*0.003 = 0.30 刚好等于上限
      expect(CharacterDerivedStats.evasionRate(c, n), 0.30);
    });
  });

  group('CharacterDerivedStats.effectiveEquipmentAttack', () {
    test('+0 强化 / 共鸣生疏 / 无开锋 → baseAttack（无意外加成，验收 §508）', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(baseAttack: 130);
      expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 130);
    });

    test('+10 强化 / 共鸣生疏 / 无开锋 → 100 × 1.5 = 150', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(baseAttack: 100, enhanceLevel: 10);
      expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 150);
    });

    test('+10 强化 / 共鸣趁手 1.10 → 100 × 1.5 × 1.10 = 165', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(
        baseAttack: 100,
        enhanceLevel: 10,
        battleCount: 200, // chenShou 阶段
      );
      expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 165);
    });

    test('+10 强化 / 共鸣趁手 / 开锋 attack 15% → 100×1.5×1.10×1.15 = 189', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(
        baseAttack: 100,
        enhanceLevel: 10,
        battleCount: 200,
        forgingSlots: [
          ForgingSlot()
            ..slotIndex = 1
            ..unlocked = true
            ..type = ForgingSlotType.attack
            ..bonusValue = 15,
          ForgingSlot()..slotIndex = 2,
          ForgingSlot()..slotIndex = 3,
        ],
      );
      // 100 * 1.5 * 1.10 * 1.15 = 189.75 → toInt = 189
      expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 189);
    });

    test('未 unlocked 的开锋槽位不计加成', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(
        baseAttack: 100,
        forgingSlots: [
          ForgingSlot()
            ..slotIndex = 1
            ..unlocked = false // 没解锁
            ..type = ForgingSlotType.attack
            ..bonusValue = 15,
          ForgingSlot()..slotIndex = 2,
          ForgingSlot()..slotIndex = 3,
        ],
      );
      expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 100);
    });
  });

  group('CharacterDerivedStats.effectiveEquipmentHp / Speed', () {
    test('Hp 应用强化倍率：+10 强化 / 共鸣生疏 → 200 × 1.5 = 300', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(baseHealth: 200, enhanceLevel: 10);
      expect(CharacterDerivedStats.effectiveEquipmentHp(eq, n), 300);
    });

    test('Speed +0 无开锋 → baseSpeed', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(baseSpeed: 30);
      expect(CharacterDerivedStats.effectiveEquipmentSpeed(eq, n), 30);
    });

    test('Speed +10 强化 + 速度开锋 20% → 30 × 1.5 × 1.0 × 1.20 = 54', () {
      final n = GameRepository.instance.numbers;
      final eq = _mkEquip(
        baseSpeed: 30,
        enhanceLevel: 10,
        forgingSlots: [
          ForgingSlot()
            ..slotIndex = 1
            ..unlocked = true
            ..type = ForgingSlotType.speed
            ..bonusValue = 20,
          ForgingSlot()..slotIndex = 2,
          ForgingSlot()..slotIndex = 3,
        ],
      );
      // 30 * 1.5 * 1.0 * 1.20 = 54
      expect(CharacterDerivedStats.effectiveEquipmentSpeed(eq, n), 54);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 测试辅助：构造 Character / Equipment / Technique 的最小 fixture
// ─────────────────────────────────────────────────────────────────────────────

Character _mkChar({
  required RealmTier tier,
  required RealmLayer layer,
  required int internalForce,
  int constitution = 5,
  int enlightenment = 5,
  int agility = 5,
  int fortune = 5,
  TechniqueSchool? school,
}) {
  final attrs = Attributes()
    ..constitution = constitution
    ..enlightenment = enlightenment
    ..agility = agility
    ..fortune = fortune;
  return Character.create(
    name: '测试',
    realmTier: tier,
    realmLayer: layer,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: internalForce,
    school: school,
  );
}

Equipment _mkEquip({
  int baseAttack = 0,
  int baseHealth = 0,
  int baseSpeed = 0,
  int enhanceLevel = 0,
  int battleCount = 0,
  List<ForgingSlot>? forgingSlots,
}) {
  return Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: baseAttack,
    baseHealth: baseHealth,
    baseSpeed: baseSpeed,
    enhanceLevel: enhanceLevel,
    battleCount: battleCount,
    forgingSlots: forgingSlots,
  );
}

Technique _mkTech({required TechniqueTier tier}) {
  return Technique.create(
    defId: 'test_tech',
    ownerCharacterId: 1,
    tier: tier,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
  );
}
