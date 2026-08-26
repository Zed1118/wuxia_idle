import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_participant_snapshot_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

const _stageId = 'stage_01_01';
const _battleSeed = 2026082701;
const _rewardSeed = 2026082702;
const _repeatRuns = 3;
const _policy = Phase0aBotTacticPolicy.steadyGuard();

enum _Mode { manual, bot, headless, sweep }

void main() {
  late GameRepository repository;
  late _BattleMatrix matrix;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
    final scenario = await _openScenario(repository);
    try {
      final snapshot = await _resolveSnapshot(
        mode: _Mode.sweep,
        characterId: scenario.characterId,
      );
      matrix = await _buildBattleMatrix(
        repository: repository,
        snapshot: snapshot,
      );
    } finally {
      await _closeScenario(scenario);
    }
  });

  test('第1组 手动 command 经生产 input adapter 成为领域 intent，四模式逐 tick 同 hash', () {
    _expectFourModeTraceParity(matrix);
    expect(matrix.manualIntentTypes, isNotEmpty);
    expect(matrix.manualIntentTypes.every((types) => types.isNotEmpty), isTrue);
  });

  test('第2组 前台 bot 产生与手动回放相同 command，四模式逐 tick 同 hash', () {
    _expectFourModeTraceParity(matrix);
    expect(
      matrix.traces[_Mode.bot]!.commandSummaries,
      matrix.traces[_Mode.manual]!.commandSummaries,
    );
  });

  test('第3组 headless 与 sweep 按同一 fixed tick 推进，四模式 tick 数/hash 一致', () {
    _expectFourModeTraceParity(matrix);
    final expectedTicks = matrix.traces[_Mode.manual]!.states.length - 1;
    expect(matrix.traces[_Mode.headless]!.ticks, expectedTicks);
    expect(matrix.traces[_Mode.sweep]!.ticks, expectedTicks);
    expect(matrix.actualSweep.timedOut, isFalse);
  });

  test('第4组 同快照/seed/战术/输入得到同领域事件与结算摘要', () {
    _expectFourModeTraceParity(matrix);
    final expected = matrix.traces[_Mode.manual]!;
    for (final trace in matrix.traces.values) {
      expect(trace.events, expected.events);
      expect(trace.eventRecords, expected.eventRecords);
      expect(trace.settlementSummary, expected.settlementSummary);
    }
  });

  test('第5组 生产 sweep 终局反校验同核 trace，不存在战力比较捷径证据', () {
    _expectFourModeTraceParity(matrix);
    expect(
      _settlementSummary(matrix.actualSweep.settlement!),
      matrix.traces[_Mode.sweep]!.settlementSummary,
    );
  });

  test('第6组 async 批量推进只省略渲染，不改变逐 tick 状态或事件', () {
    _expectFourModeTraceParity(matrix);
    final sync = matrix.traces[_Mode.headless]!;
    final async = matrix.traces[_Mode.sweep]!;
    expect(async.states, sync.states);
    expect(async.recordsByTick, sync.recordsByTick);
  });

  testWidgets('第7组 同活动四模式共享重复掉落 profile，重复项按次数计入', (tester) async {
    final profiles = <_Mode, _RewardProfile>{};
    for (final mode in _Mode.values) {
      profiles[mode] = await _runRewardMode(
        tester: tester,
        repository: repository,
        mode: mode,
      );
    }
    final expected = profiles[_Mode.manual]!;
    for (final entry in profiles.entries) {
      expect(entry.value.canonical, expected.canonical, reason: entry.key.name);
    }
    expect(
      expected.equipmentCounts.values.any((count) => count > 1),
      isTrue,
      reason: '三次重打中的同 defId 装备必须按重复次数保留，不能转 set 去重',
    );
    // 单一稳定输出供报告与复跑命令直接核对；不含实例 id/时间戳。
    // ignore: avoid_print
    print(
      'N14_EVIDENCE battle=${matrix.digest} '
      'ticks=${matrix.traces[_Mode.manual]!.ticks} '
      'reward=${expected.digest} profile=${expected.canonical}',
    );
  });
}

