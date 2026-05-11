import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/combat/derived_stats.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/forging_slot.dart';

/// T22 装备战斗加成整合验收（phase2_tasks T22 §253-275）。
///
/// 5 战例（A-E）覆盖完整链路：基础 → 强化 → 强化+共鸣+开锋 → 满级 → 师承内力上限。
/// 公式：`final = baseAttack × (1 + enhanceLevel × 0.05) × resonanceBonus × (1 + forgePct)`
void main() {
  setUp(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  tearDown(GameRepository.resetForTest);

  Equipment newEq({
    required int baseAttack,
    int enhanceLevel = 0,
    int battleCount = 0,
    bool isLineageHeritage = false,
    List<ForgingSlot>? forgingSlots,
  }) =>
      Equipment.create(
        defId: 'test',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.weapon,
        baseAttack: baseAttack,
        baseHealth: 0,
        baseSpeed: 10,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
        isLineageHeritage: isLineageHeritage,
        obtainedAt: DateTime(2026, 5, 11),
        obtainedFrom: 'test',
        forgingSlots: forgingSlots,
      );

  ForgingSlot openSlot({
    required int slotIndex,
    required ForgingSlotType type,
    required int bonusValue,
  }) =>
      ForgingSlot()
        ..slotIndex = slotIndex
        ..type = type
        ..unlocked = true
        ..bonusValue = bonusValue;

  // ────────────────────────────────────────────────────────────────────────────
  // 战例 A：+0 裸装 → baseAttack 即为最终值
  // ────────────────────────────────────────────────────────────────────────────

  test('战例 A：+0 裸装 baseAttack=400 → effective=400', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(baseAttack: 400);
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 400);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 战例 B：+12 强化 → ×1.60
  // ────────────────────────────────────────────────────────────────────────────

  test('战例 B：+12 强化 baseAttack=400 → 640 (×1.60)', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(baseAttack: 400, enhanceLevel: 12);
    // 400 × (1 + 12*0.05) = 400 × 1.60 = 640
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 640);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 战例 C：+19 强化 → ×1.95
  // ────────────────────────────────────────────────────────────────────────────

  test('战例 C：+19 强化 baseAttack=400 → 780 (×1.95)', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(baseAttack: 400, enhanceLevel: 19);
    // 400 × (1 + 19*0.05) = 400 × 1.95 = 780
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 780);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 战例 D：+49 满强化 → ×3.45
  // ────────────────────────────────────────────────────────────────────────────

  test('战例 D：+49 满强化 baseAttack=400 → 1380 (×3.45)', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(baseAttack: 400, enhanceLevel: 49);
    // 400 × (1 + 49*0.05) = 400 × 3.45 = 1380
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 1380);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 战例 E：全栈 +12 + 满共鸣（默契 ×1.20）+ 开锋 attack 槽 1 (+15%)
  // ────────────────────────────────────────────────────────────────────────────

  test('战例 E：+12 + 默契共鸣 + 开锋 attack 槽 1 (+15%) → 883', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(
      baseAttack: 400,
      enhanceLevel: 12,
      battleCount: 1500, // 默契段 [500, 2000)
      forgingSlots: [
        openSlot(
          slotIndex: 1,
          type: ForgingSlotType.attack,
          bonusValue: 15,
        ),
        ForgingSlot()..slotIndex = 2,
        ForgingSlot()..slotIndex = 3,
      ],
    );
    // 400 × 1.60 × 1.20 × (1 + 0.15) = 768 × 1.15 = 883.2 → 883
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 883);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 边界 1：开锋 attack 槽 1 + 槽 2 双开（15% + 20% = 35%）
  // ────────────────────────────────────────────────────────────────────────────

  test('边界 1：双开 attack 槽 1+2 (15%+20%=35%) → 540', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(
      baseAttack: 400,
      forgingSlots: [
        openSlot(slotIndex: 1, type: ForgingSlotType.attack, bonusValue: 15),
        openSlot(slotIndex: 2, type: ForgingSlotType.attack, bonusValue: 20),
        ForgingSlot()..slotIndex = 3,
      ],
    );
    // 400 × 1.0 × 1.0 × (1 + 0.35) = 540
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 540);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 边界 2：未开锋的槽不计入（unlocked=false）
  // ────────────────────────────────────────────────────────────────────────────

  test('边界 2：未开锋的槽即使有 type/bonusValue 也不计入', () {
    final n = GameRepository.instance.numbers;
    final eq = newEq(
      baseAttack: 400,
      forgingSlots: [
        ForgingSlot()
          ..slotIndex = 1
          ..type = ForgingSlotType.attack
          ..unlocked = false // 关键：未解锁
          ..bonusValue = 100,
        ForgingSlot()..slotIndex = 2,
        ForgingSlot()..slotIndex = 3,
      ],
    );
    expect(CharacterDerivedStats.effectiveEquipmentAttack(eq, n), 400);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 师承 1：基础内力上限 10000 + 4 件师承遗物 → ×1.20 = 12000
  // ────────────────────────────────────────────────────────────────────────────

  test('师承内力 1：基础 10000 + 4 件师承遗物 → 12000 (×1.20)', () {
    final n = GameRepository.instance.numbers;
    final ch = Character.create(
      name: 'X',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.yuanShu,
      attributes: Attributes()..constitution = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForceMax: 10000,
    );
    final equipped = [
      newEq(baseAttack: 100, isLineageHeritage: true),
      newEq(baseAttack: 100, isLineageHeritage: true),
      newEq(baseAttack: 100, isLineageHeritage: true),
      newEq(baseAttack: 100, isLineageHeritage: true),
    ];
    expect(
      CharacterDerivedStats.internalForceMaxWithLineage(ch, equipped, n),
      12000,
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 师承 2：0 件师承 → 内力上限不变
  // ────────────────────────────────────────────────────────────────────────────

  test('师承内力 2：无师承遗物 → 内力上限保持基础 10000', () {
    final n = GameRepository.instance.numbers;
    final ch = Character.create(
      name: 'X',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.yuanShu,
      attributes: Attributes()..constitution = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForceMax: 10000,
    );
    final equipped = [
      newEq(baseAttack: 100, isLineageHeritage: false),
    ];
    expect(
      CharacterDerivedStats.internalForceMaxWithLineage(ch, equipped, n),
      10000,
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 师承 3：1 件师承 → +5% = 10500
  // ────────────────────────────────────────────────────────────────────────────

  test('师承内力 3：1 件师承遗物 → 10500 (×1.05)', () {
    final n = GameRepository.instance.numbers;
    final ch = Character.create(
      name: 'X',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.yuanShu,
      attributes: Attributes()..constitution = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForceMax: 10000,
    );
    final equipped = [
      newEq(baseAttack: 100, isLineageHeritage: true),
    ];
    expect(
      CharacterDerivedStats.internalForceMaxWithLineage(ch, equipped, n),
      10500,
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 配置：lineageInternalForceMaxBonus 与 yaml 一致 (0.05)
  // ────────────────────────────────────────────────────────────────────────────

  test('NumbersConfig.lineageInternalForceMaxBonus = 0.05', () {
    final n = GameRepository.instance.numbers;
    expect(n.lineageInternalForceMaxBonus, 0.05);
  });
}
