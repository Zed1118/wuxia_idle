import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';
import '../domain/tower_progress.dart';
import 'leaderboard_sync_service.dart';
import 'tower_progress_service.dart';

part 'tower_providers.g.dart';

/// 当前存档的爬塔进度（Phase 3 T42）。
///
/// recordClear / recordDefeat 后调用 `ref.invalidate(towerProgressProvider)`
/// 触发刷新，[towerFloorListProvider] 自动级联。
@Riverpod(dependencies: [])
Future<TowerProgress> towerProgress(Ref ref) async {
  return TowerProgressService(
    isar: IsarSetup.instance,
  ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
}

/// 30 层列表含三态 status（Phase 3 T42）。
///
/// 依赖 [towerProgressProvider]，进度刷新后自动级联。
@Riverpod(dependencies: [towerProgress])
Future<List<TowerFloorEntry>> towerFloorList(Ref ref) async {
  final progress = await ref.watch(towerProgressProvider.future);
  return TowerProgressService.floorList(
    progress: progress,
    allFloors: GameRepository.instance.towerFloors,
  );
}

/// 九霄塔逐次亲战候选。占用或无主修者保留展示但不可选择。
class TowerParticipantCandidate {
  const TowerParticipantCandidate({
    required this.character,
    required this.occupied,
    required this.healing,
    required this.hasMainTechnique,
  });

  final Character character;
  final bool occupied;
  final bool healing;
  final bool hasMainTechnique;

  bool get selectable => !occupied && !healing && hasMainTechnique;
}

/// 读取当前掌门与存活门人；历史祖师不混入，身份损坏时整体 fail closed。
Future<List<TowerParticipantCandidate>> loadTowerParticipantCandidates({
  required Isar isar,
}) async {
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final candidates = <TowerParticipantCandidate>[];
  for (final member in scheduling.members) {
    if (!member.isAlive) continue;
    final character = await isar.characters.get(member.characterId);
    if (character == null) {
      throw StateError('Tower participant disappeared: ${member.characterId}');
    }
    candidates.add(
      TowerParticipantCandidate(
        character: character,
        occupied: member.activity != null,
        healing: character.injuryHoursRemaining > 0,
        hasMainTechnique: character.mainTechniqueId != null,
      ),
    );
  }
  candidates.sort((a, b) {
    if (a.character.id == scheduling.leaderId) return -1;
    if (b.character.id == scheduling.leaderId) return 1;
    return a.character.id.compareTo(b.character.id);
  });
  return List.unmodifiable(candidates);
}

/// 选择后、进入真实 Host 前再次核验并装配 exact snapshot；绝不回退掌门。
Future<CombatantSnapshot> resolveTowerParticipantSnapshot({
  required Isar isar,
  required int requestedParticipantId,
}) async {
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final member = scheduling.members
      .where((value) => value.characterId == requestedParticipantId)
      .firstOrNull;
  final character = await isar.characters.get(requestedParticipantId);
  if (member == null ||
      !member.isAlive ||
      member.activity != null ||
      character == null ||
      character.injuryHoursRemaining > 0 ||
      character.mainTechniqueId == null) {
    throw StateError('Tower participant is not battle eligible');
  }
  for (final equipmentId in [
    character.equippedWeaponId,
    character.equippedArmorId,
    character.equippedAccessoryId,
  ]) {
    if (equipmentId != null && await isar.equipments.get(equipmentId) == null) {
      throw StateError('Tower participant has dangling equipment');
    }
  }
  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([requestedParticipantId]);
  if (snapshots.length != 1 ||
      snapshots.single.characterId != requestedParticipantId) {
    throw StateError('Tower participant snapshot mismatch');
  }
  return snapshots.single;
}

@Riverpod(dependencies: [])
Future<List<TowerParticipantCandidate>> towerParticipantCandidates(Ref ref) =>
    loadTowerParticipantCandidates(isar: IsarSetup.instance);

/// 排行榜同步服务(P0.2 #40 Phase 3,方案 D placeholder)。
///
/// Demo 阶段默认注入 [NoopLeaderboardSync](0 backend / 0 network call)。
/// 未来升 Pro plan 接 Supabase 时,替换返回为 SupabaseLeaderboardSync 即可,
/// victory hook 0 改动。
@Riverpod(dependencies: [])
LeaderboardSyncService leaderboardSync(Ref ref) {
  return const NoopLeaderboardSync();
}
