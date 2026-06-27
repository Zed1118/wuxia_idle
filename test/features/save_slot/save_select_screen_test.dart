import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/data/slot_summary.dart';
import 'package:wuxia_idle/features/save_slot/application/slot_list_provider.dart';
import 'package:wuxia_idle/features/save_slot/presentation/save_select_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 存档选择屏(spec B §5):列 3 槽、有档显摘要、空槽显新开、删除确认流。
/// override slotListProvider 注入混合 fixtures,避免真 Isar(隔离 UI 层)。
void main() {
  final mixed = <SlotSummary>[
    SlotSummary(
      slotId: 1,
      isEmpty: false,
      founderName: '风清扬',
      realmDisplay: '武圣登峰',
      chapterIndex: 6,
      clearedStageCount: 30,
      lastPlayed: null,
    ),
    SlotSummary.empty(2),
    SlotSummary.empty(3),
  ];

  Widget host(List<SlotSummary> slots) => ProviderScope(
        overrides: [
          slotListProvider.overrideWith((ref) async => slots),
        ],
        child: const MaterialApp(home: SaveSelectScreen()),
      );

  testWidgets('列 3 槽 + 有档显祖师名/进度 + 空槽显新开', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    // 标题
    expect(find.text(UiStrings.slotSelectTitle), findsOneWidget);
    // 3 张卡
    expect(find.text(UiStrings.slotCardTitle(1)), findsOneWidget);
    expect(find.text(UiStrings.slotCardTitle(2)), findsOneWidget);
    expect(find.text(UiStrings.slotCardTitle(3)), findsOneWidget);
    // 有档槽显祖师名 + 进度
    expect(find.textContaining('风清扬'), findsOneWidget);
    expect(find.textContaining('第 6 章'), findsOneWidget);
    // 空槽显「空 · 新开江湖」(slot2/slot3 两处)
    expect(find.text(UiStrings.slotSaveEmpty), findsNWidgets(2));
  });

  testWidgets('删除按钮仅有档槽出现', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();
    // 仅 slot1 有删除按钮(空槽 trailing 是 chevron 不是删除)
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });

  testWidgets('点删除 → 弹确认弹窗(取消不触发删档)', (tester) async {
    await tester.pumpWidget(host(mixed));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    // 确认弹窗渲染
    expect(find.text(UiStrings.slotDeleteConfirm), findsOneWidget);
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
