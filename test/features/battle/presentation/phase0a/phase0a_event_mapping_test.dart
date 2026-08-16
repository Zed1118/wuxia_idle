import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_event_sequencer.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';

Phase0aActor _actor(
  String id,
  Phase0aSide side,
  double x,
  double y, {
  Phase0aDefeatKind defeatKind = Phase0aDefeatKind.normal,
}) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector(x, y),
  facing: ArenaVector.zero,
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: defeatKind,
);

Phase0aArenaState _state({
  ArenaVector playerPosition = const ArenaVector(0, 0),
  List<Phase0aActor> enemies = const [],
}) => Phase0aArenaState(
  tick: 0,
  nextSeq: 0,
  player: _actor(
    'player',
    Phase0aSide.player,
    playerPosition.x,
    playerPosition.y,
  ),
  enemies: enemies,
  skillSlots: const [],
);

Phase0aHitLanded _hit({
  required int seq,
  String actor = 'e1',
  String target = 'player',
  int damage = 25,
  bool isCritical = false,
}) => Phase0aHitLanded(
  seq: seq,
  tick: seq,
  actor: actor,
  target: target,
  moveKind: Phase0aMoveKind.light,
  isCritical: isCritical,
  isUltimate: false,
  resolvedDamage: damage,
  remainingHealth: 100 - damage,
);

List<Phase0aVfxEntry> _popups(List<Phase0aVfxEntry> entries) =>
    entries.where((e) => e.kind == Phase0aVfxKind.damagePopup).toList();

