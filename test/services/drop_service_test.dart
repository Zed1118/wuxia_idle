import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/services/drop_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T27 DropService 验收（phase2_tasks T27 §356-386）。
void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // 测试 fixture
  // ──────────────────────────────────────────────────────────────────────────

  EquipmentDef weaponDef() => const EquipmentDef(
        id: 'test_weapon_tie_jian',
        name: '铁剑',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        baseAttackMin: 100,
        baseAttackMax: 150,
        baseHealthMin: 0,
        baseHealthMax: 0,
        baseSpeedMin: 5,
        baseSpeedMax: 10,
        presetLoreIds: [],
        dropSourceTags: [],
        iconPath: '',
      );

  EquipmentDef armorDef() => const EquipmentDef(
        id: 'test_armor_bu_yi',
        name: '布衣',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.armor,
        baseAttackMin: 0,
        baseAttackMax: 0,
        baseHealthMin: 200,
        baseHealthMax: 300,
        baseSpeedMin: 0,
        baseSpeedMax: 5,
        presetLoreIds: [],
        dropSourceTags: [],
        iconPath: '',
      );

  StageDef stageWith(List<DropEntry> table) => StageDef(
        id: 'test_stage',
        name: '测试关',
        stageType: StageType.mainline,
        chapterIndex: 1,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: false,
        dropEquipmentDefIds: const [],
        dropItemDefIds: const [],
        dropTable: table,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );

  EquipmentDef lookup(String id) => switch (id) {
        'test_weapon_tie_jian' => weaponDef(),
        'test_armor_bu_yi' => armorDef(),
        _ => throw StateError('未配置 def: $id'),
      };

  final fixedTime = DateTime(2026, 5, 11);
  DropService service() => DropService(
        equipmentDefLookup: lookup,
        now: () => fixedTime,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // 1. dropTable 空 → 空 DropResult，不消耗 rng
  // ──────────────────────────────────────────────────────────────────────────

  test('dropTable 为空 → 返回 isEmpty 的 DropResult，不调用 rng', () {
    var nextDoubleCalls = 0;
    final rng = _MockRng(
      doubles: const [],
      onNextDouble: () => nextDoubleCalls++,
    );
    final result = service().rollDrops(stageWith(const []), rng);
    expect(result.isEmpty, isTrue);
    expect(result.equipments, isEmpty);
    expect(result.items, isEmpty);
    expect(nextDoubleCalls, 0);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. dropChance = 0 → 必不掉
  // ──────────────────────────────────────────────────────────────────────────

  test('dropChance = 0.0 → 无论 rng 抽多少都不掉', () {
    // nextDouble() ∈ [0, 1)，最小值 0；0 >= 0 故 continue
    final rng = _MockRng(doubles: const [0.0, 0.0, 0.0, 0.0]);
    final result = service().rollDrops(
      stageWith(const [
        EquipmentDrop(equipmentDefId: 'test_weapon_tie_jian', dropChance: 0.0),
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 3,
          dropChance: 0.0,
        ),
      ]),
      rng,
    );
    expect(result.equipments, isEmpty);
    expect(result.items, isEmpty);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. dropChance = 1 → 必掉（任何 rng 输出 < 1.0）
  // ──────────────────────────────────────────────────────────────────────────

  test('dropChance = 1.0 → 装备 + 物品都必掉，装备走 EquipmentFactory', () {
    final result = service().rollDrops(
      stageWith(const [
        EquipmentDrop(equipmentDefId: 'test_weapon_tie_jian', dropChance: 1.0),
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 2,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ]),
      DefaultRng(seed: 1),
    );
    expect(result.equipments.length, 1);
    expect(result.equipments.first.defId, 'test_weapon_tie_jian');
    expect(result.equipments.first.baseAttack,
        inInclusiveRange(100, 150)); // 走了 EquipmentFactory
    expect(result.equipments.first.obtainedAt, fixedTime);
    expect(result.equipments.first.obtainedFrom, '关卡掉落');
    expect(result.equipments.first.ownerCharacterId, isNull);
    expect(result.items.length, 1);
    expect(result.items.first.defId, 'item_mojianshi');
    expect(result.items.first.quantity, 2);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. quantity range [1, 3] → 落在区间内
  // ──────────────────────────────────────────────────────────────────────────

  test('quantity = [1, 3] → roll 出的 quantity 始终 ∈ [1, 3]', () {
    final rng = DefaultRng(seed: 7);
    for (int i = 0; i < 200; i++) {
      final result = service().rollDrops(
        stageWith(const [
          ItemDrop(
            inventoryItemDefId: 'item_mojianshi',
            quantityMin: 1,
            quantityMax: 3,
            dropChance: 1.0,
          ),
        ]),
        rng,
      );
      expect(result.items.first.quantity, inInclusiveRange(1, 3));
    }
  });

  test('quantity = [5, 5] 单点 → 总是 5', () {
    final result = service().rollDrops(
      stageWith(const [
        ItemDrop(
          inventoryItemDefId: 'item_xinxuejiejing',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
      ]),
      DefaultRng(seed: 123),
    );
    expect(result.items.first.quantity, 5);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. 蒙特卡洛 dropChance = 0.3 → 1000 次落 ±5%
  // ──────────────────────────────────────────────────────────────────────────

  test('蒙特卡洛 1000 次 dropChance=0.3 → 命中率 ∈ [25%, 35%]', () {
    final rng = DefaultRng(seed: 42);
    int hits = 0;
    for (int i = 0; i < 1000; i++) {
      final result = service().rollDrops(
        stageWith(const [
          ItemDrop(
            inventoryItemDefId: 'item_mojianshi',
            quantityMin: 1,
            quantityMax: 1,
            dropChance: 0.3,
          ),
        ]),
        rng,
      );
      if (result.items.isNotEmpty) hits++;
    }
    expect(hits, inInclusiveRange(250, 350));
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 6. 混合 entry：装备 + 物品并存，按 yaml 顺序处理
  // ──────────────────────────────────────────────────────────────────────────

  test('dropTable 混合 EquipmentDrop + ItemDrop，各自独立判定', () {
    // 4 条 entry，全部 chance=1.0，应全部命中
    final result = service().rollDrops(
      stageWith(const [
        EquipmentDrop(equipmentDefId: 'test_weapon_tie_jian', dropChance: 1.0),
        EquipmentDrop(equipmentDefId: 'test_armor_bu_yi', dropChance: 1.0),
        ItemDrop(
          inventoryItemDefId: 'item_a',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_b',
          quantityMin: 2,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ]),
      DefaultRng(seed: 0),
    );
    expect(result.equipments.length, 2);
    expect(result.equipments.map((e) => e.defId).toList(),
        ['test_weapon_tie_jian', 'test_armor_bu_yi']);
    expect(result.items.length, 2);
    expect(result.items.map((e) => e.defId).toList(), ['item_a', 'item_b']);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 7. 确定性：同种子两次结果一致
  // ──────────────────────────────────────────────────────────────────────────

  test('同种子 Rng → 两次 rollDrops 结果完全一致（确定性）', () {
    final table = const [
      EquipmentDrop(equipmentDefId: 'test_weapon_tie_jian', dropChance: 0.5),
      ItemDrop(
        inventoryItemDefId: 'item_mojianshi',
        quantityMin: 1,
        quantityMax: 5,
        dropChance: 0.5,
      ),
    ];
    final r1 = service().rollDrops(stageWith(table), DefaultRng(seed: 99));
    final r2 = service().rollDrops(stageWith(table), DefaultRng(seed: 99));
    expect(r1.equipments.length, r2.equipments.length);
    expect(r1.items.length, r2.items.length);
    if (r1.equipments.isNotEmpty) {
      expect(r1.equipments.first.baseAttack, r2.equipments.first.baseAttack);
      expect(r1.equipments.first.baseSpeed, r2.equipments.first.baseSpeed);
    }
    if (r1.items.isNotEmpty) {
      expect(r1.items.first.quantity, r2.items.first.quantity);
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 8. DropEntry.fromYaml 解析覆盖
  // ──────────────────────────────────────────────────────────────────────────

  group('DropEntry.fromYaml', () {
    test('equipmentDefId + dropChance → EquipmentDrop', () {
      final e = DropEntry.fromYaml({
        'equipmentDefId': 'weapon_x',
        'dropChance': 0.3,
      });
      expect(e, isA<EquipmentDrop>());
      expect((e as EquipmentDrop).equipmentDefId, 'weapon_x');
      expect(e.dropChance, 0.3);
    });

    test('inventoryItemDefId + quantity list → ItemDrop', () {
      final e = DropEntry.fromYaml({
        'inventoryItemDefId': 'item_a',
        'quantity': [1, 3],
        'dropChance': 1.0,
      });
      expect(e, isA<ItemDrop>());
      final item = e as ItemDrop;
      expect(item.inventoryItemDefId, 'item_a');
      expect(item.quantityMin, 1);
      expect(item.quantityMax, 3);
    });

    test('inventoryItemDefId 不带 quantity → 默认 [1, 1]', () {
      final e = DropEntry.fromYaml({
        'inventoryItemDefId': 'item_a',
        'dropChance': 0.5,
      });
      final item = e as ItemDrop;
      expect(item.quantityMin, 1);
      expect(item.quantityMax, 1);
    });

    test('inventoryItemDefId + quantity 单数字 → [n, n]', () {
      final e = DropEntry.fromYaml({
        'inventoryItemDefId': 'item_a',
        'quantity': 5,
        'dropChance': 1.0,
      });
      final item = e as ItemDrop;
      expect(item.quantityMin, 5);
      expect(item.quantityMax, 5);
    });

    test('同时含 equipmentDefId 和 inventoryItemDefId → 抛 FormatException', () {
      expect(
        () => DropEntry.fromYaml({
          'equipmentDefId': 'x',
          'inventoryItemDefId': 'y',
          'dropChance': 1.0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('两个都缺 → 抛 FormatException', () {
      expect(
        () => DropEntry.fromYaml({'dropChance': 1.0}),
        throwsA(isA<FormatException>()),
      );
    });

    test('dropChance 越界 → 抛 FormatException', () {
      expect(
        () => DropEntry.fromYaml({
          'equipmentDefId': 'x',
          'dropChance': 1.5,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DropEntry.fromYaml({
          'equipmentDefId': 'x',
          'dropChance': -0.1,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('quantity 范围 min > max → 抛 FormatException', () {
      expect(
        () => DropEntry.fromYaml({
          'inventoryItemDefId': 'item_a',
          'quantity': [5, 3],
          'dropChance': 1.0,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

/// 注入式 Rng，用于精确控制 nextDouble 返回值。
/// 不用于 EquipmentFactory 内部（fromDef 不命中时根本不调到那里）。
class _MockRng implements Rng {
  final List<double> doubles;
  final void Function()? onNextDouble;
  int _idx = 0;

  _MockRng({required this.doubles, this.onNextDouble});

  @override
  double nextDouble() {
    onNextDouble?.call();
    if (_idx >= doubles.length) {
      throw StateError('MockRng 用尽 doubles');
    }
    return doubles[_idx++];
  }

  @override
  int nextInt(int max) => 0;

  @override
  T pick<T>(List<T> list) => list.first;
}