final class _Scenario {
  const _Scenario({required this.directory, required this.characterId});

  final Directory directory;
  final int characterId;
}

Future<_Scenario> _openScenario(GameRepository repository) async {
  final directory = await Directory.systemTemp.createTemp('n14_same_core_');
  await IsarSetup.init(directory: directory, inspector: false);
  await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  final character = await IsarSetup.instance.characters.where().findFirst();
  if (character == null) throw StateError('N14 scenario has no character');
  final save = await IsarSetup.instance.saveDatas.get(0);
  if (save == null) throw StateError('N14 scenario has no save');
  await IsarSetup.instance.writeTxn(() async {
    save
      ..founderCharacterId = character.id
      ..activeCharacterIds = [character.id]
      ..sweepReadinessPoints = 20
      ..sweepReadinessLastRecoveredAt = DateTime.utc(2026, 8, 27);
    await IsarSetup.instance.saveDatas.put(save);
    await IsarSetup.instance.mainlineProgress.put(
      MainlineProgress()
        ..saveDataId = save.slotId
        ..clearedStageIds = [_stageId]
        ..clearedAt = [DateTime.utc(2026, 8, 27)],
    );
  });
  // Fail fast if the real stage disappears or ceases to be mainline content.
  final stage = repository.getStage(_stageId);
  if (stage.id != _stageId) throw StateError('N14 stage route drifted');
  return _Scenario(directory: directory, characterId: character.id);
}

Future<void> _closeScenario(_Scenario scenario) async {
  if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
  IsarSetup.resetForTest();
  if (await scenario.directory.exists()) {
    await scenario.directory.delete(recursive: true);
  }
}

ActivityParticipationRequest _request({
  required _Mode mode,
  required int characterId,
}) => ActivityParticipationRequest(
  contentId: _stageId,
  contentKind: ActivityContentKind.mainline,
  characterId: characterId,
  loadoutPlanId: mainlineLoadoutPlanId(
    stageId: _stageId,
    characterId: characterId,
  ),
  participation: ActivityParticipationMode.direct,
  controller: switch (mode) {
    _Mode.manual => ActivityController.human,
    _ => ActivityController.playerBot,
  },
  clock: switch (mode) {
    _Mode.manual || _Mode.bot => ActivityClock.realtime,
    _ => ActivityClock.headless,
  },
  entryKind: switch (mode) {
    _Mode.sweep => ActivityEntryKind.sweep,
    _ => ActivityEntryKind.replay,
  },
);

Future<CombatantSnapshot> _resolveSnapshot({
  required _Mode mode,
  required int characterId,
}) async {
  final resolved = await MainlineParticipantSnapshotService(
    IsarSetup.instance,
  ).resolve(_request(mode: mode, characterId: characterId));
  return resolved.snapshot;
}

final class _FlowFixture {
  const _FlowFixture({required this.mapping, required this.flow});

  final Phase0aStageMapping mapping;
  final _RecordingFlow flow;
}

_FlowFixture _freshFlow({
  required GameRepository repository,
  required CombatantSnapshot snapshot,
  required Random rng,
}) {
  final mapping = Phase0aStageContentMapper.map(
    stage: repository.getStage(_stageId),
    playerSnapshot: snapshot,
    numbers: repository.numbers,
    cycleIndex: 1,
  );
  final flow = Phase0aProductionFlowAssembler.assemble(
    initialState: mapping.initialState,
    waves: mapping.waves,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    numbers: repository.numbers,
    rng: rng,
    playerAdapter: mapping.playerAdapter,
    enemyAiAdapter: mapping.enemyAiAdapter,
    waveTransitionPolicy: mapping.waveTransitionPolicy,
  );
  return _FlowFixture(mapping: mapping, flow: _RecordingFlow(flow));
}

final class _BattleMatrix {
  const _BattleMatrix({
    required this.traces,
    required this.manualIntentTypes,
    required this.actualSweep,
  });

  final Map<_Mode, _Trace> traces;
  final List<List<String>> manualIntentTypes;
  final Phase0aSweepRunResult actualSweep;

