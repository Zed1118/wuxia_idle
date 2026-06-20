import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/isar_setup.dart';
import '../domain/equipment_catalog_entry.dart';
import 'equipment_catalog_service.dart';

part 'equipment_catalog_providers.g.dart';

/// 当前存档全部图鉴条目。
@Riverpod(dependencies: [])
Future<List<EquipmentCatalogEntry>> equipmentCatalogList(Ref ref) async {
  final isar = IsarSetup.instance;
  return EquipmentCatalogService(isar: isar).allEntries(IsarSetup.currentSlotId);
}

/// 已录条目数（主菜单解锁门控：>0 显入口）。
@Riverpod(dependencies: [])
Future<int> equipmentCatalogCount(Ref ref) async {
  final isar = IsarSetup.instance;
  final list = await EquipmentCatalogService(isar: isar).allEntries(IsarSetup.currentSlotId);
  return list.length;
}
