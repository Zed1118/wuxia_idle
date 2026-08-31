import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/expedition_location_detail_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Future<void> revealExpeditionLocation(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('jianghu-map-expedition-location')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  ExpeditionRun activeRun({bool defeated = false}) => ExpeditionRun()
    ..saveDataId = 0
    ..policy = ExpeditionPolicy.yanJingCaiYao
    ..seed = 25
    ..departedAt = DateTime(2026, 8, 25)
    ..currentNode = 8
    ..defeated = defeated;

  Widget app({required bool unlocked, ExpeditionRun? active}) => ProviderScope(
    overrides: [
      towerProgressProvider.overrideWith(
        (ref) async => TowerProgress()
          ..saveDataId = 0
          ..highestClearedFloor = 0,
      ),
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()..clearedStageIds = const [],
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
      mainMenuSaveSnapshotProvider.overrideWith(
        (ref) async => SaveData()..jianghuJourneyUnlocked = unlocked,
      ),
      activeGauntletProvider.overrideWith((ref) async => null),
      activeExpeditionProvider.overrideWith((ref) async => active),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  test('百草岭地点状态复用进行中与战败文案', () {
    expect(jianghuMapExpeditionStatus(null), isNull);
    expect(
      jianghuMapExpeditionStatus(activeRun()),
      UiStrings.expeditionActiveDepth(8),
    );
    expect(
      jianghuMapExpeditionStatus(activeRun(defeated: true)),
      UiStrings.expeditionDefeatedBanner,
    );
  });

  testWidgets('未解锁时江湖地图隐藏百草岭', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(unlocked: false));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.expeditionBaicaoName), findsNothing);
  });

  testWidgets('解锁后江湖地图显示百草岭地点', (tester) async {
    await tester.pumpWidget(app(unlocked: true));
    await tester.pump();
    await tester.pump();
    await revealExpeditionLocation(tester);

    expect(find.text(UiStrings.expeditionBaicaoName), findsOneWidget);
    expect(find.text(UiStrings.expeditionBaicaoSubtitle), findsOneWidget);
  });

  testWidgets('百草岭地点显示进行中远征深度', (tester) async {
    await tester.pumpWidget(app(unlocked: true, active: activeRun()));
    await tester.pump();
    await tester.pump();
    await revealExpeditionLocation(tester);

    expect(find.text(UiStrings.expeditionActiveDepth(8)), findsOneWidget);
  });

  testWidgets('百草岭地点先进入统一地点详情', (tester) async {
    await tester.pumpWidget(app(unlocked: true));
    await tester.pump();
    await tester.pump();
    await revealExpeditionLocation(tester);

    final button = tester.widget<WuxiaInkButton>(
      find.byKey(const ValueKey('jianghu-map-expedition-location')),
    );
    button.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ExpeditionLocationDetailScreen), findsOneWidget);
  });
}
