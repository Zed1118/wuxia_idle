import '../domain/battle_state.dart';

/// 纯表现层的三战位队列回放结果。
///
/// 群战引擎仍让整队同时参战；这里只按 [BattleState.actionLog]
/// 的击杀顺序回放“画面上的三个人”。首发占据 0..2 号位，
/// 某位阵亡时由尚未入场且当时未阵亡的下一人补同一空位。
/// 不写回 state，不影响战斗、结算或目标选择。
class BattleVisualRoster {
  const BattleVisualRoster._({
    required this.leftSlots,
    required this.rightSlots,
    required this.queuedAliveEnemyCount,
  });

  factory BattleVisualRoster.fromState(BattleState state) {
    final leftSlots = _replayTeam(state.leftTeam, state.actionLog);
    final rightSlots = _replayTeam(state.rightTeam, state.actionLog);
    final visibleRightIds = rightSlots.whereType<int>().toSet();
    final queuedAliveEnemyCount = state.rightTeam
        .where(
          (character) =>
              character.isAlive &&
              !visibleRightIds.contains(character.characterId),
        )
        .length;
    return BattleVisualRoster._(
      leftSlots: leftSlots,
      rightSlots: rightSlots,
      queuedAliveEnemyCount: queuedAliveEnemyCount,
    );
  }

  final List<int?> leftSlots;
  final List<int?> rightSlots;
  final int queuedAliveEnemyCount;

  List<int?> slotsForSide(int teamSide) =>
      teamSide == 0 ? leftSlots : rightSlots;

  BattleVisualPosition? positionOf(int characterId) {
    for (var slotIndex = 0; slotIndex < leftSlots.length; slotIndex++) {
      if (leftSlots[slotIndex] == characterId) {
        return BattleVisualPosition(
          teamSide: 0,
          slotIndex: slotIndex,
          teamSize: leftSlots.length.clamp(1, 3),
        );
      }
    }
    for (var slotIndex = 0; slotIndex < rightSlots.length; slotIndex++) {
      if (rightSlots[slotIndex] == characterId) {
        return BattleVisualPosition(
          teamSide: 1,
          slotIndex: slotIndex,
          teamSize: rightSlots.length.clamp(1, 3),
        );
      }
    }
    return null;
  }
}

class BattleVisualPosition {
  const BattleVisualPosition({
    required this.teamSide,
    required this.slotIndex,
    required this.teamSize,
  });

  final int teamSide;
  final int slotIndex;
  final int teamSize;

  int get slotKey => teamSide * 3 + slotIndex;
}

List<int?> _replayTeam(
  List<BattleCharacter> team,
  List<BattleAction> actionLog,
) {
  if (team.isEmpty) return const <int?>[];
  if (team.length <= 3) {
    return [for (final character in team) character.characterId];
  }

  final teamIds = {for (final character in team) character.characterId};
  final slots = <int?>[
    for (final character in team.take(3)) character.characterId,
  ];
  final waiting = <int>[
    for (final character in team.skip(3)) character.characterId,
  ];
  final defeated = <int>{};

  for (final action in actionLog) {
    final targetId = action.targetId;
    if (!action.defeatedTarget ||
        targetId == null ||
        !teamIds.contains(targetId)) {
      continue;
    }
    defeated.add(targetId);
    final defeatedSlot = slots.indexOf(targetId);
    if (defeatedSlot < 0) continue;

    int? replacement;
    while (waiting.isNotEmpty && replacement == null) {
      final candidate = waiting.removeAt(0);
      if (!defeated.contains(candidate)) replacement = candidate;
    }
    slots[defeatedSlot] = replacement;
  }

  // 兼容无 actionLog 的轻量 fixture：只用当前存活态补齐，
  // 真实生产战斗仍以上面的击杀顺序为准。
  final aliveIds = {
    for (final character in team)
      if (character.isAlive) character.characterId,
  };
  for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
    final characterId = slots[slotIndex];
    if (characterId != null && aliveIds.contains(characterId)) continue;
    while (waiting.isNotEmpty) {
      final candidate = waiting.removeAt(0);
      if (aliveIds.contains(candidate)) {
        slots[slotIndex] = candidate;
        break;
      }
    }
  }
  return slots;
}
