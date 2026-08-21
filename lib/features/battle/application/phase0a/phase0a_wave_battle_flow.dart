import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_combat_session.dart';
import 'phase0a_player_input_adapter.dart';

/// Phase 0A 波次与唯一终局编排:真实包装 [Phase0aCombatSession] 的薄 flow。
///
/// 本层只负责 `wave_started` / `wave_cleared` / `battle_victory` /
/// `battle_defeat` 的事件序与波次装配;移动、AI、命中、伤害、CD、真气
/// 结算全部仍由 session → reducer 完成,不复制任何规则,也不接
/// 奖励/掉落/成长/伤势/存档等终局下游(未来挂在终局事件之后)。
///
/// 冻结语义(第四批协调计划 + 2026-08-16 拍板):
/// - 首波 `wave_started` 全场一次,排在首个战斗事件前;击杀末敌固定
///   `enemy_defeated → wave_cleared → next wave_started | battle_victory`。
/// - 事件 payload 的 waveIndex 对外 1-based(首波 = 1);内部游标 0-based
///   不外泄。
/// - 每拍 reducer 结束后唯一派生终局:玩家死亡优先 defeat(病态双方同时
///   为空也按 defeat),玩家存活且当前波清空才 cleared/推进/胜利。
/// - 所有 flow 自发事件消耗的 seq 都持久化回 state(终局事件也不例外);
///   终局后 advance 返回空事件、不推进 tick/seq、不调用 adapter/resolver。
/// - 换波只替换 enemies:玩家 HP/真气/普攻 CD、技能槽 CD/可用态、tick/seq
///   全部连续;换波不消耗额外拍。
/// - 会话不带任何 public 可变后门:需要换态(预留 seq/换波/固化终局 seq)
///   时以新 [Phase0aArenaState] 重建私有会话,复用同一 adapter/resolver
///   实例,保证 seeded RNG 连续。
final class Phase0aWaveBattleFlow {
  Phase0aWaveBattleFlow({
    required Phase0aCombatSession session,
    required List<Phase0aWave> waves,
  }) : _session = session,
       _waves = _checkedWaves(waves, session.state) {
    // 首态防御性副本:外部 list(敌人/技能槽)构造后 mutation 不得污染
    // flow;敌人直接采用首波的已校验不可修改副本(内容一致性上面已验)。
    _rebuildSession(
      Phase0aArenaState(
        tick: session.state.tick,
        nextSeq: session.state.nextSeq,
        player: session.state.player,
        enemies: _waves.first.enemies,
        skillSlots: List.unmodifiable(List.of(session.state.skillSlots)),
      ),
    );
  }

  Phase0aCombatSession _session;
  final List<Phase0aWave> _waves;

  /// 当前波 0-based 内部游标(事件 payload 一律换算 1-based,不外泄)。
  int _waveCursor = 0;
  Phase0aBattleOutcome _outcome = Phase0aBattleOutcome.ongoing;
  bool _firstWaveAnnounced = false;

  Phase0aArenaState get state => _session.state;
  Phase0aBattleOutcome get outcome => _outcome;
  List<Phase0aWave> get waves => _waves;

