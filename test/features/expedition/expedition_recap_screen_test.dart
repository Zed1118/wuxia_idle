import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_recap_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

RewardEntry _r(String key, int qty) => RewardEntry()
  ..rewardKey = key
  ..quantity = qty;

Future<void> _pumpRecap(
  WidgetTester tester,
  ExpeditionReturnResult result,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: ExpeditionRecapScreen(result: result)),
  );
  await tester.pump();
}

void main() {
  testWidgets('主动召回：最深/奖获/断魂帖/全员安然，1280×720 无溢出', (tester) async {
    final result = ExpeditionReturnResult(
      returned: true,
      deepestNode: 12,
      grantedRewards: [_r('exp', 800), _r('item_yaocao', 3), _r('item_duanhuntie', 1)],
      downedCount: 0,
      defeated: false,
    );
    await _pumpRecap(tester, result, const Size(1280, 720));

    expect(find.text(UiStrings.expeditionRecapTitle), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapReturnedTitle), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapDeepest(12)), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapCompletedNodes(12)), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapExp(800)), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapTicket(1)), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapSafeReturn), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapBack), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('战败返程：败走标题 + 无奖获 + 重伤伤势，1440×900 无溢出', (tester) async {
    const result = ExpeditionReturnResult(
      returned: true,
      deepestNode: 7,
      grantedRewards: [],
      downedCount: 2,
      defeated: true,
    );
    await _pumpRecap(tester, result, const Size(1440, 900));

    expect(find.text(UiStrings.expeditionRecapDefeatedTitle), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapNoReward), findsOneWidget);
    expect(find.text(UiStrings.expeditionRecapDefeatedInjury(2)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('主动召回但有人负伤：显负伤调息文案', (tester) async {
    final result = ExpeditionReturnResult(
      returned: true,
      deepestNode: 9,
      grantedRewards: [_r('item_silver', 120)],
      downedCount: 1,
      defeated: false,
    );
    await _pumpRecap(tester, result, const Size(1280, 720));

    expect(find.text(UiStrings.expeditionRecapDownedInjury(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
