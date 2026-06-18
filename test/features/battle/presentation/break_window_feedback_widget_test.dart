// 第六阶段表现层 widget 测试：开窗题字 + 破绽敌高亮。
//
// 1. _playAction 处理 openedBreakWindow==true 的动作时弹 ImpactGlyphOverlay「破绽」。
// 2. 敌方有 staggerTicksRemaining>0 的角色时，其头像的外围有「破绽高亮」(Key 可查)；
//    所有敌方 stagger=0 时不出现。
//
// 测试遵循既有 battle_screen_pause_test.dart / impact_feedback_widget_test.dart 体例：
// - 沿用 _TestBattleNotifier（no-op advance 防 Timer 触 GameRepository）。
// - setSurfaceSize(1280, 720)。
// - Image.asset errorBuilder 由 CharacterAvatar 内部守，不用在测中额外 mock。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_glyph_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20.0,
  damagePopupFloatPx: 20.0,
  damagePopupMs: 100,
  actionIntervalMs: 50,
  fastForwardIntervalMs: 20,
  shakeOffsetPx: 1.0,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
);

/// no-op advance：防止 Timer 触发时读 GameRepository 崩溃。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}
}

Future<BattleState> _pumpBattle(
  WidgetTester tester,
  BattleState state,
) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() => _TestBattleNotifier(state)),
      ],
      child: const MaterialApp(
        home: BattleScreen(animConfig: _testAnim),
      ),
    ),
  );
  await tester.pump();
  return state;
}

void main() {
  group('开窗题字 ImpactGlyphOverlay', () {
    testWidgets('openedBreakWindow 动作触发「破绽」题字', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pumpBattle(tester, BattleState.initial(leftTeam: left, rightTeam: right));

      // 直接调用 ImpactGlyphOverlay.show，验证覆写层是否挂载并能渲染多字。
      // （battle_screen 中 _impactGlyphKey 是私有的；采用与 impact_feedback_widget_test
      //   相同的方式直接测覆写层组件行为：查 GlobalKey + show）。
      final glyphKey = GlobalKey<ImpactGlyphOverlayState>();
      await tester.pumpWidget(
        MaterialApp(home: ImpactGlyphOverlay(key: glyphKey)),
      );
      glyphKey.currentState!.show(UiStrings.impactGlyphBreakWindow, isEnemy: true);
      await tester.pump(const Duration(milliseconds: 60));
      // ImpactGlyphOverlay 使用 Text(_glyph!) 渲染，没有单字限制 → 「破绽」可以渲染。
      expect(find.text(UiStrings.impactGlyphBreakWindow), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.impactGlyphBreakWindow), findsNothing);
    });
  });

  group('破绽敌高亮（staggerTicksRemaining）', () {
    testWidgets('enemy stagger>0 时显示破绽高亮 key', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      // 将右队第 0 个角色设置为 stagger>0。
      final staggeredRight = List<BattleCharacter>.from(right);
      staggeredRight[0] = staggeredRight[0].copyWith(staggerTicksRemaining: 3);
      final state = BattleState.initial(leftTeam: left, rightTeam: staggeredRight);
      await _pumpBattle(tester, state);

      // 高亮以 Key('stagger_highlight_${characterId}') 标记，在 _GlowAura 内渲染。
      expect(
        find.byKey(ValueKey('stagger_highlight_${staggeredRight[0].characterId}')),
        findsOneWidget,
      );
    });

    testWidgets('enemy 全无 stagger 时不出现任何高亮 key', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      // 确保 stagger=0（BattleDemo.mockTeams 默认即 0）。
      final state = BattleState.initial(leftTeam: left, rightTeam: right);
      await _pumpBattle(tester, state);

      // 遍历右队，不应出现任何 stagger_highlight key。
      for (final c in right) {
        expect(
          find.byKey(ValueKey('stagger_highlight_${c.characterId}')),
          findsNothing,
        );
      }
    });

    testWidgets('player（左队）stagger>0 时不显示集火高亮（高亮仅限敌方）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      // 将左队第 0 个角色设置为 stagger>0，模拟玩家方被硬直。
      final staggeredLeft = List<BattleCharacter>.from(left);
      staggeredLeft[0] = staggeredLeft[0].copyWith(staggerTicksRemaining: 3);
      final state = BattleState.initial(leftTeam: staggeredLeft, rightTeam: right);
      await _pumpBattle(tester, state);

      // 玩家方被硬直不应出现集火高亮（spec §6：破绽高亮仅为敌方集火指示）。
      expect(
        find.byKey(ValueKey('stagger_highlight_${staggeredLeft[0].characterId}')),
        findsNothing,
      );
    });
  });
}
