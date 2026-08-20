import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/hp_bar.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import '../../../../support/test_data.dart';

/// Phase 0A debug 战斗屏红测(第七批派单 §测试与证伪 3/4/5):
/// 真实 `Phase0aDebugBattleFixture`(data/phase0a_debug_battle.yaml → 真实
/// assembler → 真实 Phase0aWaveBattleFlow)驱动整屏,禁止 fake flow。
///
/// 契约:
/// - 首屏(1280×720 / 1440×900)所有存活敌人名字/血条常驻,玩家 HUD 有血条
///   与真气条;
/// - 手动 `controller.step()` 后角色屏幕脚点真实移动;
/// - 普攻命中弹出与 `event.resolvedDamage` 完全相同的数字,血条来自 state
///   (= event.remainingHealth),不由 widget 自算;
/// - 玩家远距命中出现掌风轨迹;Q 涡旋且被拉目标离玩家更近;R 径向墨爆且
///   逐非零目标各一个精确伤害数字;
/// - 两波 wave banner 依次出现;打到 victory 后全场唯一终局封签,终局后
///   step 零事件、零新反馈、输入无效;
/// - 键盘 WASD/J/Q/R 与鼠标技能印各至少一条真实通路;
/// - 全程固定拍手动步进,不依赖 pumpAndSettle / 真实计时 / 像素颜色。
void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];

  ValueKey<String> standeeKey(String actorId) =>
      ValueKey<String>('phase0a_standee_$actorId');
  ValueKey<String> hpKey(String actorId) =>
      ValueKey<String>('phase0a_hp_$actorId');
  const playerHudKey = ValueKey('phase0a_player_hud');
  const playerQiKey = ValueKey('phase0a_player_qi');
  const gatherSealKey = ValueKey('phase0a_seal_gather');
  const clearSealKey = ValueKey('phase0a_seal_clear');
  const waveBannerKey = ValueKey('phase0a_wave_banner');
  const outcomeSealKey = ValueKey('phase0a_outcome_seal');
  const meleeSlashKey = ValueKey('phase0a_melee_slash');
  const palmTrailKey = ValueKey('phase0a_palm_trail');
  const gatherVortexKey = ValueKey('phase0a_gather_vortex');
  const clearBurstKey = ValueKey('phase0a_clear_burst');
  const defeatInkKey = ValueKey('phase0a_defeat_ink');
  ValueKey<String> gatherPullKey(String actorId) =>
      ValueKey<String>('phase0a_gather_pull_$actorId');
  ValueKey<String> hitFlashKey(String actorId) =>
      ValueKey<String>('phase0a_hit_flash_$actorId');
  ValueKey<String> hpEmphasisKey(String actorId) =>
      ValueKey<String>('phase0a_hp_emphasis_$actorId');
  ValueKey<String> defeatInkTargetKey(String actorId) =>
      ValueKey<String>('phase0a_defeat_ink_$actorId');

  late Phase0aDebugBattleFixture fixture;
  late Phase0aBattleController controller;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
  });

  tearDown(GameRepository.resetForTest);

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size viewport = const Size(1280, 720),
    bool autoStep = true,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: autoStep),
      ),
    );
    await tester.pump();
  }

  List<Phase0aEvent> step(
    WidgetTester tester, [
    Phase0aPlayerCommand? command,
  ]) {
    if (command != null) controller.enqueue(command);
    final events = controller.step();
    return events;
  }

  Future<List<Phase0aEvent>> stepAndPump(
    WidgetTester tester, [
    Phase0aPlayerCommand? command,
  ]) async {
    final events = step(tester, command);
    await tester.pump();
    return events;
  }

  /// 朝最近存活敌人逼近并普攻;未接敌前移动,接敌后(出现过玩家命中)原地
  /// 普攻,避免贴身压缩远距命中窗口。
  Phase0aPlayerCommand attackTowardNearest(Phase0aArenaState state) {
    if (state.enemies.isEmpty) return const Phase0aPlayerCommand(attack: true);
    final player = state.player.position;
    var nearest = state.enemies.first;
    var best = double.infinity;
    for (final enemy in state.enemies) {
      final dx = enemy.position.x - player.x;
      final dy = enemy.position.y - player.y;
      final dist = dx * dx + dy * dy;
      if (dist < best) {
        best = dist;
        nearest = enemy;
      }
    }
    const eps = 1.0;
    final dx = nearest.position.x - player.x;
    final dy = nearest.position.y - player.y;
    return Phase0aPlayerCommand(
      attack: true,
      right: dx > eps,
      left: dx < -eps,
      down: dy > eps,
      up: dy < -eps,
    );
  }

  double distanceToPlayer(Phase0aArenaState state, String actorId) {
    final enemy = state.enemies.firstWhere((e) => e.id == actorId);
    final dx = enemy.position.x - state.player.position.x;
    final dy = enemy.position.y - state.player.position.y;
    return dx * dx + dy * dy;
  }

  group('首屏常驻 HUD(双视口)', () {
    for (final viewport in viewports) {
      testWidgets(
        '所有存活敌人名字/血条常驻 + 玩家 HUD (${viewport.width}x${viewport.height})',
        (tester) async {
          await pumpScreen(tester, viewport: viewport);

          final state = controller.state;
          expect(state.enemies, isNotEmpty, reason: 'fixture 首波必须有敌人');
          for (final enemy in state.enemies) {
            expect(
              find.byKey(standeeKey(enemy.id)),
              findsOneWidget,
              reason: '存活敌人 ${enemy.id} 立绘常驻',
            );
            expect(
              find.text(fixture.roster.nameOf(enemy.id)),
              findsOneWidget,
              reason: '存活敌人 ${enemy.id} 名称常驻',
            );
            final hpBar = tester.widget<HpBar>(find.byKey(hpKey(enemy.id)));
            expect(hpBar.current, enemy.currentHealth);
            expect(hpBar.max, enemy.maxHealth);
          }

          expect(find.byKey(playerHudKey), findsOneWidget);
          final playerHp = tester.widget<HpBar>(find.byKey(hpKey('player')));
          expect(playerHp.current, state.player.currentHealth);
          expect(playerHp.max, state.player.maxHealth);
          expect(find.byKey(playerQiKey), findsOneWidget);
          expect(find.byKey(gatherSealKey), findsOneWidget);
          expect(find.byKey(clearSealKey), findsOneWidget);
        },
      );
    }
  });

  group('键盘 WASD:手动步进改变屏幕脚点', () {
    testWidgets('D/A/S/W 各一步,玩家立绘屏幕脚点按对应方向移动', (tester) async {
      await pumpScreen(tester);

      final cases =
          <
            (
              LogicalKeyboardKey,
              double Function(Offset before, Offset after),
              String,
            )
          >[
            (
              LogicalKeyboardKey.keyD,
              (before, after) => after.dx - before.dx,
              'D 右移',
            ),
            (
              LogicalKeyboardKey.keyA,
              (before, after) => before.dx - after.dx,
              'A 左移',
            ),
            (
              LogicalKeyboardKey.keyS,
              (before, after) => after.dy - before.dy,
              'S 下移(y 越大越靠前)',
            ),
            (
              LogicalKeyboardKey.keyW,
              (before, after) => before.dy - after.dy,
              'W 上移',
            ),
          ];

      for (final (key, delta, label) in cases) {
        final before = tester.getCenter(find.byKey(standeeKey('player')));
        await tester.sendKeyEvent(key);
        final expectedDuration = Duration(
          microseconds:
              (controller.fixedDeltaSeconds * Duration.microsecondsPerSecond)
                  .round(),
        );
        step(tester);
        await tester.pump();
        await tester.pump(expectedDuration ~/ 2);
        final middle = tester.getCenter(find.byKey(standeeKey('player')));
        expect(
          delta(before, middle),
          greaterThan(0),
          reason: '$label:隐式动画中间帧必须朝目标移动',
        );
        await tester.pump(expectedDuration ~/ 2);
        final after = tester.getCenter(find.byKey(standeeKey('player')));
        expect(
          delta(before, after),
          greaterThan(0),
          reason: '$label:屏幕脚点必须真实移动',
        );
      }
    });
  });

  group('键盘 J 普攻:伤害数字与 event 精确一致,血条来自 state', () {
    testWidgets('舞台 primary click 入队一次普攻并按点击方向瞄准', (tester) async {
      await pumpScreen(tester);
      final stage = Phase0aStage(viewport: const Size(1280, 720));
      final player = stage.worldToScreen(controller.state.player.position);
      final target = player + const Offset(240, -80);

      await tester.tapAt(target);
      await tester.pump();
      final events = controller.step();
      expect(events.whereType<Phase0aAttackStarted>(), hasLength(1));
      expect(controller.state.player.facing.x, greaterThan(0));
      expect(controller.state.player.facing.y, lessThan(0));
    });

    testWidgets('primary pointer down 持续攻击，pointer up 后停止重复攻击', (tester) async {
      await pumpScreen(tester);
      final stage = Phase0aStage(viewport: const Size(1280, 720));
      final target =
          stage.worldToScreen(controller.state.player.position) +
          const Offset(220, 0);
      final gesture = await tester.startGesture(
        target,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      for (var i = 0; i < 36; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final heldCount = controller.events
          .whereType<Phase0aAttackStarted>()
          .where((event) => event.actor == 'player')
          .length;
      expect(heldCount, greaterThanOrEqualTo(2));

      await gesture.up();
      for (var i = 0; i < 36; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final afterUpCount = controller.events
          .whereType<Phase0aAttackStarted>()
          .where((event) => event.actor == 'player')
          .length;
      expect(afterUpCount, heldCount);
    });

    testWidgets('非 primary、暂停、终局舞台点击均不产生普攻', (tester) async {
      await pumpScreen(tester);
      final stage = Phase0aStage(viewport: const Size(1280, 720));
      final target =
          stage.worldToScreen(controller.state.player.position) +
          const Offset(180, 20);
      final before = controller.events.length;

      // Secondary button must not be interpreted as a basic attack.
      final gesture = await tester.startGesture(
        target,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pump();
      expect(controller.step().whereType<Phase0aAttackStarted>(), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(target);
      await tester.pump();
      expect(controller.step().whereType<Phase0aAttackStarted>(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      for (
        var i = 0;
        i < 300 && controller.outcome == Phase0aBattleOutcome.ongoing;
        i++
      ) {
        controller.step(attackTowardNearest(controller.state));
      }
      expect(controller.outcome, isNot(Phase0aBattleOutcome.ongoing));
      await tester.tapAt(target);
      await tester.pump();
      expect(controller.step().whereType<Phase0aAttackStarted>(), isEmpty);
      expect(controller.events.length, greaterThanOrEqualTo(before));
    });

    testWidgets('点击技能印不额外触发 basic attack，J 仍按 facing 普攻', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(clearSealKey));
      await tester.pump();
      final clearEvents = controller.step();
      expect(clearEvents.whereType<Phase0aClearStarted>(), hasLength(1));
      expect(clearEvents.whereType<Phase0aAttackStarted>(), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      final jEvents = controller.step();
      expect(jEvents.whereType<Phase0aAttackStarted>(), hasLength(1));
      expect(controller.state.player.facing.x, greaterThan(0));
      expect(controller.state.player.facing.y, closeTo(0, 0.001));
    });

    testWidgets('命中弹出 resolvedDamage 原文数字,目标血条 == remainingHealth', (
      tester,
    ) async {
      await pumpScreen(tester);

      Phase0aHitLanded? playerHit;
      for (var i = 0; i < 60 && playerHit == null; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        final events = await stepAndPump(tester);
        for (final event in events.whereType<Phase0aHitLanded>()) {
          if (event.actor == 'player' && event.resolvedDamage > 0) {
            playerHit = event;
          }
        }
      }
      expect(playerHit, isNotNull, reason: '键盘 J 必须真实驱动普攻命中');

      final hit = playerHit!;
      // 伤害数字 == event.resolvedDamage,表现层不得重算/取整/改写。
      expect(find.text('${hit.resolvedDamage}'), findsWidgets);

      // 血条来自 state,且与事件剩余血一致(不由 widget 自算扣血)。
      final targets = controller.state.enemies
          .where((enemy) => enemy.id == hit.target)
          .toList();
      if (targets.isEmpty) {
        expect(hit.remainingHealth, 0);
        expect(find.byKey(hpKey(hit.target)), findsNothing);
      } else {
        final target = targets.single;
        expect(target.currentHealth, hit.remainingHealth);
        final hpBar = tester.widget<HpBar>(find.byKey(hpKey(hit.target)));
        expect(hpBar.current, hit.remainingHealth);
        expect(hpBar.max, target.maxHealth);
      }
    });

    testWidgets('非致死命中短闪白,目标血条强调保持后自动消退', (tester) async {
      await pumpScreen(tester);

      Phase0aHitLanded? survivingHit;
      for (
        var i = 0;
        i < 240 &&
            survivingHit == null &&
            controller.outcome == Phase0aBattleOutcome.ongoing;
        i++
      ) {
        final events = await stepAndPump(
          tester,
          attackTowardNearest(controller.state),
        );
        for (final event in events.whereType<Phase0aHitLanded>()) {
          if (event.actor == 'player' &&
              event.resolvedDamage > 0 &&
              controller.state.enemies.any(
                (enemy) => enemy.id == event.target,
              )) {
            survivingHit = event;
          }
        }
      }

      expect(survivingHit, isNotNull, reason: 'fixture 必须存在一次非致死玩家命中');
      final target = survivingHit!.target;
      expect(find.byKey(hitFlashKey(target)), findsOneWidget);
      expect(find.byKey(hpEmphasisKey(target)), findsOneWidget);

      await tester.pump(
        Duration(
          milliseconds:
              (Phase0aPresentationTokens.hitFlashSeconds * 1000).ceil() + 40,
        ),
      );
      expect(find.byKey(hitFlashKey(target)), findsNothing);
      expect(find.byKey(hpEmphasisKey(target)), findsOneWidget);

      await tester.pump(
        Duration(
          milliseconds:
              ((Phase0aPresentationTokens.hpEmphasisSeconds -
                          Phase0aPresentationTokens.hitFlashSeconds) *
                      1000)
                  .ceil() +
              80,
        ),
      );
      expect(find.byKey(hpEmphasisKey(target)), findsNothing);
    });

    testWidgets('玩家受击时立绘闪白且 HUD 气血条强调', (tester) async {
      await pumpScreen(tester);

      Phase0aHitLanded? playerHit;
      for (var i = 0; i < 120 && playerHit == null; i++) {
        final events = await stepAndPump(tester);
        for (final event in events.whereType<Phase0aHitLanded>()) {
          if (event.target == 'player' && event.resolvedDamage > 0) {
            playerHit = event;
          }
        }
      }

      expect(playerHit, isNotNull, reason: '敌人 AI 必须能真实命中玩家');
      expect(find.byKey(hitFlashKey('player')), findsOneWidget);
      expect(find.byKey(hpEmphasisKey('player')), findsOneWidget);
    });
  });

  group('玩家攻击分型:近战墨痕 / 远程掌风', () {
    testWidgets('整局进攻中两种 VFX 均出现且同拍互斥', (tester) async {
      await pumpScreen(tester);

      var trailSeen = false;
      var slashSeen = false;
      for (
        var i = 0;
        i < 240 &&
            !(trailSeen && slashSeen) &&
            controller.outcome == Phase0aBattleOutcome.ongoing;
        i++
      ) {
        final engaged = controller.feedback.any(
          (e) => e.kind == Phase0aVfxKind.damagePopup,
        );
        final command = engaged
            ? const Phase0aPlayerCommand(attack: true)
            : attackTowardNearest(controller.state);
        await stepAndPump(tester, command);
        if (controller.feedback.any(
          (e) => e.kind == Phase0aVfxKind.palmTrail,
        )) {
          trailSeen = true;
          expect(find.byKey(palmTrailKey), findsOneWidget);
          expect(find.byKey(meleeSlashKey), findsNothing);
        }
        if (controller.feedback.any(
          (e) => e.kind == Phase0aVfxKind.meleeSlash,
        )) {
          slashSeen = true;
          expect(find.byKey(meleeSlashKey), findsOneWidget);
          expect(find.byKey(palmTrailKey), findsNothing);
        }
      }

      expect(trailSeen, isTrue, reason: 'fixture 必含一次玩家远距命中');
      expect(slashSeen, isTrue, reason: 'fixture 必含一次玩家近距命中');
    });
  });

  group('键盘 Q:涡旋 + 拉拢', () {
    testWidgets('Q 产生 gatherVortex,被拉目标离玩家距离变小', (tester) async {
      await pumpScreen(tester);

      final before = controller.state;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      final events = await stepAndPump(tester);

      expect(
        events.whereType<Phase0aGatherStarted>(),
        hasLength(1),
        reason: '键盘 Q 必须真实驱动聚怪',
      );
      final applied = events.whereType<Phase0aGatherApplied>().single;
      final pulled = applied.outcomes
          .where((o) => o.statusApplied == Phase0aSkillStatus.pulled)
          .toList();
      expect(pulled, isNotEmpty, reason: 'fixture 首拍 Q 必须至少拉到一个敌人');

      expect(find.byKey(gatherVortexKey), findsOneWidget);
      final stage = Phase0aStage(viewport: const Size(1280, 720));
      for (final outcome in pulled) {
        final pull = controller.feedback.singleWhere(
          (entry) =>
              entry.kind == Phase0aVfxKind.gatherPull &&
              entry.targetId == outcome.target,
        );
        final screenSource = stage.worldToScreen(pull.source!);
        final screenTarget = stage.worldToScreen(pull.vfxTarget!);
        final expectedMidpoint = Offset(
          (screenSource.dx + screenTarget.dx) / 2,
          (screenSource.dy + screenTarget.dy) / 2,
        );
        expect(find.byKey(gatherPullKey(outcome.target)), findsOneWidget);
        expect(
          (tester.getCenter(find.byKey(gatherPullKey(outcome.target))) -
                  expectedMidpoint)
              .distance,
          lessThan(2),
          reason: 'Q 拉拢轨迹必须绑定目标→玩家的事件位置快照',
        );
        expect(
          distanceToPlayer(controller.state, outcome.target),
          lessThan(distanceToPlayer(before, outcome.target)),
          reason: '被拉目标 ${outcome.target} 必须向玩家拉近',
        );
      }
    });
  });

  group('鼠标 R 技能印:径向墨爆 + 逐目标伤害数字', () {
    testWidgets('点击 clear 印驱动清场,每个非零 outcome 各一个精确伤害数字', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(clearSealKey));
      await tester.pump();
      final events = await stepAndPump(tester);

      expect(
        events.whereType<Phase0aClearStarted>(),
        hasLength(1),
        reason: '鼠标点击 R 印必须真实驱动清场',
      );
      final applied = events.whereType<Phase0aClearApplied>().single;
      expect(applied.outcomes, isNotEmpty);

      expect(find.byKey(clearBurstKey), findsOneWidget);
      final nonZero = applied.outcomes
          .where((o) => o.resolvedDamage > 0)
          .toList();
      expect(nonZero, isNotEmpty, reason: 'fixture 首拍 R 必须打出非零伤害');
      for (final outcome in nonZero) {
        expect(
          find.text('${outcome.resolvedDamage}'),
          findsWidgets,
          reason: '目标 ${outcome.target} 的伤害数字必须等于 outcome.resolvedDamage',
        );
      }
      // 零伤害 outcome 不得产 popup:本帧伤害 popup 数 == 非零 outcome 数。
      final popups = controller.feedback
          .where((e) => e.kind == Phase0aVfxKind.damagePopup)
          .length;
      expect(popups, nonZero.length);
    });
  });

  group('死亡墨散层级', () {
    testWidgets('精英死亡墨散尺寸大于普通敌人且均绑定各自目标', (tester) async {
      await pumpScreen(tester);

      Size? normalSize;
      Size? eliteSize;
      for (
        var i = 0;
        i < 320 &&
            eliteSize == null &&
            controller.outcome == Phase0aBattleOutcome.ongoing;
        i++
      ) {
        final events = await stepAndPump(
          tester,
          attackTowardNearest(controller.state),
        );
        for (final defeated in events.whereType<Phase0aEnemyDefeated>()) {
          final finder = find.byKey(defeatInkTargetKey(defeated.target));
          expect(finder, findsOneWidget);
          final size = tester.getSize(finder);
          if (defeated.defeatKind == Phase0aDefeatKind.elite) {
            eliteSize = size;
          } else {
            normalSize ??= size;
          }
        }
      }

      expect(normalSize, isNotNull, reason: 'fixture 必须击败普通敌人');
      expect(eliteSize, isNotNull, reason: 'fixture 必须击败精英敌人');
      expect(eliteSize!.width, greaterThan(normalSize!.width));
      expect(eliteSize.height, greaterThan(normalSize.height));
    });
  });

  group('波次横幅与唯一终局封签', () {
    testWidgets('两波 banner 依次可见;victory 唯一封签;终局后 step 零反馈', (tester) async {
      await pumpScreen(tester);

      final bannerIndices = <int>[];
      var guard = 0;
      while (controller.outcome == Phase0aBattleOutcome.ongoing &&
          guard < 240) {
        final events = await stepAndPump(
          tester,
          attackTowardNearest(controller.state),
        );
        for (final started in events.whereType<Phase0aWaveStarted>()) {
          bannerIndices.add(started.waveIndex);
          expect(
            find.byKey(waveBannerKey),
            findsOneWidget,
            reason: '第 ${started.waveIndex} 波 banner 必须上屏',
          );
        }
        guard++;
      }

      expect(
        controller.outcome,
        Phase0aBattleOutcome.victory,
        reason: 'debug fixture 必须可用纯进攻打到胜利',
      );
      expect(bannerIndices, [1, 2], reason: '两波 banner 依次出现(1-based)');

      // 全场唯一终局封签。
      expect(find.byKey(outcomeSealKey), findsOneWidget);

      // 终局后:键盘/鼠标输入 + step 均零事件、零新反馈,封签仍唯一。
      final feedbackAtEnd = List<Phase0aVfxEntry>.of(controller.feedback);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.tap(find.byKey(clearSealKey));
      await tester.pump();
      final afterEvents = await stepAndPump(
        tester,
        const Phase0aPlayerCommand(attack: true),
      );
      expect(afterEvents, isEmpty);
      expect(controller.feedback, feedbackAtEnd);
      expect(find.byKey(outcomeSealKey), findsOneWidget);
      expect(find.byKey(gatherVortexKey), findsNothing);
      expect(find.byKey(clearBurstKey), findsNothing);
    });
  });

  group('Phase0aVfxController 坐标快照(Batch 8A)', () {
    /// 容忍度:屏幕坐标与 worldToScreen 预期值的偏差上限(像素)。
    const epsilon = 2.0;

    testWidgets(
      '掌风 VFX 中心 = source/vfxTarget 屏幕连线中点,且不在 safeRect.center (1280x720)',
      (tester) async {
        await pumpScreen(tester, viewport: const Size(1280, 720));
        final stage = Phase0aStage(viewport: const Size(1280, 720));
        final safeCenter = stage.safeRect.center;

        var trailSeen = false;
        for (
          var i = 0;
          i < 240 &&
              !trailSeen &&
              controller.outcome == Phase0aBattleOutcome.ongoing;
          i++
        ) {
          final engaged = controller.feedback.any(
            (e) => e.kind == Phase0aVfxKind.damagePopup,
          );
          final command = engaged
              ? const Phase0aPlayerCommand(attack: true)
              : attackTowardNearest(controller.state);
          await stepAndPump(tester, command);
          if (controller.feedback.any(
            (e) => e.kind == Phase0aVfxKind.palmTrail,
          )) {
            trailSeen = true;
          }
        }

        expect(trailSeen, isTrue, reason: 'fixture 必须产生掌风');
        final palmEntry = controller.feedback.firstWhere(
          (e) => e.kind == Phase0aVfxKind.palmTrail,
        );
        final src = palmEntry.source!;
        final dst = palmEntry.vfxTarget!;
        final screenSrc = stage.worldToScreen(src);
        final screenDst = stage.worldToScreen(dst);
        final expectedCenter = Offset(
          (screenSrc.dx + screenDst.dx) / 2,
          (screenSrc.dy + screenDst.dy) / 2,
        );

        final actualCenter = tester.getCenter(find.byKey(palmTrailKey));
        final actualSize = tester.getSize(find.byKey(palmTrailKey));
        final expectedWidth =
            (screenDst - screenSrc).distance +
            Phase0aPresentationTokens.palmTrailPadding * 2;
        expect(actualSize.width, closeTo(expectedWidth, epsilon));
        expect(
          actualSize.height,
          closeTo(Phase0aPresentationTokens.palmTrailHeight, epsilon),
          reason: '掌风必须是沿命中方向的窄带，不能再使用固定大方形画布',
        );
        expect(
          actualSize.height,
          lessThan(Phase0aPresentationTokens.vfxCenterSize / 2),
        );
        expect(
          (actualCenter - expectedCenter).distance,
          lessThan(epsilon),
          reason: '掌风中心应等于 source/vfxTarget 屏幕连线中点',
        );
        // 旧 Center 实现会把 VFX 放在 safeRect.center,新实现不应。
        expect(
          (actualCenter - safeCenter).distance,
          greaterThan(epsilon * 10),
          reason: '掌风不应在 safeRect.center(旧 Center 实现会通过)',
        );

        final transformFinder = find.ancestor(
          of: find.byKey(palmTrailKey),
          matching: find.byType(Transform),
        );
        expect(transformFinder, findsOneWidget);
        final transform = tester.widget<Transform>(transformFinder);
        final matrix = transform.transform.storage;
        final actualAngle = math.atan2(matrix[1], matrix[0]);
        final expectedAngle = math.atan2(
          screenDst.dy - screenSrc.dy,
          screenDst.dx - screenSrc.dx,
        );
        final angleDelta = math
            .atan2(
              math.sin(actualAngle - expectedAngle),
              math.cos(actualAngle - expectedAngle),
            )
            .abs();
        expect(
          angleDelta,
          lessThan(0.001),
          reason: '掌风旋转角应与 source→vfxTarget 屏幕方向一致',
        );
      },
    );

    testWidgets('伤害数字在独立反馈层上浮淡出并按表现 token 到期移除', (tester) async {
      await pumpScreen(tester, autoStep: false);

      Phase0aHitLanded? hit;
      for (var i = 0; i < 80 && hit == null; i++) {
        final events = await stepAndPump(
          tester,
          attackTowardNearest(controller.state),
        );
        for (final event in events.whereType<Phase0aHitLanded>()) {
          if (event.actor == 'player' && event.resolvedDamage > 0) {
            hit = event;
            break;
          }
        }
      }
      expect(hit, isNotNull);

      final damageFinder = find.text('${hit!.resolvedDamage}').first;
      expect(damageFinder, findsOneWidget);
      final initialCenter = tester.getCenter(damageFinder);
      final initialOpacity = tester.widget<Opacity>(
        find.ancestor(of: damageFinder, matching: find.byType(Opacity)).first,
      );

      final halfLife = Duration(
        microseconds:
            (Phase0aPresentationTokens.damagePopupSeconds *
                    Duration.microsecondsPerSecond /
                    2)
                .round(),
      );
      await tester.pump(halfLife);

      final middleFinder = find.text('${hit.resolvedDamage}').first;
      final middleCenter = tester.getCenter(middleFinder);
      final middleOpacity = tester.widget<Opacity>(
        find.ancestor(of: middleFinder, matching: find.byType(Opacity)).first,
      );
      expect(middleCenter.dy, lessThan(initialCenter.dy));
      expect(middleOpacity.opacity, greaterThan(initialOpacity.opacity));

      await tester.pump(halfLife + const Duration(milliseconds: 1));
      expect(find.text('${hit.resolvedDamage}'), findsNothing);
    });

    testWidgets(
      'Q 涡旋中心 = worldToScreen(anchor),且不在 safeRect.center (1280x720)',
      (tester) async {
        await pumpScreen(tester, viewport: const Size(1280, 720));
        final stage = Phase0aStage(viewport: const Size(1280, 720));
        final safeCenter = stage.safeRect.center;

        await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
        await stepAndPump(tester);

        final vortexEntry = controller.feedback.firstWhere(
          (e) => e.kind == Phase0aVfxKind.gatherVortex,
        );
        final anchor = vortexEntry.anchor!;
        final expectedCenter = stage.worldToScreen(anchor);

        expect(find.byKey(gatherVortexKey), findsOneWidget);
        final actualCenter = tester.getCenter(find.byKey(gatherVortexKey));
        expect(
          (actualCenter - expectedCenter).distance,
          lessThan(epsilon),
          reason: 'Q 涡旋中心应等于 worldToScreen(entry.anchor)',
        );
        // 旧 Center 实现会放在 safeRect.center,新实现不应。
        expect(
          (actualCenter - safeCenter).distance,
          greaterThan(epsilon * 10),
          reason: 'Q 涡旋不应在 safeRect.center(旧 Center 实现会通过)',
        );
      },
    );

    testWidgets(
      'R 墨爆中心 = worldToScreen(anchor),且不在 safeRect.center (1280x720)',
      (tester) async {
        await pumpScreen(tester, viewport: const Size(1280, 720));
        final stage = Phase0aStage(viewport: const Size(1280, 720));
        final safeCenter = stage.safeRect.center;

        await tester.tap(find.byKey(clearSealKey));
        await tester.pump();
        await stepAndPump(tester);

        final burstEntry = controller.feedback.firstWhere(
          (e) => e.kind == Phase0aVfxKind.clearBurst,
        );
        final anchor = burstEntry.anchor!;
        final expectedCenter = stage.worldToScreen(anchor);

        expect(find.byKey(clearBurstKey), findsOneWidget);
        final actualCenter = tester.getCenter(find.byKey(clearBurstKey));
        expect(
          (actualCenter - expectedCenter).distance,
          lessThan(epsilon),
          reason: 'R 墨爆中心应等于 worldToScreen(entry.anchor)',
        );
        expect(
          (actualCenter - safeCenter).distance,
          greaterThan(epsilon * 10),
          reason: 'R 墨爆不应在 safeRect.center(旧 Center 实现会通过)',
        );
      },
    );

    testWidgets('VFX 坐标在 1440x900 视口下不裁切,且不在 safeRect.center', (tester) async {
      await pumpScreen(tester, viewport: const Size(1440, 900));
      final stage = Phase0aStage(viewport: const Size(1440, 900));
      final safeCenter = stage.safeRect.center;

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await stepAndPump(tester);

      final vortexEntry = controller.feedback.firstWhere(
        (e) => e.kind == Phase0aVfxKind.gatherVortex,
      );
      final anchor = vortexEntry.anchor!;
      final expectedCenter = stage.worldToScreen(anchor);

      expect(find.byKey(gatherVortexKey), findsOneWidget);
      final actualCenter = tester.getCenter(find.byKey(gatherVortexKey));
      expect(
        (actualCenter - expectedCenter).distance,
        lessThan(epsilon),
        reason: '1440x900 下涡旋中心应等于 worldToScreen(anchor)',
      );
      expect(
        (actualCenter - safeCenter).distance,
        greaterThan(epsilon * 10),
        reason: '1440x900 下涡旋不应在 safeRect.center',
      );

      // 验证不裁切
      final topLeft = tester.getTopLeft(find.byKey(gatherVortexKey));
      final size = tester.getSize(find.byKey(gatherVortexKey));
      const vpW = 1440.0, vpH = 900.0;
      expect(topLeft.dx, greaterThanOrEqualTo(0));
      expect(topLeft.dy, greaterThanOrEqualTo(0));
      expect(topLeft.dx + size.width, lessThanOrEqualTo(vpW));
      expect(topLeft.dy + size.height, lessThanOrEqualTo(vpH));
    });

    testWidgets('致死伤害数字与死亡墨散保留被移除敌人的事件位置 (1280x720)', (tester) async {
      const viewport = Size(1280, 720);
      await pumpScreen(tester, viewport: viewport);
      final stage = Phase0aStage(viewport: viewport);

      Phase0aVfxEntry? defeatEntry;
      Phase0aVfxEntry? lethalPopup;
      for (
        var i = 0;
        i < 240 &&
            defeatEntry == null &&
            controller.outcome == Phase0aBattleOutcome.ongoing;
        i++
      ) {
        await stepAndPump(tester, attackTowardNearest(controller.state));
        final defeats = controller.feedback
            .where((entry) => entry.kind == Phase0aVfxKind.defeatInk)
            .toList();
        if (defeats.isEmpty) continue;
        defeatEntry = defeats.single;
        lethalPopup = controller.feedback
            .where(
              (entry) =>
                  entry.kind == Phase0aVfxKind.damagePopup &&
                  entry.targetId == defeatEntry!.targetId,
            )
            .single;
      }

      expect(defeatEntry, isNotNull, reason: 'fixture 必须产生一次单目标击败');
      expect(lethalPopup, isNotNull, reason: '击败同拍必须保留致死伤害数字');
      expect(
        controller.state.enemies.any(
          (enemy) => enemy.id == defeatEntry!.targetId,
        ),
        isFalse,
        reason: '验证时目标必须已经从当前 state 移除',
      );

      final expected = stage.worldToScreen(defeatEntry!.anchor!);
      expect(
        (expected - stage.safeRect.center).distance,
        greaterThan(epsilon * 10),
        reason: 'fixture 击败位置需与旧 fallback 中心可区分',
      );
      expect(find.byKey(defeatInkKey), findsOneWidget);
      final actualDefeatCenter = tester.getCenter(find.byKey(defeatInkKey));
      expect(
        (actualDefeatCenter - expected).distance,
        lessThan(epsilon),
        reason: '死亡墨散中心应等于已移除敌人的事件位置快照',
      );

      final expectedPopup = stage.worldToScreen(lethalPopup!.anchor!);
      final popupFinder = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return widget is Positioned &&
            key is ValueKey<String> &&
            key.value.startsWith('phase0a_popup_');
      });
      final popupPositions = tester.widgetList<Positioned>(popupFinder);
      expect(
        popupPositions.any(
          (positioned) =>
              positioned.left != null &&
              (positioned.left! - expectedPopup.dx).abs() < epsilon,
        ),
        isTrue,
        reason: '致死飘字应使用事件位置快照，不得回退到 safeRect.center',
      );
    });
  });
}
