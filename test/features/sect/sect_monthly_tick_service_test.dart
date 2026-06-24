import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_monthly_tick_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_reputation_decay.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';

/// B1 接通门派事件 game loop · 月度 tick 编排纯函数测族
/// (spec `2026-06-24-b1-sect-event-game-loop-wiring-design.md` §6)。
///
/// 不实例化 Isar(memory `feedback_isar_autoincrement_test_id_collision`),
/// 走 pure-ish service + NumbersConfigStub。
void main() {
  final yaml = <String, dynamic>{
    'sect_event': {
      'tournament': {
        'trigger_probability': 0.30,
        'cooldown_days': 30,
        'trigger_realm_min': 'yiLiu',
        'expire_days': 7,
        'narrative_ids': ['tournament_01', 'tournament_02', 'tournament_03'],
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
  final numbers = NumbersConfigStub(yaml);
  final tick = SectMonthlyTickService(
    eventSvc: SectEventService(numbers: numbers),
    decaySvc: SectReputationDecayService(numbers: numbers),
    numbers: numbers,
  );

  Sect baseSect({
    DateTime? lastEventAt,
    DateTime? lastTickAt,
    int rep = 50,
    DateTime? createdAt,
  }) =>
      Sect()
        ..id = 1
        ..name = '无名宗'
        ..founderId = 1
        ..sectLevel = 1
        ..sectReputation = rep
        ..totalWins = 0
        ..createdAt = createdAt ?? DateTime(2026, 1, 1)
        ..lastEventAt = lastEventAt
        ..lastTickAt = lastTickAt;

  SectEvent pending({required DateTime triggeredAt, String narrativeId = 'tournament_01'}) =>
      SectEvent()
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = triggeredAt
        ..narrativeId = narrativeId;

  group('B1 月度 tick · 月数 catch-up', () {
    test('R1 同月再开(<30 天)→ 不触发 / lastTickAt 不变', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1));
      final r = tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 6, 20), // 19 天
        rng: _SeqRng(doubles: [0.0], ints: [0]),
      );
      expect(r.newEvents, isEmpty);
      expect(sect.lastTickAt, DateTime(2026, 6, 1), reason: '<1 月不推进锚点');
    });

    test('R2 满 1 月 + prob 命中 → 1 新 pending(narrativeId 取自池)+ 锚点推进 30 天', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1));
      final r = tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5), // 34 天 → 1 月
        rng: _SeqRng(doubles: [0.0], ints: [1]), // 0.0<0.30 命中 · pick idx 1
      );
      expect(r.newEvents.length, 1);
      expect(r.newEvents.first.narrativeId, 'tournament_02');
      expect(r.newEvents.first.status, SectEventStatus.pending);
      expect(sect.lastTickAt, DateTime(2026, 7, 1), reason: '锚点 += 1×30 天,保 4 天余数');
    });

    test('R3 满 1 月 + prob 未命中 → 0 新事件但锚点仍推进', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1));
      final r = tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.99], ints: [0]), // 0.99≥0.30 不命中
      );
      expect(r.newEvents, isEmpty);
      expect(sect.lastTickAt, DateTime(2026, 7, 1));
    });

    test('R4 多月 catch-up(3 月 prob 全命中)→ 受 active_events_max=3 clamp', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 4, 1));
      final r = tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5), // 95 天 → 3 月
        rng: _SeqRng(doubles: [0.0, 0.0, 0.0], ints: [0, 1, 2]),
      );
      expect(r.newEvents.length, 3, reason: '3 月各触发 1 件,cap=3 不越');
      expect(sect.lastTickAt, DateTime(2026, 4, 1).add(const Duration(days: 90)));
    });

    test('R4b 已有 2 active + 多月命中 → 仅再生成 1 件至 cap', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 4, 1));
      final existing = [
        pending(triggeredAt: DateTime(2026, 7, 4)),
        pending(triggeredAt: DateTime(2026, 7, 4)),
      ];
      final r = tick.compute(
        sect: sect,
        activeEvents: existing,
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5), // 3 月
        rng: _SeqRng(doubles: [0.0, 0.0, 0.0], ints: [0, 0, 0]),
      );
      expect(r.newEvents.length, 1, reason: '已 2 active,cap=3 仅余 1 槽');
    });

    test('R5 境界不足(erLiu < yiLiu)→ 不触发', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1));
      final r = tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.erLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.0], ints: [0]),
      );
      expect(r.newEvents, isEmpty);
    });
  });

  group('B1 月度 tick · 过期扫描(不绑月界)', () {
    test('R6 pending 超 7 天 → expired + rep -5', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 7, 4), rep: 50);
      final stale = pending(triggeredAt: DateTime(2026, 6, 20)); // 15 天
      final r = tick.compute(
        sect: sect,
        activeEvents: [stale],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.99], ints: [0]),
      );
      expect(r.expiredEvents.length, 1);
      expect(stale.status, SectEventStatus.expired);
      expect(sect.sectReputation, 45, reason: 'loss_delta -5');
    });

    test('R7 pending 6 天 → 不过期', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 7, 4), rep: 50);
      final fresh = pending(triggeredAt: DateTime(2026, 6, 29)); // 6 天
      final r = tick.compute(
        sect: sect,
        activeEvents: [fresh],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.99], ints: [0]),
      );
      expect(r.expiredEvents, isEmpty);
      expect(fresh.status, SectEventStatus.pending);
    });
  });

  group('B1 月度 tick · 声望衰减', () {
    test('R8 idle ≥30 天多月 → 每月累扣 5', () {
      // lastEventAt 很久以前 → 每个 elapsed month 都 idle 扣 5。
      final sect = baseSect(
        lastEventAt: DateTime(2026, 1, 1),
        lastTickAt: DateTime(2026, 4, 1),
        rep: 50,
      );
      tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5), // 3 月
        rng: _SeqRng(doubles: [0.99, 0.99, 0.99], ints: [0, 0, 0]),
      );
      expect(sect.sectReputation, 35, reason: '3 月 × -5 = -15');
    });

    test('R9 lastEventAt == null(初创)→ 不衰减', () {
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1), rep: 50);
      tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.99], ints: [0]),
      );
      expect(sect.sectReputation, 50);
    });

    test('R10 衰减 clamp ≥0 不越下界', () {
      final sect = baseSect(
        lastEventAt: DateTime(2026, 1, 1),
        lastTickAt: DateTime(2026, 1, 1),
        rep: 3,
      );
      tick.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5), // 6 月 × -5 = -30 → clamp 0
        rng: _SeqRng(doubles: List.filled(6, 0.99), ints: List.filled(6, 0)),
      );
      expect(sect.sectReputation, 0);
    });
  });

  group('B1 月度 tick · 防御', () {
    test('R11 narrative_ids 空池 → 不触发(防空 pick 崩)', () {
      final emptyPoolYaml = Map<String, dynamic>.from(yaml);
      emptyPoolYaml['sect_event'] = {
        ...yaml['sect_event'] as Map,
        'tournament': {
          'trigger_probability': 1.0,
          'cooldown_days': 30,
          'trigger_realm_min': 'yiLiu',
          'expire_days': 7,
          'narrative_ids': <String>[],
        },
      };
      final stub = NumbersConfigStub(emptyPoolYaml);
      final t = SectMonthlyTickService(
        eventSvc: SectEventService(numbers: stub),
        decaySvc: SectReputationDecayService(numbers: stub),
        numbers: stub,
      );
      final sect = baseSect(lastTickAt: DateTime(2026, 6, 1));
      final r = t.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: DateTime(2026, 7, 5),
        rng: _SeqRng(doubles: [0.0], ints: [0]),
      );
      expect(r.newEvents, isEmpty);
    });
  });
}

/// 仅 raw map 的 NumbersConfig stub(沿 sect_event_service_test 体例)。
class NumbersConfigStub implements NumbersConfig {
  const NumbersConfigStub(this._raw);
  final Map<String, dynamic> _raw;

  @override
  Map<String, dynamic> get raw => _raw;

  @override
  SectEventDef get sectEvent => SectEventDef.fromYaml(
      (_raw['sect_event'] as Map?)?.cast<String, dynamic>());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'NumbersConfigStub: only raw impl, invocation=${invocation.memberName}');
}

/// 确定性 rng:doubles 供概率分支 · ints 供 narrativeId pick。
class _SeqRng implements Random {
  _SeqRng({List<double> doubles = const [], List<int> ints = const []})
      : _doubles = List.of(doubles),
        _ints = List.of(ints);
  final List<double> _doubles;
  final List<int> _ints;

  @override
  double nextDouble() {
    if (_doubles.isEmpty) throw StateError('_SeqRng doubles exhausted');
    return _doubles.removeAt(0);
  }

  @override
  int nextInt(int max) {
    if (_ints.isEmpty) throw StateError('_SeqRng ints exhausted');
    return _ints.removeAt(0) % max;
  }

  @override
  bool nextBool() => throw UnimplementedError();
}
