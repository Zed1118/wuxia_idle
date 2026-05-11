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

/// 角色已学全部心法（phase2_tasks.md T31 §472）。
///
/// 顺序：mainTechniqueId（若有）→ assistTechniqueIds 原序。复用
/// [techniqueByIdProvider] 单条 family，测试中可以 override 单条心法即生效。
/// 任一 id 在 Isar 缺失（返回 null）会被丢掉，不抛错——和角色面板兜底一致。
@riverpod
Future<List<Technique>> characterAllTechniques(
  CharacterAllTechniquesRef ref,
  int characterId,
) async {
  final ch = await ref.watch(characterByIdProvider(characterId).future);
  if (ch == null) return [];
  final ids = <int>[
    if (ch.mainTechniqueId != null) ch.mainTechniqueId!,
    ...ch.assistTechniqueIds,
  ];
  final techs = <Technique>[];
  for (final id in ids) {
    final t = await ref.watch(techniqueByIdProvider(id).future);
    if (t != null) techs.add(t);
  }
  return techs;
}
