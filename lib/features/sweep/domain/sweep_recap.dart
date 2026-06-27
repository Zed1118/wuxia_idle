import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';

/// 扫荡逐关战果的单关贡献（settle 一关后由结算 service 映射产出）。
class SweepBattleOutcome {
  /// 本关掉落装备件数。
  final int equipmentDrops;

  /// 本关物品掉落（defId → 数量，含银两 `item_silver`）。
  final Map<String, int> itemsByDefId;

  /// 本关累计经验（全员）。
  final int expGained;

  /// 本关角色升层（修炼度/境界）次数。
  final int realmAdvances;

  /// 本关掉落技能残页次数（爬塔重打仅此项，守防刷红线）。
  final int skillFragments;

  /// 本关因重复、已满或规则门控未入账的收益条数。
  final int ignoredDrops;

  const SweepBattleOutcome({
    this.equipmentDrops = 0,
    this.itemsByDefId = const {},
    this.expGained = 0,
    this.realmAdvances = 0,
    this.skillFragments = 0,
    this.ignoredDrops = 0,
  });
}

enum SweepResultLayerKind { rare, equipment, material, resource, ineffective }

class SweepResultLine {
  final String text;
  final bool highlighted;

  const SweepResultLine(this.text, {this.highlighted = false});
}

class SweepResultLayer {
  final SweepResultLayerKind kind;
  final String title;
  final List<SweepResultLine> lines;
  final bool highlighted;

  const SweepResultLayer({
    required this.kind,
    required this.title,
    required this.lines,
    this.highlighted = false,
  });
}

/// 扫荡战果总账（不可变，逐关 [accumulate] 折叠）。
///
/// 收尾 recap dialog 读此显「总掉落/银两/经验/升层」（数字跳动体例复用桃花岛纪事）。
class SweepRecap {
  /// 成功扫过的关数。
  final int stagesCleared;

  /// 累计掉落装备件数。
  final int equipmentDrops;

  /// 累计物品（defId → 数量，同 defId 跨关合并）。
  final Map<String, int> itemsByDefId;

  /// 累计经验。
  final int expGained;

  /// 累计升层次数。
  final int realmAdvances;

  /// 累计技能残页数。
  final int skillFragments;

  /// 累计因重复、已满或规则门控未入账的收益条数。
  final int ignoredDrops;

  const SweepRecap({
    required this.stagesCleared,
    required this.equipmentDrops,
    required this.itemsByDefId,
    required this.expGained,
    required this.realmAdvances,
    required this.skillFragments,
    required this.ignoredDrops,
  });

  const SweepRecap.empty()
    : stagesCleared = 0,
      equipmentDrops = 0,
      itemsByDefId = const {},
      expGained = 0,
      realmAdvances = 0,
      skillFragments = 0,
      ignoredDrops = 0;

  /// 折入一关战果，返回新实例（原账不变）。
  SweepRecap accumulate(SweepBattleOutcome o) {
    final merged = Map<String, int>.of(itemsByDefId);
    o.itemsByDefId.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
    return SweepRecap(
      stagesCleared: stagesCleared + 1,
      equipmentDrops: equipmentDrops + o.equipmentDrops,
      itemsByDefId: merged,
      expGained: expGained + o.expGained,
      realmAdvances: realmAdvances + o.realmAdvances,
      skillFragments: skillFragments + o.skillFragments,
      ignoredDrops: ignoredDrops + o.ignoredDrops,
    );
  }

  List<SweepResultLayer> resultLayers() {
    final layers = <SweepResultLayer>[];
    final rareLines = <SweepResultLine>[
      if (skillFragments > 0)
        SweepResultLine(
          UiStrings.sweepRecapFragments(skillFragments),
          highlighted: true,
        ),
      if ((itemsByDefId['item_jingyandan_large'] ?? 0) > 0)
        SweepResultLine(
          UiStrings.sweepRecapLargePills(
            itemsByDefId['item_jingyandan_large']!,
          ),
          highlighted: true,
        ),
    ];
    if (rareLines.isNotEmpty) {
      layers.add(
        SweepResultLayer(
          kind: SweepResultLayerKind.rare,
          title: UiStrings.sweepLayerRare,
          lines: rareLines,
          highlighted: true,
        ),
      );
    }

    if (equipmentDrops > 0) {
      layers.add(
        SweepResultLayer(
          kind: SweepResultLayerKind.equipment,
          title: UiStrings.sweepLayerEquipment,
          lines: [
            SweepResultLine(UiStrings.sweepRecapEquipment(equipmentDrops)),
          ],
        ),
      );
    }

    final materialCount = itemsByDefId.entries
        .where((e) => _isMaterial(ItemType.fromDefId(e.key)))
        .fold<int>(0, (s, e) => s + e.value);
    if (materialCount > 0) {
      layers.add(
        SweepResultLayer(
          kind: SweepResultLayerKind.material,
          title: UiStrings.sweepLayerMaterials,
          lines: [
            SweepResultLine(UiStrings.sweepRecapMaterials(materialCount)),
          ],
        ),
      );
    }

    final resourceLines = <SweepResultLine>[
      if ((itemsByDefId['item_silver'] ?? 0) > 0)
        SweepResultLine(
          UiStrings.sweepRecapSilver(itemsByDefId['item_silver']!),
        ),
      if (expGained > 0) SweepResultLine(UiStrings.sweepRecapExp(expGained)),
      if (realmAdvances > 0)
        SweepResultLine(UiStrings.sweepRecapAdvances(realmAdvances)),
      if (_smallAndMidPills > 0)
        SweepResultLine(UiStrings.sweepRecapPills(_smallAndMidPills)),
    ];
    if (resourceLines.isNotEmpty) {
      layers.add(
        SweepResultLayer(
          kind: SweepResultLayerKind.resource,
          title: UiStrings.sweepLayerResources,
          lines: resourceLines,
        ),
      );
    }

    if (ignoredDrops > 0 || layers.isEmpty) {
      layers.add(
        SweepResultLayer(
          kind: SweepResultLayerKind.ineffective,
          title: UiStrings.sweepLayerIneffective,
          lines: [
            SweepResultLine(
              ignoredDrops > 0
                  ? UiStrings.sweepRecapIgnored(ignoredDrops)
                  : UiStrings.sweepRecapNoGains,
            ),
          ],
        ),
      );
    }

    return layers;
  }

  int get _smallAndMidPills =>
      (itemsByDefId['item_jingyandan_small'] ?? 0) +
      (itemsByDefId['item_jingyandan_mid'] ?? 0);
}

bool _isMaterial(ItemType type) =>
    type == ItemType.moJianShi ||
    type == ItemType.xinXueJieJing ||
    type == ItemType.miscMaterial;
