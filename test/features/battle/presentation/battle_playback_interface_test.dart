import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import '../../../support/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_playback_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_bottom_bar.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_header.dart';

const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20,
  damagePopupFloatPx: 20,
  damagePopupMs: 100,
  actionIntervalMs: 50,
  fastForwardIntervalMs: 20,
  shakeOffsetPx: 1,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
);

class _StaticBattleNotifier extends BattleNotifier {
  _StaticBattleNotifier(this.initial);

  final BattleState initial;

  @override
  BattleState build() => initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void advanceOneAction({int maxConsecutiveSteps = 300}) {}
}

void main() {
  test('BattleScreen 只消费播放视图与状态，不读取动画资源', () async {
    final source = await File(
      'lib/features/battle/presentation/battle_screen.dart',
    ).readAsString();

    for (final forbidden in const [
      '.attackControllers',
      '.hitFlashControllers',
      '.hitFlashColors',
      '.activeTrails',
      '.activeEffects',
      '.popups',
      '.closeupCtrl',
      '.shakeCtrl',
      '.screenFlashKey',
      '.ultimateCaptionKey',
      '.impactGlyphKey',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }

    expect(source, contains('BattlePlaybackMotion('));
    expect(source, contains('BattlePlaybackField('));
    expect(source, contains('BattlePlaybackOverlays('));
  });

  testWidgets('播放视图在 1280×720 与 1440×900 均完整渲染', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      final (left, right) = BattleDemo.mockTeams();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            battleProvider.overrideWith(
              () => _StaticBattleNotifier(
                BattleState.initial(leftTeam: left, rightTeam: right),
              ),
            ),
          ],
          child: const MaterialApp(
            home: BattleScreen(
              animConfig: _testAnim,
              playback: BattleScreenPlaybackConfig(startPaused: true),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BattlePlaybackMotion), findsOneWidget);
      expect(find.byType(BattlePlaybackField), findsOneWidget);
      expect(find.byType(BattlePlaybackOverlays), findsOneWidget);
      final motion = find.byType(BattlePlaybackMotion);
      expect(
        find.descendant(of: motion, matching: find.byType(BattlePlaybackField)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: motion, matching: find.byType(Header)),
        findsNothing,
        reason: '顶栏不能随命中特写缩放或屏震',
      );
      expect(
        find.descendant(of: motion, matching: find.byType(AutoRotationBar)),
        findsNothing,
        reason: '自动轮转谱不能随命中特写缩放或屏震',
      );
      expect(tester.takeException(), isNull, reason: '$size 不应 overflow/抛异常');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Windows 1080p 在 100% 125% 150% 显示缩放下完整渲染', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final scale in const [1.0, 1.25, 1.5]) {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = scale;
      final logicalSize = tester.view.physicalSize / scale;
      for (final allowPlayerIntervention in const [false, true]) {
        final (left, right) = BattleDemo.mockTeams();

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              battleProvider.overrideWith(
                () => _StaticBattleNotifier(
                  BattleState.initial(leftTeam: left, rightTeam: right),
                ),
              ),
            ],
            child: MaterialApp(
              home: BattleScreen(
                animConfig: _testAnim,
                playback: BattleScreenPlaybackConfig(
                  startPaused: true,
                  allowPlayerIntervention: allowPlayerIntervention,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          MediaQuery.sizeOf(tester.element(find.byType(BattleScreen))),
          logicalSize,
          reason: 'Windows ${scale * 100}% 应按逻辑像素布局',
        );
        expect(find.byType(Header), findsOneWidget);
        expect(find.byType(BattlePlaybackField), findsOneWidget);
        expect(
          find.byType(allowPlayerIntervention ? BottomBar : AutoCommandDesk),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('battle_command_desk')),
          findsOneWidget,
        );
        for (var i = 0; i < 7; i++) {
          expect(find.byKey(ValueKey('battle_skill_slot_$i')), findsOneWidget);
        }
        for (var i = 0; i < 3; i++) {
          expect(find.byKey(ValueKey('battle_pouch_slot_$i')), findsOneWidget);
        }
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Windows ${scale * 100}%（${logicalSize.width}×${logicalSize.height}）'
              '${allowPlayerIntervention ? '点选' : '自动'}模式不应 overflow/抛异常',
        );

        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