  String get digest => _stableDigest(
    _Mode.values
        .map((mode) => '${mode.name}:${traces[mode]!.digest}')
        .join('|'),
  );
}

Future<_BattleMatrix> _buildBattleMatrix({
  required GameRepository repository,
  required CombatantSnapshot snapshot,
}) async {
  final botFixture = _freshFlow(
    repository: repository,
    snapshot: snapshot,
    rng: newMathRandom(seed: _battleSeed),
  );
  final botController = Phase0aBattleController(
    flow: botFixture.flow,
    roster: Phase0aVisualRoster.fromMapping(botFixture.mapping),
    fixedDeltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
  );
  final bot = Phase0aPlayerBotAdapter(
    playerAdapter: botFixture.mapping.playerAdapter,
    policy: _policy,
  );
  final commands = <Phase0aPlayerCommand>[];
  while (botController.outcome == Phase0aBattleOutcome.ongoing &&
      commands.length < repository.numbers.phase0aArena.maxSimulationTicks) {
    final command = bot.commandFor(botController.state);
    commands.add(command);
    botController.step(command);
  }
  final botTrace = _finishTrace(botFixture, botController.outcome);
  botController.dispose();

  final manualFixture = _freshFlow(
    repository: repository,
    snapshot: snapshot,
    rng: newMathRandom(seed: _battleSeed),
  );
  final manualController = Phase0aBattleController(
    flow: manualFixture.flow,
    roster: Phase0aVisualRoster.fromMapping(manualFixture.mapping),
    fixedDeltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
  );
  final manualIntentTypes = <List<String>>[];
  for (final command in commands) {
    if (manualController.outcome != Phase0aBattleOutcome.ongoing) break;
    manualIntentTypes.add([
      for (final intent in manualFixture.mapping.playerAdapter.intentsFor(
        state: manualController.state,
        command: command,
      ))
        intent.runtimeType.toString(),
    ]);
    manualController.step(command);
  }
  final manualTrace = _finishTrace(manualFixture, manualController.outcome);
  manualController.dispose();

  final headlessFixture = _freshFlow(
    repository: repository,
    snapshot: snapshot,
    rng: newMathRandom(seed: _battleSeed),
  );
  final headlessResult = Phase0aHeadlessRunner.runToEnd(
    flow: headlessFixture.flow,
    bot: Phase0aPlayerBotAdapter(
      playerAdapter: headlessFixture.mapping.playerAdapter,
      policy: _policy,
    ),
    deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
    maxTicks: repository.numbers.phase0aArena.maxSimulationTicks,
  );
  final headlessTrace = _finishTrace(headlessFixture, headlessResult.outcome);

  final sweepFixture = _freshFlow(
    repository: repository,
    snapshot: snapshot,
    rng: newMathRandom(seed: _battleSeed),
  );
  final sweepResult = await Phase0aHeadlessRunner.runToEndAsync(
    flow: sweepFixture.flow,
    bot: Phase0aPlayerBotAdapter(
      playerAdapter: sweepFixture.mapping.playerAdapter,
      policy: _policy,
    ),
    deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
    maxTicks: repository.numbers.phase0aArena.maxSimulationTicks,
    yieldEveryTicks: 32,
  );
  final sweepTrace = _finishTrace(sweepFixture, sweepResult.outcome);

  final actualSweep = await Phase0aSweepHeadlessRunner(
    isar: IsarSetup.instance,
    numbers: repository.numbers,
    rng: newMathRandom(seed: _battleSeed),
    botPolicy: _policy,
  ).runMainline(stage: repository.getStage(_stageId), cycleIndex: 1);

  return _BattleMatrix(
    traces: {
      _Mode.manual: manualTrace,
      _Mode.bot: botTrace,
      _Mode.headless: headlessTrace,
      _Mode.sweep: sweepTrace,
    },
    manualIntentTypes: manualIntentTypes,
    actualSweep: actualSweep,
  );
}

final class _RecordingFlow implements Phase0aBattleFlow {
  _RecordingFlow(this._inner) : states = [_inner.state];

