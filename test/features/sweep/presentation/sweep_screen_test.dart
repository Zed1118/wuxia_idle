import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_screen.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 假扫荡单位：起手即抛 → 触发 SweepScreen 装配失败 halt 路径，
/// 可在无 Isar/GameRepository 的轻量 widget 测下验「战败 recap」渲染。
class _ThrowingUnit implements SweepUnit {
  @override
  String get label => '试炼一关';
  @override
  String get battleHint => '试炼一关';
  @override
  String? get sceneBackgroundPath => null;
  @override
  BgmTrack get bgmTrack => BgmTrack.tower;
  @override
  Future<void> startBattle(WidgetRef ref) async => throw StateError('boom');
  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) async => null;
}

void main() {
  testWidgets('装配失败 → 战败 recap：显标题/原因/返回按钮 + 周目行', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(
            units: [_ThrowingUnit()],
            unitName: '问鼎江湖',
            cycle: 2,
          ),
        ),
      ),
    );
    // postFrameCallback → _startCurrent → startBattle 抛 → recordDefeat → recap。
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepDefeatReason), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapBack), findsOneWidget);
    // 战败仍记一行「通关 0 关」。
    expect(find.text(UiStrings.sweepRecapStages(0)), findsOneWidget);
    // recap 告知扫的是第几周目（用户要求：扫完知道扫的是哪个周目）。
    expect(find.text(UiStrings.sweepRecapCycle(2)), findsOneWidget);
  });
}
