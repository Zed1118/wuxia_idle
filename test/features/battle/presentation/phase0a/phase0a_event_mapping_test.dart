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

    test('玩家近程命中产生双弧墨痕,远程命中产生掌风且互斥', () {
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
      final slashes = entries
          .where((e) => e.kind == Phase0aVfxKind.meleeSlash)
          .toList();
      expect(trails, hasLength(1));
      expect(trails.single.actorId, 'player');
      expect(trails.single.targetId, 'far');
      expect(slashes, hasLength(1));
      expect(slashes.single.actorId, 'player');
      expect(slashes.single.targetId, 'near');
      expect(slashes.single.anchor, const ArenaVector(20, 0));
    });

    test('敌方命中不产生玩家专属掌风或双弧墨痕', () {
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
      expect(
        entries.where((e) => e.kind == Phase0aVfxKind.meleeSlash),
        isEmpty,
      );
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
          isCritical: false,
          defeated: false,
          statusApplied: Phase0aSkillStatus.pulled,
        ),
        Phase0aSkillOutcome(
          target: 'e2',
          resolvedDamage: 0,
          isCritical: false,
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
      expect(pulls.single.source, const ArenaVector(40, 0));
      expect(pulls.single.vfxTarget, ArenaVector.zero);
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
              isCritical: true,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 0,
              isCritical: false,
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

    test('ClearApplied 飘字暴击标记逐 outcome 透传,不硬编码', () {
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
        const Phase0aClearApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 88,
              isCritical: true,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 66,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          ],
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(2));
      expect(
        popups.firstWhere((p) => p.targetId == 'e1').isCritical,
        isTrue,
        reason: '暴击 R 飘字应标记 critical',
      );
      expect(
        popups.firstWhere((p) => p.targetId == 'e2').isCritical,
        isFalse,
        reason: '非暴击 R 飘字不应标记 critical',
      );
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
            enemies: [_actor('e1', Phase0aSide.enemy, enemyPos.x, enemyPos.y)],
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
            enemies: [_actor('e1', Phase0aSide.enemy, enemyPos.x, enemyPos.y)],
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
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 55,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
            Phase0aSkillOutcome(
              target: 'e3',
              resolvedDamage: 120,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          ],
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(3));
      for (final popup in popups) {
        expect(
          popup.anchor,
          isNotNull,
          reason: '${popup.targetId} 伤害数字必须有 anchor',
        );
      }
      // 多目标 anchor 不应相同
      final anchors = popups.map((p) => p.anchor).toSet();
      expect(anchors.length, 3, reason: '多目标伤害数字 anchor 应互不相同');
    });
  });

  group('Phase0aVfxController 容量上限', () {
    test('契约常量:popup 上限 48,总 entry 上限 160', () {
      expect(Phase0aVfxController.maxDamagePopups, 48);
      expect(Phase0aVfxController.maxEntries, 160);
    });

    test('单次消费 60 次非零命中,damage popup 精确截断为 48', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 40, 0)]));
      final events = [
        for (var i = 1; i <= 60; i++) _hit(seq: i, damage: 10 + i),
      ];
      final entries = controller.consume(events);
      expect(_popups(entries).length, Phase0aVfxController.maxDamagePopups);
    });

    test('高频混合事件产量超过上限时,总 entry 精确截断为 160', () {
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
        for (var i = 91; i <= 220; i++)
          Phase0aEnemyDefeated(
            seq: i,
            tick: i,
            target: 'e$i',
            defeatKind: Phase0aDefeatKind.normal,
          ),
        for (var i = 221; i <= 260; i++)
          Phase0aWaveStarted(
            seq: i,
            tick: i,
            waveIndex: i - 220,
            waveTotal: 40,
          ),
      ];
      final entries = controller.consume(events);
      expect(entries.length, Phase0aVfxController.maxEntries);
    });

    for (final isVictory in [true, false]) {
      test('容量已满仍保留${isVictory ? '胜利' : '败北'}终局封签且总量不越界', () {
        final controller = Phase0aVfxController()..syncActors(_state());
        final events = <Phase0aEvent>[
          for (var i = 1; i <= Phase0aVfxController.maxEntries; i++)
            Phase0aWaveStarted(
              seq: i,
              tick: i,
              waveIndex: i,
              waveTotal: Phase0aVfxController.maxEntries,
            ),
          if (isVictory)
            const Phase0aBattleVictory(seq: 161, tick: 161)
          else
            const Phase0aBattleDefeat(seq: 161, tick: 161),
        ];

        final entries = controller.consume(events);

        expect(entries, hasLength(Phase0aVfxController.maxEntries));
        final seals = entries
            .where((entry) => entry.kind == Phase0aVfxKind.outcomeSeal)
            .toList();
        expect(seals, hasLength(1));
        expect(seals.single.isVictory, isVictory);
        expect(entries.last.kind, Phase0aVfxKind.outcomeSeal);
      });
    }
  });

  group('Phase0aVfxController 事件坐标 event-first(本批)', () {
    test('伤害飘字优先事件坐标,不反查错位的同步状态', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(enemies: [_actor('e1', Phase0aSide.enemy, 999, 999)]),
        );
      final entries = controller.consume([
        const Phase0aHitLanded(
          seq: 1,
          tick: 1,
          actor: 'player',
          target: 'e1',
          moveKind: Phase0aMoveKind.light,
          isCritical: false,
          isUltimate: false,
          resolvedDamage: 25,
          remainingHealth: 75,
          actorPosition: ArenaVector(40, 20),
          targetPosition: ArenaVector(50, 25),
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.anchor, const ArenaVector(50, 25));
    });

    test('双弧墨痕/掌风坐标 event-first,与同步位置无关', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final far = Phase0aVfxController.palmTrailMinDistance + 50;
      final entries = controller.consume([
        const Phase0aHitLanded(
          seq: 1,
          tick: 1,
          actor: 'player',
          target: 'ghost',
          moveKind: Phase0aMoveKind.light,
          isCritical: false,
          isUltimate: false,
          resolvedDamage: 10,
          remainingHealth: 90,
          actorPosition: ArenaVector(500, 0),
          targetPosition: ArenaVector(510, 0),
        ),
        Phase0aHitLanded(
          seq: 2,
          tick: 1,
          actor: 'player',
          target: 'ghost2',
          moveKind: Phase0aMoveKind.light,
          isCritical: false,
          isUltimate: false,
          resolvedDamage: 10,
          remainingHealth: 90,
          actorPosition: const ArenaVector(0, 0),
          targetPosition: ArenaVector(far, 0),
        ),
      ]);
      final slashes = entries
          .where((e) => e.kind == Phase0aVfxKind.meleeSlash)
          .toList();
      expect(slashes, hasLength(1));
      expect(slashes.single.anchor, const ArenaVector(510, 0));
      final trails = entries
          .where((e) => e.kind == Phase0aVfxKind.palmTrail)
          .toList();
      expect(trails, hasLength(1));
      expect(trails.single.source, const ArenaVector(0, 0));
      expect(trails.single.vfxTarget, ArenaVector(far, 0));
    });

    test('无同步状态时事件坐标仍可用(涡旋/死亡墨散)', () {
      // 故意不 syncActors:_actors 为空,只能靠事件坐标。
      final controller = Phase0aVfxController();
      final entries = controller.consume([
        const Phase0aGatherStarted(
          seq: 1,
          tick: 1,
          actor: 'player',
          actorPosition: ArenaVector(123, 45),
        ),
        const Phase0aEnemyDefeated(
          seq: 2,
          tick: 1,
          target: 'e1',
          defeatKind: Phase0aDefeatKind.normal,
          targetPosition: ArenaVector(400, -100),
        ),
      ]);
      final vortex = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherVortex)
          .toList();
      expect(vortex, hasLength(1));
      expect(vortex.single.anchor, const ArenaVector(123, 45));
      final ink = entries
          .where((e) => e.kind == Phase0aVfxKind.defeatInk)
          .toList();
      expect(ink, hasLength(1));
      expect(ink.single.anchor, const ArenaVector(400, -100));
    });

    test('Q 拉线端点取 outcome 拉前位置 → 真实环点,不是玩家中心', () {
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(enemies: [_actor('e1', Phase0aSide.enemy, 999, 999)]),
        );
      final entries = controller.consume([
        const Phase0aGatherApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 0,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.pulled,
              sourcePosition: ArenaVector(200, 0),
              targetPosition: ArenaVector(90, 0),
            ),
          ],
        ),
      ]);
      final pulls = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherPull)
          .toList();
      expect(pulls, hasLength(1));
      expect(pulls.single.source, const ArenaVector(200, 0));
      expect(pulls.single.vfxTarget, const ArenaVector(90, 0));
      expect(pulls.single.vfxTarget, isNot(ArenaVector.zero));
    });

    test('R 墨爆与多目标飘字锚点均优先事件坐标', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final entries = controller.consume([
        const Phase0aClearStarted(
          seq: 1,
          tick: 1,
          actor: 'player',
          actorPosition: ArenaVector(77, 88),
        ),
        const Phase0aClearApplied(
          seq: 2,
          tick: 1,
          actor: 'player',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 88,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
              targetPosition: ArenaVector(40, 0),
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 55,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.staggered,
              targetPosition: ArenaVector(-30, 20),
            ),
          ],
        ),
      ]);
      final burst = entries
          .where((e) => e.kind == Phase0aVfxKind.clearBurst)
          .toList();
      expect(burst, hasLength(1));
      expect(burst.single.anchor, const ArenaVector(77, 88));
      final popups = _popups(entries);
      expect(popups, hasLength(2));
      expect(
        popups.firstWhere((p) => p.targetId == 'e1').anchor,
        const ArenaVector(40, 0),
      );
      expect(
        popups.firstWhere((p) => p.targetId == 'e2').anchor,
        const ArenaVector(-30, 20),
      );
    });

    test('数字技能飘字锚点取 outcome.targetPosition', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final entries = controller.consume([
        const Phase0aSkillApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          hotkey: 1,
          skillId: 'skill_a',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 12,
              isCritical: true,
              defeated: false,
              statusApplied: Phase0aSkillStatus.none,
              targetPosition: ArenaVector(30, 10),
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 0,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.none,
              targetPosition: ArenaVector(-20, -40),
            ),
          ],
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.anchor, const ArenaVector(30, 10));
      expect(popups.single.isCritical, isTrue);
    });

    test('缺字段旧事件走同步状态回退', () {
      final controller = Phase0aVfxController()
        ..syncActors(_state(enemies: [_actor('e1', Phase0aSide.enemy, 40, 0)]));
      final entries = controller.consume([
        // 无坐标字段的手工旧构造:必须回退同步状态,行为不变。
        _hit(seq: 1, actor: 'player', target: 'e1', damage: 25),
        const Phase0aGatherStarted(seq: 2, tick: 1, actor: 'player'),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.anchor, const ArenaVector(40, 0));
      final vortex = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherVortex)
          .toList();
      expect(vortex.single.anchor, ArenaVector.zero);
    });

    test('敌方命中携带事件坐标也不冒玩家专属 VFX', () {
      final far = Phase0aVfxController.palmTrailMinDistance + 50;
      final controller = Phase0aVfxController()
        ..syncActors(
          _state(enemies: [_actor('e1', Phase0aSide.enemy, far, 0)]),
        );
      final entries = controller.consume([
        Phase0aHitLanded(
          seq: 1,
          tick: 1,
          actor: 'e1',
          target: 'player',
          moveKind: Phase0aMoveKind.heavy,
          isCritical: false,
          isUltimate: false,
          resolvedDamage: 25,
          remainingHealth: 75,
          actorPosition: ArenaVector(far, 0),
          targetPosition: const ArenaVector(0, 0),
        ),
      ]);
      expect(entries.where((e) => e.kind == Phase0aVfxKind.palmTrail), isEmpty);
      expect(
        entries.where((e) => e.kind == Phase0aVfxKind.meleeSlash),
        isEmpty,
      );
      // 通用受击飘字仍然产出,锚点取事件目标坐标。
      final popups = _popups(entries);
      expect(popups, hasLength(1));
      expect(popups.single.anchor, const ArenaVector(0, 0));
    });
  });

  group('Phase0aVfxController Q 伤害飘字(同链补缺)', () {
    test('Q 非零伤害逐目标飘字,anchor = 真实环点落点', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final entries = controller.consume([
        const Phase0aGatherApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          outcomes: [
            Phase0aSkillOutcome(
              target: 'e1',
              resolvedDamage: 35,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.pulled,
              sourcePosition: ArenaVector(200, 0),
              targetPosition: ArenaVector(90, 0),
            ),
            Phase0aSkillOutcome(
              target: 'e2',
              resolvedDamage: 0,
              isCritical: false,
              defeated: false,
              statusApplied: Phase0aSkillStatus.pulled,
              sourcePosition: ArenaVector(-150, 0),
              targetPosition: ArenaVector(-90, 0),
            ),
          ],
        ),
      ]);
      final popups = _popups(entries);
      expect(popups, hasLength(1), reason: '零伤目标不飘字');
      expect(popups.single.targetId, 'e1');
      expect(popups.single.damage, 35);
      expect(popups.single.anchor, const ArenaVector(90, 0));
      final pulls = entries
          .where((e) => e.kind == Phase0aVfxKind.gatherPull)
          .toList();
      expect(pulls, hasLength(2));
    });

    test('Q 超 48 个非零目标飘字精确截断为上限', () {
      // 故意不 sync:锚点全部来自事件坐标,证明截断逻辑与回退无关。
      final controller = Phase0aVfxController();
      final entries = controller.consume([
        Phase0aGatherApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          outcomes: [
            for (var i = 1; i <= 60; i++)
              Phase0aSkillOutcome(
                target: 'g$i',
                resolvedDamage: 10 + i,
                isCritical: false,
                defeated: false,
                statusApplied: Phase0aSkillStatus.none,
                targetPosition: ArenaVector(i * 10.0, 0),
              ),
          ],
        ),
      ]);
      expect(_popups(entries).length, Phase0aVfxController.maxDamagePopups);
    });

    test('Q 飘字/拉线打满容量后终局封签不丢且总量不越界', () {
      final controller = Phase0aVfxController()..syncActors(_state());
      final events = <Phase0aEvent>[
        Phase0aGatherApplied(
          seq: 1,
          tick: 1,
          actor: 'player',
          outcomes: [
            for (var i = 1; i <= 60; i++)
              Phase0aSkillOutcome(
                target: 'g$i',
                resolvedDamage: 10 + i,
                isCritical: false,
                defeated: false,
                statusApplied: Phase0aSkillStatus.pulled,
                sourcePosition: ArenaVector(i * 20.0, 0),
                targetPosition: ArenaVector(i * 10.0, 0),
              ),
          ],
        ),
        for (var i = 2; i <= 62; i++)
          Phase0aEnemyDefeated(
            seq: i,
            tick: 1,
            target: 'g${i - 1}',
            defeatKind: Phase0aDefeatKind.normal,
            targetPosition: ArenaVector(i * 10.0, 0),
          ),
        const Phase0aBattleVictory(seq: 63, tick: 1),
      ];
      final entries = controller.consume(events);
      expect(
        entries.length,
        lessThanOrEqualTo(Phase0aVfxController.maxEntries),
      );
      expect(_popups(entries).length, Phase0aVfxController.maxDamagePopups);
      final seals = entries
          .where((entry) => entry.kind == Phase0aVfxKind.outcomeSeal)
          .toList();
      expect(seals, hasLength(1));
      expect(seals.single.isVictory, isTrue);
      expect(entries.last.kind, Phase0aVfxKind.outcomeSeal);
    });

    test('sequencer 去重只看 seq,坐标字段不参与', () {
      final sequencer = Phase0aEventSequencer();
      const first = Phase0aHitLanded(
        seq: 7,
        tick: 1,
        actor: 'player',
        target: 'e1',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 10,
        remainingHealth: 90,
        targetPosition: ArenaVector(60, 0),
      );
      const duplicate = Phase0aHitLanded(
        seq: 7,
        tick: 1,
        actor: 'player',
        target: 'e1',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 10,
        remainingHealth: 90,
        targetPosition: ArenaVector(999, 0),
      );
      final accepted = sequencer.ingest([first, duplicate]);
      expect(accepted, hasLength(1));
      expect(identical(accepted.single, first), isTrue);
      expect(sequencer.ingest([duplicate]), isEmpty);
    });
  });
}
