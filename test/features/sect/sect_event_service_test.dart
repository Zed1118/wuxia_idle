import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';

/// P3.4 §12.1 Batch 2.2 service R1 触发链路测族(spec §7 R1)。
///
/// 不实例化 Isar(memory `feedback_isar_autoincrement_test_id_collision`),
/// 走 pure-ish service + NumbersConfigStub(noSuchMethod 暴露 raw 一字段)。
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
      'sect_level': {'max': 7, 'initial': 1, 'promote_wins_threshold': 3},
      'active_events_max': 3,
    },
  };
  final numbers = NumbersConfigStub(yaml);
  final svc = SectEventService(numbers: numbers);

  Sect baseSect({DateTime? lastEventAt, int rep = 50}) => Sect()
    ..id = 1
    ..name = '无名宗'
    ..founderId = 1
    ..sectLevel = 1
    ..sectReputation = rep
    ..totalWins = 0
    ..createdAt = DateTime(2026, 5, 1)
    ..lastEventAt = lastEventAt;

  SectEvent activeStub({int sectId = 1}) => SectEvent()
    ..sectId = sectId
    ..type = SectEventType.tournament
    ..status = SectEventStatus.pending
    ..triggeredAt = DateTime(2026, 5, 24)
    ..narrativeId = 'tournament_active';

  group('P3.4 sect_event service R1 触发链路', () {
    test(
      'R1.1 cooldown OK + 境界 OK + active 未满 + rng=0.0 必触发 → 返 pending event',
      () {
        final sect = baseSect(lastEventAt: null);
        final rng = _DeterministicRng([0.0]);
        final ev = svc.checkAndTrigger(
          sect: sect,
          activeEvents: const [],
          playerRealm: RealmTier.yiLiu,
          now: DateTime(2026, 5, 24),
          pickedNarrativeId: 'tournament_01',
          rng: rng,
        );
        expect(ev, isNotNull);
        expect(ev!.sectId, 1);
        expect(ev.type, SectEventType.tournament);
        expect(ev.status, SectEventStatus.pending);
        expect(ev.narrativeId, 'tournament_01');
        expect(ev.resolvedAt, isNull);
        expect(ev.reputationDelta, isNull);
      },
    );

    test('R1.2 cooldown 未到(lastEventAt 1 天前)→ 返 null', () {
      final now = DateTime(2026, 5, 24);
      final sect = baseSect(lastEventAt: now.subtract(const Duration(days: 1)));
      final rng = _DeterministicRng([0.0]);
      final ev = svc.checkAndTrigger(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: now,
        pickedNarrativeId: 'tournament_01',
        rng: rng,
      );
      expect(ev, isNull, reason: 'cooldown=30d,距上次 1d < 30d');
    });

    test('R1.3 境界不够(xueTu < yiLiu)→ 返 null', () {
      final sect = baseSect(lastEventAt: null);
      final rng = _DeterministicRng([0.0]);
      final ev = svc.checkAndTrigger(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.xueTu,
        now: DateTime(2026, 5, 24),
        pickedNarrativeId: 'tournament_01',
        rng: rng,
      );
      expect(
        ev,
        isNull,
        reason: 'trigger_realm_min=yiLiu,xueTu index(0) < yiLiu index(3)',
      );
    });

    test('R1.4 activeEvents 已 3 条达上限 → 返 null', () {
      final sect = baseSect(lastEventAt: null);
      final rng = _DeterministicRng([0.0]);
      final ev = svc.checkAndTrigger(
        sect: sect,
        activeEvents: [activeStub(), activeStub(), activeStub()],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 5, 24),
        pickedNarrativeId: 'tournament_01',
        rng: rng,
      );
      expect(ev, isNull, reason: 'active_events_max=3,已 3 条不再触发');
    });
  });
}

/// 仅 raw map 的 NumbersConfig stub(对齐
/// test/features/inheritance/application/founder_buff_service_test.dart 体例)。
class NumbersConfigStub implements NumbersConfig {
  const NumbersConfigStub(this._raw);
  final Map<String, dynamic> _raw;

  @override
  Map<String, dynamic> get raw => _raw;

  @override
  SectEventDef get sectEvent => SectEventDef.fromYaml(
    (_raw['sect_event'] as Map?)?.cast<String, dynamic>(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'NumbersConfigStub: only raw impl, invocation=${invocation.memberName}',
  );
}

/// 确定性 rng:按 queue 顺序吐固定 double 值(供 R1 触发概率分支测)。
class _DeterministicRng implements Random {
  _DeterministicRng(List<double> values) : _queue = List.of(values);
  final List<double> _queue;

  @override
  double nextDouble() {
    if (_queue.isEmpty) {
      throw StateError('_DeterministicRng exhausted');
    }
    return _queue.removeAt(0);
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}
