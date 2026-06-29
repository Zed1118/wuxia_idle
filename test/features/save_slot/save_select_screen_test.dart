import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/data/slot_summary.dart';
import 'package:wuxia_idle/features/save_slot/application/slot_list_provider.dart';
import 'package:wuxia_idle/features/save_slot/presentation/save_select_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_icon_button.dart';

/// 存档选择屏(spec B §5):列 3 槽、有档显摘要、空槽显新开、删除确认流。
/// override slotListProvider 注入混合 fixtures,避免真 Isar(隔离 UI 层)。
void main() {
  final mixed = <SlotSummary>[
    SlotSummary(
      slotId: 1,
      isEmpty: false,
      slotName: '夜雨江湖',
      founderName: '风清扬',
      realmDisplay: '武圣登峰',
      chapterIndex: 6,
      clearedStageCount: 30,
      highestTowerFloor: 18,
      lastPlayed: DateTime(2026, 6, 29, 20, 15),
      isMostRecent: true,
    ),
    SlotSummary.empty(2),
    SlotSummary.empty(3),
  ];

  Widget host(List<SlotSummary> slots) => ProviderScope(
    overrides: [slotListProvider.overrideWith((ref) async => slots)],
    child: const MaterialApp(home: SaveSelectScreen()),
  );

  testWidgets('列 3 槽 + 有档显名称/进度/最近游玩 + 空槽显新开', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    // 标题
    expect(find.text(UiStrings.slotSelectTitle), findsOneWidget);
    // 3 张卡
    expect(find.text('夜雨江湖'), findsWidgets);
    expect(find.text(UiStrings.slotCardTitle(2)), findsOneWidget);
    expect(find.text(UiStrings.slotCardTitle(3)), findsOneWidget);
    // 有档槽显祖师名 + 进度
    expect(
      find.text(UiStrings.slotFounderSummary('风清扬', '武圣登峰')),
      findsOneWidget,
    );
    expect(find.textContaining('第 6 章'), findsOneWidget);
    expect(find.textContaining('最高第 18 层'), findsOneWidget);
    expect(find.text(UiStrings.slotRecentBadge), findsOneWidget);
    expect(find.textContaining('2026-06-29 20:15'), findsOneWidget);
    // 空槽显「空 · 新开江湖」(slot2/slot3 两处)
    expect(find.text(UiStrings.slotSaveEmpty), findsNWidgets(2));
  });

  testWidgets('重命名/删除按钮仅有档槽出现', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();
    // 仅 slot1 有删除按钮(空槽 trailing 是 chevron 不是删除)
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byType(WuxiaIconButton), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });

  testWidgets('点重命名 → 弹命名对话框', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.slotRenameTitle), findsOneWidget);
    expect(find.text(UiStrings.slotRenameClearHint), findsOneWidget);
    expect(find.text('夜雨江湖'), findsWidgets);
    await tester.tap(find.text(UiStrings.slotCancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('点删除 → 需输入存档名才启用确认', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    // 确认弹窗渲染
    expect(find.text(UiStrings.slotDeleteConfirmFor('夜雨江湖')), findsOneWidget);
    expect(
      find.text(UiStrings.slotDeleteProtectionValue('夜雨江湖')),
      findsOneWidget,
    );
    var deleteButton = tester.widget<PlaqueButton>(
      find.widgetWithText(PlaqueButton, UiStrings.slotDelete),
    );
    expect(deleteButton.disabled, isTrue);

    await tester.enterText(find.byType(TextField), '夜雨江湖');
    await tester.pumpAndSettle();
    deleteButton = tester.widget<PlaqueButton>(
      find.widgetWithText(PlaqueButton, UiStrings.slotDelete),
    );
    expect(deleteButton.disabled, isFalse);

    // 取消关闭,不调 deleteSlot(无真 Isar 也不崩)
    await tester.tap(find.text(UiStrings.slotCancel));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.slotDeleteConfirm), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点空槽 → 弹「新开江湖」确认', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.slotCardTitle(2)));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.slotNewGameConfirm), findsOneWidget);
    await tester.tap(find.text(UiStrings.slotCancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
