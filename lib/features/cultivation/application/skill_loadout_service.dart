import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

enum SkillSlot { main1, main2, assist, resonance, ultimate, key }

sealed class EquipSlotResult {
  const EquipSlotResult();
}

class SlotEquipSucceeded extends EquipSlotResult {
  const SlotEquipSucceeded();
}

class SlotEquipTierLocked extends EquipSlotResult {
  const SlotEquipTierLocked();
}

class SlotEquipNotFound extends EquipSlotResult {
  const SlotEquipNotFound();
}

/// 波A:破招槽 style gate 失败(非 canInterrupt 招,或 style 与角色流派不符)。
class SlotEquipStyleLocked extends EquipSlotResult {
  const SlotEquipStyleLocked();
}

/// 技能装配持久化（P1b）。装配 gate = SkillDef.canEquipAtRealm（§5.3 三系锁死）。
class SkillLoadoutService {
  final Isar _isar;
  SkillLoadoutService(this._isar);

  Future<EquipSlotResult> equipSkill({
    required int characterId,
    required SkillSlot slot,
    required String skillId,
  }) async {
    final repo = GameRepository.instance;
    final def = repo.skillDefs[skillId];
    if (def == null) return const SlotEquipNotFound();
    EquipSlotResult result = const SlotEquipSucceeded();
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) {
        result = const SlotEquipNotFound();
        return;
      }
      if (!def.canEquipAtRealm(c.realmTier)) {
        result = const SlotEquipTierLocked();
        return;
      }
      // 波A 破招槽 gate:只能装 canInterrupt && style == 角色流派 的破招技。
      if (slot == SkillSlot.key &&
          (!def.canInterrupt || def.style == null || def.style != c.school)) {
        result = const SlotEquipStyleLocked();
        return;
      }
      _writeSlot(c, slot, skillId);
      await _isar.characters.put(c);
    });
    return result;
  }

  Future<void> unequipSlot({
    required int characterId,
    required SkillSlot slot,
  }) async {
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) return;
      _writeSlot(c, slot, null);
      await _isar.characters.put(c);
    });
  }

  /// 读角色主/辅修心法招 + joint 解锁态，autoFill 补空槽并落库。
  Future<void> applyAutoFill({
    required int characterId,
    required List<SkillDef> mainTechniqueSkills,
    required List<SkillDef> assistTechniqueSkills,
    required SkillDef? jointSkill,
    required int ultimatePowerThreshold,
    List<SkillDef> interruptSkills = const [],
  }) async {
    await _isar.writeTxn(() async {
      final c = await _isar.characters.get(characterId);
      if (c == null) return;
      final filled = SkillLoadout.autoFill(
        mainTechniqueSkills: mainTechniqueSkills,
        assistTechniqueSkills: assistTechniqueSkills,
        jointSkill: jointSkill,
        realmTier: c.realmTier,
        existing: SkillLoadout.fromCharacter(c),
        ultimatePowerThreshold: ultimatePowerThreshold,
        interruptSkills: interruptSkills,
        school: c.school,
      );
      c.mainSkillId1 = filled.mainSkillId1;
      c.mainSkillId2 = filled.mainSkillId2;
      c.assistSkillId = filled.assistSkillId;
      c.resonanceSkillId = filled.resonanceSkillId;
      c.ultimateSkillId = filled.ultimateSkillId;
      c.keySkillId = filled.keySkillId;
      await _isar.characters.put(c);
    });
  }

  void _writeSlot(Character c, SkillSlot slot, String? id) {
    switch (slot) {
      case SkillSlot.main1:
        c.mainSkillId1 = id;
      case SkillSlot.main2:
        c.mainSkillId2 = id;
      case SkillSlot.assist:
        c.assistSkillId = id;
      case SkillSlot.resonance:
        c.resonanceSkillId = id;
      case SkillSlot.ultimate:
        c.ultimateSkillId = id;
      case SkillSlot.key:
        c.keySkillId = id;
    }
  }
}
