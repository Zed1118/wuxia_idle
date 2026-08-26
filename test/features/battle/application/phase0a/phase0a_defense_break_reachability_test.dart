import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';

import '../../../../support/isar_test_support.dart';
import '../../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'phase0a_defense_break_reachability_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    'senior defense-break autoFill reaches Phase 0A numeric binding',
    () async {
      final isar = IsarSetup.instance;
      late int seniorId;
      await isar.writeTxn(() async {
        final senior = Character.create(
          name: 'senior reachability fixture',
          realmTier: RealmTier.sanLiu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes()
            ..constitution = 5
            ..enlightenment = 5
            ..agility = 5
            ..fortune = 5,
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.senior,
          createdAt: DateTime(2026, 8, 26),
          school: TechniqueSchool.gangMeng,
          internalForce: 500,
          internalForceMax: 500,
        );
        seniorId = await isar.characters.put(senior);
        final technique = Technique.create(
          defId: 'tech_gangmeng_changlian',
          ownerCharacterId: seniorId,
          tier: TechniqueTier.changLianGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 8, 26),
          cultivationLayer: CultivationLayer.xiaoCheng,
        );
        senior.mainTechniqueId = await isar.techniques.put(technique);
        await isar.characters.put(senior);
      });

      final player = (await PlayerCombatantSnapshotAssembler(
        isar: isar,
      ).loadExactRoster([seniorId])).single;
      expect(
        repository.getSkill('skill_gangmeng_changlian_skill').defenseBreakPct,
        0.30,
      );
      expect(
        player.skillLoadout.ids,
        contains('skill_gangmeng_changlian_skill'),
      );
      final defenseBreakNumericSlots = CombatantSkillLoadout.numericSlots.where(
        (slot) {
          final skill = player.skillLoadout.skillFor(slot);
          return skill != null && skill.defenseBreakPct != 0;
        },
      );

      expect(defenseBreakNumericSlots, hasLength(1));
      expect(
        player.skillLoadout.skillFor(defenseBreakNumericSlots.single)?.id,
        'skill_gangmeng_changlian_skill',
      );

      // Known defect: the real senior autoFill result reaches a Phase 0A numeric
      // slot, whose binding rejects defenseBreakPct because the reducer has no
      // state consumer. Keep reproducing until the user chooses a disposition.
      expect(
        () => Phase0aStageContentMapper.map(
          stage: repository.getStage('stage_01_01'),
          playerSnapshot: player,
          numbers: repository.numbers,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(
              'skill_gangmeng_changlian_skill: defenseBreak/qiDrain '
              '尚无 reducer 状态消费方',
            ),
          ),
        ),
      );
    },
  );
}
