import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/player_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'player_combatant_skill_loadout_test_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'loadExactRoster preserves autoFill seven-slot loadout and numeric positions',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();

      final snapshots = await PlayerCombatantSnapshotAssembler(
        isar: IsarSetup.instance,
      ).loadExactRoster(const [1]);
      final snapshot = snapshots.single;
      final character = (await IsarSetup.instance.characters.get(1))!;

      final loadout = snapshot.skillLoadout;
      expect(loadout.basicAttack?.type, SkillType.normalAttack);
      expect(loadout.basicAttack?.parentTechniqueDefId, isNotNull);
      expect(loadout.main1?.id, character.mainSkillId1);
      expect(loadout.main2?.id, character.mainSkillId2);
      expect(loadout.assist?.id, character.assistSkillId);
      expect(loadout.resonance?.id, character.resonanceSkillId);
      expect(loadout.ultimate?.id, character.ultimateSkillId);
      expect(loadout.encounter?.id, character.equippedEncounterSkillId);
      expect(loadout.key?.id, character.keySkillId);

      final expectedIds = <String?>[
        character.mainSkillId1,
        character.mainSkillId2,
        character.assistSkillId,
        character.resonanceSkillId,
        character.ultimateSkillId,
        character.equippedEncounterSkillId,
        character.keySkillId,
      ];
      for (final id in expectedIds.whereType<String>()) {
        expect(
          snapshot.availableSkills.any((skill) => skill.id == id),
          isTrue,
          reason: 'non-empty loadout slot must resolve to the same SkillDef id',
        );
      }

      expect(
        CombatantSkillLoadout.numericSlots,
        orderedEquals([
          CombatantSkillSlot.main1,
          CombatantSkillSlot.main2,
          CombatantSkillSlot.assist,
          CombatantSkillSlot.resonance,
          CombatantSkillSlot.ultimate,
          CombatantSkillSlot.encounter,
        ]),
        reason:
            'empty slots must remain positional; numeric slots cannot compress',
      );
    },
  );
}
