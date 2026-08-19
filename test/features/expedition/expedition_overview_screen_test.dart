import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_overview_screen.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_recap_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_archive_chrome.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_title_bar.dart';

import '../../support/isar_test_support.dart';

class _FixedClock extends SystemClock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

Character _char(
  int id,
  String name, {
  TechniqueSchool? school,
  int? mainTechniqueId,
}) => Character()
  ..id = id
  ..name = name
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.qiMeng
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = LineageRole.disciple
  ..school = school
  ..createdAt = DateTime(2026, 7, 16)
  ..isFounder = false
  ..mainTechniqueId = mainTechniqueId;

ExpeditionCandidate _cand(
  Character c, {
  bool occupied = false,
  bool hasMain = true,
}) => ExpeditionCandidate(
  character: c,
  occupied: occupied,
  hasMainTechnique: hasMain,
);

const _config = ExpeditionConfig(
  normalNodeMinutes: 90,
  eliteNodeMinutes: 180,
  hpRecoverPctPerNode: 0.15,
  qiRecoverPctPerNode: 0.15,
  zhangshiPctPerLayer: 0.05,
);

Future<void> _pump(WidgetTester tester, Size size, ProviderScope app) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

ExpeditionRun _run({required int currentNode}) => ExpeditionRun()
  ..saveDataId = 0
  ..policy = ExpeditionPolicy.yiZhanLiXing
  ..seed = 1
  ..departedAt = DateTime(2026, 7, 16, 8)
  ..lastSettledAt = null
  ..currentNode = currentNode
  ..members = []
  ..stagedRewards = [];

