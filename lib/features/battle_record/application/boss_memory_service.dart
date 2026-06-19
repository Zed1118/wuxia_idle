import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../domain/boss_memory.dart';
import '../domain/boss_memory_key.dart';
import '../domain/boss_memory_source.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../tower/domain/tower_progress.dart';

/// Boss 战绩写入服务。
///
/// 语义：
/// - 首胜 → 建一条完整纪念（isPreRecord=false，defeatCount=1，所有快照字段写入）。
/// - 重打同 bossKey → 仅 defeatCount++，首胜快照冻结不覆盖。
/// - 幂等：同 saveDataId+bossKey 永远最多一行。
class BossMemoryService {
  BossMemoryService({required this.isar});

  final Isar isar;

  Future<BossMemory?> _find(int saveDataId, String bossKey) => isar.bossMemorys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .bossKeyEqualTo(bossKey)
      .findFirst();

  /// 首胜建完整纪念；已存在同 bossKey → 仅 defeatCount++（幂等不覆盖快照）。
  ///
  /// treasure/topContributor 由调用方算好传入，service 不碰选取逻辑。
  Future<void> recordBossVictory({
    required int saveDataId,
    required String bossKey,
    required BossMemorySource source,
    required int groupIndex,
    required String bossName,
    required int totalDamage,
    required int critCount,
    required int totalTicks,
    String? topContributorName,
    int? topContributorDamage,
    String? treasureName,
    EquipmentTier? treasureTier,
    required List<String> rosterNames,
    required List<String> rosterPortraits,
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      final existing = await _find(saveDataId, bossKey);
      if (existing != null) {
        existing.defeatCount += 1;
        await isar.bossMemorys.put(existing);
        return;
      }
      final m = BossMemory()
        ..saveDataId = saveDataId
        ..bossKey = bossKey
        ..source = source
        ..groupIndex = groupIndex
        ..bossName = bossName
        ..firstClearedAt = now
        ..isPreRecord = false
        ..totalDamage = totalDamage
        ..critCount = critCount
        ..totalTicks = totalTicks
        ..topContributorName = topContributorName
        ..topContributorDamage = topContributorDamage
        ..treasureName = treasureName
        ..treasureTier = treasureTier
        ..rosterNames = rosterNames
        ..rosterPortraits = rosterPortraits
        ..defeatCount = 1;
      await isar.bossMemorys.put(m);
    });
  }

  /// 查当前存档所有战绩纪念，按 groupIndex 升序。
  Future<List<BossMemory>> allMemories(int saveDataId) => isar.bossMemorys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .findAll();

  /// 老档回填：已击败 Boss → isPreRecord 骨架（战绩字段空）。
  ///
  /// 幂等：已存在同 bossKey 的纪念（不论 isPreRecord true/false）直接跳过，
  /// 不重建、不覆盖。
  ///
  /// 来源：
  ///   1. MainlineProgress.clearedStageIds — 仅筛 isBossStage=true 的关卡。
  ///   2. TowerProgress.highestClearedFloor — Boss 层 {5,10,15,20,25,30} 中
  ///      ≤ highestClearedFloor 的层数。
  ///
  /// 塔回填的 firstClearedAt 为 null（无精确时间）。
  /// 全部条目在一个 writeTxn 内批量 put。
  Future<void> backfillFromProgress(int saveDataId) async {
    final repo = GameRepository.instance;

    // --- 收集待写入条目 ---
    final toWrite = <BossMemory>[];

    // --- 主线 ---
    final mpRow = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (mpRow != null) {
      final ids = mpRow.clearedStageIds;
      final dates = mpRow.clearedAt;
      for (var i = 0; i < ids.length; i++) {
        final stageId = ids[i];
        final def = repo.stageDefs[stageId];
        if (def == null || !def.isBossStage) continue;
        final key = mainlineBossKey(stageId);
        // 幂等：已存在则跳过
        final existing = await _find(saveDataId, key);
        if (existing != null) continue;
        final bossName = def.enemyTeam.isNotEmpty ? def.enemyTeam.last.name : '';
        final m = BossMemory()
          ..saveDataId = saveDataId
          ..bossKey = key
          ..source = BossMemorySource.mainline
          ..groupIndex = mainlineGroupIndex(stageId)
          ..bossName = bossName
          ..firstClearedAt = i < dates.length ? dates[i] : null
          ..isPreRecord = true
          ..rosterNames = const []
          ..rosterPortraits = const []
          ..defeatCount = 1;
        toWrite.add(m);
      }
    }

    // --- 爬塔 ---
    const bossFloors = [5, 10, 15, 20, 25, 30];
    final tpRow = await isar.towerProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (tpRow != null) {
      final highest = tpRow.highestClearedFloor;
      for (final floor in bossFloors) {
        if (floor > highest) break; // bossFloors 已升序，提前 break
        final key = towerBossKey(floor);
        // 幂等：已存在则跳过
        final existing = await _find(saveDataId, key);
        if (existing != null) continue;
        // 取塔层敌人名（从 towerFloors 按 floorIndex 找，floor 从 1 起）
        final floorDef = floor <= repo.towerFloors.length
            ? repo.towerFloors[floor - 1]
            : null;
        final bossName = floorDef != null && floorDef.enemyTeam.isNotEmpty
            ? floorDef.enemyTeam.last.name
            : '';
        final m = BossMemory()
          ..saveDataId = saveDataId
          ..bossKey = key
          ..source = BossMemorySource.tower
          ..groupIndex = floor
          ..bossName = bossName
          ..firstClearedAt = null
          ..isPreRecord = true
          ..rosterNames = const []
          ..rosterPortraits = const []
          ..defeatCount = 1;
        toWrite.add(m);
      }
    }

    if (toWrite.isEmpty) return;

    // 批量写入（一个 writeTxn，不嵌套）
    await isar.writeTxn(() async {
      for (final m in toWrite) {
        await isar.bossMemorys.put(m);
      }
    });
  }
}
