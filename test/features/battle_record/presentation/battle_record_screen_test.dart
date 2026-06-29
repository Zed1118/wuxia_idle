import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle_record/application/boss_memory_providers.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_catalog_entry.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/battle_record/presentation/battle_record_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_loading.dart';

/// T8 BattleRecordScreen widget 测试。
///
/// 不接真实 Isar / GameRepository：两个 provider 全 override 为 fixture，
/// 立绘 Image.asset 缺图走 errorBuilder 兜底，不影响布局断言。
void main() {
  // ── 公共 fixture ──────────────────────────────────────────────────────────

  /// 最小 catalog：3 主线 + 2 塔
  List<BossCatalogEntry> mkCatalog() => [
        const BossCatalogEntry(
          bossKey: 'stage_01_05',
          source: BossMemorySource.mainline,
          groupIndex: 1,
        ),
        const BossCatalogEntry(
          bossKey: 'stage_02_05',
          source: BossMemorySource.mainline,
          groupIndex: 2,
        ),
        const BossCatalogEntry(
          bossKey: 'stage_03_05',
          source: BossMemorySource.mainline,
          groupIndex: 3,
        ),
        const BossCatalogEntry(
          bossKey: 'tower_floor_5',
          source: BossMemorySource.tower,
          groupIndex: 5,
        ),
        const BossCatalogEntry(
          bossKey: 'tower_floor_10',
          source: BossMemorySource.tower,
          groupIndex: 10,
        ),
      ];

  BossMemory mkMemory({
    required String bossKey,
    required BossMemorySource source,
    required int groupIndex,
    required String bossName,
    bool isPreRecord = false,
    DateTime? firstClearedAt,
    int defeatCount = 1,
  }) {
    return BossMemory()
      ..bossKey = bossKey
      ..source = source
      ..groupIndex = groupIndex
      ..bossName = bossName
      ..isPreRecord = isPreRecord
      ..firstClearedAt = firstClearedAt ?? DateTime(2026, 3, 15)
      ..defeatCount = defeatCount
      ..rosterNames = []
      ..rosterPortraits = [];
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<BossCatalogEntry> catalog,
    required List<BossMemory> memories,
  }) async {
    // 扩 viewport 让 ListView 完整渲染（memory feedback_listview_widget_test_viewport）
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bossCatalogProvider.overrideWithValue(catalog),
          bossMemoryListProvider.overrideWith((ref) async => memories),
        ],
        child: const MaterialApp(home: BattleRecordScreen()),
      ),
    );
    // 等待 FutureProvider 完成
    await tester.pump();
    await tester.pump();
  }

  // ── 测试用例 ──────────────────────────────────────────────────────────────

  testWidgets('已击败显纪念卡 + 未击败显剩影', (tester) async {
    final catalog = mkCatalog();
    // 只给 stage_01_05 + tower_floor_5 命中
    final memories = [
      mkMemory(
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        defeatCount: 3,
      ),
      mkMemory(
        bossKey: 'tower_floor_5',
        source: BossMemorySource.tower,
        groupIndex: 5,
        bossName: '塔层精英',
        defeatCount: 1,
      ),
    ];

    await pumpScreen(tester, catalog: catalog, memories: memories);

    // 屏幕标题
    expect(find.text(UiStrings.battleRecordTitle), findsOneWidget);

    // 已击败纪念卡：bossName 可见
    expect(find.text('撑伞高人'), findsOneWidget);
    expect(find.text('塔层精英'), findsOneWidget);

    // 击败次数文案
    expect(
      find.text(UiStrings.battleRecordDefeatCount(3)),
      findsOneWidget,
      reason: '撑伞高人击败 3 次',
    );
    expect(
      find.text(UiStrings.battleRecordDefeatCount(1)),
      findsOneWidget,
      reason: '塔层精英击败 1 次',
    );

    // 未命中条目显「未会之敌」（stage_02_05 / stage_03_05 / tower_floor_10）
    expect(
      find.text(UiStrings.battleRecordLockedBoss),
      findsNWidgets(3),
      reason: '3 条未命中的 catalog 条目显剩影占位',
    );
  });

  testWidgets('剩影占位不显 bossName（§5.7 不剧透）', (tester) async {
    final catalog = [
      const BossCatalogEntry(
        bossKey: 'stage_02_05',
        source: BossMemorySource.mainline,
        groupIndex: 2,
      ),
    ];
    // 无 memory，全部是占位
    await pumpScreen(tester, catalog: catalog, memories: []);

    // 占位存在
    expect(find.text(UiStrings.battleRecordLockedBoss), findsOneWidget);

    // 任何 boss 名字都不能出现——占位里肯定没有，确认没有意外文案泄漏
    expect(find.text('撑伞高人'), findsNothing);
    expect(find.text('神秘Boss'), findsNothing);
  });

  testWidgets('分组标题：主线征程 + 爬塔问鼎均存在', (tester) async {
    await pumpScreen(
      tester,
      catalog: mkCatalog(),
      memories: [],
    );

    expect(find.text('主线征程'), findsOneWidget);
    expect(find.text('爬塔问鼎'), findsOneWidget);
  });

  testWidgets('pre-record 骨架纪念卡不崩', (tester) async {
    final catalog = [
      const BossCatalogEntry(
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
      ),
    ];
    final memories = [
      mkMemory(
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        isPreRecord: true,
        firstClearedAt: null, // 骨架可能无日期
        defeatCount: 1,
      )..firstClearedAt = null, // 确保清空
    ];

    await pumpScreen(tester, catalog: catalog, memories: memories);

    // 不崩，bossName 显示
    expect(find.text('撑伞高人'), findsOneWidget);
    // 击败次数也在
    expect(find.text(UiStrings.battleRecordDefeatCount(1)), findsOneWidget);
    // 剩影占位不出现（已有纪念卡）
    expect(find.text(UiStrings.battleRecordLockedBoss), findsNothing);
  });

  testWidgets('初胜日期显示在纪念卡上', (tester) async {
    final catalog = [
      const BossCatalogEntry(
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
      ),
    ];
    final memories = [
      mkMemory(
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        firstClearedAt: DateTime(2026, 3, 15),
        defeatCount: 1,
      ),
    ];

    await pumpScreen(tester, catalog: catalog, memories: memories);

    expect(
      find.text(UiStrings.battleRecordClearedAt('2026.3.15')),
      findsOneWidget,
    );
  });

  testWidgets('加载中显示 loading indicator', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // completer 控制 Future 不完成，确保 loading 态持续
    final completer = Completer<List<BossMemory>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bossCatalogProvider.overrideWithValue(const []),
          bossMemoryListProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: BattleRecordScreen()),
      ),
    );
    // 不 pump()，直接检查 loading 态
    expect(find.byType(InkLoadingIndicator), findsOneWidget);
    // 收尾：完成 completer 避免 timer/pending 警告
    completer.complete([]);
  });
}