  final Phase0aBattleFlow _inner;
  final List<Phase0aArenaState> states;
  final List<Phase0aPlayerCommand> commands = [];
  final List<Phase0aEvent> events = [];
  final List<List<CombatEventRecord>> recordsByTick = [];

  @override
  Phase0aArenaState get state => _inner.state;

  @override
  Phase0aBattleOutcome get outcome => _inner.outcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      _inner.lastOrderedEventRecords;

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    commands.add(command);
    final emitted = _inner.advance(
      deltaSeconds: deltaSeconds,
      command: command,
    );
    states.add(_inner.state);
    events.addAll(emitted);
    recordsByTick.add(List.unmodifiable(_inner.lastOrderedEventRecords));
    return emitted;
  }
}

final class _Trace {
  const _Trace({
    required this.states,
    required this.commandSummaries,
    required this.events,
    required this.recordsByTick,
    required this.settlementSummary,
  });

  final List<Phase0aArenaState> states;
  final List<String> commandSummaries;
  final List<Phase0aEvent> events;
  final List<List<CombatEventRecord>> recordsByTick;
  final String settlementSummary;

  int get ticks => states.length - 1;
  List<CombatEventRecord> get eventRecords => [
    for (final records in recordsByTick) ...records,
  ];
  List<String> get tickHashes => [
    for (var index = 1; index < states.length; index++)
      _stableDigest(
        '${_stateSummary(states[index])}|'
        '${recordsByTick[index - 1].map(_recordSummary).join(';')}',
      ),
  ];
  String get digest => _stableDigest(tickHashes.join('|'));
}

_Trace _finishTrace(_FlowFixture fixture, Phase0aBattleOutcome outcome) {
  final settlement = Phase0aSettlementAdapter.fromMapping(
    mapping: fixture.mapping,
    outcome: outcome,
    finalState: fixture.flow.state,
    events: fixture.flow.events,
  );
  return _Trace(
    states: List.unmodifiable(fixture.flow.states),
    commandSummaries: List.unmodifiable(
      fixture.flow.commands.map(_commandSummary),
    ),
    events: List.unmodifiable(fixture.flow.events),
    recordsByTick: List.unmodifiable(fixture.flow.recordsByTick),
    settlementSummary: _settlementSummary(settlement),
  );
}

void _expectFourModeTraceParity(_BattleMatrix matrix) {
  expect(matrix.traces.keys.toSet(), _Mode.values.toSet());
  final expected = matrix.traces[_Mode.manual]!;
  for (final entry in matrix.traces.entries) {
    expect(entry.value.tickHashes, expected.tickHashes, reason: entry.key.name);
  }
}

Future<_RewardProfile> _runRewardMode({
  required WidgetTester tester,
  required GameRepository repository,
  required _Mode mode,
}) async {
  final scenario = await tester.runAsync(() => _openScenario(repository));
  if (scenario == null) throw StateError('N14 scenario setup failed');
  WidgetRef? capturedRef;
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey('n14_${mode.name}'),
      overrides: [
        rngProvider.overrideWithValue(DefaultRng(seed: _rewardSeed)),
        mathRandomProvider.overrideWithValue(newMathRandom(seed: _battleSeed)),
      ],
      child: _RefHarness(onReady: (ref) => capturedRef = ref),
    ),
  );
  await tester.pump();
  final profile = await tester.runAsync(() async {
    final ref = capturedRef;
    if (ref == null) throw StateError('N14 WidgetRef was not captured');
    final before = await _RewardSnapshot.capture(scenario.characterId);
    final settlement = await _runModeBattle(
      ref: ref,
      repository: repository,
      mode: mode,
      characterId: scenario.characterId,
    );
    for (var run = 0; run < _repeatRuns; run++) {
      switch (mode) {
        case _Mode.manual || _Mode.bot:
          final outcome = await applyVictoryResolution(
            ref: ref,
            stage: repository.getStage(_stageId),
            cycle: 1,
            settlementSnapshot: settlement,
            expectedParticipantId: scenario.characterId,
          );
          if (outcome == null) throw StateError('${mode.name} reward is null');
        case _Mode.headless:
          final outcome = await settleMainlineHeadlessReplayVictory(
            ref: ref,
            stage: repository.getStage(_stageId),
            cycle: 1,
            settlementSnapshot: settlement,
            expectedParticipantId: scenario.characterId,
          );
          if (outcome == null) throw StateError('headless reward is null');
        case _Mode.sweep:
          final outcome = await settleMainlineSweepVictory(
            ref: ref,
            stage: repository.getStage(_stageId),
            cycle: 1,
            settlementSnapshot: settlement,
            expectedParticipantId: scenario.characterId,
          );
          if (outcome == null) throw StateError('sweep reward is null');
      }
    }
    final after = await _RewardSnapshot.capture(scenario.characterId);
    return after.deltaFrom(before);
  });
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(() => _closeScenario(scenario));
  return profile!;
}

