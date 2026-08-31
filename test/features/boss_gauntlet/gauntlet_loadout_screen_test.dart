import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_ui.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2.5 断魂庄装载屏（§7.1）：帖库存 / 三关 Boss + 推荐境界 / 单人选择 / 补给装载 /
/// 持帖入庄。1280×720 与 1440×900 一屏无溢出。config 用真 GameRepository（三敌名真值）。
Character _char(
  int id,
  String name, {
  TechniqueSchool? school,
  int? mainTechniqueId,
  bool isFounder = false,
}) => Character()
  ..id = id
  ..name = name
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.jingTong
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = isFounder ? LineageRole.founder : LineageRole.disciple
  ..school = school
  ..createdAt = DateTime(2026, 7, 17)
  ..isFounder = isFounder
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

const _clearedInfo = GauntletLoadoutInfo(
  ticketCount: 2,
  supplies: [],
  clearedCyclesMax: 1,
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  required List<GauntletCandidate> candidates,
  GauntletLoadoutInfo info = _info,
  BossGauntletRun? activeRun,
  GauntletService? service,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (service != null)
          gauntletServiceProvider.overrideWith((ref) => service),
        gauntletCandidatesProvider.overrideWith((ref) async => candidates),
        gauntletLoadoutInfoProvider.overrideWith((ref) async => info),
        activeGauntletProvider.overrideWith((ref) async => activeRun),
      ],
      child: const MaterialApp(home: GauntletLoadoutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// 纯 DTO 假会话（override activeGauntletProvider 用，不走 Isar）。
BossGauntletRun _fakeRun({required GauntletPhase phase, int stage = 2}) =>
    BossGauntletRun()
      ..saveDataId = 0
      ..seed = 0
      ..currentStage = stage
      ..sessionPhase = phase;

class _SpyGauntletService extends GauntletService {
  _SpyGauntletService(super.isar);

  List<int>? enteredCharacterIds;
  ActivityParticipationRequest? entryAutomationRequest;
  ActivityParticipationRequest? driveAutomationRequest;

  @override
  Future<int> enter({
    required List<int> characterIds,
    Map<String, int> supplies = const {},
    required int supplyCap,
    int cycleIndex = 1,
    ActivityParticipationRequest? automationRequest,
  }) async {
    enteredCharacterIds = List.of(characterIds);
    entryAutomationRequest = automationRequest;
    return 77;
  }

  @override
  Future<GauntletAutomationDriveResult> driveHeadlessReplayToRewardChoice({
    required ActivityParticipationRequest request,
    required BossGauntletConfig config,
    required NumbersConfig numbers,
  }) async {
    driveAutomationRequest = request;
    return const GauntletAutomationDriveResult(
      terminal: GauntletAutomationDriveTerminal.awaitingRewardChoice,
      stagesCompleted: 3,
    );
  }

  @override
  Future<BossGauntletRun?> activeRun() async => null;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_loadout_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
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
    expect(find.byType(WuxiaTitleBar), findsOneWidget);
    expect(find.byType(InkPageHeader), findsOneWidget);
    expect(find.byType(InkSectionLabel), findsWidgets);
    expect(find.byType(InkListCard), findsWidgets);
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

  testWidgets('装载屏：空闲当前掌门候选可被真实择一交互选中', (tester) async {
    final leader = _cand(_char(9, '当代掌门', mainTechniqueId: 9, isFounder: true));
    await _pump(tester, const Size(1280, 720), candidates: [leader]);

    await tester.tap(find.text('当代掌门'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSelectedCount(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('路线 C 装载屏只允许选一名弟子', (tester) async {
    final selectable = [
      _cand(_char(1, '沈青', school: TechniqueSchool.lingQiao)),
      _cand(_char(2, '楚河', school: TechniqueSchool.gangMeng)),
    ];
    await _pump(tester, const Size(1280, 720), candidates: selectable);

    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('楚河'));
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

  testWidgets('装载屏：无 active 会话 → 不显恢复区（新建 UI 原样）', (tester) async {
    await _pump(tester, const Size(1280, 720), candidates: candidates);

    expect(find.text(UiStrings.gauntletResumeTitle), findsNothing);
    expect(find.text(UiStrings.gauntletResumeButton), findsNothing);
    // 择人交互可用（点可入庄者计数 +1）。
    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSelectedCount(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('完整首通后生产整备入口才开放快速推演', (tester) async {
    await _pump(tester, const Size(1280, 720), candidates: candidates);
    expect(
      find.text(UiStrings.mainlineHeadlessReplayMode),
      findsNothing,
      reason: '首次通关必须保持真人亲战',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pump(
      tester,
      const Size(1280, 720),
      candidates: candidates,
      info: _clearedInfo,
    );
    expect(find.text(UiStrings.mainlineHeadlessReplayMode), findsOneWidget);
    final button = tester.widget<PlaqueButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is PlaqueButton &&
            widget.label == UiStrings.mainlineHeadlessReplayMode,
      ),
    );
    expect(button.onTap, isNull, reason: '未选择实际参与者时必须 fail closed');
  });

  testWidgets('快速推演从生产整备页提交 exact participant 的 headless replay', (
    tester,
  ) async {
    final service = _SpyGauntletService(IsarSetup.instance);
    await _pump(
      tester,
      const Size(1280, 720),
      candidates: candidates,
      info: _clearedInfo,
      service: service,
    );
    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    final quickButton = find.byWidgetPredicate(
      (widget) =>
          widget is PlaqueButton &&
          widget.label == UiStrings.mainlineHeadlessReplayMode,
    );
    await tester.ensureVisible(quickButton);
    await tester.tap(quickButton);
    await tester.pumpAndSettle();

    expect(service.enteredCharacterIds, [1]);
    expect(
      service.entryAutomationRequest,
      same(service.driveAutomationRequest),
      reason: '扣帖前准入与实际推演必须复用同一请求快照',
    );
    final request = service.driveAutomationRequest!;
    expect(request.contentKind, ActivityContentKind.gauntlet);
    expect(request.contentId, GauntletService.gauntletId);
    expect(request.characterId, 1);
    expect(request.loadoutPlanId, 'gauntlet-plan-1');
    expect(request.participation, ActivityParticipationMode.direct);
    expect(request.controller, ActivityController.playerBot);
    expect(request.clock, ActivityClock.headless);
    expect(request.entryKind, ActivityEntryKind.replay);
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：有 active 会话（interlude）→ 恢复区显示 + 新建交互禁用', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      candidates: candidates,
      activeRun: _fakeRun(phase: GauntletPhase.interlude, stage: 2),
    );

    // 恢复区：标题 + 第几关/相位 + 续战按钮。
    expect(find.text(UiStrings.gauntletResumeTitle), findsOneWidget);
    expect(
      find.text(
        UiStrings.gauntletResumeHint(2, UiStrings.gauntletPhaseInterlude),
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.gauntletResumeButton), findsOneWidget);

    // 择人禁用：点可入庄者不计数。
    await tester.tap(find.text('沈青'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSelectedCount(0)), findsOneWidget);

    // 补给步进禁用：滚入点 + 号预算不动。
    final addBtn = find.widgetWithIcon(InkWell, Icons.add).first;
    await tester.ensureVisible(addBtn);
    await tester.pumpAndSettle();
    await tester.tap(addBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletSupplyBudget(0, 3)), findsOneWidget);

    // 新建入庄按钮禁用（P0 回归：不再走「入庄受阻」SnackBar 路径）。
    final enterButton = tester.widget<PlaqueButton>(
      find.byWidgetPredicate(
        (w) => w is PlaqueButton && w.label == UiStrings.gauntletEnterButton,
      ),
    );
    expect(enterButton.onTap, isNull, reason: '有 active 会话 → 新建入庄禁用');
    await tester.ensureVisible(find.text(UiStrings.gauntletEnterButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(UiStrings.gauntletEnterButton),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletEnterFailed), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('装载屏：续战态帖已耗 → 不显无帖提示', (tester) async {
    await _pump(
      tester,
      const Size(1280, 720),
      candidates: candidates,
      info: _noTicketInfo,
      activeRun: _fakeRun(phase: GauntletPhase.inBattle, stage: 1),
    );

    expect(find.text(UiStrings.gauntletResumeTitle), findsOneWidget);
    expect(find.text(UiStrings.gauntletNoTicketHint), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
