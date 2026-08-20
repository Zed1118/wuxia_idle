import 'package:flutter/foundation.dart';

import '../../application/phase0a/phase0a_player_input_adapter.dart';
import '../../application/phase0a/phase0a_wave_battle_flow.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_event_sequencer.dart';
import 'phase0a_vfx_controller.dart';
import 'phase0a_visual_roster.dart';

final class Phase0aBattleController extends ChangeNotifier {
  Phase0aBattleController({
    required Phase0aWaveBattleFlow flow,
    required this.roster,
    required this.fixedDeltaSeconds,
  }) : _flow = flow {
    if (!(fixedDeltaSeconds.isFinite && fixedDeltaSeconds > 0)) {
      throw ArgumentError.value(
        fixedDeltaSeconds,
        'fixedDeltaSeconds',
        'must be finite and positive',
      );
    }
    _vfx.syncActors(_flow.state);
  }

  /// 当前 flow。`restart` 换入新实例,故非 final。
  Phase0aWaveBattleFlow _flow;
  final Phase0aVisualRoster roster;
  final double fixedDeltaSeconds;

  /// 排序器/VFX 均带跨拍内部状态(已接受 seq 集合 / 终局封签 `_sealed`),
  /// restart 必须一并重建,故非 final。
  Phase0aEventSequencer _sequencer = Phase0aEventSequencer();
  Phase0aVfxController _vfx = Phase0aVfxController();

  Phase0aPlayerCommand _pending = const Phase0aPlayerCommand();
  List<Phase0aEvent> _lastEvents = const <Phase0aEvent>[];
  List<Phase0aEvent> _events = const <Phase0aEvent>[];
  List<Phase0aVfxEntry> _feedback = const <Phase0aVfxEntry>[];

  Phase0aArenaState get state => _flow.state;
  Phase0aBattleOutcome get outcome => _flow.outcome;
  List<Phase0aEvent> get lastEvents => _lastEvents;
  List<Phase0aEvent> get events => _events;
  List<Phase0aVfxEntry> get feedback => _feedback;

  /// 终局重开(9B):换入调用方装配的全新 flow,重建排序器与 VFX 控制器,
  /// 清空 pending/事件/反馈缓存。只换实例,不触碰 domain 任何规则;
  /// 新 flow 的装配责任在调用方(debug 路由 = 重载 fixture 同 seed 新会话)。
  void restart(Phase0aWaveBattleFlow newFlow) {
    _flow = newFlow;
    _sequencer = Phase0aEventSequencer();
    _vfx = Phase0aVfxController();
    _pending = const Phase0aPlayerCommand();
    _lastEvents = const <Phase0aEvent>[];
    _events = const <Phase0aEvent>[];
    _feedback = const <Phase0aVfxEntry>[];
    _vfx.syncActors(_flow.state);
    notifyListeners();
  }

  void enqueue(Phase0aPlayerCommand command) {
    if (outcome != Phase0aBattleOutcome.ongoing) return;
    _pending = _merge(_pending, command);
  }

  List<Phase0aEvent> step([Phase0aPlayerCommand? command]) {
    if (outcome != Phase0aBattleOutcome.ongoing) {
      return const <Phase0aEvent>[];
    }
    if (command != null) enqueue(command);
    final snapshot = _pending;
    _pending = const Phase0aPlayerCommand();

    _vfx.syncActors(_flow.state);
    final emitted = _flow.advance(
      deltaSeconds: fixedDeltaSeconds,
      command: snapshot,
    );
    final accepted = _sequencer.ingest(emitted);
    _lastEvents = List.unmodifiable(accepted);
    _events = List.unmodifiable([..._events, ...accepted]);
    _feedback = List.unmodifiable(_vfx.consume(accepted));
    notifyListeners();
    return _lastEvents;
  }

  static Phase0aPlayerCommand _merge(
    Phase0aPlayerCommand left,
    Phase0aPlayerCommand right,
  ) => Phase0aPlayerCommand(
    left: left.left || right.left,
    right: left.right || right.right,
    up: left.up || right.up,
    down: left.down || right.down,
    attack: left.attack || right.attack,
    attackAimDirection: right.attack
        ? right.attackAimDirection
        : left.attackAimDirection,
    skillHotkey: right.skillHotkey ?? left.skillHotkey,
    skillAimDirection: right.skillHotkey != null
        ? right.skillAimDirection
        : left.skillAimDirection,
    gather: left.gather || right.gather,
    clear: left.clear || right.clear,
  );
}
