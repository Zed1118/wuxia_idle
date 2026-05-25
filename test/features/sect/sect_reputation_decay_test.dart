import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_reputation_decay.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/domain/sect_outcome.dart';

/// P3.4 §12.1 Batch 2.2 R2 联动测族(spec §7 R2):
/// resolve win/loss/expired → reputation/totalWins/sectLevel 联动
/// + SectReputationDecayService 30d idle → -5 decay。
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
  final numbers = NumbersConfigStub(yaml);
  final svc = SectEventService(numbers: numbers);
  final decay = SectReputationDecayService(numbers: numbers);

  Sect baseSect({
    int rep = 50,
    int totalWins = 0,
    int level = 1,
    DateTime? lastEventAt,
  }) =>
      Sect()
        ..id = 1
        ..name = '无名宗'
        ..founderId = 1
        ..sectLevel = level
        ..sectReputation = rep
        ..totalWins = totalWins
        ..createdAt = DateTime(2026, 5, 1)
        ..lastEventAt = lastEventAt;

  SectEvent pending() => SectEvent()
    ..sectId = 1
    ..type = SectEventType.tournament
    ..status = SectEventStatus.pending
    ..triggeredAt = DateTime(2026, 5, 24)
    ..narrativeId = 'tournament_01';

  group('P3.4 sect_event service R2 联动', () {
    test('R2.1 win → reputation +10 / totalWins +1 / 第 3 胜 sectLevel +1', () {
      // 前 2 胜:rep/level 涨 rep,wins +1,但 level 不变
      var sect = baseSect(rep: 50, totalWins: 0, level: 1);
      var ev = pending();
      final (s2, e2) = svc.resolve(
        sect: sect,
        event: ev,
        outcome: SectOutcome.win,
        now: DateTime(2026, 6, 24),
      );
      expect(s2.sectReputation, 60);
      expect(s2.totalWins, 1);
      expect(s2.sectLevel, 1, reason: '第 1 胜不升 level');
      expect(e2.status, SectEventStatus.resolved);
      expect(e2.reputationDelta, 10);
      expect(e2.resolvedAt, DateTime(2026, 6, 24));
      expect(s2.lastEventAt, DateTime(2026, 6, 24));

      // 第 2 胜
      sect = baseSect(rep: 60, totalWins: 1, level: 1);
      ev = pending();
      final (s3, _) = svc.resolve(
        sect: sect,
        event: ev,
        outcome: SectOutcome.win,
        now: DateTime(2026, 7, 24),
      );
      expect(s3.sectReputation, 70);
      expect(s3.totalWins, 2);
      expect(s3.sectLevel, 1);

      // 第 3 胜 → level +1
      sect = baseSect(rep: 70, totalWins: 2, level: 1);
      ev = pending();
      final (s4, _) = svc.resolve(
        sect: sect,
        event: ev,
        outcome: SectOutcome.win,
        now: DateTime(2026, 8, 24),
      );
      expect(s4.sectReputation, 80);
      expect(s4.totalWins, 3);
      expect(s4.sectLevel, 2, reason: 'promote_wins_threshold=3,第 3 胜升 level');
    });

    test('R2.2 loss → reputation -5,base=0 时 clamp ≥0 不变', () {
      // 普通 loss
      var sect = baseSect(rep: 50);
      final (s2, e2) = svc.resolve(
        sect: sect,
        event: pending(),
        outcome: SectOutcome.loss,
        now: DateTime(2026, 6, 24),
      );
      expect(s2.sectReputation, 45);
      expect(s2.totalWins, 0, reason: 'loss 不动 totalWins');
      expect(s2.sectLevel, 1);
      expect(e2.status, SectEventStatus.resolved);
      expect(e2.reputationDelta, -5);

      // base=0 loss → clamp 不变
      sect = baseSect(rep: 0);
      final (s3, _) = svc.resolve(
        sect: sect,
        event: pending(),
        outcome: SectOutcome.loss,
        now: DateTime(2026, 6, 24),
      );
      expect(s3.sectReputation, 0, reason: 'min=0 clamp');
    });

    test('R2.3 expired → reputation -5 + status=expired', () {
      final sect = baseSect(rep: 50);
      final (s2, e2) = svc.resolve(
        sect: sect,
        event: pending(),
        outcome: SectOutcome.expired,
        now: DateTime(2026, 6, 1),
      );
      expect(s2.sectReputation, 45);
      expect(e2.status, SectEventStatus.expired,
          reason: 'expired 路 status 不是 resolved');
      expect(e2.reputationDelta, -5);
      expect(e2.resolvedAt, DateTime(2026, 6, 1));
    });

    test('R2.4 decay: lastEventAt 30 天前 → -5;< 30d 与 null 各 0', () {
      final now = DateTime(2026, 6, 24);

      // 距 30 天 → -5
      final stale = baseSect(rep: 50, lastEventAt: now.subtract(const Duration(days: 30)));
      expect(decay.computeDecay(sect: stale, now: now), -5);

      // 距 31 天 → -5
      final older = baseSect(rep: 50, lastEventAt: now.subtract(const Duration(days: 31)));
      expect(decay.computeDecay(sect: older, now: now), -5);

      // 距 29 天 → 0
      final fresh = baseSect(rep: 50, lastEventAt: now.subtract(const Duration(days: 29)));
      expect(decay.computeDecay(sect: fresh, now: now), 0);

      // null → 0(新建 sect)
      final blank = baseSect(rep: 50, lastEventAt: null);
      expect(decay.computeDecay(sect: blank, now: now), 0);
    });

    test('R2.5 sectLevel clamp ≤ max(连胜 21 场 → level 7 后不再升)', () {
      // 模拟连续 21 胜:第 3/6/9/12/15/18/21 → level +1 → 上 7
      var sect = baseSect(rep: 50, totalWins: 0, level: 1);
      for (var i = 0; i < 21; i++) {
        final (s, _) = svc.resolve(
          sect: sect,
          event: pending(),
          outcome: SectOutcome.win,
          now: DateTime(2026, 6, i + 1),
        );
        sect = s;
      }
      expect(sect.totalWins, 21);
      expect(sect.sectLevel, 7, reason: 'levelMax=7 已上限');
      expect(sect.sectReputation, 100, reason: 'repMax=100 已上限');

      // 第 22-24 胜:totalWins=24 触发 promote 但 clamp 守住 7
      for (var i = 0; i < 3; i++) {
        final (s, _) = svc.resolve(
          sect: sect,
          event: pending(),
          outcome: SectOutcome.win,
          now: DateTime(2026, 7, i + 1),
        );
        sect = s;
      }
      expect(sect.totalWins, 24);
      expect(sect.sectLevel, 7, reason: 'clamp ≤ max 守住');
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
      (_raw['sect_event'] as Map?)?.cast<String, dynamic>());

  @override
  PvpDef get pvp =>
      PvpDef.fromYaml((_raw['pvp'] as Map?)?.cast<String, dynamic>());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'NumbersConfigStub: only raw impl, invocation=${invocation.memberName}');
}