  /// 推进一拍:终局后完全幂等(空事件、state 不变、下游零调用)。
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_outcome != Phase0aBattleOutcome.ongoing) {
      return const <Phase0aEvent>[];
    }

    // 首波 wave_started 预留 seq:reducer 从 state.nextSeq 起分配,
    // 先以 nextSeq+1 的新 state 重建会话,预留序号留给 flow 自发事件。
    final reservingFirstWave = !_firstWaveAnnounced;
    final previousSession = _session;
    if (reservingFirstWave) {
      _rebuildSession(_withNextSeq(_session.state, _session.state.nextSeq + 1));
    }
    final List<Phase0aEvent> combatEvents;
    try {
      combatEvents = _session.advance(
        deltaSeconds: deltaSeconds,
        command: command,
      );
    } catch (_) {
      // 异常回滚:恢复原会话与首波标记,不留下半消费的 seq。
      if (reservingFirstWave) {
        _session = previousSession;
      }
      rethrow;
    }

    final resolved = _session.state;
    final tick = resolved.tick;
    var nextSeq = resolved.nextSeq;
    final events = <Phase0aEvent>[];
    if (reservingFirstWave) {
      _firstWaveAnnounced = true;
      events.add(
        Phase0aWaveStarted(
          seq: previousSession.state.nextSeq,
          tick: tick,
          waveIndex: _waveCursor + 1,
          waveTotal: _waves.length,
        ),
      );
    }
    events.addAll(combatEvents);

    if (!resolved.player.isAlive) {
      // 玩家死亡优先:病态双方同时为空也按 defeat,禁止双终局。
      _outcome = Phase0aBattleOutcome.defeat;
      events.add(Phase0aBattleDefeat(seq: nextSeq, tick: tick));
      nextSeq += 1;
      _rebuildSession(_withNextSeq(resolved, nextSeq));
    } else if (resolved.enemies.isEmpty) {
      events.add(
        Phase0aWaveCleared(
          seq: nextSeq,
          tick: tick,
          waveIndex: _waveCursor + 1,
        ),
      );
      nextSeq += 1;
      if (_waveCursor + 1 >= _waves.length) {
        _outcome = Phase0aBattleOutcome.victory;
        events.add(Phase0aBattleVictory(seq: nextSeq, tick: tick));
        nextSeq += 1;
        _rebuildSession(_withNextSeq(resolved, nextSeq));
      } else {
        _waveCursor += 1;
        events.add(
          Phase0aWaveStarted(
            seq: nextSeq,
            tick: tick,
            waveIndex: _waveCursor + 1,
            waveTotal: _waves.length,
          ),
        );
        nextSeq += 1;
        // 换波只替换 enemies:玩家/技能槽/tick/seq 原样连续。
        _rebuildSession(
          Phase0aArenaState(
            tick: resolved.tick,
            nextSeq: nextSeq,
            player: resolved.player,
            enemies: _waves[_waveCursor].enemies,
            skillSlots: resolved.skillSlots,
          ),
        );
      }
    }
    return List.unmodifiable(events);
  }

  /// 以新 state 重建私有会话,复用同一 adapter/resolver 实例。
  void _rebuildSession(Phase0aArenaState nextState) {
    final previous = _session;
    _session = Phase0aCombatSession(
      initialState: nextState,
      playerAdapter: previous.playerAdapter,
      enemyAiAdapter: previous.enemyAiAdapter,
      damageResolver: previous.damageResolver,
      enemySkillDamageResolver: previous.enemySkillDamageResolver,
    );
  }

  static Phase0aArenaState _withNextSeq(Phase0aArenaState state, int nextSeq) {
    return Phase0aArenaState(
      tick: state.tick,
      nextSeq: nextSeq,
      player: state.player,
      enemies: state.enemies,
      skillSlots: state.skillSlots,
    );
  }

  /// 构造期 fail-fast:波次非空、首态玩家 side、首态 enemies 与首波一致、
  /// 全场 actor id 唯一;波次列表做防御性不可修改副本。
  static List<Phase0aWave> _checkedWaves(
    List<Phase0aWave> waves,
    Phase0aArenaState initialState,
  ) {
    if (waves.isEmpty) {
      throw ArgumentError.value(waves, 'waves', '波次列表不得为空');
    }
    if (initialState.player.side != Phase0aSide.player) {
      throw ArgumentError.value(
        initialState.player.id,
        'session',
        '首态玩家必须为 player side',
      );
    }
    if (!_sameActors(initialState.enemies, waves.first.enemies)) {
      throw ArgumentError.value(
        waves.first.enemies.map((enemy) => enemy.id).toList(),
        'waves',
        '首态 enemies 必须与首波一致',
      );
    }
    final ids = <String>{initialState.player.id};
    for (final wave in waves) {
      for (final enemy in wave.enemies) {
        if (!ids.add(enemy.id)) {
          throw ArgumentError.value(enemy.id, 'waves', '全场 actor id 重复');
        }
      }
    }
    return List.unmodifiable(List.of(waves));
  }

  static bool _sameActors(List<Phase0aActor> a, List<Phase0aActor> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
