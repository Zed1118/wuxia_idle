import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_header.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// surviveTicks 型胜负条件的**玩家可见面**守卫（2026-07-29 Ch21 主线首用补）。
///
/// 背景：该条件此前只有战斗逻辑——schema(`stage_win_condition.dart`)、灌入
/// (`stage_entry_flow` → `BattleState.winCondition`)、逐 tick 判定
/// (`default_ground_strategy`)俱全，**表现层零呈现**。心魔 07 靠独立呈现路径
/// 兜底，主线不可复用；不补则玩家读作「打不死的对手忽然赢了」。
///
/// 本测锁两条语义（不锁字面文案，文案随 UiStrings 走）：
///   ① 配 surviveTicks 时顶栏出条件条，未配 / defeatAll 时**整行不渲染**
///      （前 20 章零影响是硬要求，不能顺手给全部战斗加一行）；
///   ② 胜利仪式副标题按赢法区分，surviveTicks 取胜不说「旗开得胜」。
// Header 内含 ContextHelpButton(Consumer),必须有 ProviderScope 才能构建。
Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

/// Header 必填回调较多且与本测无关，统一给 no-op，只留 state 作变量。
Header _header(BattleState state) => Header(
  state: state,
  onToggleLog: () {},
  onPause: () {},
  isPaused: false,
  onFastForward: () {},
  isFastForward: false,
  allowPlayerIntervention: false,
);

BattleState _state({StageWinCondition? wc, int tick = 0}) {
  var s = BattleState.initial(
    leftTeam: const [],
    rightTeam: const [],
    winCondition: wc,
  );
  if (tick > 0) s = s.copyWith(tick: tick);
  return s;
}

const _survive18 = StageWinCondition(
  type: StageWinConditionType.surviveTicks,
  surviveTicksRequired: 18,
);

void main() {
  group('顶栏条件条', () {
    testWidgets('未配 winCondition → 不渲染条件条（前 20 章零影响）', (tester) async {
      await tester.pumpWidget(_wrap(_header(_state())));
      expect(find.textContaining('守住'), findsNothing);
    });

    testWidgets('defeatAll 型 → 不渲染条件条', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _header(
            _state(
              wc: const StageWinCondition(
                type: StageWinConditionType.defeatAll,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('守住'), findsNothing);
    });

    testWidgets('surviveTicks 未达成 → 显剩余拍数', (tester) async {
      await tester.pumpWidget(_wrap(_header(_state(wc: _survive18, tick: 11))));
      // 18 需撑 · 已到 11 → 还差 7
      expect(
        find.text(UiStrings.surviveConditionRemaining(18, 7)),
        findsOneWidget,
      );
      expect(find.text(UiStrings.surviveConditionMet(18)), findsNothing);
    });

    testWidgets('surviveTicks 已达成 → 改显已守满', (tester) async {
      await tester.pumpWidget(_wrap(_header(_state(wc: _survive18, tick: 18))));
      expect(find.text(UiStrings.surviveConditionMet(18)), findsOneWidget);
    });
  });

  group('胜利仪式副标题按赢法区分', () {
    testWidgets('defeatAll 取胜 → 旗开得胜', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VictoryOverlay(
            result: BattleResult.leftWin,
            totalDamage: 1,
            critCount: 0,
            totalTicks: 18,
            onContinue: () {},
          ),
        ),
      );
      expect(find.text(UiStrings.victorySubtitle), findsOneWidget);
      expect(find.text(UiStrings.battleResultSurvived), findsNothing);
    });

    testWidgets('surviveTicks 取胜 → 守住了', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VictoryOverlay(
            result: BattleResult.leftWin,
            totalDamage: 1,
            critCount: 0,
            totalTicks: 18,
            onContinue: () {},
            survivedByTicks: true,
          ),
        ),
      );
      expect(find.text(UiStrings.battleResultSurvived), findsOneWidget);
      expect(find.text(UiStrings.victorySubtitle), findsNothing);
    });
  });
}
