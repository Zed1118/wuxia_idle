import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../data/defs/expedition_config.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';
import '../domain/expedition_run.dart';
import 'expedition_service.dart';

part 'expedition_providers.g.dart';

/// [ExpeditionService] provider（百草岭远征 · B2.4）。
///
/// 沿 nullable propagation 链（`lineup_providers` 体例）：isar 为 null 时 service
/// 也为 null，widget 端 `service == null` 短路。战斗协作者
/// 有跨节点缓存、按结算次创建，不入 provider（避免陈旧缓存）。
@riverpod
ExpeditionService? expeditionService(Ref ref) {
  final isar = ref.watch(isarProvider);
  return isar == null ? null : ExpeditionService(isar);
}

/// 当前 active 远征（总览/派遣中屏 watch；无远征 → null）。派遣/召回/结算写路径
/// 后由 caller `ref.invalidate(activeExpeditionProvider)` 统一失效。
@riverpod
Future<ExpeditionRun?> activeExpedition(Ref ref) async {
  final service = ref.watch(expeditionServiceProvider);
  if (service == null) return null;
  return service.activeRun();
}

/// 百草岭配置（§8.2）。经 provider watch 而非在 widget 构造期直读单例，避开
/// GameRepository 异步加载与控制器 final 字段的竞态（feedback_flutter_async_config
/// _race_controller_final）。未加载 → null，UI 端降级（不显下一节点剩余时间）。
@riverpod
ExpeditionConfig? expeditionConfig(Ref ref) =>
    GameRepository.instanceOrNull?.expeditionConfig;

/// 历史最深节点（批 B 周目选择：深度里程碑折算「已通周目」等价值 +
/// [SaveData.baicaoMaxDepth] 展示）。派遣/召回写路径后由 caller
/// `ref.invalidate(expeditionMaxDepthProvider)` 统一失效。
@riverpod
Future<int> expeditionMaxDepth(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return 0;
  final save = await isar.saveDatas.get(0);
  return save?.baicaoMaxDepth ?? 0;
}

/// 单个派遣候选（总览派遣态用）：角色 + 可派遣性标注（§4.1）。
class ExpeditionCandidate {
  const ExpeditionCandidate({
    required this.character,
    required this.occupied,
    required this.hasMainTechnique,
    required this.healing,
    required this.hasValidLoadout,
  });

  final Character character;

  /// 已被其它活动（闭关/远征/断魂庄）占用 → 不可派遣（UI 标灰）。
  final bool occupied;

  /// 已修主修 → 可派遣前置（§4.1）。未修 UI 标灰引导研习（§5.7）。
  final bool hasMainTechnique;
  final bool healing;
  final bool hasValidLoadout;

  /// 满足派遣前置：未被占用且已修主修。
  bool get dispatchable =>
      !occupied && !healing && hasMainTechnique && hasValidLoadout;
}

/// 派遣候选池（总览派遣态）：当前掌门 + 全部存活门人（覆盖 active 门人与 inactive
/// 替补），各标占用/主修态。当前掌门必须由 [CurrentLeaderResolver] 核实，前代祖师
/// 不得混入；亡者排除，已被占用者仍列出但标灰（§7.1「远征中」口径），不做
/// GameRepository 依赖的排序（保持轻量、可在无 defs 环境测）。派遣/召回写路径后由
/// caller `ref.invalidate(expeditionCandidatesProvider)` 统一失效。
@riverpod
Future<List<ExpeditionCandidate>> expeditionCandidates(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final candidates = <ExpeditionCandidate>[];
  for (final member in scheduling.members) {
    if (!member.isAlive) continue;
    final character = await isar.characters.get(member.characterId);
    if (character == null) {
      throw StateError(
        'Expedition candidate references missing character: '
        '${member.characterId}',
      );
    }
    var validLoadout = character.mainTechniqueId != null;
    for (final equipmentId in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (equipmentId == null) continue;
      final equipment = await isar.equipments.get(equipmentId);
      validLoadout =
          validLoadout &&
          equipment != null &&
          equipment.ownerCharacterId == character.id;
    }
    for (final techniqueId in [
      character.mainTechniqueId,
      ...character.assistTechniqueIds,
    ]) {
      if (techniqueId == null) continue;
      final technique = await isar.techniques.get(techniqueId);
      validLoadout =
          validLoadout &&
          technique != null &&
          technique.ownerCharacterId == character.id;
    }
    candidates.add(
      ExpeditionCandidate(
        character: character,
        occupied: member.activity != null,
        hasMainTechnique: character.mainTechniqueId != null,
        healing: character.injuryHoursRemaining > 0,
        hasValidLoadout: validLoadout,
      ),
    );
  }
  return candidates;
}
