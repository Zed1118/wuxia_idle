import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

/// Phase 0A 第七批:`VisualRoute.phase0aBattlePlayable` 路由契约红测。
///
/// 钉死三件事:
/// 1. `phase0a_battle_playable` id 的 parse / roundtrip;
/// 2. host(`visual_route_host.dart`)switch 注册了该路由;
/// 3. 生产入口(`main.dart` 正常路径 / `stage_entry_flow.dart`)不引用该路由——
///    它只允许经 debug `--dart-define=VISUAL_ROUTE` 到达。
void main() {
  group('VisualRoute.phase0aBattlePlayable', () {
    test('id 稳定为 phase0a_battle_playable', () {
      expect(VisualRoute.phase0aBattlePlayable.id, 'phase0a_battle_playable');
      expect(VisualRoute.phase0aBattleProfile.id, 'phase0a_battle_profile');
      expect(
        parseVisualRoute('phase0a_battle_profile'),
        VisualRoute.phase0aBattleProfile,
      );
      expect(
        parseVisualRoute('phase0a_black_ridge_profile'),
        VisualRoute.phase0aBlackRidgeProfile,
      );
    });

    test('Boss 机制实机 route id 可解析', () {
      expect(
        parseVisualRoute('phase0a_battle_boss_mechanics'),
        VisualRoute.phase0aBattleBossMechanics,
      );
      expect(VisualRoute.phase0aBattleBossMechanics.controlsReadiness, isTrue);
    });

    test('guardian 机制实机 route id 可解析', () {
      expect(
        parseVisualRoute('phase0a_battle_guardian_mechanics'),
        VisualRoute.phase0aBattleGuardianMechanics,
      );
    });

    test('反馈静态验收路由 id 可解析', () {
      const routes = <VisualRoute, String>{
        VisualRoute.phase0aBattleAttackFeedback:
            'phase0a_battle_attack_feedback',
        VisualRoute.phase0aBattleGatherFeedback:
            'phase0a_battle_gather_feedback',
        VisualRoute.phase0aBattleClearFeedback: 'phase0a_battle_clear_feedback',
      };
      for (final entry in routes.entries) {
        expect(entry.key.id, entry.value);
        expect(parseVisualRoute(entry.value), entry.key);
      }
    });

    test('parseVisualRoute 可解析', () {
      expect(
        parseVisualRoute('phase0a_battle_playable'),
        VisualRoute.phase0aBattlePlayable,
      );
    });

    test('id 往返一致', () {
      expect(
        parseVisualRoute(VisualRoute.phase0aBattlePlayable.id),
        VisualRoute.phase0aBattlePlayable,
      );
    });

    test('host switch 已注册该路由', () {
      final hostSource = File(
        'lib/features/debug/presentation/visual_route_host.dart',
      ).readAsStringSync();
      expect(
        hostSource.contains('VisualRoute.phase0aBattlePlayable'),
        isTrue,
        reason: 'visual_route_host.dart 的 buildVisualTarget 必须接新屏',
      );
      expect(hostSource.contains('_Phase0aFeedbackPreview'), isTrue);
      expect(hostSource.contains('_Phase0aProfilePreview'), isTrue);
      expect(hostSource.contains('Phase0aPlayerBotAdapter'), isTrue);
      expect(
        hostSource.contains('autoStep: widget.initialCommand == null'),
        isTrue,
      );
      expect(hostSource.contains('visualRouteFeedbackHoldSeconds'), isTrue);
      expect(
        hostSource.contains('VisualRoute.phase0aBattleBossMechanics'),
        isTrue,
      );
      expect(
        hostSource.contains('data/phase0a_debug_boss_battle.yaml'),
        isTrue,
      );
      final bossCaseStart = hostSource.indexOf(
        'case VisualRoute.phase0aBattleBossMechanics:',
      );
      final guardianCaseStart = hostSource.indexOf(
        'case VisualRoute.phase0aBattleGuardianMechanics:',
      );
      expect(bossCaseStart, greaterThanOrEqualTo(0));
      expect(guardianCaseStart, greaterThan(bossCaseStart));
      final bossCaseSource = hostSource.substring(
        bossCaseStart,
        guardianCaseStart,
      );
      expect(bossCaseSource.contains('Phase0aBossMechanicsPreview'), isTrue);
      expect(bossCaseSource.contains('seed: fixture.seed'), isTrue);
      expect(bossCaseSource.contains('onReady: onTargetReady'), isTrue);
      expect(
        hostSource.contains('Phase0aBossMechanicsRouteDriver'),
        isTrue,
        reason: 'Boss 验收路由必须走可执行驱动器并冻结真实破绽态',
      );
      expect(
        hostSource.contains('VisualRoute.phase0aBattleGuardianMechanics'),
        isTrue,
      );
      expect(
        hostSource.contains('data/phase0a_debug_guardian_mechanics.yaml'),
        isTrue,
      );
      expect(hostSource.contains('_Phase0aGuardianMechanicsPreview'), isTrue);
    });

    test('main.dart 与 stage_entry_flow.dart 不引用该路由', () {
      for (final path in const [
        'lib/main.dart',
        'lib/features/mainline/presentation/stage_entry_flow.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('phase0aBattlePlayable'),
          isFalse,
          reason: '$path 不得引用 phase0aBattlePlayable(debug 专用路由)',
        );
        expect(
          source.contains('phase0a_battle_playable'),
          isFalse,
          reason: '$path 不得引用 phase0a_battle_playable(debug 专用路由)',
        );
        expect(
          source.contains('battle/presentation/phase0a'),
          isFalse,
          reason: '$path 不得 import phase0a 表现层新屏',
        );
      }
    });
  });
}
