import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

SpawnEntry entry(String id) => SpawnEntry(entryId: id, enemyId: 'enemy_$id');

SpawnDirectorConfig cfg({
  int activeLimit = 8,
  int threshold = 2,
  int warning = 3,
  int grace = 2,
}) => SpawnDirectorConfig(
  activeLimit: activeLimit,
  reinforcementThreshold: threshold,
  entryWarningTicks: warning,
  attackGraceTicks: grace,
);

void expectSameState(SpawnDirectorState a, SpawnDirectorState b) {
  expect(a.tick, b.tick);
  expect(a.totalCount, b.totalCount);
  expect(a.activeCount, b.activeCount);
  expect(a.warningCount, b.warningCount);
  expect(a.pendingCount, b.pendingCount);
  expect(a.removedCount, b.removedCount);
  expect(a.units, b.units);
}

List<String> unitIds(SpawnDirectorState state) =>
    state.units.map((u) => u.entryId).toList();

List<String> activeIds(SpawnDirectorState state) => state.units
    .where((u) => u.stage == SpawnUnitStage.active)
    .map((u) => u.entryId)
    .toList();

void main() {
  group('SpawnDirectorConfig 严格校验', () {
    test('activeLimit 必须为正', () {
      expect(
        () => SpawnDirectorConfig(
          activeLimit: 0,
          reinforcementThreshold: 0,
          entryWarningTicks: 0,
          attackGraceTicks: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpawnDirectorConfig(
          activeLimit: -1,
          reinforcementThreshold: 0,
          entryWarningTicks: 0,
          attackGraceTicks: 0,
        ),
        throwsArgumentError,
      );
    });

    test('reinforcementThreshold 不得为负或达到 activeLimit', () {
      expect(
        () => SpawnDirectorConfig(
          activeLimit: 4,
          reinforcementThreshold: -1,
          entryWarningTicks: 0,
          attackGraceTicks: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpawnDirectorConfig(
          activeLimit: 4,
          reinforcementThreshold: 4,
          entryWarningTicks: 0,
          attackGraceTicks: 0,
        ),
        throwsArgumentError,
      );
    });

    test('entryWarningTicks 不得为负', () {
      expect(
        () => SpawnDirectorConfig(
          activeLimit: 4,
          reinforcementThreshold: 1,
          entryWarningTicks: -1,
          attackGraceTicks: 0,
        ),
        throwsArgumentError,
      );
    });

    test('attackGraceTicks 不得为负', () {
      expect(
        () => SpawnDirectorConfig(
          activeLimit: 4,
          reinforcementThreshold: 1,
          entryWarningTicks: 0,
          attackGraceTicks: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SpawnEntry 校验（fail closed）', () {
    test('空 / 纯空白 / 含空白 entryId 拒绝', () {
      expect(() => SpawnEntry(entryId: '', enemyId: 'x'), throwsArgumentError);
      expect(
        () => SpawnEntry(entryId: '   ', enemyId: 'x'),
        throwsArgumentError,
      );
      expect(
        () => SpawnEntry(entryId: 'a b', enemyId: 'x'),
        throwsArgumentError,
      );
      expect(
        () => SpawnEntry(entryId: ' ab', enemyId: 'x'),
        throwsArgumentError,
      );
    });

    test('空 / 纯空白 / 含空白 enemyId 拒绝', () {
      expect(() => SpawnEntry(entryId: 'a', enemyId: ''), throwsArgumentError);
      expect(
        () => SpawnEntry(entryId: 'a', enemyId: '  '),
        throwsArgumentError,
      );
      expect(
        () => SpawnEntry(entryId: 'a', enemyId: 'x y'),
        throwsArgumentError,
      );
    });

    test('重复 entryId 拒绝（fail closed）', () {
      expect(
        () => SpawnDirector(config: cfg(), entries: [entry('a'), entry('a')]),
        throwsArgumentError,
      );
    });

    test('重复 enemyId 允许（同一敌人类型可多入口）', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [
          SpawnEntry(entryId: 'a', enemyId: 'bandit_blade'),
          SpawnEntry(entryId: 'b', enemyId: 'bandit_blade'),
        ],
      );
      expect(d.state.totalCount, 2);
      expect(d.state.units.map((u) => u.enemyId).toSet(), {'bandit_blade'});
    });
  });

  group('无显式入口不得生成', () {
    test('空入口列表永不生成，仅推进 tick', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0),
        entries: const [],
      );
      expect(d.state.totalCount, 0);
      var cur = d;
      for (var i = 0; i < 5; i++) {
        final r = cur.advance();
        expect(r.events, isEmpty);
        expect(r.director.state.activeCount, 0);
        expect(r.director.state.pendingCount, 0);
        cur = r.director;
      }
      expect(cur.state.tick, 5);
      expect(cur.hasReserve, isFalse);
      expect(cur.activeFull, isFalse);
    });
  });

  group('初始补兵与基础生命周期', () {
    test('warning=0 / grace=0 时首拍即按 reserve 顺序满员上场且可攻击', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('b'), entry('a'), entry('c')],
      );
      expect(d.state.tick, 0);
      expect(d.state.pendingCount, 3);
      expect(d.state.activeCount, 0);
      expect(d.needsReinforcement, isTrue);
      expect(d.activeFull, isFalse);
      expect(d.hasReserve, isTrue);

      final r = d.advance();
      expect(r.director.state.tick, 1);
      expect(r.director.state.activeCount, 3);
      expect(r.director.state.pendingCount, 0);
      expect(r.director.activeFull, isTrue);
      expect(r.events, const [
        SpawnDirectorEvent(SpawnDirectorEventType.entered, 'a', 'enemy_a', 1),
        SpawnDirectorEvent(SpawnDirectorEventType.entered, 'b', 'enemy_b', 1),
        SpawnDirectorEvent(SpawnDirectorEventType.entered, 'c', 'enemy_c', 1),
      ]);
      for (final u in r.director.state.units) {
        expect(u.stage, SpawnUnitStage.active);
        expect(u.canAttack, isTrue);
        expect(u.remainingGraceTicks, 0);
        expect(u.enteredTick, 1);
      }
    });

    test('预警拍：pending → warning → active', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 2, grace: 0),
        entries: [entry('a')],
      );
      final r1 = d.advance();
      expect(r1.events, const [
        SpawnDirectorEvent(
          SpawnDirectorEventType.warningStarted,
          'a',
          'enemy_a',
          1,
        ),
      ]);
      expect(r1.director.state.warningCount, 1);
      expect(r1.director.state.activeCount, 0);
      var u = r1.director.state.units.single;
      expect(u.stage, SpawnUnitStage.warning);
      expect(u.remainingWarningTicks, 2);
      expect(u.canAttack, isFalse);

      final r2 = r1.director.advance();
      expect(r2.events, isEmpty);
      u = r2.director.state.units.single;
      expect(u.remainingWarningTicks, 1);

      final r3 = r2.director.advance();
      expect(r3.events, const [
        SpawnDirectorEvent(SpawnDirectorEventType.entered, 'a', 'enemy_a', 3),
      ]);
      expect(r3.director.state.activeCount, 1);
      expect(r3.director.state.warningCount, 0);
      u = r3.director.state.units.single;
      expect(u.stage, SpawnUnitStage.active);
      expect(u.enteredTick, 3);
    });

    test('攻击宽限：上场后 grace 拍内不可攻击，到期才可攻击', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 0, grace: 3),
        entries: [entry('a')],
      );
      var r = d.advance();
      var u = r.director.state.units.single;
      expect(u.remainingGraceTicks, 3);
      expect(u.canAttack, isFalse);

      r = r.director.advance();
      u = r.director.state.units.single;
      expect(u.remainingGraceTicks, 2);
      expect(u.canAttack, isFalse);

      r = r.director.advance();
      u = r.director.state.units.single;
      expect(u.remainingGraceTicks, 1);
      expect(u.canAttack, isFalse);

      r = r.director.advance();
      expect(r.events, const [
        SpawnDirectorEvent(
          SpawnDirectorEventType.graceExpired,
          'a',
          'enemy_a',
          4,
        ),
      ]);
      u = r.director.state.units.single;
      expect(u.remainingGraceTicks, 0);
      expect(u.canAttack, isTrue);
    });

    test('grace=0 不产生 graceExpired 事件', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a')],
      );
      final r1 = d.advance();
      expect(r1.director.state.units.single.canAttack, isTrue);
      expect(r1.director.advance().events, isEmpty);
    });
  });

  group('补兵阈值与稳定 reserve 顺序', () {
    test('活跃高于阈值时不补兵', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 1, warning: 0, grace: 0),
        entries: [entry('a'), entry('b'), entry('c'), entry('d')],
      );
      var cur = d.advance().director; // a,b,c 上场，d 后备
      expect(cur.state.activeCount, 3);
      expect(cur.needsReinforcement, isFalse);
      cur = cur.markExited('a'); // 剩 b,c = 2 > 阈值 1
      final r = cur.advance();
      expect(r.events, isEmpty);
      expect(r.director.state.activeCount, 2);
      expect(r.director.state.pendingCount, 1);
      expect(r.director.needsReinforcement, isFalse);
    });

    test('活跃降至阈值及以下时按 reserve 顺序补到 activeLimit', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 1, warning: 0, grace: 0),
        entries: [entry('e'), entry('b'), entry('a'), entry('d'), entry('c')],
      );
      var cur = d.advance().director;
      expect(activeIds(cur.state), ['a', 'b', 'c']);

      cur = cur.markExited('a'); // 2 > 1 不补
      cur = cur.advance().director;
      expect(activeIds(cur.state), ['b', 'c']);

      cur = cur.markExited('b'); // active c = 1 <= 阈值 1 → 补至满员
      cur = cur.advance().director;
      expect(activeIds(cur.state), ['c', 'd', 'e']);

      cur = cur.markExited('c'); // active d,e = 2 > 1 不补
      cur = cur.advance().director;
      expect(activeIds(cur.state), ['d', 'e']);
      expect(cur.state.pendingCount, 0);
      expect(cur.hasReserve, isFalse);
    });

    test('后备耗尽：补不满也停，active 可低于上限', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 5, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b')],
      );
      final r = d.advance();
      expect(r.director.state.activeCount, 2);
      expect(r.director.state.pendingCount, 0);
      expect(r.director.hasReserve, isFalse);
      expect(r.director.activeFull, isFalse);
    });

    test('active 已满：管道满则不补、可反复推进', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b'), entry('c'), entry('d'), entry('e')],
      );
      final cur = d.advance().director;
      expect(cur.activeFull, isTrue);
      expect(cur.state.pendingCount, 2);
      final r2 = cur.advance();
      expect(r2.events, isEmpty);
      expect(r2.director.state.activeCount, 3);
      expect(r2.director.state.pendingCount, 2);
      expect(r2.director.activeFull, isTrue);
    });

    test('预警单位占用管道容量，active+warning 不超 activeLimit', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 5, grace: 0),
        entries: [entry('a'), entry('b'), entry('c'), entry('d'), entry('e')],
      );
      final r = d.advance();
      expect(r.director.state.warningCount, 3);
      expect(r.director.state.pendingCount, 2);
      expect(r.director.state.activeCount, 0);
      var cur = r.director;
      for (var i = 0; i < 5; i++) {
        cur = cur.advance().director;
      }
      expect(cur.state.activeCount, 3);
      expect(cur.state.warningCount, 0);
      expect(cur.state.pendingCount, 2);
    });
  });

  group('markExited 离场（fail closed）', () {
    test('未知 entryId 拒绝', () {
      final d = SpawnDirector(config: cfg(), entries: [entry('a')]);
      expect(() => d.markExited('zzz'), throwsArgumentError);
    });

    test('后备单位不可离场', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b')],
      );
      final cur = d.advance().director; // a 上场，b 后备
      expect(() => cur.markExited('b'), throwsArgumentError);
    });

    test('预警单位不可离场', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 2, grace: 0),
        entries: [entry('a')],
      );
      final cur = d.advance().director; // a 预警中
      expect(() => cur.markExited('a'), throwsArgumentError);
    });

    test('已离场单位不可重复离场', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a')],
      );
      final cur = d.advance().director;
      final exited = cur.markExited('a');
      expect(exited.state.removedCount, 1);
      expect(() => exited.markExited('a'), throwsArgumentError);
    });

    test('离场记录 removed 快照', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b'), entry('c')],
      );
      final cur = d.advance().director;
      final exited = cur.markExited('b');
      expect(exited.state.activeCount, 2);
      expect(exited.state.removedCount, 1);
      final u = exited.state.unitById('b');
      expect(u, isNotNull);
      expect(u!.stage, SpawnUnitStage.removed);
      expect(u.removedTick, 1);
      expect(u.canAttack, isFalse);
    });

    test('unitById 返回快照或 null', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 1, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a')],
      );
      expect(d.state.unitById('a')!.entryId, 'a');
      expect(d.state.unitById('zzz'), isNull);
    });
  });

  group('快照稳定顺序', () {
    test('pending → warning → active → removed 分组稳定排序', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 1, warning: 2, grace: 0),
        entries: [entry('c'), entry('e'), entry('a'), entry('b'), entry('d')],
      );
      expect(unitIds(d.state), ['a', 'b', 'c', 'd', 'e']); // t0 全 pending
      final t1 = d.advance().director;
      expect(unitIds(t1.state), [
        'd',
        'e',
        'a',
        'b',
        'c',
      ]); // pending 先 warning 后
      final t3 = t1.advance().director.advance().director; // a,b,c 上场
      expect(unitIds(t3.state), ['d', 'e', 'a', 'b', 'c']);
      final t4 = t3.markExited('b');
      expect(unitIds(t4.state), ['d', 'e', 'a', 'c', 'b']); // removed 最后
    });
  });

  group('输入顺序无关与确定性', () {
    test('入口列表输入顺序无关：reserve 顺序与行为一致', () {
      final shuffled1 = [
        entry('b'),
        entry('a'),
        entry('d'),
        entry('c'),
        entry('e'),
      ];
      final shuffled2 = [
        entry('e'),
        entry('c'),
        entry('b'),
        entry('d'),
        entry('a'),
      ];
      final d1 = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 1, warning: 2, grace: 2),
        entries: shuffled1,
      );
      final d2 = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 1, warning: 2, grace: 2),
        entries: shuffled2,
      );
      expect(unitIds(d1.state), ['a', 'b', 'c', 'd', 'e']);
      expect(unitIds(d2.state), ['a', 'b', 'c', 'd', 'e']);

      final r1 = d1.advance();
      final r2 = d2.advance();
      expect(r1.events, r2.events);
      expectSameState(r1.director.state, r2.director.state);
    });

    test('相同输入相同操作序列 → 状态完全一致（确定性）', () {
      SpawnDirector run(List<SpawnEntry> entries) {
        var d = SpawnDirector(
          config: cfg(activeLimit: 3, threshold: 1, warning: 2, grace: 2),
          entries: entries,
        );
        d = d.advance().director; // t1 warning a,b,c
        d = d.advance().director; // t2 warning 剩余 1
        d = d.advance().director; // t3 active a,b,c（grace 2），pending d,e
        d = d.markExited('a'); // active b,c
        d = d.advance().director; // t4 active 2 > 阈值 1，不补
        d = d.markExited('b'); // active c
        d = d.advance().director; // t5 active 1 <= 1，补 d → warning
        return d;
      }

      final x = run([
        entry('a'),
        entry('b'),
        entry('c'),
        entry('d'),
        entry('e'),
      ]);
      final y = run([
        entry('e'),
        entry('d'),
        entry('c'),
        entry('b'),
        entry('a'),
      ]);
      expectSameState(x.state, y.state);
      expect(unitIds(x.state), unitIds(y.state));
    });
  });

  group('不可变性与防御性副本', () {
    test('构造后修改调用方入口列表不污染 director', () {
      final list = [entry('a'), entry('b'), entry('c')];
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: list,
      );
      list.clear();
      list.add(entry('zzz'));
      expect(d.state.totalCount, 3);
      expect(unitIds(d.state), ['a', 'b', 'c']);
      expect(d.advance().director.state.activeCount, 3);
    });

    test('快照列表与事件列表不可变', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a')],
      );
      expect(() => d.state.units.clear(), throwsUnsupportedError);
      expect(() => d.state.units.removeAt(0), throwsUnsupportedError);
      final r = d.advance();
      expect(() => r.events.clear(), throwsUnsupportedError);
    });

    test('advance 返回新 director，原 director 不变', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b'), entry('c')],
      );
      final r = d.advance();
      expect(d.state.tick, 0);
      expect(d.state.activeCount, 0);
      expect(d.state.pendingCount, 3);
      expect(r.director.state.tick, 1);
      expect(r.director.state.activeCount, 3);
      expect(r.director.state.pendingCount, 0);
    });

    test('markExited 返回新 director，原 director 不变', () {
      final d = SpawnDirector(
        config: cfg(activeLimit: 3, threshold: 0, warning: 0, grace: 0),
        entries: [entry('a'), entry('b'), entry('c')],
      );
      final cur = d.advance().director;
      final exited = cur.markExited('a');
      expect(cur.state.activeCount, 3);
      expect(cur.state.removedCount, 0);
      expect(exited.state.activeCount, 2);
      expect(exited.state.removedCount, 1);
    });
  });
}