void main() {
  group('Phase0aEventSequencer seq 排序与去重', () {
    test('乱序 batch 按 seq 升序输出', () {
      final sequencer = Phase0aEventSequencer();
      final accepted = sequencer.ingest([
        _hit(seq: 3),
        _hit(seq: 1),
        _hit(seq: 2),
      ]);
      expect(accepted.map((e) => e.seq).toList(), [1, 2, 3]);
    });

    test('跨批去重:已消费 seq 与重复 seq 被丢弃', () {
      final sequencer = Phase0aEventSequencer();
      sequencer.ingest([_hit(seq: 1), _hit(seq: 2)]);
      final accepted = sequencer.ingest([
        _hit(seq: 2),
        _hit(seq: 4),
        _hit(seq: 1),
        _hit(seq: 3),
      ]);
      expect(accepted.map((e) => e.seq).toList(), [3, 4]);
    });

    test('单批内相同 seq 只保留一条', () {
      final sequencer = Phase0aEventSequencer();
      final accepted = sequencer.ingest([_hit(seq: 5), _hit(seq: 5)]);
      expect(accepted.map((e) => e.seq).toList(), [5]);
    });

    test('空 batch 不产生事件', () {
      final sequencer = Phase0aEventSequencer();
      expect(sequencer.ingest(const <Phase0aEvent>[]), isEmpty);
    });
  });

  group('Phase0aVfxController 命中与伤害飘字', () {
    test('非零 HitLanded 生成精确伤害 popup', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 30, 0)]));
      final entries = controller.consume([
        _hit(
          seq: 1,
          actor: 'e1',
          target: 'player',
          damage: 137,
          isCritical: true,
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.damage, 137);
      expect(popups.single.targetId, 'player');
      expect(popups.single.isCritical, isTrue);
    });

    test('零伤害 HitLanded 不产生伤害数字', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 30, 0)]));
      final entries = controller.consume([_hit(seq: 1, damage: 0)]);
      expect(_popups(entries), isEmpty);
    });

    test('玩家远程命中产生掌风轨迹,近程不产生', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor(
                'far',
                Phase0aSide.enemy,
                Phase0aVfxController.palmTrailMinDistance + 50,
                0,
              ),
              _actor('near', Phase0aSide.enemy, 20, 0),
            ],
          ),
        );
      final entries = controller.consume([
        _hit(seq: 1, actor: 'player', target: 'far'),
        _hit(seq: 2, actor: 'player', target: 'near'),
      ]);
      final trails = entries
          .where((e) => e.kind == Phase0aVfxKind.palmTrail)
          .toList();
      expect(trails, hasLength(1));
      expect(trails.single.actorId, 'player');
      expect(trails.single.targetId, 'far');
    });

    test('敌方远程命中不产生掌风轨迹', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor(
                'e1',
                Phase0aSide.enemy,
                Phase0aVfxController.palmTrailMinDistance + 50,
                0,
              ),
            ],
          ),
        );
      final entries = controller.consume([
        _hit(seq: 1, actor: 'e1', target: 'player'),
      ]);
      expect(entries.where((e) => e.kind == Phase0aVfxKind.palmTrail), isEmpty);
    });
  });

  group('Phase0aVfxController 技能映射', () {
    test('GatherStarted 产生涡旋,GatherApplied 逐 pulled 目标产生拉拢轨迹且 outcomes 只读', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, 40, 0),
              _actor('e2', Phase0aSide.enemy, -40, 0),
            ],
          ),
        );
      const outcomes = [
        Phase0aSkillOutcome(
          target: 'e1',
          resolvedDamage: 0,
          defeated: false,
          statusApplied: Phase0aSkillStatus.pulled,
        ),
        Phase0aSkillOutcome(
          target: 'e2',
          resolvedDamage: 0,
          defeated: false,
          statusApplied: Phase0aSkillStatus.none,
        ),
      ];
      const applied = Phase0aGatherApplied(
        seq: 2,
        tick: 2,
        actor: 'player',
        outcomes: outcomes,
      );
      final entries = controller.consume([
        const Phase0aGatherStarted(seq: 1, tick: 1, actor: 'player'),
        applied,
      ]);
      expect(
        entries.where((e) => e.kind == Phase0aVfxKind.gatherVortex),
        hasLength(1),
      );
      final pulls = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherPull)
          .toList();
      expect(pulls.map((e) => e.targetId).toList(), ['e1']);
      expect(applied.outcomes, outcomes);
    });

    test('ClearStarted 产生径向墨爆,ClearApplied 逐非零目标产生精确伤害数字', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, 40, 0),
              _actor('e2', Phase0aSide.enemy, -40, 0),
            ],
          ),
        );
      final entries = controller.consume([
        const Phase0aClearStarted(seq: 1, tick: 1, actor: 'player'),
        const Phase0aClearApplied(
          seq: 2,
          tick: 2,
          actor: 'player',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 88,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 0,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          ],
        ),
      ]);
      expect(
        entries.where((e) => e.kind == Phase0aVfxKind.clearBurst),
        hasLength(1),
      );
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.targetId, 'e1');
      expect(popups.single.damage, 88);
    });
  });

  group('Phase0aVfxController 移除/波次/终局', () {
    test('EnemyDefeated 产生墨散,精英与普通语义区分,重复 seq 不重复移除', () {
      final sequencer = Phase0aEventSequencer();
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, 40, 0),
              _actor(
                'boss',
                Phase0aSide.enemy,
                -40,
                0,
                defeatKind: Phase0aDefeatKind.elite,
              ),
            ],
          ),
        );
      final batch = sequencer.ingest([
        const Phase0aEnemyDefeated(
          seq: 1,
          tick: 1,
          target: 'e1',
          defeatKind: Phase0aDefeatKind.normal,
        ),
        const Phase0aEnemyDefeated(
          seq: 2,
          tick: 2,
          target: 'boss',
          defeatKind: Phase0aDefeatKind.elite,
        ),
      ]);
      final first = controller.consume(batch);
      final replay = controller.consume(sequencer.ingest(batch));
      final inks = first
          .where((e) => e.kind == Phase0aVfxKind.defeatInk)
          .toList();
      expect(inks, hasLength(2));
      expect(
        inks.firstWhere((e) => e.targetId == 'e1').defeatKind,
        Phase0aDefeatKind.normal,
      );
      expect(
        inks.firstWhere((e) => e.targetId == 'boss').defeatKind,
        Phase0aDefeatKind.elite,
      );
      expect(replay.where((e) => e.kind == Phase0aVfxKind.defeatInk), isEmpty);
    });

    test('WaveStarted 产生波次横幅,携带 waveIndex/waveTotal', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final entries = controller.consume([
        const Phase0aWaveStarted(seq: 1, tick: 1, waveIndex: 2, waveTotal: 3),
      ]);
      final banners = entries
          .where((e) => e.kind == Phase0aVfxKind.waveBanner)
          .toList();
      expect(banners, hasLength(1));
      expect(banners.single.waveIndex, 2);
      expect(banners.single.waveTotal, 3);
    });

    test('Victory 产生全场唯一终局封签,随后 Defeat 不再新增', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final first = controller.consume([
        const Phase0aBattleVictory(seq: 1, tick: 1),
      ]);
      final seals = first
          .where((e) => e.kind == Phase0aVfxKind.outcomeSeal)
          .toList();
      expect(seals, hasLength(1));
      expect(seals.single.isVictory, isTrue);
      final second = controller.consume([
        const Phase0aBattleDefeat(seq: 2, tick: 2),
      ]);
      expect(
        second.where((e) => e.kind == Phase0aVfxKind.outcomeSeal),
        isEmpty,
      );
    });

    test('Defeat 产生败北封签', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final entries = controller.consume([
        const Phase0aBattleDefeat(seq: 1, tick: 1),
      ]);
      final seals = entries
          .where((e) => e.kind == Phase0aVfxKind.outcomeSeal)
          .toList();
      expect(seals, hasLength(1));
      expect(seals.single.isVictory, isFalse);
    });

    test('终局之后一切战斗事件不再产生新 entry', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 40, 0)]));
      controller.consume([const Phase0aBattleVictory(seq: 1, tick: 1)]);
      final after = controller.consume([
        _hit(seq: 2, damage: 50),
        const Phase0aWaveStarted(seq: 3, tick: 3, waveIndex: 2, waveTotal: 2),
        const Phase0aEnemyDefeated(
          seq: 4,
          tick: 4,
          target: 'e1',
          defeatKind: Phase0aDefeatKind.normal,
        ),
      ]);
      expect(after, isEmpty);
    });
  });

  group('Phase0aVfxController 容量上限', () {
    test('契约常量:popup 上限 48,总 entry 上限 160', () {
      expect(Phase0aVfxController.maxDamagePopups, 48);
      expect(Phase0aVfxController.maxEntries, 160);
    });

    test('单次消费 60 次非零命中,damage popup 不超过 48', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 40, 0)]));
      final events = [
        for (var i = 1; i <= 60; i++) _hit(seq: i, damage: 10 + i),
      ];
      final entries = controller.consume(events);
      expect(
        _popups(entries).length,
        lessThanOrEqualTo(Phase0aVfxController.maxDamagePopups),
      );
    });

    test('高频混合事件下总 entry 不超过 160', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, 40, 0),
              _actor(
                'e2',
                Phase0aSide.enemy,
                -40,
                0,
                defeatKind: Phase0aDefeatKind.elite,
              ),
            ],
          ),
        );
      final events = <Phase0aEvent>[
        for (var i = 1; i <= 90; i++)
          _hit(seq: i, actor: 'e1', target: 'player', damage: 7),
        for (var i = 91; i <= 140; i++)
          Phase0aEnemyDefeated(
            seq: i,
            tick: i,
            target: 'e$i',
            defeatKind: Phase0aDefeatKind.normal,
          ),
        for (var i = 141; i <= 180; i++)
          Phase0aWaveStarted(
            seq: i,
            tick: i,
            waveIndex: i - 140,
            waveTotal: 40,
          ),
      ];
      final entries = controller.consume(events);
      expect(
        entries.length,
        lessThanOrEqualTo(Phase0aVfxController.maxEntries),
      );
    });
  });
}
