import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_ui.dart';

import '../../support/test_data.dart';

/// C2.5 断魂庄装载屏（§7.1）：帖库存 / 三关 Boss + 推荐境界 / 择人 1-3 / 补给装载 /
/// 持帖入庄。1280×720 与 1440×900 一屏无溢出。config 用真 GameRepository（三敌名真值）。
Character _char(
  int id,
  String name, {
  TechniqueSchool? school,
  int? mainTechniqueId,
}) => Character()
  ..id = id
  ..name = name
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.jingTong
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = LineageRole.disciple
  ..school = school
  ..createdAt = DateTime(2026, 7, 17)
  ..isFounder = false
  ..mainTechniqueId = mainTechniqueId;

GauntletCandidate _cand(
  Character c, {
  bool occupied = false,
  bool hasMain = true,
}) => GauntletCandidate(
  character: c,
  occupied: occupied,
  hasMainTechnique: hasMain,
);

const _info = GauntletLoadoutInfo(
  ticketCount: 2,
  supplies: [
    GauntletSupplyOption(defId: 'item_liaoshangdan', name: '疗伤丹', owned: 3),
    GauntletSupplyOption(defId: 'item_xingnang_buji', name: '行囊补给', owned: 2),
  ],
);

const _noTicketInfo = GauntletLoadoutInfo(
  ticketCount: 0,
  supplies: [
    GauntletSupplyOption(defId: 'item_liaoshangdan', name: '疗伤丹', owned: 1),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  required List<GauntletCandidate> candidates,
  GauntletLoadoutInfo info = _info,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gauntletCandidatesProvider.overrideWith((ref) async => candidates),
        gauntletLoadoutInfoProvider.overrideWith((ref) async => info),
      ],
      child: const MaterialApp(home: GauntletLoadoutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  final candidates = [
    _cand(_char(1, '沈青', school: TechniqueSchool.lingQiao)),
    _cand(_char(2, '楚河', school: TechniqueSchool.gangMeng), occupied: true),
    _cand(_char(3, '柳絮', school: TechniqueSchool.yinRou), hasMain: false),
  ];

  testWidgets('装载屏：帖库存/三关Boss/推荐境界/候选/补给/入庄，1280×720 无溢出', (tester) async {
    await _pump(tester, const Size(1280, 720), candidates: candidates);

    expect(find.text(UiStrings.gauntletName), findsWidgets);
    expect(find.text(UiStrings.gauntletTicket(2)), findsOneWidget);
    // 三关 Boss（真 config 名值）。
    expect(find.text('苏无咎'), findsOneWidget);
    expect(find.text('石镇岳'), findsOneWidget);
    expect(find.text('闻九针'), findsOneWidget);
    // 候选门人 + 标签。
    expect(find.text('沈青'), findsOneWidget);
    expect(find.text(UiStrings.gauntletCandidateOccupiedTag), findsOneWidget);
    expect(find.text(UiStrings.gauntletCandidateNoMainTag), findsOneWidget);
    // 补给两类。
    expect(find.text('疗伤丹'), findsOneWidget);
    expect(find.text('行囊补给'), findsOneWidget);
    expect(find.text(UiStrings.gauntletEnterButton), findsOneWidget);
    expect(find.text(UiStrings.gauntletSelectedCount(0)), findsOneWidget);
    expect(
      tester
          .widgetList<PortraitFrame>(find.byType(PortraitFrame))
          .map((frame) => frame.placeholderText),
      containsAll(<String>['沈青', '楚河', '柳絮']),
      reason: '无立绘候选行必须有首字占位文本',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：1440×900 无溢出', (tester) async {
    await _pump(tester, const Size(1440, 900), candidates: candidates);
    expect(find.text(UiStrings.gauntletName), findsWidgets);
    expect(find.text(UiStrings.gauntletEnterButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：点可入庄者计数+1，点占用者不选', (tester) async {
    await _pump(tester, const Size(1280, 720), candidates: candidates);

    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSelectedCount(1)), findsOneWidget);

    await tester.tap(find.text('楚河')); // 占用者
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSelectedCount(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：补给 + 号装载份数 0→1（预算更新）', (tester) async {
    await _pump(tester, const Size(1280, 720), candidates: candidates);

    expect(find.text(UiStrings.gauntletSupplyBudget(0, 3)), findsOneWidget);
    // 补给步进在滚动视口折叠线下，先滚入再点（否则裁剪区 tap 落空）。
    final addBtn = find.widgetWithIcon(InkWell, Icons.add).first;
    await tester.ensureVisible(addBtn);
    await tester.pumpAndSettle();
    await tester.tap(addBtn);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSupplyBudget(1, 3)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：无断魂帖 → 入庄按钮禁用 + 提示', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      candidates: candidates,
      info: _noTicketInfo,
    );

    expect(find.text(UiStrings.gauntletNoTicketHint), findsOneWidget);
    // 选一人后按钮仍禁用（无帖）。
    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    final button = tester.widget<PlaqueButton>(
      find.byWidgetPredicate(
        (w) => w is PlaqueButton && w.label == UiStrings.gauntletEnterButton,
      ),
    );
    expect(button.onTap, isNull, reason: '无帖 → 入庄禁用');
    expect(tester.takeException(), isNull);
  });
}
