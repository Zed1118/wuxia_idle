// test/features/loot_preview/tower_card_loot_wiring_test.dart
//
// Task 9: 验证 TowerFloorCard 正确接入掉落传闻简版行（首通必得上下文）+ info 角标。
// TowerFloorCard 是纯 StatelessWidget，直接 pump 无需 ProviderScope。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

// ── fixture ─────────────────────────────────────────────────────────────────

/// 带掉落表的普通塔层（dropChance 1.0 → 首通必得桶，脚注显示）。
TowerFloorEntry _makeEntry({List<DropEntry> dropTable = const []}) {
  final def = TowerFloorDef(
    floorIndex: 3,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: const [],
    dropTable: dropTable,
  );
  return (def: def, status: TowerFloorStatus.available);
}

Widget _harness(TowerFloorEntry entry, {RealmTier? currentRealm}) {
  return MaterialApp(
    home: Scaffold(
      body: TowerFloorCard(
        entry: entry,
        onChallenge: () {},
        stepSide: TowerFloorStepSide.left,
        currentRealm: currentRealm,
      ),
    ),
  );
}

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('有掉落时显示「可能收获：」前缀行', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final entry = _makeEntry(
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ],
    );

    await tester.pumpWidget(_harness(entry));
    await tester.pump();

    expect(
      find.textContaining(UiStrings.lootSummaryPrefix),
      findsOneWidget,
      reason: '有掉落条目时应渲染「可能收获：」前缀行',
    );
  });

  testWidgets('无掉落时显示「本关无固定收获」占位', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final entry = _makeEntry();

    await tester.pumpWidget(_harness(entry));
    await tester.pump();

    expect(
      find.textContaining(UiStrings.lootNoFixedDrop),
      findsOneWidget,
      reason: '无掉落时应渲染「本关无固定收获」',
    );
  });

  testWidgets('点击 info 角标弹出传闻对话框 + 首通必得脚注', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // dropChance 1.0 → 首通必得桶 → isFirstClearGated 脚注应显示
    final entry = _makeEntry(
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ],
    );

    await tester.pumpWidget(_harness(entry));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.lootRumorDialogTitle),
      findsOneWidget,
      reason: '点击 info 角标后应弹出「本关传闻」对话框',
    );
    expect(
      find.text(UiStrings.lootTowerFirstClearOnlyFooter),
      findsOneWidget,
      reason: '爬塔 isFirstClearGated:true 应显示首通必得脚注',
    );
  });
}
