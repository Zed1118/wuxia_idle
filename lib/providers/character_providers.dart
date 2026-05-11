import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/isar_setup.dart';
import '../data/models/character.dart';
import '../data/models/equipment.dart';
import '../data/models/technique.dart';

part 'character_providers.g.dart';

/// 角色 family（phase2_tasks.md T28 §399）。
///
/// 异步读 [IsarSetup.instance]；测试中以
/// `characterByIdProvider(id).overrideWith((ref) async => fixture)` 注入，
/// 不打开真实 Isar。返回 null 表示未找到，由 UI 兜底（"角色不存在"）。
@riverpod
Future<Character?> characterById(CharacterByIdRef ref, int id) async {
  return IsarSetup.instance.characters.get(id);
}

/// 装备 family（phase2_tasks.md T28 §399）。
///
/// `Character.equippedWeaponId / equippedArmorId / equippedAccessoryId`
/// 可空，UI 调用方需先判空再 watch。
@riverpod
Future<Equipment?> equipmentById(EquipmentByIdRef ref, int id) async {
  return IsarSetup.instance.equipments.get(id);
}

/// 心法 family（phase2_tasks.md T28 §399）。
///
/// 用于查 `Character.mainTechniqueId` 与 `assistTechniqueIds`。
@riverpod
Future<Technique?> techniqueById(TechniqueByIdRef ref, int id) async {
  return IsarSetup.instance.techniques.get(id);
}
