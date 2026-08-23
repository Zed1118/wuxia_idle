import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_geometry.dart';

void main() {
  const origin = ArenaVector.zero;
  final targets = <CombatGeometryTarget>[
    const CombatGeometryTarget('far', ArenaVector(10, 0)),
    const CombatGeometryTarget('edge', ArenaVector(5, 5)),
    const CombatGeometryTarget('near', ArenaVector(2, 0)),
    const CombatGeometryTarget('outside', ArenaVector(5, 6)),
  ];

  group('前向扇形', () {
    test('包含距离与角度闭边界并按距离和 id 排序、遵守上限', () {
      final scope = ForwardFanScope(
        origin: origin,
        direction: const ArenaVector(1, 0),
        maxDistance: 10,
        halfAngleRadians: 0.7853981633974483,
        maxTargets: 2,
      );

      expect(scope.hitTargets(targets).map((target) => target.id), [
        'near',
        'edge',
      ]);
    });

    test('零向量和非法参数不产生命中', () {
      expect(
        ForwardFanScope(
          origin: origin,
          direction: ArenaVector.zero,
          maxDistance: 10,
          halfAngleRadians: 1,
          maxTargets: 3,
        ).hitTargets(targets),
        isEmpty,
      );
      expect(
        ForwardFanScope(
          origin: origin,
          direction: const ArenaVector(1, 0),
          maxDistance: -1,
          halfAngleRadians: 1,
          maxTargets: 3,
        ).hitTargets(targets),
        isEmpty,
      );
    });
  });

  test('自身圆形和目标点圆形支持内外半径闭区间', () {
    const self = SelfCircleScope(
      center: origin,
      innerRadius: 2,
      outerRadius: 7.1,
      maxTargets: 5,
    );
    const point = TargetPointCircleScope(
      center: const ArenaVector(5, 5),
      innerRadius: 0,
      outerRadius: 0.5,
      maxTargets: 5,
    );

    expect(self.hitTargets(targets).map((target) => target.id), [
      'near',
      'edge',
    ]);
    expect(point.hitTargets(targets).map((target) => target.id), ['edge']);
  });

  test('直线胶囊包含端点和半径边界，零长度无效', () {
    const line = LineCapsuleScope(
      start: const ArenaVector(0, 0),
      end: const ArenaVector(10, 0),
      radius: 5,
      maxTargets: 5,
    );
    expect(line.hitTargets(targets).map((target) => target.id), [
      'near',
      'edge',
      'far',
    ]);
    expect(
      LineCapsuleScope(
        start: origin,
        end: origin,
        radius: 5,
        maxTargets: 5,
      ).hitTargets(targets),
      isEmpty,
    );
  });

  test('位移轨迹按到起点的路径距离排序并包含终点', () {
    const scope = DisplacementTrailScope(
      start: origin,
      end: const ArenaVector(10, 0),
      radius: 5,
      maxTargets: 2,
    );
    expect(scope.hitTargets(targets).map((target) => target.id), [
      'near',
      'edge',
    ]);
  });

  test('同距离使用 id 稳定排序且输入顺序不影响结果', () {
    const scope = SelfCircleScope(
      center: origin,
      innerRadius: 0,
      outerRadius: 11,
      maxTargets: 5,
    );
    const equalDistanceTargets = <CombatGeometryTarget>[
      CombatGeometryTarget('b', ArenaVector(3, 4)),
      CombatGeometryTarget('a', ArenaVector(4, 3)),
    ];
    expect(
      scope
          .hitTargets(equalDistanceTargets.reversed)
          .map((target) => target.id),
      ['a', 'b'],
    );
  });

  test('非有限锚点和路径端点不产生命中', () {
    final invalidCircle = SelfCircleScope(
      center: const ArenaVector(double.nan, 0),
      innerRadius: 0,
      outerRadius: 10,
      maxTargets: 2,
    );
    final invalidLine = LineCapsuleScope(
      start: origin,
      end: const ArenaVector(double.infinity, 0),
      radius: 1,
      maxTargets: 2,
    );

    expect(invalidCircle.hitTargets(targets), isEmpty);
    expect(invalidLine.hitTargets(targets), isEmpty);
  });

  test('自身状态是 typed 作用域，不产生敌方命中集', () {
    const scope = SelfStateScope(
      durationSeconds: 2,
      refreshPolicy: StateRefreshPolicy.replace,
      stackingPolicy: StateStackingPolicy.unique,
      cancelWindowSeconds: 0.5,
      effects: const [SelfStateEffect.guardWindow],
    );

    expect(scope.hitTargets(targets), isEmpty);
    expect(scope.effects, contains(SelfStateEffect.guardWindow));
  });
}
