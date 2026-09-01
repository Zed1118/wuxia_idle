import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../../expedition/domain/expedition_run.dart';
import '../domain/activity_member_snapshot.dart';
import '../domain/activity_occupancy.dart';
import '../domain/durable_activity_combat_run.dart';

/// 唯一对外占用查询口（companion §3.5/§8.1 Q5）。聚合闭关（既有
/// [Character.currentRetreatSessionId] 字段路径，零重做）+ 百草岭 + 断魂庄
/// 三源，返回统一 [ActivityOccupancy]；各入口不再各自散查两套 session collection。
class CharacterOccupancyService {
  const CharacterOccupancyService(this._isar);

  final Isar _isar;

  Future<ActivityOccupancy> snapshot({
    ActivityKind? excludingKind,
    int? excludingRunId,
  }) async {
    final entries = <ActivityOccupancyEntry>[];

    // 闭关：沿既有字段路径判定，仅锁角色（不保留装备/心法）。
    final retreating = await _isar.characters
        .filter()
        .currentRetreatSessionIdIsNotNull()
        .findAll();
    if (retreating.isNotEmpty) {
      entries.add(
        ActivityOccupancyEntry(
          kind: ActivityKind.retreat,
          runId: null,
          characterIds: {for (final c in retreating) c.id},
          equipmentIds: const <int>{},
          techniqueIds: const <int>{},
        ),
      );
    }

    for (final run in await _isar.expeditionRuns.where().findAll()) {
      entries.add(_fromMembers(ActivityKind.expedition, run.id, run.members));
    }
    for (final run in await _isar.bossGauntletRuns.where().findAll()) {
      entries.add(_fromMembers(ActivityKind.bossGauntlet, run.id, run.members));
    }
    for (final run in await _isar.durableActivityCombatRuns.where().findAll()) {
      if (run.phase == DurableActivityPhase.closed) continue;
      final kind = switch (run.kind) {
        DurableActivityKind.tower => ActivityKind.tower,
        DurableActivityKind.lightFoot => ActivityKind.lightFoot,
        DurableActivityKind.massBattle => ActivityKind.massBattle,
      };
      if (kind == excludingKind && run.id == excludingRunId) continue;
      entries.add(_fromMembers(kind, run.id, run.members));
    }

    return ActivityOccupancy(entries);
  }

  ActivityOccupancyEntry _fromMembers(
    ActivityKind kind,
    int runId,
    List<ActivityMemberSnapshot> members,
  ) {
    return ActivityOccupancyEntry(
      kind: kind,
      runId: runId,
      characterIds: {for (final m in members) m.characterId},
      equipmentIds: {for (final m in members) ...m.reservedEquipmentIds},
      techniqueIds: {for (final m in members) ...m.reservedTechniqueIds},
    );
  }
}
