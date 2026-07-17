import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_interlude_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// C2.5 断魂庄整备屏（§7.2）：三成员生命/真气/阵亡/冷却 + 托管补给剩余 + 使用/继续/
/// 认输。1280×720 与 1440×900 一屏内完成主要决策（底部动作栏固定恒可见）。
const _view = GauntletInterludeView(
  stage: 2,
  members: [
    GauntletMemberView(
      characterId: 1,
      name: '沈青',
      currentHp: 3200,
      maxHp: 5000,
      currentQi: 60,
      maxQi: 100,
      downed: false,
      cooldownCount: 1,
    ),
    GauntletMemberView(
      characterId: 2,
      name: '楚河',
      currentHp: 0,
      maxHp: 4800,
      currentQi: 0,
      maxQi: 100,
      downed: true,
      cooldownCount: 0,
    ),
  ],
  supplies: [
    GauntletSupplyRemainView(
      index: 0,
      defId: 'item_liaoshangdan',
      name: '疗伤丹',
      remaining: 1,
      isHeal: true,
    ),
    GauntletSupplyRemainView(
      index: 1,
      defId: 'item_xingnang_buji',
      name: '行囊补给',
      remaining: 0,
      isHeal: false,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  GauntletInterludeView? view = _view,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gauntletInterludeViewProvider.overrideWith((ref) async => view),
      ],
      child: const MaterialApp(home: GauntletInterludeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('整备屏：关次/成员生命真气/阵亡·冷却标/补给余量/三动作，1280×720 无溢出', (tester) async {
    await _pump(tester, const Size(1280, 720));

    expect(find.text(UiStrings.gauntletInterludeSection(2)), findsOneWidget);
    expect(find.text('沈青'), findsOneWidget);
    expect(find.text('楚河'), findsOneWidget);
    // 阵亡标（楚河）+ 冷却标（沈青 1 招）。
    expect(find.text(UiStrings.gauntletMemberDownedTag), findsOneWidget);
    expect(find.text(UiStrings.gauntletMemberCooldownTag(1)), findsOneWidget);
    // 生命/真气行。
    expect(
      find.textContaining(UiStrings.gauntletMemberHp(3200, 5000)),
      findsOneWidget,
    );
    // 补给：疗伤丹余 1（可用）+ 行囊补给余 0（已用尽）。
    expect(find.text(UiStrings.gauntletSupplyRemain('疗伤丹', 1)), findsOneWidget);
    expect(find.text(UiStrings.gauntletSupplyUseButton), findsOneWidget);
    expect(find.text(UiStrings.gauntletSupplyExhausted), findsOneWidget);
    // 三动作（继续/认输固定可见）。
    expect(find.text(UiStrings.gauntletContinueButton), findsOneWidget);
    expect(find.text(UiStrings.gauntletConcedeButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('整备屏：1440×900 无溢出，继续/认输恒可见', (tester) async {
    await _pump(tester, const Size(1440, 900));
    expect(find.text(UiStrings.gauntletContinueButton), findsOneWidget);
    expect(find.text(UiStrings.gauntletConcedeButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('整备屏：无 active interlude（view=null）→ 空态，不显动作', (tester) async {
    await _pump(tester, const Size(1280, 720), view: null);
    expect(find.text(UiStrings.gauntletContinueButton), findsNothing);
    expect(find.text(UiStrings.gauntletConcedeButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('整备屏：点认输离庄弹确认框（含结算说明）', (tester) async {
    await _pump(tester, const Size(1280, 720));
    await tester.tap(find.text(UiStrings.gauntletConcedeButton));
    await tester.pumpAndSettle();
    // 确认框标题 + 结算说明文案。
    expect(find.text(UiStrings.gauntletConcedeConfirmTitle), findsWidgets);
    expect(find.text(UiStrings.gauntletConcedeConfirmBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