void main() {
  setUpAll(() => initializeTestIsarCore());

  final dispatchCandidates = [
    _cand(_char(1, '沈青', school: TechniqueSchool.lingQiao)),
    _cand(_char(2, '楚河', school: TechniqueSchool.gangMeng), occupied: true),
    _cand(_char(3, '柳絮', school: TechniqueSchool.yinRou), hasMain: false),
  ];

  testWidgets('派遣态：候选/占用标/未修主修标/三方针/派遣按钮，1280×720 无溢出', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      ProviderScope(
        overrides: [
          activeExpeditionProvider.overrideWith((ref) async => null),
          expeditionCandidatesProvider.overrideWith(
            (ref) async => dispatchCandidates,
          ),
        ],
        child: const MaterialApp(home: ExpeditionOverviewScreen()),
      ),
    );

    expect(find.text(UiStrings.expeditionOverviewTitle), findsWidgets);
    expect(find.text(UiStrings.expeditionBaicaoName), findsOneWidget);
    expect(find.text('沈青'), findsOneWidget);
    expect(find.text('楚河'), findsOneWidget);
    expect(find.text('柳絮'), findsOneWidget);
    // 占用/未修主修标
    expect(find.text(UiStrings.expeditionCandidateOccupiedTag), findsOneWidget);
    expect(find.text(UiStrings.expeditionCandidateNoMainTag), findsOneWidget);
    // 三方针
    expect(
      find.text(EnumL10n.expeditionPolicy(ExpeditionPolicy.yanJingCaiYao)),
      findsOneWidget,
    );
    expect(
      find.text(EnumL10n.expeditionPolicy(ExpeditionPolicy.xunJiFangYou)),
      findsOneWidget,
    );
    expect(
      find.text(EnumL10n.expeditionPolicy(ExpeditionPolicy.yiZhanLiXing)),
      findsOneWidget,
    );
    expect(find.text(UiStrings.expeditionDispatchButton), findsOneWidget);
    expect(find.text(UiStrings.expeditionSelectedCount(0)), findsOneWidget);
    expect(find.byType(WuxiaTitleBar), findsOneWidget);
    expect(find.byType(InkPageHeader), findsOneWidget);
    expect(find.byType(InkSectionLabel), findsNWidgets(2));
    expect(find.byType(InkListCard), findsNWidgets(6));
    expect(
      tester
          .widgetList<PortraitFrame>(find.byType(PortraitFrame))
          .map((frame) => frame.placeholderText),
      containsAll(<String>['沈青', '楚河', '柳絮']),
      reason: '无立绘候选行必须有首字占位文本',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('派遣态：点可派遣者计数+1，点占用者不选', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      ProviderScope(
        overrides: [
          activeExpeditionProvider.overrideWith((ref) async => null),
          expeditionCandidatesProvider.overrideWith(
            (ref) async => dispatchCandidates,
          ),
        ],
        child: const MaterialApp(home: ExpeditionOverviewScreen()),
      ),
    );

    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.expeditionSelectedCount(1)), findsOneWidget);

    // 占用者点了不入选（仍为 1）。
    await tester.tap(find.text('楚河'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.expeditionSelectedCount(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('派遣态：无候选显空态引导', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      ProviderScope(
        overrides: [
          activeExpeditionProvider.overrideWith((ref) async => null),
          expeditionCandidatesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: ExpeditionOverviewScreen()),
      ),
    );
    expect(find.text(UiStrings.expeditionNoCandidates), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active 态：深度/完成节点/方针/召回，1440×900 无溢出', (tester) async {
    await _pump(
      tester,
      const Size(1440, 900),
      ProviderScope(
        overrides: [
          activeExpeditionProvider.overrideWith(
            (ref) async => _run(currentNode: 12),
          ),
          expeditionConfigProvider.overrideWithValue(_config),
          systemClockProvider.overrideWithValue(_FixedClock(_fixedNow)),
        ],
        child: const MaterialApp(home: ExpeditionOverviewScreen()),
      ),
    );

    expect(find.text(UiStrings.expeditionActiveDepth(12)), findsOneWidget);
    expect(find.text(UiStrings.expeditionActiveCompleted(12)), findsOneWidget);
    expect(
      find.textContaining(
        EnumL10n.expeditionPolicy(ExpeditionPolicy.yiZhanLiXing),
      ),
      findsWidgets,
    );
    expect(find.text(UiStrings.expeditionRecallButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active 态：召回 returned:false（并发冲突/无 run）→ 提示重试，不跳假 recap', (
    tester,
  ) async {
    // 07-22 收账挂账（低）：recall 被 cursor 守卫放弃时 UI 曾按空结果直跳
    // recap = 假行记。修复后应 SnackBar 提示重试、停留本屏。
    // 用真 service + 空 Isar（无持久化 run）走 returned:false 同一出口。
    // dart:io / Isar 全收进 runAsync 真时钟区（fake 区直接 await 真 IO 会挂；
    // 沿 gauntlet_entry_flow 体例）。
    Directory? tempDir;
    addTearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (tempDir != null && tempDir!.existsSync()) {
        tempDir!.deleteSync(recursive: true);
      }
    });
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'wuxia_expedition_overview_',
      );
      await IsarSetup.init(directory: tempDir!, inspector: false);
    });

    Future<void> pumpUntilFound(Finder finder) async {
      for (var i = 0; i < 160; i++) {
        if (finder.evaluate().isNotEmpty) return;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      fail('未等到目标组件：$finder');
    }

    var activeReads = 0;
    await _pump(
      tester,
      const Size(1440, 900),
      ProviderScope(
        overrides: [
          activeExpeditionProvider.overrideWith((ref) async {
            activeReads++;
            return _run(currentNode: 12);
          }),
          expeditionConfigProvider.overrideWithValue(_config),
          systemClockProvider.overrideWithValue(_FixedClock(_fixedNow)),
          expeditionServiceProvider.overrideWithValue(
            ExpeditionService(IsarSetup.instance),
          ),
          // Isar 已 init 时 candidates provider 会真查库（fake 区会挂），一并覆写。
          expeditionCandidatesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: ExpeditionOverviewScreen()),
      ),
    );

    await tester.tap(find.text(UiStrings.expeditionRecallButton));
    await tester.pump();
    await pumpUntilFound(find.text(UiStrings.expeditionRecallConfirm));
    await tester.tap(find.text(UiStrings.expeditionRecallConfirm));
    await pumpUntilFound(find.text(UiStrings.expeditionRecallRacedSnack));

    expect(find.byType(ExpeditionRecapScreen), findsNothing, reason: '不得跳假行记');
    expect(find.text(UiStrings.expeditionRecallButton), findsOneWidget);
    expect(
      activeReads,
      greaterThan(1),
      reason: 'returned:false 后须 invalidate active provider 重读（防 stale 在途态）',
    );
    expect(tester.takeException(), isNull);
  });
}

// 出发 08:00 + 完成 12 节点，13 节点在途，固定 now 落在其间。
final DateTime _fixedNow = DateTime(2026, 7, 16, 8, 30);
