import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_player_bot_adapter.dart';
import 'phase0a_wave_battle_flow.dart';

/// Phase 0A headless 快进结果:终局态 + 消耗拍数 + 终态快照。
///
/// [outcome] 为 ongoing 即快进预算耗尽(未分胜负),消费方按超时语义处理。
final class Phase0aHeadlessResult {
  const Phase0aHeadlessResult({
    required this.outcome,
    required this.ticks,
    required this.finalState,
    required this.events,
  });

  final Phase0aBattleOutcome outcome;
  final int ticks;
  final Phase0aArenaState finalState;
  final List<Phase0aEvent> events;

  bool get timedOut => outcome == Phase0aBattleOutcome.ongoing;
}

/// Phase 0A headless 快进 runner(headless 内核批,路线 C 子项①落地):
/// 以固定拍长驱动已装配的 [Phase0aWaveBattleFlow],bot 指令替代真人输入,
/// 跑到终局(victory/defeat)或拍数预算耗尽。
///
/// 纯函数式消费,零 Flutter 依赖,供远征/断魂庄托管与离线快进复用同一
/// 模拟核;不复制任何移动/伤害/CD/波次/终局规则——全部结算只发生在
/// reducer。确定性由装配方保证:相同初态 + 相同 damageResolver 行为序列
/// 必得相同结果(rng 经 adapter 显式注入)。
final class Phase0aHeadlessRunner {
  const Phase0aHeadlessRunner._();

  static Phase0aHeadlessResult runToEnd({
    required Phase0aWaveBattleFlow flow,
    required Phase0aPlayerBotAdapter bot,
    double deltaSeconds = 1 / 30,
    int maxTicks = 30 * 60 * 5,
  }) {
    // 拍长必须有限且正:零/负值会让快进永不推进或反向,NaN 绕过一切比较。
    if (!(deltaSeconds.isFinite && deltaSeconds > 0)) {
      throw ArgumentError.value(
        deltaSeconds,
        'deltaSeconds',
        'must be finite and positive',
      );
    }
    if (maxTicks < 0) {
      throw ArgumentError.value(maxTicks, 'maxTicks', 'must be non-negative');
    }
    var ticks = 0;
    final events = <Phase0aEvent>[];
    while (flow.outcome == Phase0aBattleOutcome.ongoing && ticks < maxTicks) {
      events.addAll(
        flow.advance(
          deltaSeconds: deltaSeconds,
          command: bot.commandFor(flow.state),
        ),
      );
      ticks++;
    }
    return Phase0aHeadlessResult(
      outcome: flow.outcome,
      ticks: ticks,
      finalState: flow.state,
      events: List.unmodifiable(events),
    );
  }
}
