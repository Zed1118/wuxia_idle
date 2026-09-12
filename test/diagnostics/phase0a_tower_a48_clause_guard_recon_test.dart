// Diagnostic only: reproduce the a48aab668 clause-shape assertion gap.
// The helper below preserves the assertions from that immutable commit.
// Variants are test-only definition injections; neither mutates authored data.
import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async => repo = await loadTestGameRepository());
  for (final variant in ['renamed', 'split']) {
    test('diagnostic a48 guard accepts $variant clause shape', () async {
      Future<Phase0aTowerCombatSession> build(bool typed) =>
          createFreshPhase0aTowerCombatSession(
            Phase0aTowerCombatSessionBuildRequest(
              contentRef: const CombatContentRef.tower('tower_8'),
              floor: repo.getTowerFloor(8),
              playerSnapshot: testCombatantSnapshot(
                realmTier: RealmTier.wuSheng,
                maxHp: 20000,
                internalForce: 15000,
                totalEquipmentAttack: 2000,
                includeProductionBasicAttack: true,
              ),
              numbers: repo.numbers,
              cycleIndex: 1,
              rng: Random(20260993),
              routeAuthority:
                  Phase0aTowerEncounterRouteAuthority.migratedFloors(
                    typed ? {8} : {},
                  ),
              definitionSource: _DiagnosticDefinition(variant),
            ),
          );
      final typed = await build(true);
      final legacy = await build(false);
      Phase0aHeadlessResult run(Phase0aTowerCombatSession s) =>
          Phase0aHeadlessRunner.runToEnd(
            flow: s.flow,
            bot: Phase0aPlayerBotAdapter(playerAdapter: s.playerAdapter),
            deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
            maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
          );
      final a = run(typed);
      final b = run(legacy);
      _expectObjectiveWaveSplit(
        typedFlow: typed.flow,
        typedEvents: a.events,
        legacyEvents: b.events,
        terminal: true,
      );
      final progress = (typed.flow as Phase0aEncounterFlow).objectiveProgress!;
      final ids = progress.clauses.map((c) => c.id).toList();
      expect(
        ids,
        variant == 'renamed'
            ? ['diagnostic_renamed']
            : ['diagnostic_split_0', 'diagnostic_split_1'],
      );
      expect(a.finalState.tick, b.finalState.tick);
      expect(a.finalState.enemies, b.finalState.enemies);
      // ignore: avoid_print
      print(
        'TOWER_RECON ${jsonEncode({'kind': 'a48WeakGuard', 'variant': variant, 'floor': 8, 'clauseIds': ids, 'completed': progress.completed, 'ticks': a.finalState.tick, 'a48HelperPassed': true})}',
      );
    });
  }
}

final class _DiagnosticDefinition
    implements Phase0aTowerEncounterDefinitionSource {
  const _DiagnosticDefinition(this.variant);
  final String variant;
  @override
  CombatEncounterDef load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    final original = const Phase0aDerivedTowerEncounterDefinitionSource().load(
      contentRef: contentRef,
      floor: floor,
    );
    return CombatEncounterDef(
      id: original.id,
      spawnConfig: original.spawnConfig,
      tokenBudgets: original.tokenBudgets,
      spawnEntries: original.spawnEntries,
      objectives: CombatObjectiveCompositionRef(
        completionRule: CombatObjectiveCompletionRule.all,
        clauses: variant == 'renamed'
            ? [
                CombatObjectiveClauseRef(
                  id: 'diagnostic_renamed',
                  primitive: CombatDefeatTargetsRef(
                    original.spawnEntries.map((e) => e.entryId),
                  ),
                ),
              ]
            : [
                for (var i = 0; i < original.spawnEntries.length; i++)
                  CombatObjectiveClauseRef(
                    id: 'diagnostic_split_$i',
                    primitive: CombatDefeatTargetsRef([
                      original.spawnEntries[i].entryId,
                    ]),
                  ),
              ],
      ),
    );
  }
}

void _expectObjectiveWaveSplit({
  required Phase0aBattleFlow typedFlow,
  required List<Phase0aEvent> typedEvents,
  required List<Phase0aEvent> legacyEvents,
  required bool terminal,
}) {
  expect(
    typedEvents.where(
      (e) => e is Phase0aWaveStarted || e is Phase0aWaveCleared,
    ),
    isEmpty,
    reason: 'typed 不应发波次事件；一旦开始发会被 _combatEvents 静默丢掉',
  );
  final legacyStarts = legacyEvents.whereType<Phase0aWaveStarted>().toList();
  final legacyClears = legacyEvents.whereType<Phase0aWaveCleared>().toList();
  expect(legacyStarts, isNotEmpty, reason: 'legacy 侧被丢弃的波次事件必须确实存在，否则这层丢弃是空操作');

  // —— typed 目标进度：公开 getter，非 null 才谈得上比对 ——
  expect(typedFlow, isA<Phase0aEncounterFlow>());
  final progress = (typedFlow as Phase0aEncounterFlow).objectiveProgress;
  expect(
    progress,
    isNotNull,
    reason: 'typed 的 objectiveProgress 为 null 说明目标层没接上，映射比对无意义',
  );
  expect(progress!.clauses, isNotEmpty);
  expect(
    progress.clauses.map((c) => c.id),
    everyElement(isNotEmpty),
    reason: 'clause id 为空说明目标定义退化，后续迁层无法定位',
  );

  // —— 映射比对：typed 目标达成 ⇔ legacy 全波清空 ——
  final legacyAllWavesCleared = legacyClears.length == legacyStarts.length;
  expect(
    progress.completed,
    legacyAllWavesCleared,
    reason:
        'typed 目标达成=${progress.completed} 与 legacy 全波清空'
        '=$legacyAllWavesCleared 不一致（started=${legacyStarts.length} '
        'cleared=${legacyClears.length}）',
  );
  expect(
    progress.completed,
    terminal,
    reason: '终局片段=$terminal，typed 目标达成必须与之一致',
  );

  if (!terminal) return;
  final typedVictories = typedEvents.whereType<Phase0aBattleVictory>().toList();
  final legacyVictories = legacyEvents
      .whereType<Phase0aBattleVictory>()
      .toList();
  expect(
    typedVictories,
    hasLength(1),
    reason: 'typed 的 victory 由目标完成驱动，终局片段必须恰好一次',
  );
  expect(legacyVictories, hasLength(1));
  expect(typedVictories.single.tick, legacyVictories.single.tick);
  // legacy 的波次在 victory 当拍或更早清完；晚于 victory 说明两侧终局语义错位。
  expect(legacyClears, isNotEmpty, reason: 'legacy 终局片段必须清过波次');
  expect(
    legacyClears.last.tick,
    lessThanOrEqualTo(legacyVictories.single.tick),
  );
}
