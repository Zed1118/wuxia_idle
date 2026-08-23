// Red-first tests for the P2-G2-D02 AttackTokenDirector pure domain contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';

AttackTokenRequest _request({
  String actorId = 'bandit_01',
  AttackTokenKind kind = AttackTokenKind.melee,
  int priority = 0,
  bool isOffscreen = false,
  bool isHighImpact = false,
  bool isUnblockableArea = false,
  int spawnGraceTicksRemaining = 0,
  bool telegraphReady = true,
}) {
  return AttackTokenRequest(
    actorId: actorId,
    kind: kind,
    priority: priority,
    isOffscreen: isOffscreen,
    isHighImpact: isHighImpact,
    isUnblockableArea: isUnblockableArea,
    spawnGraceTicksRemaining: spawnGraceTicksRemaining,
    telegraphReady: telegraphReady,
  );
}

AttackTokenBudgets _budgets({
  int melee = 1,
  int ranged = 1,
  int charge = 1,
  int support = 1,
}) {
  return AttackTokenBudgets(
    melee: melee,
    ranged: ranged,
    charge: charge,
    support: support,
  );
}

void main() {
  const director = AttackTokenDirector();

  group('budget validation (caller-supplied, no hardcoded defaults)', () {
    test('negative budgets throw', () {
      expect(() => AttackTokenBudgets(melee: -1, ranged: 0, charge: 0, support: 0), throwsArgumentError);
      expect(() => AttackTokenBudgets(melee: 0, ranged: -1, charge: 0, support: 0), throwsArgumentError);
      expect(() => AttackTokenBudgets(melee: 0, ranged: 0, charge: -1, support: 0), throwsArgumentError);
      expect(() => AttackTokenBudgets(melee: 0, ranged: 0, charge: 0, support: -1), throwsArgumentError);
    });

    test('zero budgets are accepted and deny everything via budgetExhausted', () {
      final allocation = director.allocate(
        budgets: AttackTokenBudgets(melee: 0, ranged: 0, charge: 0, support: 0),
        requests: [
          _request(actorId: 'a', kind: AttackTokenKind.melee),
          _request(actorId: 'b', kind: AttackTokenKind.ranged),
          _request(actorId: 'c', kind: AttackTokenKind.charge),
          _request(actorId: 'd', kind: AttackTokenKind.support),
        ],
      );
      expect(allocation.grantedCount, 0);
      for (final decision in allocation.decisions) {
        expect(decision.granted, isFalse);
        expect(decision.denial, AttackTokenDenial.budgetExhausted);
      }
    });
  });

  group('request validation', () {
    test('empty actorId throws', () {
      expect(() => _request(actorId: ''), throwsArgumentError);
    });

    test('negative priority throws', () {
      expect(() => _request(priority: -1), throwsArgumentError);
    });

    test('negative spawn grace throws', () {
      expect(() => _request(spawnGraceTicksRemaining: -1), throwsArgumentError);
    });

    test('duplicate actorId fails closed', () {
      expect(
        () => director.allocate(
          budgets: _budgets(melee: 4),
          requests: [_request(actorId: 'dup'), _request(actorId: 'dup')],
        ),
        throwsArgumentError,
      );
    });
  });

  group('grants and per-kind budgets', () {
    test('grants when budget is available', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 1),
        requests: [_request(actorId: 'a')],
      );
      expect(allocation.grantedCount, 1);
      final decision = allocation.decisions.single;
      expect(decision.actorId, 'a');
      expect(decision.kind, AttackTokenKind.melee);
      expect(decision.granted, isTrue);
      expect(decision.denial, isNull);
    });

    test('budgets are independent per kind', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 1, ranged: 1, charge: 1, support: 1),
        requests: [
          _request(actorId: 'm1', kind: AttackTokenKind.melee),
          _request(actorId: 'r1', kind: AttackTokenKind.ranged),
          _request(actorId: 'c1', kind: AttackTokenKind.charge),
          _request(actorId: 's1', kind: AttackTokenKind.support),
          _request(actorId: 'm2', kind: AttackTokenKind.melee),
        ],
      );
      expect(allocation.grantedCount, 4);
      final m2 = allocation.decisions.firstWhere((d) => d.actorId == 'm2');
      expect(m2.granted, isFalse);
      expect(m2.denial, AttackTokenDenial.budgetExhausted);
    });
  });

  group('fail-closed safety gates', () {
    test('spawn grace denies even with budget available', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [_request(actorId: 'a', spawnGraceTicksRemaining: 2)],
      );
      expect(allocation.grantedCount, 0);
      expect(allocation.decisions.single.denial, AttackTokenDenial.spawnGraceActive);
    });

    test('incomplete telegraph denies', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [_request(actorId: 'a', telegraphReady: false)],
      );
      expect(allocation.decisions.single.denial, AttackTokenDenial.telegraphIncomplete);
    });

    test('offscreen high-impact denies', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [_request(actorId: 'a', isOffscreen: true, isHighImpact: true)],
      );
      expect(allocation.decisions.single.denial, AttackTokenDenial.offscreenHighImpact);
    });

    test('offscreen without high impact can be granted', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [_request(actorId: 'a', isOffscreen: true, isHighImpact: false)],
      );
      expect(allocation.grantedCount, 1);
    });

    test('high impact onscreen can be granted', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [_request(actorId: 'a', isOffscreen: false, isHighImpact: true)],
      );
      expect(allocation.grantedCount, 1);
    });

    test('safety gates take precedence over budget exhaustion', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 0),
        requests: [_request(actorId: 'a', spawnGraceTicksRemaining: 1)],
      );
      expect(allocation.decisions.single.denial, AttackTokenDenial.spawnGraceActive);
    });
  });

  group('unblockable area cap', () {
    test('at most one unblockable area grant per batch', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [
          _request(actorId: 'a', priority: 1, isUnblockableArea: true),
          _request(actorId: 'b', priority: 0, isUnblockableArea: true),
        ],
      );
      final a = allocation.decisions.firstWhere((d) => d.actorId == 'a');
      final b = allocation.decisions.firstWhere((d) => d.actorId == 'b');
      expect(a.granted, isTrue);
      expect(b.granted, isFalse);
      expect(b.denial, AttackTokenDenial.unblockableAreaLimit);
    });

    test('category budgets cannot bypass the unblockable area cap', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4, ranged: 4, charge: 4, support: 4),
        requests: [
          _request(actorId: 'a', kind: AttackTokenKind.melee, isUnblockableArea: true),
          _request(actorId: 'b', kind: AttackTokenKind.charge, isUnblockableArea: true),
          _request(actorId: 'c', kind: AttackTokenKind.ranged, isUnblockableArea: true),
          _request(actorId: 'd', kind: AttackTokenKind.support, isUnblockableArea: true),
        ],
      );
      expect(allocation.grantedCount, 1);
      final denied = allocation.decisions.where((d) => !d.granted).toList();
      expect(denied, hasLength(3));
      for (final d in denied) {
        expect(d.denial, AttackTokenDenial.unblockableAreaLimit);
      }
    });
  });

  group('deterministic ordering', () {
    test('higher priority wins the last budget slot', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 1),
        requests: [
          _request(actorId: 'low', priority: 0),
          _request(actorId: 'high', priority: 5),
        ],
      );
      final high = allocation.decisions.firstWhere((d) => d.actorId == 'high');
      final low = allocation.decisions.firstWhere((d) => d.actorId == 'low');
      expect(high.granted, isTrue);
      expect(low.granted, isFalse);
      expect(low.denial, AttackTokenDenial.budgetExhausted);
    });

    test('priority ties break by actorId ascending', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 1),
        requests: [
          _request(actorId: 'zz', priority: 3),
          _request(actorId: 'aa', priority: 3),
        ],
      );
      expect(allocation.decisions.first.actorId, 'aa');
      expect(allocation.decisions.first.granted, isTrue);
      expect(allocation.decisions.last.actorId, 'zz');
      expect(allocation.decisions.last.granted, isFalse);
    });

    test('result is independent of input order', () {
      final budgets = _budgets(melee: 2);
      final requests = [
        _request(actorId: 'a', priority: 1),
        _request(actorId: 'b', priority: 4),
        _request(actorId: 'c', priority: 2),
        _request(actorId: 'd', priority: 4),
      ];
      final first = director.allocate(budgets: budgets, requests: requests);
      final second = director.allocate(budgets: budgets, requests: requests.reversed.toList());
      expect(second.decisions, first.decisions);
      expect(second.grantedActorIds, ['b', 'd']);
    });

    test('decisions are emitted in deterministic candidate order', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 4),
        requests: [
          _request(actorId: 'c', priority: 1),
          _request(actorId: 'a', priority: 2),
          _request(actorId: 'b', priority: 2),
        ],
      );
      expect(
        allocation.decisions.map((d) => d.actorId).toList(),
        ['a', 'b', 'c'],
      );
    });
  });

  group('output contract', () {
    test('empty requests yield empty allocation', () {
      final allocation = director.allocate(budgets: _budgets(), requests: const []);
      expect(allocation.decisions, isEmpty);
      expect(allocation.grantedCount, 0);
      expect(allocation.grantedActorIds, isEmpty);
    });

    test('decisions list is immutable', () {
      final allocation = director.allocate(
        budgets: _budgets(melee: 1),
        requests: [_request(actorId: 'a')],
      );
      expect(
        () => allocation.decisions.add(allocation.decisions.first),
        throwsUnsupportedError,
      );
    });

    test('request and budget inputs are defensively copied', () {
      final requests = [_request(actorId: 'a')];
      final allocation = director.allocate(budgets: _budgets(), requests: requests);
      expect(
        () => allocation.decisions.length,
        returnsNormally,
      );
      requests.add(_request(actorId: 'b'));
      expect(allocation.decisions, hasLength(1));
    });
  });
}
