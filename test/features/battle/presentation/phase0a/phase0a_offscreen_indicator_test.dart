import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_offscreen_indicator.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

const _viewports = <Size>[Size(1280, 720), Size(1440, 900)];
const _indicatorKey = ValueKey('phase0a_offscreen_indicators');

const _rangedWindupSkill = SkillDef(
  id: 'offscreen_ranged_windup',
  name: 'offscreen_ranged_windup',
  description: 'offscreen_ranged_windup',
  type: SkillType.powerSkill,
  powerMultiplier: 100,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

final _rangedWindup = Phase0aChargeCast(
  skill: _rangedWindupSkill,
  chargeTicks: 3,
  attackRange: 300,
  halfArcRadians: 0.5,
  effectRadius: 0,
  cooldownSeconds: 1,
  actionCooldownSeconds: 1,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
);

Phase0aActor _player() => const Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector.zero,
  facing: ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _enemy({
  required String id,
  required ArenaVector position,
  bool isBoss = false,
  bool rangedWindup = false,
}) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: position,
  facing: const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 60,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: isBoss ? Phase0aDefeatKind.elite : Phase0aDefeatKind.normal,
  isBoss: isBoss,
  chargingCast: rangedWindup ? _rangedWindup : null,
  chargeTicksRemaining: rangedWindup ? 2 : 0,
);

final class _MutableBattleFlow implements Phase0aBattleFlow {
  _MutableBattleFlow(this._state);

  Phase0aArenaState _state;
  Phase0aArenaState? _queuedState;
  Phase0aPlayerCommand? lastCommand;

  void queue(Phase0aArenaState state) => _queuedState = state;

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    lastCommand = command;
    final queued = _queuedState;
    if (queued != null) {
      _state = queued;
      _queuedState = null;
    }
    return const [];
  }
}

Phase0aArenaState _state(List<Phase0aActor> enemies) => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _player(),
  enemies: enemies,
  skillSlots: const [
    Phase0aSkillSlot(
      slot: 'gather',
      cooldownRemaining: 0,
      qiCost: 0,
      availability: Phase0aSkillAvailability.ready,
    ),
    Phase0aSkillSlot(
      slot: 'clear',
      cooldownRemaining: 0,
      qiCost: 0,
      availability: Phase0aSkillAvailability.ready,
    ),
  ],
);

List<Phase0aActor> _enemies(int activeCount) {
  final enemies = <Phase0aActor>[
    _enemy(id: 'boss_right', position: const ArenaVector(620, 0), isBoss: true),
    _enemy(id: 'charge_left', position: const ArenaVector(-620, 0)),
    _enemy(id: 'support_top', position: const ArenaVector(0, -250)),
    _enemy(
      id: 'ranged_bottom',
      position: const ArenaVector(0, 250),
      rangedWindup: true,
    ),
  ];
  for (var index = enemies.length; index < activeCount; index++) {
    enemies.add(
      _enemy(
        id: 'melee_${index.toString().padLeft(2, '0')}',
        position: ArenaVector(
          -300 + (index % 6) * 100,
          -120 + (index % 4) * 80,
        ),
      ),
    );
  }
  return enemies;
}

Phase0aVisualRoster _roster(List<Phase0aActor> enemies) {
  final visuals = <String, Phase0aActorVisual>{
    'player': const Phase0aActorVisual(
      name: 'player',
      assetPath: 'assets/characters/battle_founder_v2.png',
      isElite: false,
    ),
  };
  for (final enemy in enemies) {
    final threat = switch (enemy.id) {
      'charge_left' => const Phase0aActorThreatVisual(
        kind: AttackTokenKind.charge,
        isHighImpact: true,
      ),
      'support_top' => const Phase0aActorThreatVisual(
        kind: AttackTokenKind.support,
        isHighImpact: false,
      ),
      'ranged_bottom' => const Phase0aActorThreatVisual(
        kind: AttackTokenKind.ranged,
        isHighImpact: false,
      ),
      _ => null,
    };
    visuals[enemy.id] = Phase0aActorVisual(
      name: enemy.id,
      assetPath: 'assets/enemies/battle_bandit_blade.png',
      isElite: enemy.isBoss,
      threat: threat,
    );
  }
  return Phase0aVisualRoster(visuals: visuals);
}

