import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../domain/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import 'gauntlet_service.dart';

part 'gauntlet_providers.g.dart';

/// [GauntletService] provider（断魂庄 · C2.5）。
///
/// 沿 nullable propagation 链（`expedition_providers` 体例）：isar 为 null 时 service
/// 也为 null，widget 端 `service == null` 短路（测试旁路）。[GauntletService.itemDefs]
/// 供 useSupply/close/返还读补给效果与库存重建类型，从 `GameRepository` 注入。
@riverpod
GauntletService? gauntletService(Ref ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return null;
  return GauntletService(
    isar,
    itemDefs: GameRepository.instanceOrNull?.itemDefs ?? const {},
  );
}

/// 当前 active 断魂庄会话（总览断魂庄卡 / 整备屏 watch；无会话 → null）。
/// enter/fight/choose/settle/close 写路径后由 caller
/// `ref.invalidate(activeGauntletProvider)` 统一失效。
@riverpod
Future<BossGauntletRun?> activeGauntlet(Ref ref) async {
  final service = ref.watch(gauntletServiceProvider);
  if (service == null) return null;
  return service.activeRun();
}

/// 断魂庄配置（§8.2）。经 provider watch 而非在 widget 构造期直读单例，避开
/// GameRepository 异步加载与控制器 final 字段的竞态（feedback_flutter_async_config
/// _race_controller_final）。未加载 → null，UI 端降级（不显三敌/推荐境界/入庄）。
@riverpod
BossGauntletConfig? gauntletConfig(Ref ref) =>
    GameRepository.instanceOrNull?.bossGauntletConfig;

/// 一种可托管补给的装载信息（装载屏补给栏用）：defId + 显示名 + 当前普通库存持有数。
class GauntletSupplyOption {
  const GauntletSupplyOption({
    required this.defId,
    required this.name,
    required this.owned,
  });

  final String defId;
  final String name;

  /// 普通库存持有数（可装载上界之一，另一上界为剩余补给预算 3-已装）。
  final int owned;
}

/// 装载屏顶部信息（断魂帖库存 + 可托管补给持有量·§7.1）。断魂庄补给类型 = itemDefs 中
/// `gauntletHpHealPct>0 || gauntletQiRestorePct>0` 者（疗伤丹/行囊补给），按 defId 稳定
/// 排序。enter/close 写路径（改库存）后由 caller `ref.invalidate(gauntletLoadoutInfoProvider)`。
class GauntletLoadoutInfo {
  const GauntletLoadoutInfo({
    required this.ticketCount,
    required this.supplies,
  });

  final int ticketCount;
  final List<GauntletSupplyOption> supplies;
}

/// 装载屏信息 provider（断魂帖库存 + 补给持有·§7.1）。
@riverpod
Future<GauntletLoadoutInfo> gauntletLoadoutInfo(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    return const GauntletLoadoutInfo(ticketCount: 0, supplies: []);
  }
  final ticket = await isar.inventoryItems.getByDefId(
    GauntletService.ticketDefId,
  );
  final defs = GameRepository.instanceOrNull?.itemDefs ?? const {};
  final supplies = <GauntletSupplyOption>[];
  for (final entry in defs.entries) {
    final d = entry.value;
    if (d.gauntletHpHealPct > 0 || d.gauntletQiRestorePct > 0) {
      final inv = await isar.inventoryItems.getByDefId(entry.key);
      supplies.add(
        GauntletSupplyOption(
          defId: entry.key,
          name: d.name,
          owned: inv?.quantity ?? 0,
        ),
      );
    }
  }
  supplies.sort((a, b) => a.defId.compareTo(b.defId));
  return GauntletLoadoutInfo(
    ticketCount: ticket?.quantity ?? 0,
    supplies: supplies,
  );
}

/// 单个入场候选（装载屏择人 1-3 用）：角色 + 可入场性标注（§5.1）。
class GauntletCandidate {
  const GauntletCandidate({
    required this.character,
    required this.occupied,
    required this.hasMainTechnique,
  });

  final Character character;

  /// 已被其它活动（闭关/远征/断魂庄）占用 → 不可入场（UI 标灰）。
  final bool occupied;

  /// 已修主修 → 可入场前置（`enter` 硬拦未修者）。未修 UI 标灰引导研习（§5.7）。
  final bool hasMainTechnique;

  /// 满足入场前置：未被占用且已修主修。
  bool get selectable => !occupied && hasMainTechnique;
}

/// 入场候选池（装载屏）：全部可上场非祖师角色（`isFounder==false && isAlive` 一条
/// Isar 查询覆盖 active 门人 + inactive 替补），各标占用/主修态。祖师坐镇不入场
/// （`enter` 硬拦）、亡者排除（§5.1）；已被占用者仍列出但标灰。不做 GameRepository
/// 依赖的排序（保持轻量、可在无 defs 环境测）。enter/settle 写路径后由 caller
/// `ref.invalidate(gauntletCandidatesProvider)` 统一失效。
@riverpod
Future<List<GauntletCandidate>> gauntletCandidates(Ref ref) async {
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
      GauntletCandidate(
        character: c,
        occupied: occ.isCharacterOccupied(c.id),
        hasMainTechnique: c.mainTechniqueId != null,
      ),
  ];
}
