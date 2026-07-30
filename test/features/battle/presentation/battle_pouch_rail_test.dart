import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_bottom_bar.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 战备行囊三格「不许谎报玩家拥有的道具」红线(C5)。
///
/// 立项背景(2026-07-30 复核):旧版 slot 0/1 **无条件写死**显示紫金葫芦与寻常药囊
/// 两张真实道具图,与玩家实际背包毫无关系 —— 每个玩家、每一场战斗,行囊里都
/// 「有」这两件。这不是中性占位,是在展示**假的游戏状态**;旁边「待装配」小字
/// 字号 9,视觉权重远输于 42px 实心彩图。
///
/// 断言写**约束语义**:纹样长什么样将来可以再调,但「三格一致」「不出现任何
/// 具体道具图」这两条是红线 —— 行囊真接线之前不得再显具体道具。
void main() {
  Widget host({bool compact = false, Size size = const Size(1280, 720)}) =>
      MediaQuery(
        data: MediaQueryData(size: size),
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: BattlePouchRail(),
            ),
          ),
        ),
      );

  Widget hostCompact({Size size = const Size(1280, 720)}) => MediaQuery(
    data: MediaQueryData(size: size),
    child: const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomRight,
          child: BattlePouchRail(compact: true),
        ),
      ),
    ),
  );

  testWidgets('三格一律空囊印记,无一格显具体道具', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      expect(
        find.byKey(ValueKey('battle.pouch.emptySeal.$i')),
        findsOneWidget,
        reason: '第 $i 格缺空囊印记 → 三格不一致',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('行囊栏内不出现任何 Image(不谎报持有道具)', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(BattlePouchRail),
        matching: find.byType(Image),
      ),
      findsNothing,
      reason: '行囊未接真背包前显任何具体道具图 = 展示假的游戏状态',
    );
  });

  testWidgets('compact 档同样三格一致且不显道具', (tester) async {
    await tester.pumpWidget(hostCompact());
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('battle.pouch.emptySeal.$i')), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(BattlePouchRail),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('「待装配」说明字仍在(保住「这里将来是行囊」的信息)', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text(UiStrings.battlePouchReserved), findsOneWidget);
    expect(find.text(UiStrings.battlePouch), findsOneWidget);
  });

  testWidgets('三格外框与木匣仍在(未把整条行囊栏改没)', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byKey(const ValueKey('battle.pouch.woodCase')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('battle_pouch_slot_$i')), findsOneWidget);
      expect(
        find.byKey(ValueKey('battle.pouch.brocadeSlot.$i')),
        findsOneWidget,
      );
    }
  });
}
