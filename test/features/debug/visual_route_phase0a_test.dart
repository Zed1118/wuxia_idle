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
