import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_recap_service.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// M2「归来」卡渲染 + 回调行为测试。导航逻辑解耦在 HomeFeed hook,
/// 卡本身只渲染 recap 数据并触发 onGoCollect / onDismiss。
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required OfflineRecap recap,
    required VoidCallback onGoCollect,
    required VoidCallback onDismiss,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineRecapCard(
            recap: recap,
            onGoCollect: onGoCollect,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }

  testWidgets('已满 recap：标题 + 地图圆满 + 预估产出 + 两按钮齐显', (tester) async {
    const recap = (
      awayHours: 5.0,
      mapName: '山林',
      isComplete: true,
      progressPct: 1.0,
      estimatedMojianshi: 120,
      estimatedExperience: 300,
      estimatedItemRewards: <String, int>{},
      estimatedTechniqueLearnPoints: 2,
      estimatedSilver: 45,
      settledHours: 4.0,
      limitReason: OfflineRecapLimitReason.plannedDuration,
    );
    await pumpCard(tester, recap: recap, onGoCollect: () {}, onDismiss: () {});

    expect(find.text(UiStrings.offlineRecapTitle), findsOneWidget);
    expect(find.textContaining('山林'), findsOneWidget);
    expect(find.textContaining('圆满'), findsOneWidget);
    expect(
      find.text(UiStrings.offlineRecapRewardOverview(120, 45, 300)),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.offlineRecapMaterialDetail('磨剑石 120')),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.offlineRecapSettlementGroupTitle),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.offlineRecapRetreatGainGroupTitle),
      findsOneWidget,
    );
    expect(find.text(UiStrings.offlineRecapCollectGroupTitle), findsOneWidget);
    expect(find.text(UiStrings.offlineRecapSilverDetail(45)), findsOneWidget);
    expect(
      find.text(UiStrings.offlineRecapExperienceDetail(300)),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.offlineRecapTechniqueLearnDetail(2)),
      findsOneWidget,
    );
    expect(find.textContaining('招式熟练度：0'), findsNothing);
    expect(
      find.textContaining(UiStrings.offlineRecapDropPending),
      findsOneWidget,
    );
    expect(
      find.textContaining(UiStrings.offlineRecapLimitPlanned),
      findsOneWidget,
    );
    expect(find.text(UiStrings.offlineRecapGoCollect), findsOneWidget);
    expect(find.text(UiStrings.offlineRecapDismiss), findsOneWidget);
  });

  testWidgets('进行中 recap：显示进度百分比（50%）', (tester) async {
    const recap = (
      awayHours: 2.0,
      mapName: '古剑冢',
      isComplete: false,
      progressPct: 0.5,
      estimatedMojianshi: 40,
      estimatedExperience: 90,
      estimatedItemRewards: <String, int>{},
      estimatedTechniqueLearnPoints: 0,
      estimatedSilver: 15,
      settledHours: 2.0,
      limitReason: OfflineRecapLimitReason.inProgress,
    );
    await pumpCard(tester, recap: recap, onGoCollect: () {}, onDismiss: () {});

    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.textContaining('古剑冢'), findsOneWidget);
    expect(
      find.textContaining(UiStrings.offlineRecapLimitInProgress),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.offlineRecapTechniqueLearnDetail(0)),
      findsNothing,
    );
  });

  testWidgets('0 值收益项隐藏，保留结算说明与收功揭晓', (tester) async {
    const recap = (
      awayHours: 2.0,
      mapName: '古剑冢',
      isComplete: false,
      progressPct: 0.5,
      estimatedMojianshi: 0,
      estimatedExperience: 0,
      estimatedItemRewards: <String, int>{},
      estimatedTechniqueLearnPoints: 0,
      estimatedSilver: 0,
      settledHours: 2.0,
      limitReason: OfflineRecapLimitReason.inProgress,
    );
    await pumpCard(tester, recap: recap, onGoCollect: () {}, onDismiss: () {});

    expect(find.text(UiStrings.offlineRecapExperienceDetail(0)), findsNothing);
    expect(find.text(UiStrings.offlineRecapSilverDetail(0)), findsNothing);
    expect(find.text(UiStrings.offlineRecapMaterialDetail('无')), findsNothing);
    expect(find.text(UiStrings.offlineRecapNoGainsDetail), findsOneWidget);
    expect(
      find.text(
        UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapDropPending),
      ),
      findsOneWidget,
    );
  });

  testWidgets('点「前去收功」触发 onGoCollect', (tester) async {
    var collected = false;
    const recap = (
      awayHours: 5.0,
      mapName: '山林',
      isComplete: true,
      progressPct: 1.0,
      estimatedMojianshi: 120,
      estimatedExperience: 300,
      estimatedItemRewards: <String, int>{},
      estimatedTechniqueLearnPoints: 0,
      estimatedSilver: 45,
      settledHours: 4.0,
      limitReason: OfflineRecapLimitReason.plannedDuration,
    );
    await pumpCard(
      tester,
      recap: recap,
      onGoCollect: () => collected = true,
      onDismiss: () {},
    );

    await tester.tap(find.text(UiStrings.offlineRecapGoCollect));
    await tester.pump();
    expect(collected, isTrue);
  });

  testWidgets('点「稍后再说」触发 onDismiss', (tester) async {
    var dismissed = false;
    const recap = (
      awayHours: 5.0,
      mapName: '山林',
      isComplete: true,
      progressPct: 1.0,
      estimatedMojianshi: 120,
      estimatedExperience: 300,
      estimatedItemRewards: <String, int>{},
      estimatedTechniqueLearnPoints: 0,
      estimatedSilver: 45,
      settledHours: 4.0,
      limitReason: OfflineRecapLimitReason.plannedDuration,
    );
    await pumpCard(
      tester,
      recap: recap,
      onGoCollect: () {},
      onDismiss: () => dismissed = true,
    );

    await tester.tap(find.text(UiStrings.offlineRecapDismiss));
    await tester.pump();
    expect(dismissed, isTrue);
  });
}
