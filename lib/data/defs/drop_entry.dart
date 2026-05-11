/// 关卡掉落条目（phase2_tasks T27 · spec §362-386）。
///
/// `StageDef.dropTable` 由若干 [DropEntry] 组成；每条独立 roll，互不影响。
/// 装备掉落与物品掉落两类，用 sealed class 分支：
///
///   - [EquipmentDrop]：roll 命中后由 `DropService` 调 `EquipmentFactory.fromDef`
///     生成具体 [Equipment] 实例
///   - [ItemDrop]：roll 命中后返回 `(defId, quantity)`，
///     `quantity` 为 `[min, max]` 闭区间随机整数
///
/// yaml 形态（同一 list 里二者并存，按 key 判别）：
/// ```yaml
/// dropTable:
///   - equipmentDefId: weapon_xunchang_tie_jian
///     dropChance: 0.30
///   - inventoryItemDefId: item_mojianshi
///     quantity: [1, 3]
///     dropChance: 1.0
/// ```
sealed class DropEntry {
  /// `[0.0, 1.0]` 闭区间。`1.0` 必掉，`0.0` 必不掉。
  final double dropChance;

  const DropEntry({required this.dropChance});

  /// 工厂分发：根据是否含 `equipmentDefId` / `inventoryItemDefId` 决定子类。
  /// 两者必须恰有一个；同时缺或同时有都 fail-fast。
  factory DropEntry.fromYaml(Map<String, dynamic> y) {
    final hasEq = y.containsKey('equipmentDefId');
    final hasItem = y.containsKey('inventoryItemDefId');
    if (hasEq == hasItem) {
      throw FormatException(
        'DropEntry 必须恰好含 equipmentDefId 或 inventoryItemDefId 之一，'
        '实际 keys=${y.keys.toList()}',
      );
    }
    final chance = (y['dropChance'] as num).toDouble();
    if (chance < 0.0 || chance > 1.0) {
      throw FormatException(
        'DropEntry.dropChance 必须 ∈ [0.0, 1.0]，实际 $chance',
      );
    }
    if (hasEq) {
      return EquipmentDrop(
        equipmentDefId: y['equipmentDefId'] as String,
        dropChance: chance,
      );
    }
    final q = y['quantity'];
    final (qMin, qMax) = _parseQuantity(q);
    return ItemDrop(
      inventoryItemDefId: y['inventoryItemDefId'] as String,
      quantityMin: qMin,
      quantityMax: qMax,
      dropChance: chance,
    );
  }

  /// `quantity` 支持三种写法：
  ///   - 缺省 / null → `[1, 1]`
  ///   - 单个数字 `5` → `[5, 5]`
  ///   - 两元素列表 `[1, 3]` → `[1, 3]`
  static (int, int) _parseQuantity(dynamic q) {
    if (q == null) return (1, 1);
    if (q is num) {
      final v = q.toInt();
      return (v, v);
    }
    if (q is List && q.length == 2) {
      final lo = (q[0] as num).toInt();
      final hi = (q[1] as num).toInt();
      if (lo > hi) {
        throw FormatException('DropEntry.quantity 范围非法：[$lo, $hi]');
      }
      if (lo < 1) {
        throw FormatException('DropEntry.quantity 下限必须 ≥ 1，实际 $lo');
      }
      return (lo, hi);
    }
    throw FormatException(
      'DropEntry.quantity 必须是 int 或 [min, max] 二元 list，实际 $q',
    );
  }
}

class EquipmentDrop extends DropEntry {
  final String equipmentDefId;

  const EquipmentDrop({
    required this.equipmentDefId,
    required super.dropChance,
  });

  @override
  String toString() =>
      'EquipmentDrop($equipmentDefId, ${(dropChance * 100).toStringAsFixed(0)}%)';
}

class ItemDrop extends DropEntry {
  final String inventoryItemDefId;
  final int quantityMin;
  final int quantityMax;

  const ItemDrop({
    required this.inventoryItemDefId,
    required this.quantityMin,
    required this.quantityMax,
    required super.dropChance,
  });

  @override
  String toString() =>
      'ItemDrop($inventoryItemDefId, x[$quantityMin-$quantityMax], '
      '${(dropChance * 100).toStringAsFixed(0)}%)';
}
