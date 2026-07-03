import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/presentation/damage_popup.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// damage_popup widget 测试(P1.1 候选 3-c sword_song 浮字)。
///
/// 覆盖:
/// - 普通 popup → 不显 ✦剑鸣 / 不显 counter
/// - critical + hasSwordSong=true → 显 ✦剑鸣
/// - critical 但 hasSwordSong=false → 不显 ✦剑鸣
/// - counter + swordSong 共存(都显)
void main() {
  Future<void> pumpPopup(WidgetTester tester, DamagePopupData data) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DamagePopup(
            data: data,
            config: AnimationNumbers.defaults,
            onComplete: () {},
          ),
        ),
      ),
    );
    // 不 pumpAndSettle:popup 会自动 forward 600ms 后 fade 消失,会让 expect 失败
    await tester.pump();
  }

  testWidgets('普通伤害 → 不显 ✦剑鸣 / 不显 counter', (tester) async {
    await pumpPopup(
        tester,
        const DamagePopupData(
          id: 1,
          text: '1500',
          type: PopupType.normal,
        ));
    expect(find.text('1500'), findsOneWidget);
    expect(find.text(UiStrings.swordSongHint), findsNothing);
    expect(find.text(UiStrings.counterUp), findsNothing);
  });

  testWidgets('暴击 + hasSwordSong=true → 显 ✦剑鸣', (tester) async {
    await pumpPopup(
        tester,
        const DamagePopupData(
          id: 1,
          text: '4500',
          type: PopupType.critical,
          hasSwordSong: true,
        ));
    expect(find.text('4500'), findsOneWidget);
    expect(find.text(UiStrings.swordSongHint), findsOneWidget);
  });

  testWidgets('暴击 + hasSwordSong=false → 不显 ✦剑鸣', (tester) async {
    await pumpPopup(
        tester,
        const DamagePopupData(
          id: 1,
          text: '4500',
          type: PopupType.critical,
          hasSwordSong: false,
        ));
    expect(find.text('4500'), findsOneWidget);
    expect(find.text(UiStrings.swordSongHint), findsNothing);
  });

  testWidgets('counter + swordSong 同时显', (tester) async {
    await pumpPopup(
        tester,
        const DamagePopupData(
          id: 1,
          text: '4500',
          type: PopupType.critical,
          hasCounterUp: true,
          hasSwordSong: true,
        ));
    expect(find.text(UiStrings.counterUp), findsOneWidget);
    expect(find.text(UiStrings.swordSongHint), findsOneWidget);
  });

  // durationMsOverride 消费:快档 clamp 后的短时长真替代 config.damagePopupMs(700)。
  testWidgets('durationMsOverride 非空 → 按覆写时长结束(短于配置默认)', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DamagePopup(
            data: const DamagePopupData(id: 1, text: '500', type: PopupType.normal),
            config: AnimationNumbers.defaults, // damagePopupMs = 700
            durationMsOverride: 200,
            onComplete: () => done = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(done, isFalse, reason: '200ms 覆写时长未到,不应结束');
    await tester.pump(const Duration(milliseconds: 100)); // 累计 250ms > 200
    expect(done, isTrue, reason: '超覆写 200ms 应结束(证明用的是覆写非默认 700)');
  });

  testWidgets('durationMsOverride 为 null → 走配置默认 700(250ms 未结束)', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DamagePopup(
            data: const DamagePopupData(id: 1, text: '500', type: PopupType.normal),
            config: AnimationNumbers.defaults,
            onComplete: () => done = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(done, isFalse, reason: '默认 700ms 下 250ms 不应结束(对照组)');
    await tester.pump(const Duration(milliseconds: 500)); // 累计 750 > 700 收尾
  });

  testWidgets('闪避 popup → 文本为闪避 + 无 ✦剑鸣 / 无 counter', (tester) async {
    await pumpPopup(
        tester,
        const DamagePopupData(
          id: 1,
          text: UiStrings.dodge,
          type: PopupType.dodge,
        ));
    expect(find.text(UiStrings.dodge), findsOneWidget);
    expect(find.text(UiStrings.swordSongHint), findsNothing);
  });
}
