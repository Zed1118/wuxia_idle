import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart'
    show shouldSkipScrollDrop;
import 'package:wuxia_idle/shared/utils/rng.dart';

/// T5 首通必得门控逻辑单元测。
///
/// stage_entry_flow.dart 的 gating 规则：
///   if (item.defId.startsWith('item_scroll_') && !isFirstClearStage) continue;
///
/// 此测验证：
///   1. DropService.rollDrops 在 dropChance=1.0 时，item_scroll_* 必出现在
///      DropResult.items（说明 roll 侧正常，gating 在写入层）。
///   2. 模拟"首通 → 写入"：isFirstClearStage=true，不跳过，scroll 进背包。
///   3. 模拟"重打 → 跳过"：isFirstClearStage=false，scroll 被 gate 掉，背包不增。
///   4. 银两/经验丹不受 gate 影响：无论 isFirstClearStage 为何值都不被过滤。
void main() {
  StageDef stageWith(List<DropEntry> table) => StageDef(
        id: 'test_stage_boss',
        name: '测试章末 Boss',
        stageType: StageType.mainline,
        chapterIndex: 1,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: true,
        dropTable: table,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );

  final service = DropService(
    equipmentDefLookup: (_) => throw StateError('测试不用装备掉落'),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 1. DropService 侧：dropChance=1.0 时 item_scroll_* 必出现在 DropResult
  // ─────────────────────────────────────────────────────────────────────────

  test('rollDrops dropChance=1.0 → item_scroll_* 必入 DropResult.items', () {
    final result = service.rollDrops(
      stageWith(const [
        ItemDrop(
          inventoryItemDefId: 'item_scroll_guan_shan_ba_ji',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ]),
      DefaultRng(seed: 1),
    );
    expect(result.items, hasLength(1));
    expect(result.items.first.defId, 'item_scroll_guan_shan_ba_ji');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. 门控逻辑语义：isFirstClearStage=true → 秘籍写入（不被 gate）
  // ─────────────────────────────────────────────────────────────────────────

  test('首通(isFirstClearStage=true)：item_scroll_* 不被 gate，应写入背包', () {
    const isFirstClearStage = true;
    final items = [
      const _ItemLike(defId: 'item_scroll_guan_shan_ba_ji', quantity: 1),
      const _ItemLike(defId: 'item_silver', quantity: 30),
    ];

    final written = items
        .where((item) =>
            !shouldSkipScrollDrop(item.defId, isFirstClear: isFirstClearStage))
        .toList();

    expect(written.map((e) => e.defId),
        containsAll(['item_scroll_guan_shan_ba_ji', 'item_silver']));
    expect(written, hasLength(2));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. 门控逻辑语义：isFirstClearStage=false → 秘籍被 gate，银两不受影响
  // ─────────────────────────────────────────────────────────────────────────

  test('重打(isFirstClearStage=false)：item_scroll_* 被 gate 跳过，银两/经验丹不受影响', () {
    const isFirstClearStage = false;
    final items = [
      const _ItemLike(defId: 'item_scroll_guan_shan_ba_ji', quantity: 1),
      const _ItemLike(defId: 'item_silver', quantity: 30),
      const _ItemLike(defId: 'item_jingyandan_large', quantity: 1),
    ];

    final written = items
        .where((item) =>
            !shouldSkipScrollDrop(item.defId, isFirstClear: isFirstClearStage))
        .toList();

    // 秘籍被 gate 掉
    expect(written.map((e) => e.defId),
        isNot(contains('item_scroll_guan_shan_ba_ji')));
    // 银两/经验丹正常通过
    expect(written.map((e) => e.defId), contains('item_silver'));
    expect(written.map((e) => e.defId), contains('item_jingyandan_large'));
    expect(written, hasLength(2));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Gate 只管 item_scroll_ 前缀，其他前缀不受影响
  // ─────────────────────────────────────────────────────────────────────────

  test('gate 精确匹配 item_scroll_ 前缀，其余 item 全部放行（含重打场景）', () {
    const isFirstClearStage = false; // 最严情形
    final items = [
      const _ItemLike(defId: 'item_scroll_guan_shan_ba_ji', quantity: 1), // gate
      const _ItemLike(defId: 'item_scroll_ma_ta_fei_yan', quantity: 1),   // gate
      const _ItemLike(defId: 'item_silver', quantity: 20),                  // pass
      const _ItemLike(defId: 'item_mojianshi', quantity: 3),                // pass
      const _ItemLike(defId: 'item_xinxuejiejing', quantity: 1),            // pass
      const _ItemLike(defId: 'item_jingyandan_large', quantity: 1),         // pass
      const _ItemLike(defId: 'item_jingyandan_peiyu', quantity: 1),         // pass
    ];

    final written = items
        .where((item) =>
            !shouldSkipScrollDrop(item.defId, isFirstClear: isFirstClearStage))
        .toList();

    expect(written.map((e) => e.defId),
        isNot(contains('item_scroll_guan_shan_ba_ji')));
    expect(written.map((e) => e.defId),
        isNot(contains('item_scroll_ma_ta_fei_yan')));
    expect(written, hasLength(5), reason: '5 个非秘籍 item 全部放行');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. 爬塔 6 本：dropChance=1.0 时 rollTowerRewards 必输出 scroll
  // ─────────────────────────────────────────────────────────────────────────

  test('rollTowerRewards dropChance=1.0 → item_scroll_* 必入 DropResult.items', () {
    const towerScrollIds = [
      'item_scroll_kai_bei_shou',
      'item_scroll_yan_zi_san_chao',
      'item_scroll_zhu_ying_yao_hong',
      'item_scroll_jin_gang_fu_mo',
      'item_scroll_jing_hong_zhao_ying',
      'item_scroll_yue_luo_wu_sheng',
    ];
    for (final scrollId in towerScrollIds) {
      final result = service.rollDrops(
        stageWith([
          ItemDrop(
            inventoryItemDefId: scrollId,
            quantityMin: 1,
            quantityMax: 1,
            dropChance: 1.0,
          ),
        ]),
        DefaultRng(seed: 7),
      );
      expect(result.items, hasLength(1), reason: '$scrollId 应命中');
      expect(result.items.first.defId, scrollId);
    }
  });
}

/// 轻量 value class，仅用于模拟 ItemDropResult 的 defId+quantity 字段。
/// 避免引入 Isar 或真实 InventoryItem schema。
class _ItemLike {
  final String defId;
  final int quantity;
  const _ItemLike({required this.defId, required this.quantity});
}
