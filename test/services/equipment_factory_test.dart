import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/services/equipment_factory.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T19 EquipmentFactory + Rng 验收（phase2_tasks T19 §159-184）。
void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // 测试用 def：覆盖 weapon / armor / accessory 三种 slot 的特征
  // ────────────────────────────────────────────────────────────────────────────

  EquipmentDef weaponDef() => const EquipmentDef(
        id: 'test_weapon_qing_feng',
        name: '青锋',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.weapon,
        schoolBias: TechniqueSchool.lingQiao,
        baseAttackMin: 320,
        baseAttackMax: 450,
        baseHealthMin: 0,
        baseHealthMax: 100,
        baseSpeedMin: 10,
        baseSpeedMax: 30,
        presetLoreIds: [],
        dropSourceTags: [],
        iconPath: '',
      );

  EquipmentDef armorDef() => const EquipmentDef(
        id: 'test_armor_jin_pao',
        name: '锦袍',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.armor,
        // armor 无攻击：min == max == 0
        baseAttackMin: 0,
        baseAttackMax: 0,
        baseHealthMin: 450,
        baseHealthMax: 750,
        baseSpeedMin: 5,
        baseSpeedMax: 15,
        presetLoreIds: [],
        dropSourceTags: [],
        iconPath: '',
      );

  EquipmentDef accessoryDef() => const EquipmentDef(
        id: 'test_accessory_yu_pei',
        name: '玉佩',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.accessory,
        baseAttackMin: 20,
        baseAttackMax: 40,
        baseHealthMin: 50,
        baseHealthMax: 100,
        baseSpeedMin: 0,
        baseSpeedMax: 8,
        presetLoreIds: [],
        dropSourceTags: [],
        iconPath: '',
      );

  final t = DateTime(2026, 5, 11);

  // ────────────────────────────────────────────────────────────────────────────
  // 1. 确定性：同种子两次生成结果完全一致
  // ────────────────────────────────────────────────────────────────────────────

  test('Rng 同种子注入 → 同一 def 两次生成 baseAttack/Health/Speed 完全一致', () {
    final eq1 = EquipmentFactory.fromDef(
      weaponDef(),
      rng: DefaultRng(seed: 42),
      obtainedAt: t,
      obtainedFrom: '掉落',
    );
    final eq2 = EquipmentFactory.fromDef(
      weaponDef(),
      rng: DefaultRng(seed: 42),
      obtainedAt: t,
      obtainedFrom: '掉落',
    );

    expect(eq1.baseAttack, eq2.baseAttack);
    expect(eq1.baseHealth, eq2.baseHealth);
    expect(eq1.baseSpeed, eq2.baseSpeed);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 2. 蒙特卡洛 100 次：weapon 三项均落区间内
  // ────────────────────────────────────────────────────────────────────────────

  test('weapon 100 次 roll：baseAttack/Health/Speed 全部落 [min, max] 闭区间', () {
    final rng = DefaultRng(seed: 1);
    final def = weaponDef();
    for (var i = 0; i < 100; i++) {
      final eq = EquipmentFactory.fromDef(
        def,
        rng: rng,
        obtainedAt: t,
        obtainedFrom: '掉落',
      );
      expect(eq.baseAttack, inInclusiveRange(def.baseAttackMin, def.baseAttackMax),
          reason: 'baseAttack 越界');
      expect(eq.baseHealth, inInclusiveRange(def.baseHealthMin, def.baseHealthMax),
          reason: 'baseHealth 越界');
      expect(eq.baseSpeed, inInclusiveRange(def.baseSpeedMin, def.baseSpeedMax),
          reason: 'baseSpeed 越界');
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 3. armor slot：attack_min=attack_max=0 时返回恒 0
  // ────────────────────────────────────────────────────────────────────────────

  test('armor 100 次 roll：baseAttack 恒 0（min==max==0），其余落区间', () {
    final rng = DefaultRng(seed: 2);
    final def = armorDef();
    for (var i = 0; i < 100; i++) {
      final eq = EquipmentFactory.fromDef(
        def,
        rng: rng,
        obtainedAt: t,
        obtainedFrom: '掉落',
      );
      expect(eq.baseAttack, 0);
      expect(eq.baseHealth, inInclusiveRange(def.baseHealthMin, def.baseHealthMax));
      expect(eq.baseSpeed, inInclusiveRange(def.baseSpeedMin, def.baseSpeedMax));
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 4. accessory slot：三项都非 0 范围
  // ────────────────────────────────────────────────────────────────────────────

  test('accessory roll：三项均落区间，slot/tier 字段镜像 def', () {
    final eq = EquipmentFactory.fromDef(
      accessoryDef(),
      rng: DefaultRng(seed: 3),
      obtainedAt: t,
      obtainedFrom: '商店',
    );
    expect(eq.slot, EquipmentSlot.accessory);
    expect(eq.tier, EquipmentTier.xunChang);
    expect(eq.school, isNull);
    expect(eq.baseAttack, inInclusiveRange(20, 40));
    expect(eq.baseHealth, inInclusiveRange(50, 100));
    expect(eq.baseSpeed, inInclusiveRange(0, 8));
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 5. forgingSlots 长度恒为 3，索引 1/2/3
  // ────────────────────────────────────────────────────────────────────────────

  test('forgingSlots 长度恒为 3，索引按 1/2/3 排列且全部 unlocked=false', () {
    final eq = EquipmentFactory.fromDef(
      weaponDef(),
      rng: DefaultRng(seed: 4),
      obtainedAt: t,
      obtainedFrom: '掉落',
    );
    expect(eq.forgingSlots, hasLength(3));
    expect(eq.forgingSlots.map((s) => s.slotIndex).toList(), [1, 2, 3]);
    expect(eq.forgingSlots.every((s) => !s.unlocked), isTrue);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 6. 默认初始字段：enhanceLevel=0 / battleCount=0 / lores 空
  // ────────────────────────────────────────────────────────────────────────────

  test('默认初始字段：enhanceLevel/battleCount=0，lores/previousOwnerIds 为空', () {
    final eq = EquipmentFactory.fromDef(
      weaponDef(),
      rng: DefaultRng(seed: 5),
      obtainedAt: t,
      obtainedFrom: '奇遇',
    );
    expect(eq.enhanceLevel, 0);
    expect(eq.battleCount, 0);
    expect(eq.lores, isEmpty);
    expect(eq.previousOwnerCharacterIds, isEmpty);
    expect(eq.isLineageHeritage, isFalse);
    expect(eq.ownerCharacterId, isNull);
    expect(eq.obtainedAt, t);
    expect(eq.obtainedFrom, '奇遇');
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 7. 可选参数：师承遗物标记 + 初始持有者
  // ────────────────────────────────────────────────────────────────────────────

  test('可选参数：传 isLineageHeritage / ownerCharacterId 正确设置', () {
    final eq = EquipmentFactory.fromDef(
      weaponDef(),
      rng: DefaultRng(seed: 6),
      obtainedAt: t,
      obtainedFrom: '师承',
      ownerCharacterId: 7,
      isLineageHeritage: true,
    );
    expect(eq.isLineageHeritage, isTrue);
    expect(eq.ownerCharacterId, 7);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 8. fail-fast：min > max 抛 StateError
  // ────────────────────────────────────────────────────────────────────────────

  test('fail-fast：baseAttackMin > baseAttackMax 抛 StateError', () {
    const badDef = EquipmentDef(
      id: 'bad_atk_range',
      name: 'X',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 200,
      baseAttackMax: 100, // < min
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 10,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: '',
    );
    expect(
      () => EquipmentFactory.fromDef(
        badDef,
        rng: DefaultRng(seed: 7),
        obtainedAt: t,
        obtainedFrom: '掉落',
      ),
      throwsA(isA<StateError>()),
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 9. 边界：min == max 直接返回该值（不走 nextInt）
  // ────────────────────────────────────────────────────────────────────────────

  test('边界：min == max 时返回固定值，与种子无关', () {
    const fixedDef = EquipmentDef(
      id: 'fixed',
      name: 'X',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.accessory,
      baseAttackMin: 100,
      baseAttackMax: 100,
      baseHealthMin: 50,
      baseHealthMax: 50,
      baseSpeedMin: 5,
      baseSpeedMax: 5,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: '',
    );
    for (final seed in [0, 1, 99, 12345]) {
      final eq = EquipmentFactory.fromDef(
        fixedDef,
        rng: DefaultRng(seed: seed),
        obtainedAt: t,
        obtainedFrom: '商店',
      );
      expect(eq.baseAttack, 100);
      expect(eq.baseHealth, 50);
      expect(eq.baseSpeed, 5);
    }
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 10. Rng.pick：等概率从 list 选元素，空 list 抛 ArgumentError
  // ────────────────────────────────────────────────────────────────────────────

  test('Rng.pick：从非空 list 取元素 / 空 list 抛 ArgumentError', () {
    final rng = DefaultRng(seed: 8);
    final list = ['a', 'b', 'c'];
    final picked = rng.pick(list);
    expect(list, contains(picked));

    expect(() => DefaultRng().pick(<int>[]), throwsArgumentError);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 11. T55：def.isLineageHeritage 透传到 Equipment.isLineageHeritage
  // ────────────────────────────────────────────────────────────────────────────

  group('T55 · isLineageHeritage 透传', () {
    EquipmentDef heritageDef() => const EquipmentDef(
          id: 'test_heritage_weapon',
          name: '传家剑',
          tier: EquipmentTier.liQi,
          slot: EquipmentSlot.weapon,
          baseAttackMin: 500,
          baseAttackMax: 500,
          baseHealthMin: 0,
          baseHealthMax: 0,
          baseSpeedMin: 30,
          baseSpeedMax: 30,
          presetLoreIds: [],
          dropSourceTags: [],
          iconPath: '',
          isLineageHeritage: true,
        );

    test('def.isLineageHeritage=true → Equipment.isLineageHeritage=true（参数不传）',
        () {
      final eq = EquipmentFactory.fromDef(
        heritageDef(),
        rng: DefaultRng(seed: 1),
        obtainedAt: t,
        obtainedFrom: 'master_starting',
      );
      expect(eq.isLineageHeritage, isTrue);
    });

    test('def.isLineageHeritage=false → 参数 isLineageHeritage=true 仍生效（override）',
        () {
      // 普通 def + 调用方强制标遗物（如奇遇赠送的临时遗物路径）
      final eq = EquipmentFactory.fromDef(
        weaponDef(),
        rng: DefaultRng(seed: 1),
        obtainedAt: t,
        obtainedFrom: 'encounter_grant',
        isLineageHeritage: true,
      );
      expect(eq.isLineageHeritage, isTrue);
    });

    test('def.isLineageHeritage=false + 参数缺省 → Equipment.isLineageHeritage=false',
        () {
      final eq = EquipmentFactory.fromDef(
        weaponDef(),
        rng: DefaultRng(seed: 1),
        obtainedAt: t,
        obtainedFrom: '掉落',
      );
      expect(eq.isLineageHeritage, isFalse);
    });
  });
}
