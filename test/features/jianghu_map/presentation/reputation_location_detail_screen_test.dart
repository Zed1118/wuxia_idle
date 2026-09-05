import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu/application/jianghu_providers.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/jianghu/presentation/reputation_panel_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/application/reputation_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/reputation_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/reputation_location_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

void main() {
  ReputationLocationDetail detail() => const ReputationLocationDetail(
    factions: [
      ReputationLocationFactionSummary(
        id: 'shaolin',
        name: '少林寺',
        alignment: 'orthodox',
        value: 50,
        tier: 'zongShi',
        tierLabel: '声振江湖',
      ),
      ReputationLocationFactionSummary(
        id: 'wudang',
        name: '武当派',
        alignment: 'orthodox',
        value: null,
        tier: null,
        tierLabel: null,
      ),
    ],
    tiers: [
      ReputationLocationTierSummary(
        tier: 'xueTu',
        label: '声名狼藉',
        min: -100,
        max: -71,
      ),
      ReputationLocationTierSummary(
        tier: 'wuSheng',
        label: '天下闻名',
        min: 71,
        max: 100,
      ),
    ],
    stageBossKillDelta: 5,
    stageBossKillRivalDelta: 3,
    encounterNpcDeltaMin: -8,
    encounterNpcDeltaMax: 8,
  );

  Widget app({
    ReputationLocationDetail? value,
    bool error = false,
    Size size = const Size(1280, 720),
  }) => ProviderScope(
    overrides: [
      reputationLocationDetailProvider.overrideWith(
        (ref) => error
            ? Future<ReputationLocationDetail>.error(StateError('broken'))
            : Future.value(value ?? detail()),
      ),
      reputationsForCurrentPlayerProvider.overrideWith(
        (ref) async => const <Reputation>[],
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(home: ReputationLocationDetailScreen()),
    ),
  );

  testWidgets('paper labels use readable ink contrast', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.text(UiStrings.reputationLocationOverviewLabel))
          .style
          ?.color,
      WuxiaUi.muted,
    );
  });

  testWidgets('展示生产门派、稀疏声望、七阶与变化来源', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.reputationLocationDetailTitle), findsOneWidget);
    expect(find.textContaining('少林寺'), findsOneWidget);
    expect(find.textContaining('武当派'), findsOneWidget);
    expect(find.textContaining('声振江湖'), findsOneWidget);
    expect(
      find.textContaining(UiStrings.reputationLocationUnrecorded),
      findsOneWidget,
    );
    expect(find.textContaining('声名狼藉'), findsOneWidget);
    expect(find.textContaining('天下闻名'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reputation-location-detail-enter')),
      findsOneWidget,
    );
  });

  testWidgets('错误态 fail closed 且无进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reputation-location-detail-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reputation-location-detail-enter')),
      findsNothing,
    );
  });

  testWidgets('详情 CTA 仍进入原声望面板', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    final button = tester.widget<WuxiaInkButton>(
      find.byKey(const ValueKey('reputation-location-detail-enter')),
    );
    button.onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ReputationPanelScreen), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      '常规视口 ${size.width.toInt()}x${size.height.toInt()} 无 overflow',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(app(size: size));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(ReputationLocationDetailScreen), findsOneWidget);
      },
    );
  }
}
