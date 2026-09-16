import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_production_profile.dart';
import 'package:wuxia_idle/features/debug/application/production_battle_frame_profile.dart';
import 'package:wuxia_idle/features/debug/application/production_profile_keyboard_driver.dart';

void main() {
  test('production workload separates living enemies from retained actors', () {
    addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
    final controller = Phase0aBattleController(
      flow: _ProfileFlow(),
      roster: Phase0aVisualRoster.debugBattle(extraEnemyIds: ['alive', 'dead']),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);

    for (final legalCharacter in [null, false, true]) {
      BattleFrameProfileProbe.configureFromArgs([
        '--battle-profile-scope=production',
        '--battle-profile-content-id=stage_01_03',
        '--battle-profile-run-id=workload',
        '--battle-profile-output=unused',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1280x720',
        if (legalCharacter != null)
          '--battle-profile-legal-character=$legalCharacter',
      ]);
      BattleFrameProfileProbe.recordEntryOrigin(visual: false);
      final profile =
          Phase0aProductionProfile.wrap(
                child: const SizedBox.shrink(),
                mode: 'battle',
                contentId: 'stage_01_03',
                runtimeKind: 'legacy_waves',
                controller: controller,
              )
              as ProductionBattleFrameProfile;
      expect(profile.scene['legal_character'], legalCharacter);
      expect(profile.scene, contains('legal_character'));
      expect(profile.readWorkload(), containsPair('active_enemies', 1));
      expect(profile.readWorkload()['active_enemy_ids'], ['alive']);
      expect(profile.readWorkload(), containsPair('resident_enemies', 2));
      expect(profile.readWorkload(), containsPair('tick', 25));
    }
  });

  testWidgets('capture input focus and lifecycle release driver keys', (
    tester,
  ) async {
    final output = Directory.systemTemp.createTempSync('profile_keyboard_');
    addTearDown(() => output.deleteSync(recursive: true));
    addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
    final flow = _ProfileFlow();
    final controller = Phase0aBattleController(
      flow: flow,
      roster: Phase0aVisualRoster.debugBattle(extraEnemyIds: ['alive', 'dead']),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);
    final battleFocus = FocusNode();
    final outsideFocus = FocusNode();
    addTearDown(battleFocus.dispose);
    addTearDown(outsideFocus.dispose);
    final requested = BattleFrameProfileProbe.configureFromArgs([
      '--battle-profile-scope=production',
      '--battle-profile-content-id=stage_01_03',
      '--battle-profile-run-id=keyboard',
      '--battle-profile-output=${output.path}',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-viewport=1280x720',
      '--battle-profile-keyboard-policy=baseline',
    ])!;
    BattleFrameProfileProbe.recordEntryOrigin(visual: false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(
      () => tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1280, 720),
            devicePixelRatio: 2,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                ProductionBattleFrameProfile(
                  config: requested,
                  owner: controller,
                  scene: const {},
                  isCombatOngoing: () => true,
                  readWorkload: () => {
                    'tick': flow.state.tick,
                    'active_enemies': 1,
                    'active_enemy_ids': <String>['alive'],
                    'combat_ongoing': true,
                  },
                  keyboardDriverFactory: (isForeground) =>
                      ProductionProfileKeyboardDriver(
                        controller: controller,
                        basicAttackRange: 150,
                        isForeground: isForeground,
                      ),
                  child: Focus(
                    focusNode: battleFocus,
                    autofocus: true,
                    onKeyEvent: (_, _) => KeyEventResult.handled,
                    child: const SizedBox.shrink(),
                  ),
                ),
                Focus(focusNode: outsideFocus, child: const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      expect(
        HardwareKeyboard.instance.logicalKeysPressed,
        contains(LogicalKeyboardKey.keyJ),
      );
      outsideFocus.requestFocus();
      await tester.pump();
      expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
      expect(outsideFocus.hasPrimaryFocus, isTrue);
      expect(battleFocus.hasPrimaryFocus, isFalse);
      expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
      flow.state = _profileState(tick: 26);
      battleFocus.requestFocus();
      await tester.pump();
      expect(
        HardwareKeyboard.instance.logicalKeysPressed,
        contains(LogicalKeyboardKey.keyJ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
      flow.state = _profileState(tick: 27);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(
        HardwareKeyboard.instance.logicalKeysPressed,
        contains(LogicalKeyboardKey.keyJ),
      );
    } finally {
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await ProductionBattleFrameProfile.flushPendingEvidence();
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    final evidence =
        jsonDecode(File('${output.path}/summary.json').readAsStringSync())
            as Map;
    final driver = evidence['keyboard_driver'] as Map;
    expect(driver['running'], isFalse);
    expect(driver['held_key_ids'], isEmpty);
    expect(driver['key_down_events'], greaterThan(0));
    expect(driver['key_down_events'], driver['key_up_events']);
    expect(evidence['capture_window_valid'], isFalse);
  });

  testWidgets(
    'periodic workload excludes offstage living and retained dead actors',
    (tester) async {
      final output = Directory.systemTemp.createTempSync('profile_visibility_');
      addTearDown(() => output.deleteSync(recursive: true));
      addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
      final flow = _ProfileFlow()..state = _profileState(includeHidden: true);
      final controller = Phase0aBattleController(
        flow: flow,
        roster: Phase0aVisualRoster.debugBattle(
          extraEnemyIds: ['alive', 'hidden', 'dead'],
        ),
        fixedDeltaSeconds: 0.1,
      );
      addTearDown(controller.dispose);
      BattleFrameProfileProbe.configureFromArgs([
        '--battle-profile-scope=production',
        '--battle-profile-content-id=stage_01_03',
        '--battle-profile-run-id=visibility',
        '--battle-profile-output=${output.path}',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1280x720',
      ]);
      BattleFrameProfileProbe.recordEntryOrigin(visual: false);
      Widget tree({required bool hideActor}) => MediaQuery(
        data: const MediaQueryData(size: Size(1280, 720), devicePixelRatio: 2),
        child: Phase0aProductionProfile.wrap(
          mode: 'battle',
          contentId: 'stage_01_03',
          runtimeKind: 'legacy_waves',
          controller: controller,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: const ValueKey('arena_container'),
              child: Column(
                children: [
                  const RepaintBoundary(
                    key: ValueKey('phase0a_actor_alive'),
                    child: SizedBox.shrink(),
                  ),
                  Offstage(
                    offstage: hideActor,
                    child: const RepaintBoundary(
                      key: ValueKey('phase0a_actor_hidden'),
                      child: SizedBox.shrink(),
                    ),
                  ),
                  const RepaintBoundary(
                    key: ValueKey('phase0a_actor_dead'),
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => tester.pumpWidget(tree(hideActor: true)));
      try {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1100)),
        );
        await tester.runAsync(() => tester.pumpWidget(tree(hideActor: false)));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1100)),
        );
      } finally {
        await tester.runAsync(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await ProductionBattleFrameProfile.flushPendingEvidence();
        });
      }
      final rows = File('${output.path}/workload.jsonl')
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map)
          .where((row) => row['visibility_observer_status'] == 'observed')
          .toList();
      expect(rows.length, greaterThanOrEqualTo(2));
      expect(rows.first['active_enemy_ids'], ['alive', 'hidden']);
      expect(rows.first['active_enemies'], 2);
      expect(rows.first['resident_enemies'], 3);
      expect(rows.first['visible_active_enemies'], 1);
      expect(rows.first['visible_enemy_ids'], ['alive']);
      expect(rows.last['visible_active_enemies'], 2);
      expect(rows.last['visible_enemy_ids'], ['alive', 'hidden']);
      for (final row in rows) {
        expect(row['visible_enemy_ids'], isNot(contains('dead')));
        expect(row['visibility_observer_elapsed_us'], greaterThanOrEqualTo(0));
        expect(row['visibility_observer_visited_elements'], greaterThan(0));
      }
    },
  );
}

class _ProfileFlow extends Fake implements Phase0aBattleFlow {
  @override
  Phase0aArenaState state = _profileState();

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;
}

Phase0aArenaState _profileState({int tick = 25, bool includeHidden = false}) =>
    Phase0aArenaState(
      tick: tick,
      nextSeq: 1,
      player: _actor('player', Phase0aSide.player),
      enemies: [
        _actor('alive', Phase0aSide.enemy),
        if (includeHidden) _actor('hidden', Phase0aSide.enemy),
        _actor('dead', Phase0aSide.enemy).copyWith(currentHealth: 0),
      ],
      skillSlots: const [],
    );

Phase0aActor _actor(String id, Phase0aSide side) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector.zero,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 100,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);
