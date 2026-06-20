import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/battle_record/presentation/boss_memory_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T9 BossMemoryDetailScreen widget 测试。
///
/// 不接 Isar / GameRepository：立绘走 errorBuilder 兜底。
/// 扩 viewport 防 ListView 截断（memory feedback_listview_widget_test_viewport）。
void main() {
  // ── 公共 fixture ──────────────────────────────────────────────────────────

  BossMemory mkFull() {
    return BossMemory()
      ..bossKey = 'stage_01_05'
      ..source = BossMemorySource.mainline
      ..groupIndex = 1
      ..bossName = '撑伞高人'
      ..isPreRecord = false
      ..firstClearedAt = DateTime(2026, 3, 15)
      ..defeatCount = 5
      ..totalDamage = 18000
      ..critCount = 7
      ..totalTicks = 12
      ..topContributorName = '祖师'
      ..topContributorDamage = 9500
      ..treasureName = '天问剑'
      ..treasureTier = EquipmentTier.liQi
      ..rosterNames = ['祖师', '大弟子']
      ..rosterPortraits = [];
  }

  BossMemory mkPreRecord() {
    return BossMemory()
      ..bossKey = 'stage_02_05'
      ..source = BossMemorySource.mainline
      ..groupIndex = 2
      ..bossName = '黑袍剑客'
      ..isPreRecord = true
      ..firstClearedAt = null
      ..defeatCount = 2
      ..totalDamage = null
      ..critCount = null
      ..totalTicks = null
      ..topContributorName = null
      ..topContributorDamage = null
      ..treasureName = null
      ..treasureTier = null
      ..rosterNames = []
      ..rosterPortraits = [];
  }

  Future<void> pumpDetail(WidgetTester tester, BossMemory memory) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: BossMemoryDetailScreen(memory: memory)),
    );
    await tester.pump();
    await tester.pump();
  }

  // ── 测试用例 ──────────────────────────────────────────────────────────────

  testWidgets('完整纪念显伤害/英雄/掉落/阵容', (tester) async {
    final m = mkFull();
    await pumpDetail(tester, m);

    // 标题 = bossName
    expect(find.text('撑伞高人'), findsWidgets);

    // 首胜战绩区标题
    expect(find.text(UiStrings.battleRecordStatsTitle), findsOneWidget);

    // 伤害/暴击/回合文案可见
    expect(find.text(UiStrings.battleRecordDamage(18000)), findsOneWidget);
    expect(find.text(UiStrings.battleRecordCrits(7)), findsOneWidget);
    expect(find.text(UiStrings.battleRecordTurns(12)), findsOneWidget);

    // 初胜日期
    expect(
      find.text(UiStrings.battleRecordClearedAt('2026.3.15')),
      findsOneWidget,
    );

    // 击败次数
    expect(find.text(UiStrings.battleRecordDefeatCount(5)), findsOneWidget);

    // 此战之最区
    expect(find.text(UiStrings.battleRecordTopContributorTitle), findsOneWidget);
    expect(find.text('祖师'), findsWidgets);
    expect(find.text(UiStrings.battleRecordDamage(9500)), findsWidgets);

    // 所获区
    expect(find.text(UiStrings.battleRecordTreasureTitle), findsOneWidget);
    expect(find.text('天问剑'), findsOneWidget);
    // 阶名「利器」
    expect(find.textContaining('利器'), findsOneWidget);

    // 出战区
    expect(find.text(UiStrings.battleRecordRosterTitle), findsOneWidget);
    expect(find.text('大弟子'), findsOneWidget);
  });

  testWidgets('pre-record 显此役不详 + 不显伤害数字', (tester) async {
    final m = mkPreRecord();
    await pumpDetail(tester, m);

    // bossName 依然可见
    expect(find.text('黑袍剑客'), findsWidgets);

    // 「此役不详·记录之前」可见
    expect(find.text(UiStrings.battleRecordPreRecord), findsOneWidget);

    // 伤害/暴击/回合一律不出现（字段为 null，优雅降级）
    expect(find.textContaining('总伤害'), findsNothing);
    expect(find.textContaining('暴击'), findsNothing);
    expect(find.textContaining('回合'), findsNothing);

    // 此战之最区不显（topContributorName == null）
    expect(find.text(UiStrings.battleRecordTopContributorTitle), findsNothing);

    // 所获区不显（treasureName == null）
    expect(find.text(UiStrings.battleRecordTreasureTitle), findsNothing);

    // 击败次数仍显
    expect(find.text(UiStrings.battleRecordDefeatCount(2)), findsOneWidget);
  });

  testWidgets('pre-record 有初胜日期时仍显示日期', (tester) async {
    final m = mkPreRecord()..firstClearedAt = DateTime(2025, 12, 1);
    await pumpDetail(tester, m);

    expect(
      find.text(UiStrings.battleRecordClearedAt('2025.12.1')),
      findsOneWidget,
    );
    // 但伤害数字不出现
    expect(find.textContaining('总伤害'), findsNothing);
  });

  testWidgets('完整纪念无掉落时所获区不显', (tester) async {
    final m = mkFull()
      ..treasureName = null
      ..treasureTier = null;
    await pumpDetail(tester, m);

    expect(find.text(UiStrings.battleRecordTreasureTitle), findsNothing);
  });

  testWidgets('完整纪念无贡献者时此战之最区不显', (tester) async {
    final m = mkFull()
      ..topContributorName = null
      ..topContributorDamage = null;
    await pumpDetail(tester, m);

    expect(find.text(UiStrings.battleRecordTopContributorTitle), findsNothing);
  });

  testWidgets('出战名单空时出战区不显', (tester) async {
    final m = mkFull()..rosterNames = [];
    await pumpDetail(tester, m);

    expect(find.text(UiStrings.battleRecordRosterTitle), findsNothing);
  });

  testWidgets('不崩：全字段最小值（仅必填字段有效值）', (tester) async {
    final m = BossMemory()
      ..bossKey = 'stage_03_05'
      ..source = BossMemorySource.mainline
      ..groupIndex = 3
      ..bossName = '古井老人'
      ..isPreRecord = false
      ..firstClearedAt = null
      ..defeatCount = 1
      ..totalDamage = null
      ..critCount = null
      ..totalTicks = null
      ..topContributorName = null
      ..topContributorDamage = null
      ..treasureName = null
      ..treasureTier = null
      ..rosterNames = []
      ..rosterPortraits = [];

    await pumpDetail(tester, m);
    expect(find.text('古井老人'), findsWidgets);
    expect(find.text(UiStrings.battleRecordDefeatCount(1)), findsOneWidget);
  });
}
