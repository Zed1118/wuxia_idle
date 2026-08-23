import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/spawn_director.dart';

/// 把 [SpawnDirector] 的单拍事件投影为带全局 seq/combat tick 的
/// [Phase0aEvent] 序列,与既有战斗事件共用同一严格递增 seq 空间。
///
/// 纯投影:不排序、不去重、不消费 RNG,不修改 director/roster/arena;
/// 按输入事件原顺序分配自 [seqStart] 起连续的 seq。投影入场点取
/// [Phase0aEncounterRoster] 绑定 actor 的显式入场坐标。
/// 任何非法输入(负 seq/tick、director event tick 与本拍不符、未知
/// entry 映射)均直接抛 [ArgumentError](fail closed)。
final class Phase0aSpawnEventAdapter {
  const Phase0aSpawnEventAdapter._();

  /// 投影一拍导演事件。返回顺序与 [directorEvents] 一致。
  static List<Phase0aEvent> project({
    required List<SpawnDirectorEvent> directorEvents,
    required Phase0aEncounterRoster roster,
    required int seqStart,
    required int combatTick,
  }) {
    if (seqStart < 0) {
      throw ArgumentError.value(seqStart, 'seqStart', 'must be non-negative');
    }
    if (combatTick < 0) {
      throw ArgumentError.value(
        combatTick,
        'combatTick',
        'must be non-negative',
      );
    }
    final events = <Phase0aEvent>[];
    var seq = seqStart;
    for (final directorEvent in directorEvents) {
      if (directorEvent.tick != combatTick) {
        throw ArgumentError.value(
          directorEvent.tick,
          'directorEvents',
          'event tick must equal combatTick $combatTick',
        );
      }
      final binding = roster.bindingByEntryId(directorEvent.entryId);
      if (binding == null) {
        throw ArgumentError.value(
          directorEvent.entryId,
          'directorEvents',
          'unknown entryId in roster',
        );
      }
      events.add(
        _projectEvent(
          directorEvent: directorEvent,
          seq: seq,
          combatTick: combatTick,
          binding: binding,
        ),
      );
      seq++;
    }
    return List.unmodifiable(events);
  }

  static Phase0aEvent _projectEvent({
    required SpawnDirectorEvent directorEvent,
    required int seq,
    required int combatTick,
    required Phase0aEncounterRosterBinding binding,
  }) {
    final position = binding.actor.position;
    return switch (directorEvent.type) {
      SpawnDirectorEventType.warningStarted => Phase0aSpawnWarningStarted(
        seq: seq,
        tick: combatTick,
        entryId: binding.entryId,
        enemyId: binding.actorId,
        entryPosition: position,
      ),
      SpawnDirectorEventType.entered => Phase0aEnemyEntered(
        seq: seq,
        tick: combatTick,
        entryId: binding.entryId,
        enemyId: binding.actorId,
        entryPosition: position,
      ),
      SpawnDirectorEventType.graceExpired => Phase0aSpawnGraceExpired(
        seq: seq,
        tick: combatTick,
        entryId: binding.entryId,
        enemyId: binding.actorId,
        entryPosition: position,
      ),
    };
  }
}
