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

  group('Phase0aVfxController 坐标快照(Batch 8A)', () {
    test('掌风 entry 携带 source/vfxTarget 等于事件时 actor 位置', () {
      const playerPos = ArenaVector(0, 0);
      const enemyPos = ArenaVector(
        Phase0aVfxController.palmTrailMinDistance + 50,
        0,
      );
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            playerPosition: playerPos,
            enemies: [_actor('far', Phase0aSide.enemy, enemyPos.x, enemyPos.y)],
          ),
        );
      final entries = controller.consume([
        _hit(seq: 1, actor: 'player', target: 'far'),
      ]);
      final trails = entries
          .where((e) => e.kind == Phase0aVfxKind.palmTrail)
          .toList();
      expect(trails, hasLength(1));
      final trail = trails.single;
      expect(trail.source, isNotNull, reason: '掌风必须有 source 快照');
      expect(trail.vfxTarget, isNotNull, reason: '掌风必须有 vfxTarget 快照');
      expect(trail.source!.x, playerPos.x);
      expect(trail.source!.y, playerPos.y);
      expect(trail.vfxTarget!.x, enemyPos.x);
      expect(trail.vfxTarget!.y, enemyPos.y);
    });

    test('Q 涡旋 entry 携带 anchor 等于事件时玩家位置', () {
      const playerPos = ArenaVector(100, 200);
      final controller = Phase0aVfxController()
        ..syncActors(_state(playerPosition: playerPos));
      final entries = controller.consume([
        const Phase0aGatherStarted(seq: 1, tick: 1, actor: 'player'),
      ]);
      final vortex = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherVortex)
          .toList();
      expect(vortex, hasLength(1));
      expect(vortex.single.anchor, isNotNull, reason: 'Q 涡旋必须有 anchor 快照');
      expect(vortex.single.anchor!.x, playerPos.x);
      expect(vortex.single.anchor!.y, playerPos.y);
    });

    test('R 墨爆 entry 携带 anchor 等于事件时玩家位置', () {
      const playerPos = ArenaVector(-50, 300);
      final controller = Phase0aVfxController()
        ..syncActors(_state(playerPosition: playerPos));
      final entries = controller.consume([
        const Phase0aClearStarted(seq: 1, tick: 1, actor: 'player'),
      ]);
      final burst = entries
          .where((e) => e.kind == Phase0aVfxKind.clearBurst)
          .toList();
      expect(burst, hasLength(1));
      expect(burst.single.anchor, isNotNull, reason: 'R 墨爆必须有 anchor 快照');
      expect(burst.single.anchor!.x, playerPos.x);
      expect(burst.single.anchor!.y, playerPos.y);
    });

    test('死亡墨散 entry 携带 anchor 等于被击败敌人位置', () {
      const enemyPos = ArenaVector(400, -100);
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, enemyPos.x, enemyPos.y),
            ],
          ),
        );
      final entries = controller.consume([
        const Phase0aEnemyDefeated(
          seq: 1,
          tick: 1,
          target: 'e1',
          defeatKind: Phase0aDefeatKind.normal,
        ),
      ]);
      final ink = entries
          .where((e) => e.kind == Phase0aVfxKind.defeatInk)
          .toList();
      expect(ink, hasLength(1));
      expect(ink.single.anchor, isNotNull, reason: '死亡墨散必须有 anchor 快照');
      expect(ink.single.anchor!.x, enemyPos.x);
      expect(ink.single.anchor!.y, enemyPos.y);
    });

    test('致死伤害数字 popup 携带 anchor 快照,不依赖 state 反查', () {
      const enemyPos = ArenaVector(200, 150);
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, enemyPos.x, enemyPos.y),
            ],
          ),
        );
      // 致死伤害:resolvedDamage >= remainingHealth
      final entries = controller.consume([
        _hit(seq: 1, actor: 'player', target: 'e1', damage: 999),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      final popup = popups.single;
      expect(popup.targetId, 'e1');
      expect(popup.damage, 999);
      // 致死伤害数字必须有 anchor,渲染层不应 fallback 到屏幕中心
      expect(popup.anchor, isNotNull, reason: '致死伤害数字必须有 anchor 快照');
      expect(popup.anchor!.x, enemyPos.x);
      expect(popup.anchor!.y, enemyPos.y);
    });

    test('R 清场多目标伤害数字各带 anchor,多目标时 anchor 互不相同', () {
      const e1Pos = ArenaVector(40, 0);
      const e2Pos = ArenaVector(-40, 50);
      const e3Pos = ArenaVector(0, -80);
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(
            enemies: [
              _actor('e1', Phase0aSide.enemy, e1Pos.x, e1Pos.y),
              _actor('e2', Phase0aSide.enemy, e2Pos.x, e2Pos.y),
              _actor('e3', Phase0aSide.enemy, e3Pos.x, e3Pos.y),
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
              resolvedDamage: 55,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e3',
              resolvedDamage: 120,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          ],
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(3));
      for (final popup in popups) {
        expect(popup.anchor, isNotNull, reason: '${popup.targetId} 伤害数字必须有 anchor');
      }
      // 多目标 anchor 不应相同
      final anchors = popups.map((p) => p.anchor).toSet();
      expect(anchors.length, 3, reason: '多目标伤害数字 anchor 应互不相同');
    });
  });
}