Future<CombatSettlementSnapshot> _runModeBattle({
  required WidgetRef ref,
  required GameRepository repository,
  required _Mode mode,
  required int characterId,
}) async {
  if (mode == _Mode.sweep) {
    final result = await Phase0aSweepHeadlessRunner(
      isar: IsarSetup.instance,
      numbers: repository.numbers,
      rng: ref.read(mathRandomProvider),
      botPolicy: _policy,
    ).runMainline(stage: repository.getStage(_stageId), cycleIndex: 1);
    if (result.timedOut || result.settlement == null) {
      throw StateError('production sweep did not produce a settlement');
    }
    return result.settlement!;
  }
  final snapshot = await _resolveSnapshot(mode: mode, characterId: characterId);
  final fixture = _freshFlow(
    repository: repository,
    snapshot: snapshot,
    rng: ref.read(mathRandomProvider),
  );
  final bot = Phase0aPlayerBotAdapter(
    playerAdapter: fixture.mapping.playerAdapter,
    policy: _policy,
  );
  if (mode == _Mode.headless) {
    final result = Phase0aHeadlessRunner.runToEnd(
      flow: fixture.flow,
      bot: bot,
      deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: repository.numbers.phase0aArena.maxSimulationTicks,
    );
    return Phase0aSettlementAdapter.fromMapping(
      mapping: fixture.mapping,
      outcome: result.outcome,
      finalState: result.finalState,
      events: result.events,
    );
  }
  final controller = Phase0aBattleController(
    flow: fixture.flow,
    roster: Phase0aVisualRoster.fromMapping(fixture.mapping),
    fixedDeltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
  );
  var ticks = 0;
  while (controller.outcome == Phase0aBattleOutcome.ongoing &&
      ticks < repository.numbers.phase0aArena.maxSimulationTicks) {
    controller.step(bot.commandFor(controller.state));
    ticks++;
  }
  final settlement = Phase0aSettlementAdapter.fromMapping(
    mapping: fixture.mapping,
    outcome: controller.outcome,
    finalState: controller.state,
    events: controller.events,
  );
  controller.dispose();
  return settlement;
}

final class _RewardSnapshot {
  const _RewardSnapshot({
    required this.equipmentCounts,
    required this.itemQuantities,
    required this.experience,
  });

  final Map<String, int> equipmentCounts;
  final Map<String, int> itemQuantities;
  final int experience;

  static Future<_RewardSnapshot> capture(int characterId) async {
    final equipments = await IsarSetup.instance.equipments.where().findAll();
    final items = await IsarSetup.instance.inventoryItems.where().findAll();
    final character = await IsarSetup.instance.characters.get(characterId);
    if (character == null) throw StateError('N14 character disappeared');
    return _RewardSnapshot(
      equipmentCounts: _counts(equipments.map((item) => item.defId)),
      itemQuantities: {for (final item in items) item.defId: item.quantity},
      experience: character.experience,
    );
  }

  _RewardProfile deltaFrom(_RewardSnapshot before) => _RewardProfile(
    equipmentCounts: _mapDelta(equipmentCounts, before.equipmentCounts),
    itemQuantities: _mapDelta(itemQuantities, before.itemQuantities),
    experience: experience - before.experience,
  );
}

