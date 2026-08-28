import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_skill_seals.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
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
          numericSkillBindings: mapping.playerAdapter.numericSkillBindings,
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

  for (final school in TechniqueSchool.values) {
    testWidgets('${school.name} 数字技能真实路径渲染起手与命中非透明像素', (tester) async {
      final skillStem = switch (school) {
        TechniqueSchool.gangMeng => 'gangmeng',
        TechniqueSchool.lingQiao => 'lingqiao',
        TechniqueSchool.yinRou => 'yinrou',
      };
      final numbers = repo.numbers;
      final basic = repo.getSkill('skill_${skillStem}_jichu_basic');
      final main = repo.getSkill('skill_${skillStem}_jichu_skill');
      final snapshot = testCombatantSnapshot(
        characterId: 1,
        name: '${school.name}渲染证据',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        school: school,
        maxHp: 15000,
        internalForce: 600,
        maxQi: 100,
        speed: 100,
        criticalRate: numbers.combat.critical.baseRate,
        evasionRate: 0,
        defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
        totalEquipmentAttack: 130,
        mainCultivationLayer: CultivationLayer.chuKui,
        availableSkills: [basic, main],
        skillLoadout: CombatantSkillLoadout(basicAttack: basic, main1: main),
      );
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: snapshot,
        numbers: numbers,
      );
      expect(
        mapping.playerAdapter.numericSkillBindings.one?.visualSchool,
        school,
      );
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260827 + school.index),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      final controller = Phase0aBattleController(
        flow: flow,
        roster: Phase0aVisualRoster.fromMapping(mapping),
        fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      );
      addTearDown(controller.dispose);

      final binding = mapping.playerAdapter.numericSkillBindings.one!;
      var targetInRange = false;
      for (var tick = 0; tick < 1200; tick++) {
        targetInRange = controller.state.enemies.any(
          (enemy) =>
              (enemy.position - controller.state.player.position).length <=
              binding.attackRange,
        );
        if (targetInRange ||
            controller.outcome != Phase0aBattleOutcome.ongoing) {
          break;
        }
        controller.step();
      }
      expect(targetInRange, isTrue, reason: '生产流必须先推进到敌人进入技能射程');
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            autoStep: false,
            numericSkillBindings: mapping.playerAdapter.numericSkillBindings,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      final events = controller.step();
      expect(events.whereType<Phase0aSkillStarted>(), hasLength(1));
      final applied = events.whereType<Phase0aSkillApplied>().single;
      expect(applied.outcomes, isNotEmpty);
      expect(
        controller.feedback.map((entry) => entry.kind),
        containsAll([Phase0aVfxKind.skillCast, Phase0aVfxKind.skillImpact]),
      );
      await tester.pump(const Duration(milliseconds: 80));

      final renderProofs =
          <({String phase, Size size, CustomPainter painter})>[];
      for (final phase in ['cast', 'impact']) {
        final keyPrefix = 'phase0a_skill_${phase}_${school.name}_paint_';
        final paintFinder = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.key is ValueKey &&
              (widget.key! as ValueKey).value.toString().startsWith(keyPrefix),
        );
        expect(
          paintFinder,
          findsOneWidget,
          reason: '$school $phase 必须进入真实 CustomPaint 渲染分支',
        );
        final size = tester.getSize(paintFinder);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));

        // 直接取真实屏幕节点携带的 painter，在独立透明画布复绘并检查
        // alpha；既验证生产 widget 非零尺寸，也能让空 painter 破坏变红。
        final painter = tester.widget<CustomPaint>(paintFinder).painter;
        expect(painter, isNotNull);
        renderProofs.add((phase: phase, size: size, painter: painter!));
      }

      // 先取齐两个真实节点再做异步图片编码；编码期间战斗 ticker 可继续
      // 走时，但不应让第二段证据因自然过期而从 widget tree 消失。
      for (final proof in renderProofs) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        proof.painter.paint(canvas, proof.size);
        final picture = recorder.endRecording();
        final bytes = await tester.runAsync(() async {
          final image = await picture.toImage(
            proof.size.width.ceil(),
            proof.size.height.ceil(),
          );
          picture.dispose();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return data;
        });
        expect(bytes, isNotNull);
        var paintedPixels = 0;
        for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
          if (bytes.getUint8(offset) != 0) paintedPixels++;
        }
        expect(
          paintedPixels,
          greaterThan(0),
          reason: '$school ${proof.phase} painter 不得退化为空画布',
        );
      }
    });
  }
}
