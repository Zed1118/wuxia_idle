import 'boss_memory_source.dart';

/// 战绩册「应有」的一个 Boss 槽（不含 bossName——锁定态不剧透）。
///
/// catalog = 全 Boss 应有槽，与 BossMemory（已击败纪念）做 join：
///   - 有对应 Memory → 显击败纪念卡。
///   - 无对应 Memory → 显「未会之敌」占位卡。
///
/// groupIndex 含义：
///   - mainline：同 mainlineGroupIndex(stageId)（Ch1-6 → 1-6 / 心魔→7 / 轻功→8 / 群战→9）。
///   - tower：层号（5 / 10 / 15 / 20 / 25 / 30）。
class BossCatalogEntry {
  final String bossKey;
  final BossMemorySource source;
  final int groupIndex;

  const BossCatalogEntry({
    required this.bossKey,
    required this.source,
    required this.groupIndex,
  });
}
