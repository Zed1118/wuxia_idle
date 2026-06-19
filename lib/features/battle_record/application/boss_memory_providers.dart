import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../domain/boss_catalog_entry.dart';
import '../domain/boss_memory.dart';
import '../domain/boss_memory_key.dart';
import '../domain/boss_memory_source.dart';
import 'boss_memory_service.dart';

part 'boss_memory_providers.g.dart';

/// 爬塔 Boss 层固定常量（与 BossMemoryService.backfillFromProgress 保持一致）。
const _towerBossFloors = [5, 10, 15, 20, 25, 30];

/// 全 Boss 应有目录（不读 Isar，纯从 GameRepository 派生，同步 provider）。
///
/// 主线：遍历 GameRepository.stageDefs 中 isBossStage=true 的关卡。
/// 爬塔：固定层 [5,10,15,20,25,30]。
/// 总计约 27 条（21 主线 + 6 塔）。
///
/// 供主屏（T8）join BossMemory 显已击败 / 占位；catalog 自身不含 bossName（锁定态不剧透）。
@Riverpod(dependencies: [])
List<BossCatalogEntry> bossCatalog(Ref ref) {
  final repo = GameRepository.instance;
  final entries = <BossCatalogEntry>[];

  // 主线 Boss
  for (final def in repo.stageDefs.values) {
    if (!def.isBossStage) continue;
    entries.add(BossCatalogEntry(
      bossKey: mainlineBossKey(def.id),
      source: BossMemorySource.mainline,
      groupIndex: mainlineGroupIndex(def.id),
    ));
  }

  // 爬塔 Boss
  for (final floor in _towerBossFloors) {
    entries.add(BossCatalogEntry(
      bossKey: towerBossKey(floor),
      source: BossMemorySource.tower,
      groupIndex: floor,
    ));
  }

  return entries;
}

/// 当前存档所有 Boss 战绩纪念列表（Isar 主键顺序）。
///
/// 分组 / 排序 / join catalog 留 T8 主屏 provider 完成，本 provider 只出原料。
/// BossMemory 含 isPreRecord=true 的骨架纪念（老档回填），也纳入列表。
@Riverpod(dependencies: [])
Future<List<BossMemory>> bossMemoryList(Ref ref) async {
  final isar = IsarSetup.instance;
  final svc = BossMemoryService(isar: isar);
  return svc.allMemories(IsarSetup.currentSlotId);
}

/// 当前存档已记录的 Boss 击败数（含骨架）。
///
/// 用途：主菜单入口门控谓词——count > 0 时显示「战绩册」入口。
/// 骨架纪念（isPreRecord=true）也算，确保老档回填后能第一时间解锁入口。
///
/// 直接调用 BossMemoryService 而非 watch bossMemoryListProvider，
/// 避免跨 `dependencies: []` 孤立 provider 的依赖声明问题。
@Riverpod(dependencies: [])
Future<int> bossMemoryCount(Ref ref) async {
  final isar = IsarSetup.instance;
  final svc = BossMemoryService(isar: isar);
  final list = await svc.allMemories(IsarSetup.currentSlotId);
  return list.length;
}
