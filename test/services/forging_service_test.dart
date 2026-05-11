import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/services/forging_service.dart';

/// T21 ForgingService 验收（phase2_tasks T21 §225-247）。
void main() {
  late ForgingConfig cfg;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    cfg = repo.numbers.forging;
  });

  Equipment newEq({int enhanceLevel = 0}) => Equipment.create(
        defId: 'test',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.weapon,
        baseAttack: 100,
        baseHealth: 0,
        baseSpeed: 10,
        enhanceLevel: enhanceLevel,
        obtainedAt: DateTime(2026, 5, 11),
        obtainedFrom: 'test',
      );

  EquipmentDef defWith({List<String> candidates = const []}) => EquipmentDef(
        id: 'test',
        name: '测试装',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.weapon,
        baseAttackMin: 100,
        baseAttackMax: 100,
        baseHealthMin: 0,
        baseHealthMax: 0,
        baseSpeedMin: 10,
        baseSpeedMax: 10,
        presetLoreIds: const [],
        dropSourceTags: const [],
        iconPath: '',
        specialSkillCandidates: candidates,
      );

  // ────────────────────────────────────────────────────────────────────────────
  // ForgingConfig 解析
  // ────────────────────────────────────────────────────────────────────────────

  group('ForgingConfig', () {
    test('3 槽 unlock 等级 = 10 / 15 / 19', () {
      expect(cfg.slotByIndex(1).unlockAtEnhanceLevel, 10);
      expect(cfg.slotByIndex(2).unlockAtEnhanceLevel, 15);
      expect(cfg.slotByIndex(3).unlockAtEnhanceLevel, 19);
    });

    test('槽 1/2 可选 attack/speed/lifesteal/pierce；槽 3 仅 specialSkill', () {
      expect(
        cfg.slotByIndex(1).availableTypes,
        containsAll([
          ForgingSlotType.attack,
          ForgingSlotType.speed,
          ForgingSlotType.lifesteal,
          ForgingSlotType.pierce,
        ]),
      );
      expect(cfg.slotByIndex(3).availableTypes, [ForgingSlotType.specialSkill]);
    });

    test('槽 2 excludePreviousSlotType=true（yaml constraint 字段）', () {
      expect(cfg.slotByIndex(1).excludePreviousSlotType, isFalse);
      expect(cfg.slotByIndex(2).excludePreviousSlotType, isTrue);
    });

    test('bonus_value：槽 1 attack=15，槽 2 attack=20', () {
      expect(cfg.slotByIndex(1).bonusValue[ForgingSlotType.attack], 15);
      expect(cfg.slotByIndex(2).bonusValue[ForgingSlotType.attack], 20);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // availableTypesForSlot
  // ────────────────────────────────────────────────────────────────────────────

  group('availableTypesForSlot', () {
    test('+9 时槽 1 锁定，返回空', () {
      final eq = newEq(enhanceLevel: 9);
      expect(
        ForgingService.availableTypesForSlot(
          eq: eq,
          slotIndex: 1,
          config: cfg,
        ),
        isEmpty,
      );
    });

    test('+10 时槽 1 解锁，返回 4 个类型', () {
      final eq = newEq(enhanceLevel: 10);
      final types = ForgingService.availableTypesForSlot(
        eq: eq,
        slotIndex: 1,
        config: cfg,
      );
      expect(types, hasLength(4));
    });

    test('+15 时槽 2 解锁，但槽 1 已选 attack → 槽 2 排除 attack', () {
      final eq = newEq(enhanceLevel: 15);
      // 模拟槽 1 已开锋为 attack
      ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      final types = ForgingService.availableTypesForSlot(
        eq: eq,
        slotIndex: 2,
        config: cfg,
      );
      expect(types, isNot(contains(ForgingSlotType.attack)));
      expect(types, contains(ForgingSlotType.speed));
      expect(types, hasLength(3));
    });

    test('槽 1 未开锋时槽 2 不排除任何类型', () {
      final eq = newEq(enhanceLevel: 15);
      final types = ForgingService.availableTypesForSlot(
        eq: eq,
        slotIndex: 2,
        config: cfg,
      );
      expect(types, hasLength(4));
    });

    test('+19 时槽 3 解锁，仅 specialSkill', () {
      final eq = newEq(enhanceLevel: 19);
      final types = ForgingService.availableTypesForSlot(
        eq: eq,
        slotIndex: 3,
        config: cfg,
      );
      expect(types, [ForgingSlotType.specialSkill]);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // forge
  // ────────────────────────────────────────────────────────────────────────────

  group('forge', () {
    test('+10 时槽 1 开 attack，bonusValue=15 写入', () {
      final eq = newEq(enhanceLevel: 10);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      expect(r, ForgeResult.success);
      expect(eq.forgingSlots[0].unlocked, isTrue);
      expect(eq.forgingSlots[0].type, ForgingSlotType.attack);
      expect(eq.forgingSlots[0].bonusValue, 15);
    });

    test('+9 时尝试开槽 1 → slotNotUnlocked', () {
      final eq = newEq(enhanceLevel: 9);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      expect(r, ForgeResult.slotNotUnlocked);
      expect(eq.forgingSlots[0].unlocked, isFalse);
    });

    test('已开锋的槽再开 → alreadyForged，不覆盖', () {
      final eq = newEq(enhanceLevel: 10);
      ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.speed,
        config: cfg,
      );
      expect(r, ForgeResult.alreadyForged);
      expect(eq.forgingSlots[0].type, ForgingSlotType.attack); // 仍是 attack
    });

    test('槽 2 选与槽 1 相同类型 → typeNotAvailable', () {
      final eq = newEq(enhanceLevel: 15);
      ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 1,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 2,
        type: ForgingSlotType.attack,
        config: cfg,
      );
      expect(r, ForgeResult.typeNotAvailable);
    });

    test('槽 3 specialSkill 但 specialSkillId=null → missingSpecialSkillId', () {
      final eq = newEq(enhanceLevel: 19);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(candidates: ['skill_a']),
        slotIndex: 3,
        type: ForgingSlotType.specialSkill,
        config: cfg,
      );
      expect(r, ForgeResult.missingSpecialSkillId);
    });

    test('槽 3 specialSkill 但 def.specialSkillCandidates 为空 → noSpecialSkillCandidates', () {
      final eq = newEq(enhanceLevel: 19);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(),
        slotIndex: 3,
        type: ForgingSlotType.specialSkill,
        specialSkillId: 'skill_a',
        config: cfg,
      );
      expect(r, ForgeResult.noSpecialSkillCandidates);
    });

    test('槽 3 specialSkill id 不在 candidates 中 → invalidSpecialSkillId', () {
      final eq = newEq(enhanceLevel: 19);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(candidates: ['skill_a']),
        slotIndex: 3,
        type: ForgingSlotType.specialSkill,
        specialSkillId: 'skill_b',
        config: cfg,
      );
      expect(r, ForgeResult.invalidSpecialSkillId);
    });

    test('槽 3 specialSkill id 在 candidates 中 → success，specialSkillId 写入', () {
      final eq = newEq(enhanceLevel: 19);
      final r = ForgingService.forge(
        eq: eq,
        def: defWith(candidates: ['skill_a', 'skill_b']),
        slotIndex: 3,
        type: ForgingSlotType.specialSkill,
        specialSkillId: 'skill_b',
        config: cfg,
      );
      expect(r, ForgeResult.success);
      expect(eq.forgingSlots[2].specialSkillId, 'skill_b');
      expect(eq.forgingSlots[2].type, ForgingSlotType.specialSkill);
    });

    test('全栈：+19 装备依次开 1=attack / 2=speed / 3=specialSkill', () {
      final eq = newEq(enhanceLevel: 19);
      final def = defWith(candidates: ['skill_a']);
      expect(
        ForgingService.forge(
          eq: eq,
          def: def,
          slotIndex: 1,
          type: ForgingSlotType.attack,
          config: cfg,
        ),
        ForgeResult.success,
      );
      expect(
        ForgingService.forge(
          eq: eq,
          def: def,
          slotIndex: 2,
          type: ForgingSlotType.speed,
          config: cfg,
        ),
        ForgeResult.success,
      );
      expect(
        ForgingService.forge(
          eq: eq,
          def: def,
          slotIndex: 3,
          type: ForgingSlotType.specialSkill,
          specialSkillId: 'skill_a',
          config: cfg,
        ),
        ForgeResult.success,
      );
      expect(eq.forgingSlots.every((s) => s.unlocked), isTrue);
      expect(eq.forgingSlots[0].bonusValue, 15);
      expect(eq.forgingSlots[1].bonusValue, 20);
    });
  });
}
