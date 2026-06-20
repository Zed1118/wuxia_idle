import 'package:isar_community/isar.dart';

import '../../../core/domain/equipment.dart';
import '../../../shared/strings.dart';
import '../domain/equipment_catalog_entry.dart';

/// 兵器谱图鉴留册 service（幂等写入 + 库存兜底回填）。
///
/// - [recordAcquisitions]：首得建档，重得仅 count++（首得快照冻结）。
/// - [reconcileFromInventory]：扫当前库存为未入册 def 兜底回填（preRecord），
///   已入册档不降级。
/// - [entryFor] / [allEntries]：查询。
class EquipmentCatalogService {
  EquipmentCatalogService({required this.isar});

  final Isar isar;

  /// 回填档来源字面量（引用 UiStrings.weaponCodexBackfillSource）。
  static const backfillSource = UiStrings.weaponCodexBackfillSource;

  Future<EquipmentCatalogEntry?> entryFor(int saveDataId, String defId) => isar
      .equipmentCatalogEntrys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .defIdEqualTo(defId)
      .findFirst();

  /// 记录获得（幂等）：首得建档，重得仅 count++（不覆盖首得快照）。
  Future<void> recordAcquisitions({
    required int saveDataId,
    required List<String> defIds,
    required String from,
    required DateTime now,
  }) async {
    if (defIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final defId in defIds) {
        final existing = await entryFor(saveDataId, defId);
        if (existing != null) {
          existing.obtainedCount += 1;
          await isar.equipmentCatalogEntrys.put(existing);
          continue;
        }
        final e = EquipmentCatalogEntry()
          ..saveDataId = saveDataId
          ..defId = defId
          ..firstObtainedAt = now
          ..firstObtainedFrom = from
          ..obtainedCount = 1
          ..isPreRecord = false;
        await isar.equipmentCatalogEntrys.put(e);
      }
    });
  }

  /// 扫当前库存兜底回填：未入册的 owned defId → preRecord（来历不详）；
  /// 已入册的跳过（不降级已有真档）。
  Future<void> reconcileFromInventory(int saveDataId) async {
    final owned = await isar.equipments.where().findAll();
    final ownedDefIds = owned.map((e) => e.defId).toSet();
    if (ownedDefIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final defId in ownedDefIds) {
        if (await entryFor(saveDataId, defId) != null) continue;
        final e = EquipmentCatalogEntry()
          ..saveDataId = saveDataId
          ..defId = defId
          ..firstObtainedAt = null
          ..firstObtainedFrom = backfillSource
          ..obtainedCount = 1
          ..isPreRecord = true;
        await isar.equipmentCatalogEntrys.put(e);
      }
    });
  }

  Future<List<EquipmentCatalogEntry>> allEntries(int saveDataId) => isar
      .equipmentCatalogEntrys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .findAll();
}
