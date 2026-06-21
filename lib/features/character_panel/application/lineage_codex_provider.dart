import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_provider.dart';
import '../../recruitment/application/recruitment_providers.dart';

part 'lineage_codex_provider.g.dart';

/// 门派谱·一代传承（祖师 + 该代门人 + 该代师承遗物）。纯派生视图模型。
class LineageGeneration {
  const LineageGeneration({
    required this.founder,
    required this.disciples,
    required this.heritageEquipments,
    required this.isCurrent,
  });

  final Character founder;
  final List<Character> disciples;
  final List<Equipment> heritageEquipments;

  /// 当代标识：founder.id == SaveData.founderCharacterId。
  final bool isCurrent;
}

/// 分代纯函数（可单测，不碰 isar）。
///
/// - 代锚点 = `isFounder==true` 的角色，按 `id` 升序（太祖在前）。
/// - 每代弟子 = `masterId == founder.id` 的非 founder 角色；
///   **当代额外并入 active 非 founder ∪ recruited**（沿现有 lineageInfoProvider
///   信任源，保当代零回归，即便生产 masterId 未填也不漏）。去重按 id。
/// - 遗物按 `ownerCharacterId` 归对应代；null owner（背包）归当代；
///   owner 不属任何角色记录的孤儿遗物也归当代（兜底不漏）。
List<LineageGeneration> groupGenerations({
  required List<Character> characters,
  required List<Equipment> heritage,
  required int? currentFounderId,
  required List<int> activeIds,
  required List<int> recruitedIds,
}) {
  final founders = characters.where((c) => c.isFounder).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (founders.isEmpty) return const [];

  final byId = {for (final c in characters) c.id: c};
  final allCharIds = byId.keys.toSet();
  final activeSet = activeIds.toSet();

  final gens = <LineageGeneration>[];
  for (final f in founders) {
    final isCurrent = currentFounderId != null && f.id == currentFounderId;

    final ids = <int>{
      for (final c in characters)
        if (!c.isFounder && c.masterId == f.id) c.id,
    };
    if (isCurrent) {
      for (final id in activeSet) {
        final c = byId[id];
        if (c != null && !c.isFounder) ids.add(id);
      }
      for (final id in recruitedIds) {
        final c = byId[id];
        if (c != null && !c.isFounder) ids.add(id);
      }
    }
    final disciples = ids.map((id) => byId[id]).whereType<Character>().toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final genCharIds = {f.id, ...disciples.map((c) => c.id)};
    final relics = heritage.where((e) {
      final owner = e.ownerCharacterId;
      if (owner == null) return isCurrent; // 背包遗物归当代
      if (genCharIds.contains(owner)) return true;
      // owner 不属任何角色记录(孤儿) → 归当代兜底
      if (!allCharIds.contains(owner)) return isCurrent;
      return false;
    }).toList();

    gens.add(LineageGeneration(
      founder: f,
      disciples: disciples,
      heritageEquipments: relics,
      isCurrent: isCurrent,
    ));
  }
  return gens;
}

/// 门派谱世代卷派生 provider。拉全部 Character（含历代退隐祖师）+ 全部师承遗物，
/// 调 [groupGenerations] 分代。上游 invalidate 自动刷新。
@riverpod
Future<List<LineageGeneration>> lineageCodex(Ref ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  final characters = await isar.characters.where().findAll();
  final allEquipments = await ref.watch(allEquipmentsProvider.future);
  final heritage =
      allEquipments.where((e) => e.isLineageHeritage).toList(growable: false);
  final activeIds = await ref.watch(activeCharacterIdsProvider.future);
  final recruitedIds = await ref.watch(recruitedDiscipleIdsProvider.future);
  final save = await isar.saveDatas.get(0);
  return groupGenerations(
    characters: characters,
    heritage: heritage,
    currentFounderId: save?.founderCharacterId,
    activeIds: activeIds,
    recruitedIds: recruitedIds,
  );
}
