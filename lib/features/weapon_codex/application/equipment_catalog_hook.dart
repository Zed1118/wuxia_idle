import 'package:flutter/foundation.dart';

import '../../../data/isar_setup.dart';
import 'equipment_catalog_service.dart';

/// 获得装备后留册(best-effort,失败不打断获得主流程)。
/// [defIds] 本次获得的装备 def id 列表;[from] 来源展示名(关卡/塔层/奇遇)。
Future<void> runEquipmentCatalogHookAfterObtain({
  required List<String> defIds,
  required String from,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null || defIds.isEmpty) return;
  try {
    await EquipmentCatalogService(isar: isar).recordAcquisitions(
      saveDataId: IsarSetup.currentSlotId,
      defIds: defIds,
      from: from,
      now: DateTime.now(),
    );
  } catch (e, s) {
    debugPrint('runEquipmentCatalogHookAfterObtain 留册失败(降级): $e\n$s');
  }
}
