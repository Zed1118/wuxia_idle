import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/battle/presentation/boss_phase_presentation.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/screen_flash.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  group('UiStrings.bossPhaseTitle', () {
    test('已知 key → 短水墨标题', () {
      expect(UiStrings.bossPhaseTitle('bossPhase_awaken'), '困兽之斗');
      expect(UiStrings.bossPhaseTitle('bossPhase_desperate'), '背水一击');
    });

    test('未知 / null key → 空串（交由调用方走 EnumL10n 兜底）', () {
      expect(UiStrings.bossPhaseTitle('nope_unknown_key'), '');
      expect(UiStrings.bossPhaseTitle(null), '');
    });
  });

  group('bossPhaseTitleFor 纯函数', () {
    BattleAction transitionAction({String? titleKey, int phase = 1}) =>
        BattleAction(
          tick: 5,
          actorId: 99,
          description: 'boss phase',
          bossPhaseTransitionTo: phase,
          bossPhaseTitleKey: titleKey,
        );

    test('有合法 titleKey → 用 UiStrings 映射', () {
      final title = bossPhaseTitleFor(
        transitionAction(titleKey: 'bossPhase_desperate'),
        '黑风寨主',
      );
      expect(title, '背水一击');
    });

    test('titleKey 为 null → 回落 EnumL10n.bossPhaseTransition', () {
      final action = transitionAction(titleKey: null, phase: 1);
      final title = bossPhaseTitleFor(action, '撑伞高人');
      expect(title, EnumL10n.bossPhaseTransition('撑伞高人', 1));
    });

    test('titleKey 未知 → 回落 EnumL10n.bossPhaseTransition', () {
      final action = transitionAction(titleKey: 'no_such_key', phase: 1);
      final title = bossPhaseTitleFor(action, '撑伞高人');
      expect(title, EnumL10n.bossPhaseTransition('撑伞高人', 1));
    });

    test('非转阶段动作（bossPhaseTransitionTo==null）→ 返回 null', () {
      const normal = BattleAction(
        tick: 1,
        actorId: 1,
        description: 'normal',
      );
      expect(bossPhaseTitleFor(normal, '某甲'), isNull);
    });
  });

  group('转阶段 overlay 通道（题字 + 闪白）', () {
    testWidgets('caption overlay show 4 字标题渲染且不抛异常', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final key = GlobalKey<UltimateCaptionOverlayState>();
      await tester.pumpWidget(MaterialApp(home: UltimateCaptionOverlay(key: key)));
      key.currentState!.show(
        UiStrings.bossPhaseTitle('bossPhase_desperate'),
        isEnemy: true,
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('背水一击'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('flash overlay 转阶段闪白后出 ColoredBox', (tester) async {
      final key = GlobalKey<ScreenFlashOverlayState>();
      await tester.pumpWidget(MaterialApp(home: ScreenFlashOverlay(key: key)));
      key.currentState!.flash(0.3);
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.descendant(
          of: find.byType(ScreenFlashOverlay),
          matching: find.byType(ColoredBox),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });
}
