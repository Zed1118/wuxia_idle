import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';

void main() {
  final thrust = BasicAttackSegment(
    id: 'thrust',
    geometryRef: 'forward_fan.thrust',
    timelineRef: 'timeline.basic.thrust',
    effectRefs: ['damage.standard'],
  );
  final sweep = BasicAttackSegment(
    id: 'sweep',
    geometryRef: 'forward_fan.sweep',
    timelineRef: 'timeline.basic.sweep',
    effectRefs: ['damage.standard', 'posture.light'],
  );

  test('五种武器身份完整且可建立共享段定义的普攻链', () {
    expect(WeaponType.values, hasLength(5));
    expect(
      WeaponType.values,
      containsAll([
        WeaponType.sword,
        WeaponType.heavy,
        WeaponType.flexible,
        WeaponType.dual,
        WeaponType.hidden,
      ]),
    );

    final chain = BasicAttackChain(
      weapon: WeaponType.sword,
      segments: [thrust, sweep],
      resetAfterIdleTicks: 3,
    );
    expect(chain.segments, [thrust, sweep]);
    expect(chain.segmentAt(0), thrust);
    expect(chain.segmentAt(1), sweep);
    expect(chain.geometryRefs, ['forward_fan.thrust', 'forward_fan.sweep']);
    expect(chain.timelineRefs, [
      'timeline.basic.thrust',
      'timeline.basic.sweep',
    ]);
    expect(
      chain,
      equals(
        BasicAttackChain(
          weapon: WeaponType.sword,
          segments: [thrust, sweep],
          resetAfterIdleTicks: 3,
        ),
      ),
    );
    expect(
      chain.hashCode,
      BasicAttackChain(
        weapon: WeaponType.sword,
        segments: [thrust, sweep],
        resetAfterIdleTicks: 3,
      ).hashCode,
    );
    expect(
      thrust.hashCode,
      BasicAttackSegment(
        id: 'thrust',
        geometryRef: 'forward_fan.thrust',
        timelineRef: 'timeline.basic.thrust',
        effectRefs: ['damage.standard'],
      ).hashCode,
    );
    expect(
      chain,
      isNot(
        equals(
          BasicAttackChain(
            weapon: WeaponType.heavy,
            segments: [thrust, sweep],
            resetAfterIdleTicks: 3,
          ),
        ),
      ),
    );
  });

  test('效果引用按声明顺序保留，且暴露集合不可变', () {
    expect(sweep.effectRefs, ['damage.standard', 'posture.light']);
    expect(() => sweep.effectRefs.add('unexpected'), throwsUnsupportedError);
  });

  test('同 tick 阈值只在达到阈值时重置且链快照不可变', () {
    final chain = BasicAttackChain(
      weapon: WeaponType.sword,
      segments: [thrust, sweep],
      resetAfterIdleTicks: 2,
    );

    expect(chain.nextSegmentIndex(currentIndex: 0, idleTicks: 1), 1);
    expect(chain.nextSegmentIndex(currentIndex: 1, idleTicks: 2), 0);
    expect(() => chain.segments.removeAt(0), throwsUnsupportedError);
    expect(() => chain.timelineRefs.add('unexpected'), throwsUnsupportedError);
  });

  test('连段推进是确定性的，空闲达到阈值或中断后重置', () {
    final chain = BasicAttackChain(
      weapon: WeaponType.dual,
      segments: [thrust, sweep],
      resetAfterIdleTicks: 3,
    );

    expect(chain.nextSegmentIndex(currentIndex: 0, idleTicks: 0), 1);
    expect(chain.nextSegmentIndex(currentIndex: 1, idleTicks: 2), 0);
    expect(chain.nextSegmentIndex(currentIndex: 1, idleTicks: 3), 0);
    expect(
      chain.nextSegmentIndex(currentIndex: 1, idleTicks: 0, interrupted: true),
      0,
    );
    expect(
      List.generate(
        4,
        (index) =>
            chain.nextSegmentIndex(currentIndex: index % 2, idleTicks: 0),
      ),
      [1, 0, 1, 0],
    );
  });

  test('拒绝空段、重复 id、空引用、非法重置 tick 和越界索引', () {
    expect(
      () => BasicAttackChain(
        weapon: WeaponType.sword,
        segments: [],
        resetAfterIdleTicks: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => BasicAttackChain(
        weapon: WeaponType.sword,
        segments: [thrust, thrust],
        resetAfterIdleTicks: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => BasicAttackSegment(
        id: 'invalid',
        geometryRef: '',
        timelineRef: 'timeline',
        effectRefs: ['effect'],
      ),
      throwsArgumentError,
    );
    expect(
      () => BasicAttackSegment(
        id: 'duplicate-effects',
        geometryRef: 'geometry',
        timelineRef: 'timeline',
        effectRefs: ['effect', 'effect'],
      ),
      throwsArgumentError,
    );
    expect(
      () => BasicAttackSegment(
        id: 'invalid-whitespace',
        geometryRef: ' geometry',
        timelineRef: 'timeline',
        effectRefs: ['effect'],
      ),
      throwsArgumentError,
    );
    expect(
      () => BasicAttackChain(
        weapon: WeaponType.sword,
        segments: [thrust],
        resetAfterIdleTicks: 0,
      ),
      throwsArgumentError,
    );
    final chain = BasicAttackChain(
      weapon: WeaponType.sword,
      segments: [thrust],
      resetAfterIdleTicks: 1,
    );
    expect(() => chain.segmentAt(1), throwsRangeError);
    expect(
      () => chain.nextSegmentIndex(currentIndex: -1, idleTicks: 0),
      throwsRangeError,
    );
    expect(
      () => chain.nextSegmentIndex(currentIndex: 0, idleTicks: -1),
      throwsArgumentError,
    );
  });

  test('不同连段可复用同一 geometry/timeline 模板', () {
    final shared = BasicAttackChain(
      weapon: WeaponType.flexible,
      segments: [
        thrust,
        BasicAttackSegment(
          id: 'follow-up',
          geometryRef: thrust.geometryRef,
          timelineRef: thrust.timelineRef,
          effectRefs: ['posture.light'],
        ),
      ],
      resetAfterIdleTicks: 2,
    );

    expect(shared.segments, hasLength(2));
    expect(shared.geometryRefs, ['forward_fan.thrust', 'forward_fan.thrust']);
  });
}