final class _RewardProfile {
  const _RewardProfile({
    required this.equipmentCounts,
    required this.itemQuantities,
    required this.experience,
  });

  final Map<String, int> equipmentCounts;
  final Map<String, int> itemQuantities;
  final int experience;

  String get canonical =>
      'equipment=${_mapSummary(equipmentCounts)};'
      'items=${_mapSummary(itemQuantities)};exp=$experience';
  String get digest => _stableDigest(canonical);
}

final class _RefHarness extends ConsumerWidget {
  const _RefHarness({required this.onReady});

  final ValueChanged<WidgetRef> onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}

Map<String, int> _counts(Iterable<String> values) {
  final result = <String, int>{};
  for (final value in values) {
    result[value] = (result[value] ?? 0) + 1;
  }
  return result;
}

Map<String, int> _mapDelta(Map<String, int> after, Map<String, int> before) {
  final keys = {...after.keys, ...before.keys}.toList()..sort();
  return {
    for (final key in keys)
      if ((after[key] ?? 0) - (before[key] ?? 0) != 0)
        key: (after[key] ?? 0) - (before[key] ?? 0),
  };
}

String _commandSummary(Phase0aPlayerCommand command) => [
  command.left,
  command.right,
  command.up,
  command.down,
  command.attack,
  command.attackAimDirection?.x,
  command.attackAimDirection?.y,
  command.skillHotkey,
  command.skillAimDirection?.x,
  command.skillAimDirection?.y,
  command.gather,
  command.clear,
  command.defenseAction?.name,
  command.defenseDirection?.x,
  command.defenseDirection?.y,
].join(',');

String _stateSummary(Phase0aArenaState state) => [
  state.tick,
  state.nextSeq,
  _actorSummary(state.player),
  for (final enemy in state.enemies) _actorSummary(enemy),
  for (final slot in state.skillSlots)
    '${slot.slot},${slot.cooldownRemaining},${slot.qiCost},${slot.availability.name}',
  state.winCondition?.type.name,
  state.winCondition?.surviveTicksRequired,
].join('|');

String _actorSummary(Phase0aActor actor) => [
  actor.id,
  actor.side.name,
  actor.position.x,
  actor.position.y,
  actor.facing.x,
  actor.facing.y,
  actor.maxHealth,
  actor.currentHealth,
  actor.moveSpeed,
  actor.qiCurrent,
  actor.qiMax,
  actor.attackCooldownRemaining,
  actor.defeatKind.name,
  actor.bossPhaseIndex,
  actor.unlockedEnemySkillIds.join(','),
  _mapSummary(actor.enemySkillCooldowns),
  actor.chargeTicksRemaining,
  actor.staggerTicksRemaining,
  actor.shieldRemaining,
  actor.shieldTicksRemaining,
  actor.parryTicksRemaining,
  actor.dodgeTicksRemaining,
  actor.defenseCooldownRemaining,
  actor.parryCounterDamage,
  actor.parryCounterBudgetRemaining,
].join(',');

String _recordSummary(CombatEventRecord record) => [
  record.eventId,
  record.tick,
  record.stage.name,
  record.tieBreak,
  record.aggregateKey,
  record.priority,
  record.feedKind.name,
].join(',');

String _settlementSummary(CombatSettlementSnapshot settlement) => [
  settlement.result?.name,
  settlement.totalTicks,
  settlement.hadActions,
  settlement.playerCharacterId,
  settlement.totalDamage,
  settlement.criticalCount,
  for (final participant in settlement.participants)
    '${participant.characterId},${participant.currentHp},${participant.maxHp}',
  for (final cast in settlement.skillCasts)
    '${cast.tick},${cast.characterId},${cast.skillId}',
  _mapSummary(settlement.damageByCharacterId),
].join('|');

String _mapSummary(Map<Object, Object> values) {
  final entries = values.entries.toList()
    ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
  return entries.map((entry) => '${entry.key}:${entry.value}').join(',');
}

String _stableDigest(String value) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
