import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_reward_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// #1 wiring Task 2 断魂庄通关三选一奖励屏（spec §3.3）：读 run 奖励候选出三件装备卡，
/// 首通/重复标；点选弹择取确认 → chooseReward。1280×720 与 1440×900 一屏无溢出。
/// 测走 override view provider 注入纯 DTO（无 Isar），service==null 旁路动作（同 C2.5
/// 整备屏体例）。
const _candidates = [
  GauntletRewardCandidate(
    defId: 'equip_a',
    name: '玄铁重剑',
    tier: EquipmentTier.shenWu,
    slot: EquipmentSlot.weapon,
    attackMin: 1800,
    attackMax: 2000,
    healthMin: 0,
    healthMax: 0,
    speedMin: 0,
    speedMax: 0,
  ),
  GauntletRewardCandidate(
    defId: 'equip_b',
    name: '软猬软甲',
    tier: EquipmentTier.shenWu,
    slot: EquipmentSlot.armor,
    attackMin: 0,
    attackMax: 0,
    healthMin: 3000,
    healthMax: 3500,
    speedMin: 0,
    speedMax: 0,
  ),
  GauntletRewardCandidate(
    defId: 'equip_c',
    name: '踏雪无痕',
    tier: EquipmentTier.shenWu,
    slot: EquipmentSlot.accessory,
    attackMin: 0,
    attackMax: 0,
    healthMin: 0,
    healthMax: 0,
    speedMin: 40,
    speedMax: 60,
  ),
];

const _viewFirstClear = GauntletRewardView(
  participantName: '入场弟子',
  isFirstClear: true,
  candidates: _candidates,
);

const _viewRepeat = GauntletRewardView(
  participantName: '当代掌门',
  isFirstClear: false,
  candidates: _candidates,
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  GauntletRewardView? view = _viewFirstClear,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gauntletRewardViewProvider.overrideWith((ref) async => view)],
      child: const MaterialApp(home: GauntletRewardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('奖励屏：三候选卡 + 首通标 + tier/slot，1280×720 无溢出', (tester) async {
    await _pump(tester, const Size(1280, 720));

    expect(find.text('玄铁重剑'), findsOneWidget);
    expect(find.text('软猬软甲'), findsOneWidget);
    expect(find.text('踏雪无痕'), findsOneWidget);
    expect(
      find.text(UiStrings.gauntletRewardParticipant('入场弟子')),
      findsOneWidget,
      reason: '胜利报告必须说明实际参战者',
    );
    // 首通标（非重复）。
    expect(find.text(UiStrings.gauntletRewardFirstClearBadge), findsOneWidget);
    expect(find.text(UiStrings.gauntletRewardRepeatBadge), findsNothing);
    // tier 标（神物·武器 等）。
    expect(
      find.textContaining(EnumL10n.equipmentTier(EquipmentTier.shenWu)),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：1440×900 无溢出，三卡在场', (tester) async {
    await _pump(tester, const Size(1440, 900));
    expect(find.text('玄铁重剑'), findsOneWidget);
    expect(find.text('踏雪无痕'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：重复通关标（减半）', (tester) async {
    await _pump(tester, const Size(1280, 720), view: _viewRepeat);
    expect(find.text(UiStrings.gauntletRewardRepeatBadge), findsOneWidget);
    expect(find.text(UiStrings.gauntletRewardFirstClearBadge), findsNothing);
    expect(
      find.text(UiStrings.gauntletRewardParticipant('当代掌门')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：无待领奖励（view=null）→ 空态，不显卡', (tester) async {
    await _pump(tester, const Size(1280, 720), view: null);
    expect(find.text('玄铁重剑'), findsNothing);
    expect(find.text(UiStrings.gauntletRewardFirstClearBadge), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：点候选卡弹择取确认框，确认不崩（service 旁路）', (tester) async {
    await _pump(tester, const Size(1280, 720));
    await tester.tap(find.text('玄铁重剑'));
    await tester.pumpAndSettle();
    // 择取确认框标题在场。
    expect(find.text(UiStrings.gauntletRewardConfirmTitle), findsWidgets);
    // service==null 旁路：确认后不崩（chooseReward 不实际触发）。
    await tester.tap(find.text(UiStrings.gauntletRewardConfirm));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：未择取时系统返回/maybePop 不出栈（PopScope 拦弃栈）', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // 奖励屏压在 home 之上（弃栈即回落 home，可观测）。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gauntletRewardViewProvider.overrideWith(
            (ref) async => _viewFirstClear,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const GauntletRewardScreen(),
                    ),
                  ),
                  child: const Text('open-reward'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-reward'));
    await tester.pumpAndSettle();
    expect(find.text('玄铁重剑'), findsOneWidget);

    // 系统返回（popRoute）→ PopScope(canPop:false) 拦，不出栈。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('玄铁重剑'), findsOneWidget, reason: '未择取 → 系统返回不出栈');
    expect(find.text('open-reward'), findsNothing);

    // maybePop 同样被拦（doNotPop 视为已处理，路由不动）。
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('玄铁重剑'), findsOneWidget, reason: '未择取 → maybePop 不出栈');
    expect(find.text('open-reward'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
