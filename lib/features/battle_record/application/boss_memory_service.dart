import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart';
import '../domain/boss_memory.dart';
import '../domain/boss_memory_source.dart';

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
}
