import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/item_source.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../taohua_island/domain/island_building_type.dart';
import '../application/item_usage_lookup_service.dart';
import '../application/material_source_lookup_service.dart';

/// 材料来源反查 bottom sheet（材料来源反查一期 · 夜间批 L）。
///
/// 纯表现层：读 [MaterialSourceLookupService] / [ItemUsageLookupService]
/// 派生结果按 [ItemSourceKind] 分组逐条列出，**不显示掉率数字**、不加导航跳转。
/// 头部：材料名 + 图标 + 当前持有量（[quantity] 未传时 watch
/// [inventoryQuantityByDefIdProvider]，Isar 未初始化的轻量测试下静默隐藏，
/// 防御式兜底不 crash）。空来源/空用途各给一行占位文案。
class MaterialSourceSheet extends ConsumerWidget {
  const MaterialSourceSheet({super.key, required this.itemId, this.quantity});

  final String itemId;

  /// 当前持有量；调用方手头已有时直传，null 则 watch provider 查询。
  final int? quantity;

  /// 统一弹出入口（纸质底体例，沿项目 showModalBottomSheet 惯例）。
  static Future<void> show(
    BuildContext context, {
    required String itemId,
    int? quantity,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: WuxiaUi.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WuxiaUi.radius)),
        side: BorderSide(color: WuxiaUi.ink, width: WuxiaUi.borderWidth),
      ),
      builder: (_) => MaterialSourceSheet(itemId: itemId, quantity: quantity),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = GameRepository.instanceOrNull;
    final displayName =
        repo?.itemDefs[itemId]?.name ?? EnumL10n.itemType(ItemType.fromDefId(itemId));
    final owned = quantity ??
        ref.watch(inventoryQuantityByDefIdProvider(itemId)).asData?.value;

    final sources = repo == null
        ? const <ItemSource>[]
        : MaterialSourceLookupService(repo).sourcesFor(itemId);
    final usages = repo == null
        ? const <String>[]
        : {
            for (final u in ItemUsageLookupService(repo).usagesFor(itemId))
              UiStrings.itemUsageLabel(u),
          }.toList();

    // 按 kind 分组（保 enum 声明顺序），组内逐条一行。
    final grouped = <ItemSourceKind, List<ItemSource>>{};
    for (final s in sources) {
      grouped.putIfAbsent(s.kind, () => []).add(s);
    }
    final sourceLines = <String>[
      for (final kind in ItemSourceKind.values)
        for (final s in grouped[kind] ?? const <ItemSource>[])
          UiStrings.materialSourceLine(
            UiStrings.itemSourceLabel(s),
            _detailFor(s, repo),
          ),
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: _Header(
                itemId: itemId,
                displayName: displayName,
                owned: owned,
              ),
            ),
            const Divider(height: 1, color: WuxiaUi.ink),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  const _SectionTitle(UiStrings.materialSourceSheetSourcesTitle),
                  if (sourceLines.isEmpty)
                    const _EntryLine(
                      UiStrings.materialSourceSheetEmptySources,
                      muted: true,
                    )
                  else
                    for (final line in sourceLines) _EntryLine(line),
                  const SizedBox(height: 12),
                  const _SectionTitle(UiStrings.materialSourceSheetUsagesTitle),
                  if (usages.isEmpty)
                    const _EntryLine(
                      UiStrings.materialSourceSheetEmptyUsages,
                      muted: true,
                    )
                  else
                    for (final line in usages) _EntryLine(line),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单条来源的明细段（关卡名/塔层/闭关图名/建筑名）；集中中文全在 UiStrings。
  static String? _detailFor(ItemSource s, GameRepository? repo) {
    final base = switch (s.kind) {
      ItemSourceKind.mainline => UiStrings.materialSourceMainlineDetail(
        s.chapterIndex ?? 0,
        s.name ?? '',
      ),
      ItemSourceKind.stage || ItemSourceKind.seclusion => s.name,
      ItemSourceKind.tower => UiStrings.materialSourceTowerDetail(
        s.floorIndex ?? 0,
      ),
      ItemSourceKind.shop ||
      ItemSourceKind.equipmentDisassembly ||
      ItemSourceKind.enhancementFailure => null,
      ItemSourceKind.islandSource => _buildingLabel(s.name),
      ItemSourceKind.islandRecipe => _recipeBuildingLabel(s.sourceId, repo),
    };
    final withBoss = s.isBoss && base != null
        ? '$base${UiStrings.materialSourceBossSuffix}'
        : base;
    return withBoss;
  }

  /// islandSource 的 name 是 [BuildingType].name（enum 英文名），转显示名。
  static String? _buildingLabel(String? enumName) {
    if (enumName == null) return null;
    final type = BuildingType.values.asNameMap()[enumName];
    return type == null ? enumName : EnumL10n.buildingType(type);
  }

  /// islandRecipe 反查所属加工建筑显示名。
  static String? _recipeBuildingLabel(String? recipeId, GameRepository? repo) {
    if (recipeId == null || repo == null) return null;
    for (final entry in repo.numbers.taohuaIsland.buildings.entries) {
      if (entry.value.recipes.any((r) => r.recipeId == recipeId)) {
        return EnumL10n.buildingType(entry.key);
      }
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.itemId,
    required this.displayName,
    required this.owned,
  });

  final String itemId;
  final String displayName;
  final int? owned;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: WuxiaImage(
            'assets/images/items/$itemId.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: wuxiaAssetErrorBuilder(
              () => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: WuxiaUi.slotFill,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: WuxiaUi.ink.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: WuxiaUi.muted,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (owned != null) ...[
                const SizedBox(height: 3),
                Text(
                  UiStrings.materialSourceSheetOwned(owned!),
                  style: const TextStyle(color: WuxiaUi.muted, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: WuxiaUi.jiang,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryLine extends StatelessWidget {
  const _EntryLine(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          color: muted ? WuxiaUi.muted : WuxiaUi.ink2,
          fontSize: 13.5,
          height: 1.4,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
