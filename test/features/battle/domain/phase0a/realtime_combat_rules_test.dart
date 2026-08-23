import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/realtime_combat_rules.dart';

/// Phase 0A 纯 Dart 战斗几何规则单测。
///
/// 语义锚 = probe `tools/phase0minus_probe/test/gameplay/combat_rules_test.dart`
/// 已策略/真机验证的口径;数值全部由调用方显式传入,生产代码无默认值。
void main() {
  group('ArenaVector 值对象', () {
    test('零向量归一化安全返回零向量', () {
      expect(ArenaVector.zero.normalized(), ArenaVector.zero);
      expect(const ArenaVector(0, 0).normalized(), ArenaVector.zero);
    });

    test('非零归一化长度为一', () {
      final normalized = const ArenaVector(3, 4).normalized();
      expect(normalized.x, closeTo(0.6, 0.0001));
      expect(normalized.y, closeTo(0.8, 0.0001));
      expect(normalized.length, closeTo(1, 0.0001));
    });

    test('加减点乘与数乘保持纯值语义', () {
      final a = const ArenaVector(1, 2);
      final b = const ArenaVector(3, -1);
      expect(a + b, const ArenaVector(4, 1));
      expect(b - a, const ArenaVector(2, -3));
      expect(a.dot(b), 1);
      expect(a * 2, const ArenaVector(2, 4));
    });
  });

  group('四向输入移动归一化', () {
    test('对角输入归一为 sqrt1_2 分量(y 轴向下为正)', () {
      final movement = normalizeMovementInput(
        left: false,
        right: true,
        up: true,
        down: false,
      );
      expect(movement.length, closeTo(1, 0.0001));
      expect(movement.x, closeTo(math.sqrt1_2, 0.0001));
      expect(movement.y, closeTo(-math.sqrt1_2, 0.0001));
    });

    test('反向按键互相抵消', () {
      expect(
        normalizeMovementInput(left: true, right: true, up: false, down: false),
        ArenaVector.zero,
      );
      expect(
        normalizeMovementInput(left: true, right: true, up: true, down: true),
        ArenaVector.zero,
      );
      expect(
        normalizeMovementInput(
          left: false,
          right: false,
          up: false,
          down: false,
        ),
        ArenaVector.zero,
      );
    });

    test('单轴输入保持单位长度不被缩放', () {
      final movement = normalizeMovementInput(
        left: true,
        right: false,
        up: false,
        down: false,
      );
      expect(movement, const ArenaVector(-1, 0));
    });
  });

  group('距离与朝向扇区双条件判定', () {
    final origin = ArenaVector.zero;
    final aimRight = const ArenaVector(1, 0);

    test('同时满足距离与扇区才命中', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: const ArenaVector(100, 20),
          range: 145,
          halfArcRadians: 0.72,
        ),
        isTrue,
      );
    });

    test('反向目标在距离内也不命中', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: const ArenaVector(-100, 0),
          range: 145,
          halfArcRadians: 0.72,
        ),
        isFalse,
      );
    });

    test('超出距离的目标不命中', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: const ArenaVector(150, 0),
          range: 145,
          halfArcRadians: 0.72,
        ),
        isFalse,
      );
    });

    test('与自身重合的目标视为命中', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: ArenaVector.zero,
          range: 145,
          halfArcRadians: 0.72,
        ),
        isTrue,
      );
    });

    test('非法负距离即使与自身重合也 fail closed', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: origin,
          range: -1,
          halfArcRadians: 0.72,
        ),
        isFalse,
      );
    });

    test('零朝向默认向右', () {
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: ArenaVector.zero,
          target: const ArenaVector(50, 0),
          range: 145,
          halfArcRadians: 0.72,
        ),
        isTrue,
      );
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: ArenaVector.zero,
          target: const ArenaVector(0, 50),
          range: 145,
          halfArcRadians: 0.72,
        ),
        isFalse,
      );
    });

    test('扇区角边界按闭区间处理', () {
      const halfArc = 0.72;
      final insideEdge = ArenaVector(
        100 * math.cos(halfArc - 0.01),
        100 * math.sin(halfArc - 0.01),
      );
      final outsideEdge = ArenaVector(
        100 * math.cos(halfArc + 0.01),
        100 * math.sin(halfArc + 0.01),
      );
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: insideEdge,
          range: 145,
          halfArcRadians: halfArc,
        ),
        isTrue,
      );
      expect(
        isTargetInsideStrikeArc(
          origin: origin,
          aimDirection: aimRight,
          target: outsideEdge,
          range: 145,
          halfArcRadians: halfArc,
        ),
        isFalse,
      );
    });
  });

  group('聚怪可读环', () {
    test('环外敌人被拉到以玩家为中心的环上', () {
      final destination = gatherRingDestination(
        playerCenter: const ArenaVector(10, 20),
        enemyPosition: const ArenaVector(410, 20),
        ringRadius: 88,
      );
      expect(destination.x, closeTo(98, 0.0001));
      expect(destination.y, closeTo(20, 0.0001));
    });

    test('斜向敌人沿方向投影到环上', () {
      final destination = gatherRingDestination(
        playerCenter: ArenaVector.zero,
        enemyPosition: const ArenaVector(300, 400),
        ringRadius: 100,
      );
      expect(destination.x, closeTo(60, 0.0001));
      expect(destination.y, closeTo(80, 0.0001));
    });

    test('已在环内的敌人不被推走', () {
      final destination = gatherRingDestination(
        playerCenter: ArenaVector.zero,
        enemyPosition: const ArenaVector(30, 40),
        ringRadius: 88,
      );
      expect(destination, const ArenaVector(30, 40));
    });

    test('恰好落在环上的敌人保持原位', () {
      final destination = gatherRingDestination(
        playerCenter: ArenaVector.zero,
        enemyPosition: const ArenaVector(88, 0),
        ringRadius: 88,
      );
      expect(destination, const ArenaVector(88, 0));
    });
  });

  group('精英破招窗口 = 预告末段', () {
    test('窗口前的蓄力不可破', () {
      expect(
        isEliteBreakWindowOpen(
          telegraphRemainingSeconds: 1.2,
          breakWindowSeconds: 0.65,
        ),
        isFalse,
      );
    });

    test('窗口末段内可破', () {
      expect(
        isEliteBreakWindowOpen(
          telegraphRemainingSeconds: 0.5,
          breakWindowSeconds: 0.65,
        ),
        isTrue,
      );
    });

    test('预告归零后窗口关闭', () {
      expect(
        isEliteBreakWindowOpen(
          telegraphRemainingSeconds: 0,
          breakWindowSeconds: 0.65,
        ),
        isFalse,
      );
      expect(
        isEliteBreakWindowOpen(
          telegraphRemainingSeconds: -0.1,
          breakWindowSeconds: 0.65,
        ),
        isFalse,
      );
    });

    test('恰好等于窗口长度的上界按闭区间可破', () {
      expect(
        isEliteBreakWindowOpen(
          telegraphRemainingSeconds: 0.65,
          breakWindowSeconds: 0.65,
        ),
        isTrue,
      );
    });
  });
}
