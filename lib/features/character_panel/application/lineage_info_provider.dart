import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';

part 'lineage_info_provider.g.dart';

/// 师徒名单视图模型（W17 候选 E）。
///
/// 纯派生 view model，组合 `charactersProvider`（实际由 [activeCharacterIdsProvider]
/// + [characterByIdProvider] 派生）+ [allEquipmentsProvider]。无 schema bump，
/// 无 Isar 写入。预研：`docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md`。
class LineageInfo {
  const LineageInfo({
    required this.founder,
    required this.disciples,
    required this.heritageEquipments,
  });

  /// 祖师角色（`isFounder == true` 的 active 角色）。Demo 阶段固定 1 个，
  /// 若 active 集合中无 founder（异常存档）返回 null，UI 兜底空态。
  final Character? founder;

  /// 弟子列表（`lineageRole == LineageRole.disciple` 的 active 角色），
  /// 按 [activeCharacterIdsProvider] 原顺序保留（大弟子 / 二弟子）。
  final List<Character> disciples;

  /// 师承遗物列表（全仓 Equipment 中 `isLineageHeritage == true`），
  /// 复用 [allEquipmentsProvider] 已排序（tier desc + enhanceLevel desc）。
  /// 不区分 equipped vs 背包——师承遗物作为一个集合呈现。
  final List<Equipment> heritageEquipments;
}

/// 师徒名单派生 provider（W17 候选 E）。
///
/// 通过 [activeCharacterIdsProvider] 拿出战角色 id 列表，逐个 watch
/// [characterByIdProvider] 派生 founder / disciples 分组；再 watch
/// [allEquipmentsProvider] 过滤 `isLineageHeritage` 拿师承遗物集合。
///
/// 任一上游 invalidate（如 stage 结束后 ref.invalidate(allEquipmentsProvider)）
/// 都会触发本 provider 重算，UI 自动刷新。
@riverpod
Future<LineageInfo> lineageInfo(Ref ref) async {
  final ids = await ref.watch(activeCharacterIdsProvider.future);
  final characters = <Character>[];
  for (final id in ids) {
    final c = await ref.watch(characterByIdProvider(id).future);
    if (c != null) characters.add(c);
  }
  Character? founder;
  final disciples = <Character>[];
  for (final c in characters) {
    if (c.isFounder && founder == null) {
      founder = c;
    } else {
      disciples.add(c);
    }
  }
  final allEquipments = await ref.watch(allEquipmentsProvider.future);
  final heritage =
      allEquipments.where((e) => e.isLineageHeritage).toList(growable: false);
  return LineageInfo(
    founder: founder,
    disciples: disciples,
    heritageEquipments: heritage,
  );
}
