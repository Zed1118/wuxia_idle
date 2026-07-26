import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  RetreatSession fakeSession({DateTime? startedAt}) => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..realmTierAtStart = RealmTier.xueTu
    ..startedAt = startedAt ?? DateTime.now()
    ..status = RetreatStatus.active;

  Future<void> pumpActive(
    WidgetTester tester, {
    DateTime? startedAt,
    Size size = const Size(1280, 720),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mapDef = GameRepository.instance.getSeclusionMap(
      RetreatMapType.shanLin,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveRetreatScreen(
                      session: fakeSession(startedAt: startedAt),
                      mapDef: mapDef,
                      characterId: 1,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('闭关屏有返回按钮', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('闭关中状态牌显示地点、时长与预计收获类型', (tester) async {
    await pumpActive(tester);
    final mapDef = GameRepository.instance.getSeclusionMap(
      RetreatMapType.shanLin,
    );

    expect(find.text(UiStrings.activeRetreatStatusCardTitle), findsOneWidget);
    expect(
      find.text(UiStrings.activeRetreatStatusLocation(mapDef.mapName)),
      findsOneWidget,
    );
    expect(find.textContaining('已闭关：'), findsWidgets);
    expect(find.text(UiStrings.activeRetreatPlannedHours(4)), findsNothing);
    expect(
      find.text(
        UiStrings.activeRetreatEquipmentRolls(
          0,
          GameRepository.instance.numbers.retreat.equipmentRollMaxCount,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.activeRetreatExpectedTypes), findsOneWidget);
    expect(
      find.textContaining(UiStrings.activeRetreatRewardMojianshi),
      findsWidgets,
    );
    expect(
      find.textContaining(UiStrings.activeRetreatRewardExperience),
      findsWidgets,
    );
  });

  testWidgets('Esc 退出闭关屏', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ActiveRetreatScreen), findsNothing);
  });

  testWidgets('Enter 打开收功确认', (tester) async {
    await pumpActive(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.activeRetreatConfirmTitle), findsOneWidget);
  });

  testWidgets('10 天闭关在 1440×900 显示 72h 圆满与 168h 挂机接续', (tester) async {
    await pumpActive(
      tester,
      startedAt: DateTime.now().subtract(const Duration(days: 10)),
      size: const Size(1440, 900),
    );

    expect(find.text(UiStrings.activeRetreatFullRateComplete), findsWidgets);
    expect(
      find.text(
        UiStrings.activeRetreatPassiveOverflow(UiStrings.compactHours(168.0)),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.activeRetreatEquipmentRolls(6, 6)),
      findsWidgets,
    );
    final completionLabels = tester
        .widgetList<Text>(find.text(UiStrings.activeRetreatFullRateComplete))
        .where((text) => text.style?.color == WuxiaUi.goldOnPaper);
    expect(completionLabels, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}
