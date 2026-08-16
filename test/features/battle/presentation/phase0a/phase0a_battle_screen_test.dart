import 'package:flutter/material.dart';
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
  const palmTrailKey = ValueKey('phase0a_palm_trail');
  const gatherVortexKey = ValueKey('phase0a_gather_vortex');
  const clearBurstKey = ValueKey('phase0a_clear_burst');

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
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: Phase0aBattleScreen(controller: controller)),
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
        await stepAndPump(tester);
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
  });

  group('玩家远距命中:掌风轨迹', () {
    testWidgets('整局进攻中至少一次 palmTrail entry 且轨迹 widget 可见', (tester) async {
      await pumpScreen(tester);

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

      expect(trailSeen, isTrue, reason: 'fixture 必含一次玩家远距命中');
      expect(find.byKey(palmTrailKey), findsWidgets);
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
      for (final outcome in pulled) {
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
}
