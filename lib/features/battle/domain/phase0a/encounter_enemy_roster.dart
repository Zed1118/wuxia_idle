import 'arena_vector.dart';
import 'phase0a_combat_model.dart';
import 'spawn_director.dart';

/// SpawnDirector entry 与完整 [Phase0aActor] 的精确绑定。
///
/// [actorId] 冗余携带仅为可读性;权威校验在 [Phase0aEncounterRoster] 构造期:
/// [entryId] 必须存在于绑定的 director,[actorId] 必须等于对应 entry 的
/// enemyId,[actor] 必须为敌方阵营、初始存活且 ID 不等于玩家。
final class Phase0aEncounterRosterBinding {
  Phase0aEncounterRosterBinding({required this.entryId, required this.actor})
    : actorId = actor.id;

  final String entryId;
  final String actorId;
  final Phase0aActor actor;
}

/// 冻结遭遇名单:把 [SpawnDirector] 的每个 entryId/enemyId 精确绑定到一个
/// 完整 [Phase0aActor],[Phase0aActor.position] 即该 entry 的显式入场点。
///
/// 构造期一次性校验,任何非法输入(缺失/多余/重复绑定、entry/enemy 不匹配、
/// 非敌方/初始死亡/与玩家同 ID 的 actor、全场 actor ID 冲突)均直接抛
/// [ArgumentError](fail closed)。构造后完全不可变:绑定列表防御性复制并按
/// entryId 稳定排序,不暴露任何可变 map/list;lookup 对未知输入返回 null。
final class Phase0aEncounterRoster {
  Phase0aEncounterRoster({
    required SpawnDirector director,
    required String playerId,
    required List<Phase0aEncounterRosterBinding> bindings,
  }) : _director = director,
       _playerId = _checkedPlayerId(playerId),
       _bindings = _freeze(director, playerId, bindings);

  final SpawnDirector _director;
  final String _playerId;
  final List<Phase0aEncounterRosterBinding> _bindings;

  static String _checkedPlayerId(String playerId) {
    if (playerId.trim().isEmpty || RegExp(r'\s').hasMatch(playerId)) {
      throw ArgumentError.value(
        playerId,
        'playerId',
        'must be non-empty and contain no whitespace',
      );
    }
    return playerId;
  }

  static List<Phase0aEncounterRosterBinding> _freeze(
    SpawnDirector director,
    String playerId,
    List<Phase0aEncounterRosterBinding> bindings,
  ) {
    _checkedPlayerId(playerId);
    final entries = director.state.units;
    final entriesByEntryId = <String, SpawnUnitSnapshot>{
      for (final unit in entries) unit.entryId: unit,
    };
    if (bindings.length != entries.length) {
      throw ArgumentError.value(
        bindings,
        'bindings',
        'expected ${entries.length} bindings, got ${bindings.length}',
      );
    }
    final seenEntryIds = <String>{};
    final seenActorIds = <String>{};
    final frozen = <Phase0aEncounterRosterBinding>[];
    for (final binding in bindings) {
      final entry = entriesByEntryId[binding.entryId];
      if (entry == null) {
        throw ArgumentError.value(
          binding.entryId,
          'bindings',
          'unknown entryId',
        );
      }
      if (!seenEntryIds.add(binding.entryId)) {
        throw ArgumentError.value(
          binding.entryId,
          'bindings',
          'duplicate entryId',
        );
      }
      final actor = binding.actor;
      if (actor.id != entry.enemyId) {
        throw ArgumentError.value(
          actor.id,
          'bindings',
          'actor id must equal entry enemyId ${entry.enemyId}',
        );
      }
      if (!seenActorIds.add(actor.id)) {
        throw ArgumentError.value(actor.id, 'bindings', 'duplicate actor id');
      }
      if (actor.id == playerId) {
        throw ArgumentError.value(
          actor.id,
          'bindings',
          'actor id must not equal playerId',
        );
      }
      if (actor.side != Phase0aSide.enemy) {
        throw ArgumentError.value(
          actor.id,
          'bindings',
          'actor must be on the enemy side',
        );
      }
      if (!actor.isAlive) {
        throw ArgumentError.value(
          actor.id,
          'bindings',
          'actor must be alive at roster freeze time',
        );
      }
      frozen.add(binding);
    }
    frozen.sort((a, b) => a.entryId.compareTo(b.entryId));
    return List.unmodifiable(frozen);
  }

  /// 冻结时的 director 输入(只读引用;名单不持有也不推进导演状态)。
  SpawnDirector get director => _director;

  /// 与该 roster 互斥的玩家 actor ID。
  String get playerId => _playerId;

  /// 全部绑定,按 entryId 升序,不可修改。
  List<Phase0aEncounterRosterBinding> get bindings => _bindings;

  int get size => _bindings.length;

  /// 按 entryId 查绑定;未知入口返回 null。
  Phase0aEncounterRosterBinding? bindingByEntryId(String entryId) {
    for (final binding in _bindings) {
      if (binding.entryId == entryId) return binding;
    }
    return null;
  }

  /// 按 enemyId(= 绑定 actor 的 id)查绑定;未知敌人返回 null。
  Phase0aEncounterRosterBinding? bindingByEnemyId(String enemyId) {
    for (final binding in _bindings) {
      if (binding.actorId == enemyId) return binding;
    }
    return null;
  }

  /// 按 entryId 查显式入场点坐标;未知入口返回 null。
  ArenaVector? entryPositionOf(String entryId) =>
      bindingByEntryId(entryId)?.actor.position;

  @override
  bool operator ==(Object other) {
    if (other is! Phase0aEncounterRoster) return false;
    if (!identical(other._director, _director) &&
        other._director != _director) {
      return false;
    }
    if (other._bindings.length != _bindings.length) return false;
    for (var i = 0; i < _bindings.length; i++) {
      final a = other._bindings[i];
      final b = _bindings[i];
      if (a.entryId != b.entryId || a.actor != b.actor) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    _director,
    Object.hashAll(
      _bindings.map((binding) => Object.hash(binding.entryId, binding.actor)),
    ),
  );
}
