import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  TowerProgress progressAt(int highest) => TowerProgress()
    ..saveDataId = 0
    ..highestClearedFloor = highest;

  Widget app({int highest = 6}) => ProviderScope(
    overrides: [
      towerProgressProvider.overrideWith((ref) async => progressAt(highest)),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  test('九霄塔地点状态继续读取生产塔数据', () {
    expect(
      jianghuMapTowerStatus(progressAt(6)),
      UiStrings.mainMenuTowerBossStatus(6, 7),
    );
  });

  testWidgets('地图显示九霄塔地点与生产进度状态', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.jianghuMapTitle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTowerBossStatus(6, 7)), findsOneWidget);
  });

  testWidgets('九霄塔地点仍经生产入口进入 TowerFloorListScreen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuTower));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(TowerFloorListScreen), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('江湖地图 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
