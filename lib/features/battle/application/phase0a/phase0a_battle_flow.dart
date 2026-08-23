import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart' show Phase0aBattleOutcome;
import 'phase0a_player_input_adapter.dart';

/// Phase 0A 战斗 flow 最小消费契约(2026-08-23 D03 冻结)。
///
/// live controller、headless sync/async 快进、终局「再战」builder 只依赖
/// 这组成员:`state` / `outcome` / `lastOrderedEventRecords` / `advance`。
/// 波次编排(transition policy / 波次列表 / 波次游标 / session / resolver)
/// 属于 [Phase0aWaveBattleFlow] 的具体实现细节,非 wave flow 无需感知,
/// 也不在本接口暴露。
abstract interface class Phase0aBattleFlow {
  Phase0aArenaState get state;

  Phase0aBattleOutcome get outcome;

  List<CombatEventRecord> get lastOrderedEventRecords;

  /// 推进一拍,返回本拍事件;终局后必须幂等(空事件、state 不变)。
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  });
}
