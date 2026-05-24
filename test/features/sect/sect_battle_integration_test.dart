import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/application/sect_reputation_decay.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/domain/sect_outcome.dart';

import 'package:wuxia_idle/core/application/battle_providers.dart';

/// P3.4 Batch 2.3 战斗联动 R1 应战 e2e 整链测(spec §7 R1.5+)。
///
/// **测试范围**:in-memory service + SectStateNotifier 整链
/// (seed pending → notifier.resolve(win) → state.sect.totalWins +1 / reputation +10
///  + activeEvents 空 + historicalEvents +1)。
///
/// **不实例化 Isar / 不真 BattleScreen wire**(memory `feedback_isar_autoincrement_test_id_collision`)
/// · BattleScreen e2e 留 manual + golden 验收 + Phase 4 真持久化 wire 后做 widget e2e。
void main() {
  final yaml = <String, dynamic>{
    'sect_event': {
      'tournament': {
        'trigger_probability': 0.30,
        'cooldown_days': 30,
        'trigger_realm_min': 'yiLiu',
        'expire_days': 7,
      },
      'reputation': {
        'initial': 50,
        'win_delta': 10,
        'loss_delta': -5,
        'decay_per_month_idle': 5,
        'max': 100,
        'min': 0,
      },
      'sect_level': {
        'max': 7,
        'initial': 1,
        'promote_wins_threshold': 3,
      },
      'active_events_max': 3,
    },
  };

  /// 注 fake NumbersConfig 走 raw map(避 GameRepository.instance 未 init)。
  ProviderContainer makeContainer() {
    final numbers = NumbersConfigStub(yaml);
    final container = ProviderContainer(
      overrides: [
        numbersConfigProvider.overrideWithValue(numbers),
      ],
    );
    return container;
  }

  SectEvent makePending({int id = 100}) => SectEvent()
    ..id = id
    ..sectId = 1
    ..type = SectEventType.tournament
    ..status = SectEventStatus.pending
    ..triggeredAt = DateTime(2026, 5, 24)
    ..narrativeId = 'tournament_01';

  group('P3.4 R1 应战 e2e 整链', () {
    test(
        'R1.5 seed pending → notifier.resolve(win) → reputation 50→60 + totalWins 0→1 + activeEvents 空',
        () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sectStateProvider.notifier);
      final pending = makePending();
      notifier.seedActiveEvent(pending);

      expect(container.read(sectStateProvider).sect.sectReputation, 50);
      expect(container.read(sectStateProvider).sect.totalWins, 0);
      expect(container.read(sectStateProvider).activeEvents.length, 1);
      expect(container.read(sectStateProvider).historicalEvents.length, 0);

      notifier.resolve(event: pending, outcome: SectOutcome.win);

      final state = container.read(sectStateProvider);
      expect(state.sect.sectReputation, 60);
      expect(state.sect.totalWins, 1);
      expect(state.activeEvents.length, 0);
      expect(state.historicalEvents.length, 1);
      expect(state.historicalEvents.first.status, SectEventStatus.resolved);
      expect(state.historicalEvents.first.reputationDelta, 10);
    });

    test('R1.6 seed pending → notifier.resolve(loss · 拒绝路径)→ reputation 50→45',
        () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sectStateProvider.notifier);
      final pending = makePending();
      notifier.seedActiveEvent(pending);

      notifier.resolve(event: pending, outcome: SectOutcome.loss);

      final state = container.read(sectStateProvider);
      expect(state.sect.sectReputation, 45);
      expect(state.sect.totalWins, 0);
      expect(state.historicalEvents.first.reputationDelta, -5);
    });

    test('R1.7 3 连胜 → sectLevel 1→2(promote_wins_threshold=3)', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sectStateProvider.notifier);

      for (var i = 0; i < 3; i++) {
        final p = makePending(id: 100 + i);
        notifier.seedActiveEvent(p);
        notifier.resolve(event: p, outcome: SectOutcome.win);
      }

      final state = container.read(sectStateProvider);
      expect(state.sect.totalWins, 3);
      expect(state.sect.sectLevel, 2);
      // reputation 50 → 60 → 70 → 80(每胜 +10,未撞 max=100)
      expect(state.sect.sectReputation, 80);
    });
  });

  group('P3.4 Decay service provider wire', () {
    test('R1.8 sectReputationDecayServiceProvider 注入 numbers → 路径通',
        () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final decay = container.read(sectReputationDecayServiceProvider);
      expect(decay, isA<SectReputationDecayService>());
    });

    test('R1.9 sectEventServiceProvider 注入 numbers → 路径通', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final svc = container.read(sectEventServiceProvider);
      expect(svc, isA<SectEventService>());
    });
  });
}

class NumbersConfigStub implements NumbersConfig {
  const NumbersConfigStub(this._raw);
  final Map<String, dynamic> _raw;

  @override
  Map<String, dynamic> get raw => _raw;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'NumbersConfigStub: only raw impl, invocation=${invocation.memberName}');
}
