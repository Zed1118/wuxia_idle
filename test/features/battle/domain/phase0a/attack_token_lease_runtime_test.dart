import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';

AttackTokenRequest _request({
  required String actorId,
  AttackTokenKind kind = AttackTokenKind.melee,
  int priority = 0,
  bool isOffscreen = false,
  bool isHighImpact = false,
  bool isUnblockableArea = false,
  int spawnGraceTicksRemaining = 0,
  bool telegraphReady = true,
}) => AttackTokenRequest(
  actorId: actorId,
  kind: kind,
  priority: priority,
  isOffscreen: isOffscreen,
  isHighImpact: isHighImpact,
  isUnblockableArea: isUnblockableArea,
  spawnGraceTicksRemaining: spawnGraceTicksRemaining,
  telegraphReady: telegraphReady,
);

AttackTokenLease _lease(
  String leaseId, {
  required String actorId,
  AttackTokenRequest? request,
}) => AttackTokenLease(
  id: AttackTokenLeaseId(leaseId),
  request: request ?? _request(actorId: actorId),
);

void main() {
  group('snapshot and ordered mutations', () {
    test('empty runtime starts at revision zero', () {
      final runtime = AttackTokenLeaseRuntime.empty();

      expect(runtime.snapshot.revision, 0);
      expect(runtime.snapshot.activeLeases, isEmpty);
    });

    test('acquire returns a successor and preserves every request fact', () {
      final request = _request(
        actorId: 'archer_01',
        kind: AttackTokenKind.ranged,
        priority: 37,
        isOffscreen: true,
        isHighImpact: false,
        isUnblockableArea: true,
        spawnGraceTicksRemaining: 4,
        telegraphReady: false,
      );
      final lease = _lease(
        'lease_archer_01',
        actorId: request.actorId,
        request: request,
      );
      final runtime = AttackTokenLeaseRuntime.empty();
      final base = runtime.snapshot;

      final prepared = runtime.prepare([AcquireAttackTokenLease(lease)]);

      expect(prepared.base, same(base));
      expect(prepared.next.revision, 1);
      expect(runtime.snapshot, same(base));
      expect(runtime.snapshot.activeLeases, isEmpty);

      final successor = runtime.commit(prepared);
      final retained = successor.snapshot.activeLeases[lease.id]!;
      expect(successor, isNot(same(runtime)));
      expect(successor.snapshot, same(prepared.next));
      expect(retained.request, same(request));
      expect(retained.request.actorId, 'archer_01');
      expect(retained.request.kind, AttackTokenKind.ranged);
      expect(retained.request.priority, 37);
      expect(retained.request.isOffscreen, isTrue);
      expect(retained.request.isHighImpact, isFalse);
      expect(retained.request.isUnblockableArea, isTrue);
      expect(retained.request.spawnGraceTicksRemaining, 4);
      expect(retained.request.telegraphReady, isFalse);
    });

    test('release removes a known lease and increments revision once', () {
      final lease = _lease('lease_a', actorId: 'actor_a');
      final root = AttackTokenLeaseRuntime.empty();
      final acquired = root.commit(
        root.prepare([AcquireAttackTokenLease(lease)]),
      );

      final prepared = acquired.prepare([ReleaseAttackTokenLease(lease.id)]);
      final released = acquired.commit(prepared);

      expect(acquired.snapshot.revision, 1);
      expect(acquired.snapshot.activeLeases, contains(lease.id));
      expect(released.snapshot.revision, 2);
      expect(released.snapshot.activeLeases, isEmpty);
    });

    test('same-batch acquire and release follow declaration order', () {
      final lease = _lease('lease_ephemeral', actorId: 'actor_a');
      final runtime = AttackTokenLeaseRuntime.empty();

      final prepared = runtime.prepare([
        AcquireAttackTokenLease(lease),
        ReleaseAttackTokenLease(lease.id),
      ]);
      final successor = runtime.commit(prepared);

      expect(prepared.mutations, hasLength(2));
      expect(successor.snapshot.revision, 1);
      expect(successor.snapshot.activeLeases, isEmpty);
    });

    test('release then acquire permits an explicit same-actor replacement', () {
      final first = _lease('lease_first', actorId: 'actor_a');
      final replacement = _lease('lease_replacement', actorId: 'actor_a');
      final root = AttackTokenLeaseRuntime.empty();
      final acquired = root.commit(
        root.prepare([AcquireAttackTokenLease(first)]),
      );

      final replaced = acquired.commit(
        acquired.prepare([
          ReleaseAttackTokenLease(first.id),
          AcquireAttackTokenLease(replacement),
        ]),
      );

      expect(replaced.snapshot.activeLeases.keys, [replacement.id]);
    });
  });

  group('defensive snapshots', () {
    test('restore copies caller map and exposes an unmodifiable map', () {
      final lease = _lease('lease_seed', actorId: 'actor_seed');
      final callerMap = <AttackTokenLeaseId, AttackTokenLease>{lease.id: lease};
      final runtime = AttackTokenLeaseRuntime.restore(
        revision: 9,
        activeLeases: callerMap,
      );

      callerMap.clear();

      expect(runtime.snapshot.revision, 9);
      expect(runtime.snapshot.activeLeases, {lease.id: lease});
      expect(
        () => runtime.snapshot.activeLeases.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => runtime.snapshot.activeLeases[lease.id] = lease,
        throwsUnsupportedError,
      );
    });

    test('prepare copies caller iterable and exposes an unmodifiable list', () {
      final lease = _lease('lease_input', actorId: 'actor_input');
      final callerList = <AttackTokenLeaseMutation>[
        AcquireAttackTokenLease(lease),
      ];
      final runtime = AttackTokenLeaseRuntime.empty();

      final prepared = runtime.prepare(callerList);
      callerList.clear();

      expect(prepared.mutations, hasLength(1));
      expect(() => prepared.mutations.clear(), throwsUnsupportedError);
      final successor = runtime.commit(prepared);
      expect(successor.snapshot.activeLeases, contains(lease.id));
    });

    test('invalid restore identity and actor conflicts fail closed', () {
      final lease = _lease('lease_a', actorId: 'actor_a');
      expect(
        () => AttackTokenLeaseRuntime.restore(
          revision: 0,
          activeLeases: {AttackTokenLeaseId('different_key'): lease},
        ),
        throwsArgumentError,
      );
      expect(
        () => AttackTokenLeaseRuntime.restore(
          revision: 0,
          activeLeases: {
            lease.id: lease,
            AttackTokenLeaseId('lease_b'): _lease(
              'lease_b',
              actorId: 'actor_a',
            ),
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => AttackTokenLeaseRuntime.restore(
          revision: -1,
          activeLeases: const {},
        ),
        throwsArgumentError,
      );
    });
  });

  group('atomic failure and owner-bound commit', () {
    test('lazy iterable failure publishes nothing', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final originalSnapshot = runtime.snapshot;
      final lease = _lease('lease_a', actorId: 'actor_a');

      Iterable<AttackTokenLeaseMutation> lazyMutations() sync* {
        yield AcquireAttackTokenLease(lease);
        throw StateError('lazy mutation input failed');
      }

      expect(() => runtime.prepare(lazyMutations()), throwsStateError);
      expect(runtime.snapshot, same(originalSnapshot));
      expect(runtime.snapshot.activeLeases, isEmpty);
    });

    test('duplicate lease and actor acquire reject the whole batch', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final originalSnapshot = runtime.snapshot;
      final first = _lease('lease_a', actorId: 'actor_a');

      expect(
        () => runtime.prepare([
          AcquireAttackTokenLease(first),
          AcquireAttackTokenLease(first),
        ]),
        throwsStateError,
      );
      expect(
        () => runtime.prepare([
          AcquireAttackTokenLease(first),
          AcquireAttackTokenLease(_lease('lease_b', actorId: 'actor_a')),
        ]),
        throwsStateError,
      );
      expect(runtime.snapshot, same(originalSnapshot));
      expect(runtime.snapshot.activeLeases, isEmpty);
    });

    test('unknown release rejects the whole batch', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final originalSnapshot = runtime.snapshot;

      expect(
        () => runtime.prepare([
          ReleaseAttackTokenLease(AttackTokenLeaseId('missing')),
        ]),
        throwsStateError,
      );
      expect(runtime.snapshot, same(originalSnapshot));
    });

    test('foreign and non-exact predecessors fail closed', () {
      final root = AttackTokenLeaseRuntime.empty();
      final foreign = AttackTokenLeaseRuntime.empty();
      final prepared = root.prepare([
        AcquireAttackTokenLease(_lease('lease_a', actorId: 'actor_a')),
      ]);

      expect(() => foreign.commit(prepared), throwsStateError);

      final siblingPrepared = root.prepare([
        AcquireAttackTokenLease(_lease('lease_b', actorId: 'actor_b')),
      ]);
      final sibling = root.commit(siblingPrepared);
      expect(() => sibling.commit(prepared), throwsStateError);

      final successor = root.commit(prepared);
      expect(successor.snapshot.activeLeases.keys.single.value, 'lease_a');
      expect(() => root.commit(prepared), throwsStateError);
    });

    test(
      'failed mutation leaves runtime and snapshot identities untouched',
      () {
        final runtime = AttackTokenLeaseRuntime.empty();
        final originalRuntime = runtime;
        final originalSnapshot = runtime.snapshot;

        expect(
          () => runtime.prepare([
            AcquireAttackTokenLease(_lease('lease_a', actorId: 'actor_a')),
            ReleaseAttackTokenLease(AttackTokenLeaseId('unknown')),
          ]),
          throwsStateError,
        );

        expect(runtime, same(originalRuntime));
        expect(runtime.snapshot, same(originalSnapshot));
        expect(runtime.snapshot.revision, 0);
        expect(runtime.snapshot.activeLeases, isEmpty);
      },
    );

    test('separate prepared values produce isolated sibling successors', () {
      final root = AttackTokenLeaseRuntime.empty();
      final branchAPrepared = root.prepare([
        AcquireAttackTokenLease(_lease('lease_a', actorId: 'actor_a')),
      ]);
      final branchBPrepared = root.prepare([
        AcquireAttackTokenLease(_lease('lease_b', actorId: 'actor_b')),
      ]);

      final branchA = root.commit(branchAPrepared);
      final branchB = root.commit(branchBPrepared);

      expect(root.snapshot.activeLeases, isEmpty);
      expect(branchA.snapshot.activeLeases.keys.single.value, 'lease_a');
      expect(branchB.snapshot.activeLeases.keys.single.value, 'lease_b');
      expect(branchA.snapshot, isNot(same(branchB.snapshot)));
      expect(branchA.snapshot.revision, 1);
      expect(branchB.snapshot.revision, 1);
    });
  });

  test('lease IDs require canonical non-empty caller identity', () {
    expect(() => AttackTokenLeaseId(''), throwsArgumentError);
    expect(() => AttackTokenLeaseId('   '), throwsArgumentError);
    expect(() => AttackTokenLeaseId(' lease '), throwsArgumentError);
    expect(AttackTokenLeaseId('lease'), AttackTokenLeaseId('lease'));
  });

  test(
    'source contract stays isolated from production lifecycle inference',
    () {
      final source = File(
        'lib/features/battle/domain/phase0a/attack_token_lease_runtime.dart',
      ).readAsStringSync();
      final imports = RegExp(
        "^import '([^']+)';",
        multiLine: true,
      ).allMatches(source).map((match) => match.group(1)).toList();

      expect(imports, ['attack_token_director.dart']);
      for (final forbidden in const [
        'phase0a_combat_session',
        'attack_token_enforcing_batch_gate',
        'action_timeline',
        'phase0a_combat_adapter',
        'phase0a_combat_reducer',
        'phase0a_combat_events',
        'phase0a_combat_host',
        'AttackTokenDirector',
        'AttackTokenBudgets',
        'Phase0aIntent',
        'ActionTimeline',
        'Phase0aEvent',
        'Phase0aCombatState',
        'DamagePacket',
        "'/data/",
        'candidate',
        'default',
        '.kind',
        '.priority',
        '.isOffscreen',
        '.isHighImpact',
        '.isUnblockableArea',
        '.spawnGraceTicksRemaining',
        '.telegraphReady',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    },
  );
}
