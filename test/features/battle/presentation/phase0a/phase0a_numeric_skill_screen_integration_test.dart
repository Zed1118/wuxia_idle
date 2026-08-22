import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_skill_seals.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async => repo = await loadTestGameRepository());

  testWidgets('数字键与鼠标技能印同路释放真实 SkillDef，空槽 fail-closed', (tester) async {
    final numbers = repo.numbers;
    final basic = repo.getSkill('skill_gangmeng_jichu_basic');
    final main = repo.getSkill('skill_gangmeng_jichu_skill');
    final ultimate = repo.getSkill('skill_gangmeng_jichu_ult');
    final snapshot = testCombatantSnapshot(
      characterId: 1,
      name: '数字技能祖师',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 15000,
      internalForce: 600,
      maxQi: 100,
      speed: 100,
      criticalRate: numbers.combat.critical.baseRate,
      evasionRate: 0,
      defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
      totalEquipmentAttack: 130,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: [basic, main, ultimate],
      skillLoadout: CombatantSkillLoadout(
        basicAttack: basic,
        main1: main,
        ultimate: ultimate,
      ),
    );
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_01'),
      playerSnapshot: snapshot,
      numbers: numbers,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: Random(20260820),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final controller = Phase0aBattleController(
      flow: flow,
      roster: Phase0aVisualRoster.fromMapping(mapping),
      fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: false,
          numericSkillBindings: mapping.numericSkillBindings,
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    final keyEvents = controller.step();
    expect(keyEvents.whereType<Phase0aSkillStarted>().single.skillId, main.id);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    final emptyEvents = controller.step();
    expect(emptyEvents.whereType<Phase0aSkillStarted>(), isEmpty);

    await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(5)));
    final clickEvents = controller.step();
    expect(
      clickEvents.whereType<Phase0aSkillStarted>().single.skillId,
      ultimate.id,
    );
  });
}