Future<({Phase0aBattleController controller, _MutableBattleFlow flow})>
_pumpBattle(
  WidgetTester tester, {
  required Size viewport,
  required List<Phase0aActor> enemies,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final flow = _MutableBattleFlow(_state(enemies));
  final controller = Phase0aBattleController(
    flow: flow,
    roster: _roster(enemies),
    fixedDeltaSeconds: 0.1,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Phase0aBattleScreen(controller: controller, autoStep: false),
    ),
  );
  await tester.pump();
  return (controller: controller, flow: flow);
}

Future<int> _paintedPixelCount(
  WidgetTester tester,
  Phase0aOffscreenIndicatorPainter painter,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), size);
  final picture = recorder.endRecording();
  final bytes = await tester.runAsync(() async {
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data;
  });
  var painted = 0;
  for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
    if (bytes.getUint8(offset) > 0) painted++;
  }
  return painted;
}

void main() {
  group('complete actor bounds and HUD separation', () {
    for (final viewport in _viewports) {
      testWidgets('camera edge actors fit above the real HUD $viewport', (
        tester,
      ) async {
        final enemies = <Phase0aActor>[
          _enemy(
            id: 'top_left',
            position: const ArenaVector(-479, -194),
            isBoss: true,
          ),
          _enemy(
            id: 'top_right',
            position: const ArenaVector(479, -194),
            isBoss: true,
          ),
          _enemy(
            id: 'bottom_left',
            position: const ArenaVector(-479, 194),
            isBoss: true,
          ),
          _enemy(
            id: 'bottom_right',
            position: const ArenaVector(479, 194),
            isBoss: true,
          ),
        ];
        await _pumpBattle(tester, viewport: viewport, enemies: enemies);
        final hud = tester.getRect(
          find.byKey(const ValueKey('phase0a_player_hud')),
        );
        for (final enemy in enemies) {
          final bounds = tester.getRect(
            find.byKey(ValueKey('phase0a_actor_position_${enemy.id}')),
          );
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(viewport.width));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(
            bounds.bottom,
            lessThan(hud.top),
            reason: '${enemy.id} must not enter the HUD band',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'offscreen actor is not painted or mouse-selected, domain stays intact',
      (tester) async {
        final enemy = _enemy(
          id: 'charge_left',
          position: const ArenaVector(-510, 0),
        );
        final harness = await _pumpBattle(
          tester,
          viewport: _viewports.first,
          enemies: [enemy],
        );
        final position = find.byKey(
          const ValueKey('phase0a_actor_position_charge_left'),
        );
        final hidden = tester.widget<Offstage>(
          find.descendant(of: position, matching: find.byType(Offstage)).first,
        );
        expect(hidden.offstage, isTrue);
        expect(
          find.byKey(const ValueKey('phase0a_standee_charge_left')),
          findsNothing,
        );
        expect(find.byKey(_indicatorKey), findsOneWidget);
        final stage = Phase0aStage(
          viewport: _viewports.first,
          cameraCenter: ArenaVector.zero,
        );
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kPrimaryMouseButton,
        );
        await pointer.down(
          stage.worldToScreen(enemy.position) - const Offset(0, 60),
        );
        await pointer.up();
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('phase0a_selected_target_charge_left'),
            skipOffstage: false,
          ),
          findsNothing,
        );
        harness.controller.step();
        expect(harness.flow.lastCommand!.attack, isFalse);
        expect(
          harness.controller.state.enemies.single.position,
          enemy.position,
        );
        expect(
          harness.controller.state.enemies.single.currentHealth,
          enemy.currentHealth,
        );
        final inside = enemy.copyWith(position: ArenaVector.zero);
        harness.flow.queue(_state([inside]));
        harness.controller.step();
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          find.byKey(const ValueKey('phase0a_standee_charge_left')),
          findsOneWidget,
        );
        expect(find.byKey(_indicatorKey), findsNothing);
      },
    );
    test('bottom threat marker stays above controls in both viewports', () {
      final painter = Phase0aOffscreenIndicatorPainter(
        indicators: [
          Phase0aOffscreenIndicator(
            actorIds: ['below'],
            kind: Phase0aOffscreenThreatKind.boss,
            proximity: Phase0aOffscreenProximity.near,
            direction: const ArenaVector(0, 1),
            priority: 4,
          ),
        ],
      );
      for (final viewport in _viewports) {
        expect(
          painter.markerCenters(viewport).single.dy,
          lessThan(viewport.height - 180),
        );
      }
    });
  });
  group('camera-aware stage geometry', () {
    for (final viewport in _viewports) {
      test('75% player camera exposes unclamped visibility '
          '${viewport.width}x${viewport.height}', () {
        final stage = Phase0aStage(
          viewport: viewport,
          cameraCenter: ArenaVector.zero,
        );
        expect(stage.cameraWorldRect.width, 960);
        expect(stage.cameraWorldRect.height, 390);
        final center = stage.worldToScreen(ArenaVector.zero);
        expect(center.dx, closeTo(stage.safeRect.center.dx, 0.51));
        expect(center.dy, closeTo(stage.safeRect.center.dy, 0.51));
        expect(stage.isWorldPointVisible(ArenaVector.zero), isTrue);
        expect(stage.isWorldPointVisible(const ArenaVector(620, 0)), isFalse);
      });
    }

    test('camera follows player but remains clamped inside arena', () {
      final stage = Phase0aStage(
        viewport: _viewports.first,
        cameraCenter: const ArenaVector(620, 250),
      );
      expect(stage.cameraWorldRect.right, stage.worldMax.x);
      expect(stage.cameraWorldRect.bottom, stage.worldMax.y);
    });
  });

  group('real Phase0aBattleScreen offscreen indicators', () {
    for (final viewport in _viewports) {
      for (final activeCount in const [8, 16, 24]) {
        testWidgets('caps and paints three directions for $activeCount actors '
            '${viewport.width}x${viewport.height}', (tester) async {
          final enemies = _enemies(activeCount);
          await _pumpBattle(tester, viewport: viewport, enemies: enemies);

          expect(find.byKey(_indicatorKey), findsOneWidget);
          final paint = tester.widget<CustomPaint>(find.byKey(_indicatorKey));
          final painter = paint.painter! as Phase0aOffscreenIndicatorPainter;
          expect(painter.indicators, hasLength(3));
          expect(painter.indicators.map((item) => item.kind).toSet(), {
            Phase0aOffscreenThreatKind.boss,
            Phase0aOffscreenThreatKind.charge,
            Phase0aOffscreenThreatKind.support,
          });
          expect(
            painter.indicators.expand((item) => item.actorIds),
            isNot(contains('ranged_bottom')),
            reason: '第四方向按冻结优先级被三方向上限淘汰',
          );
          final size = tester.getSize(find.byKey(_indicatorKey));
          expect(
            await _paintedPixelCount(tester, painter, size),
            greaterThan(0),
          );
          for (final center in painter.markerCenters(size)) {
            expect(center.dx, inInclusiveRange(0, size.width));
            expect(center.dy, inInclusiveRange(0, size.height));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('ordinary offscreen chase mobs never create indicators', (
      tester,
    ) async {
      final enemies = <Phase0aActor>[
        _enemy(id: 'ordinary_left', position: const ArenaVector(-620, 0)),
        _enemy(id: 'ordinary_right', position: const ArenaVector(620, 0)),
      ];
      await _pumpBattle(tester, viewport: _viewports.first, enemies: enemies);
      expect(find.byKey(_indicatorKey), findsNothing);
    });

    testWidgets('indicator disappears on entry and returns on exit', (
      tester,
    ) async {
      final enemies = <Phase0aActor>[
        _enemy(id: 'charge_left', position: const ArenaVector(-620, 0)),
      ];
      final harness = await _pumpBattle(
        tester,
        viewport: _viewports.first,
        enemies: enemies,
      );
      expect(find.byKey(_indicatorKey), findsOneWidget);

      final inside = enemies.single.copyWith(position: ArenaVector.zero);
      harness.flow.queue(_state([inside]));
      harness.controller.step();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(_indicatorKey), findsNothing);

      final outside = inside.copyWith(position: const ArenaVector(620, 0));
      harness.flow.queue(_state([outside]));
      harness.controller.step();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(_indicatorKey), findsOneWidget);
    });
  });
}
