import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../domain/expedition_config.dart';
import '../domain/expedition_run.dart';
import 'expedition_service.dart';

part 'expedition_providers.g.dart';

/// [ExpeditionService] provider（百草岭远征 · B2.4）。
///
/// 沿 nullable propagation 链（`lineup_providers` 体例）：isar 为 null 时 service
/// 也为 null，widget 端 `service == null` 短路。战斗协作者 [ExpeditionCombatRunner]
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

/// 单个派遣候选（总览派遣态用）：角色 + 可派遣性标注（§4.1）。
class ExpeditionCandidate {
  const ExpeditionCandidate({
    required this.character,
    required this.occupied,
    required this.hasMainTechnique,
  });

  final Character character;

  /// 已被其它活动（闭关/远征/断魂庄）占用 → 不可派遣（UI 标灰）。
  final bool occupied;

  /// 已修主修 → 可派遣前置（§4.1）。未修 UI 标灰引导研习（§5.7）。
  final bool hasMainTechnique;

  /// 满足派遣前置：未被占用且已修主修。
  bool get dispatchable => !occupied && hasMainTechnique;
}

/// 派遣候选池（总览派遣态）：全部可上场非祖师角色（`isFounder==false && isAlive`
/// 一条 Isar 查询即覆盖 active 门人 + inactive 替补），各标占用/主修态。祖师坐镇
/// 不出征、亡者排除（§4.1）；已被占用者仍列出但标灰（§7.1「远征中」口径），不做
/// GameRepository 依赖的排序（保持轻量、可在无 defs 环境测）。派遣/召回写路径后由
/// caller `ref.invalidate(expeditionCandidatesProvider)` 统一失效。
@riverpod
Future<List<ExpeditionCandidate>> expeditionCandidates(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  final chars = await isar.characters
      .filter()
      .isFounderEqualTo(false)
      .isAliveEqualTo(true)
      .findAll();
  final occ = await CharacterOccupancyService(isar).snapshot();
  return [
    for (final c in chars)
      ExpeditionCandidate(
        character: c,
        occupied: occ.isCharacterOccupied(c.id),
        hasMainTechnique: c.mainTechniqueId != null,
      ),
  ];
}
