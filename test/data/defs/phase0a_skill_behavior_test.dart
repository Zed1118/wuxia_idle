import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/phase0a_skill_behavior.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_tactical_skill_binding.dart';

SkillDef tacticalSkill({
  required String id,
  required Phase0aSkillBehavior behavior,
}) => SkillDef(
  id: id,
  name: id,
  description: id,
  type: SkillType.powerSkill,
  powerMultiplier: 0,
  qiDelta: -10,
  cooldownTurns: 3,
  requiresManualTrigger: true,
  visualEffect: '',
  source: SkillSource.special,
  targetType: TargetType.aoe,
  phase0aBehavior: behavior,
);

void main() {
  test('parses radial caster pull and keeps effects immutable', () {
    final behavior = Phase0aSkillBehavior.fromYaml({
      'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 520},
      'effects': [
        {'type': 'pull', 'destinationRadius': 120},
      ],
    });

    expect(behavior.geometry.shape, Phase0aSkillGeometryShape.radial);
    expect(behavior.geometry.anchor, Phase0aSkillGeometryAnchor.caster);
    expect(behavior.geometry.radius, 520);
    expect(
      behavior.effectOf(Phase0aSkillEffectType.pull)?.destinationRadius,
      120,
    );
    expect(
      () => behavior.effects.add(
        const Phase0aSkillEffect(type: Phase0aSkillEffectType.damage),
      ),
      throwsUnsupportedError,
    );
  });

  test('parses damage plus stagger clear behavior', () {
    final behavior = Phase0aSkillBehavior.fromYaml({
      'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 340},
      'effects': [
        {'type': 'damage'},
        {'type': 'stagger'},
      ],
    });

    expect(behavior.hasEffect(Phase0aSkillEffectType.damage), isTrue);
    expect(behavior.hasEffect(Phase0aSkillEffectType.stagger), isTrue);
  });

  test('unknown geometry/effect and invalid pull fail closed', () {
    Map<String, dynamic> yaml({
      String shape = 'radial',
      String anchor = 'caster',
      Object? effect = 'damage',
      num radius = 10,
      num? destinationRadius,
    }) => {
      'geometry': {'shape': shape, 'anchor': anchor, 'radius': radius},
      'effects': [
        {'type': effect, 'destinationRadius': ?destinationRadius},
      ],
    };

    expect(
      () => Phase0aSkillBehavior.fromYaml(yaml(shape: 'cone')),
      throwsStateError,
    );
    expect(
      () => Phase0aSkillBehavior.fromYaml(yaml(anchor: 'target')),
      throwsStateError,
    );
    expect(
      () => Phase0aSkillBehavior.fromYaml(yaml(effect: 'teleport')),
      throwsStateError,
    );
    expect(
      () => Phase0aSkillBehavior.fromYaml(
        yaml(effect: 'pull', destinationRadius: 11),
      ),
      throwsStateError,
    );
  });

  test('duplicates fail; break parses and clear binding consumes it', () {
    expect(
      () => Phase0aSkillBehavior.fromYaml({
        'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 10},
        'effects': [
          {'type': 'damage'},
          {'type': 'damage'},
        ],
      }),
      throwsStateError,
    );

    final withBreak = Phase0aSkillBehavior.fromYaml({
      'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 10},
      'effects': [
        {'type': 'damage'},
        {'type': 'stagger'},
        {'type': 'break', 'points': 1},
      ],
    });
    expect(withBreak.hasEffect(Phase0aSkillEffectType.breakPower), isTrue);

    // charge/破招纵切(2026-08-22):clear 允许集 = damage+stagger+break,
    // binding 暴露 typed break 载荷供 reducer 破招迁移消费。
    expect(
      Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.clear,
        slot: 'clear',
        skill: tacticalSkill(id: 'clear_break', behavior: withBreak),
      ).breakPower,
      1,
    );

    // Q 契约不变:gather 仍为纯 pull,带 break 拒绝(fail-closed)。
    expect(
      () => Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.gather,
        slot: 'gather',
        skill: tacticalSkill(id: 'gather_break', behavior: withBreak),
      ),
      throwsStateError,
    );

    // clear 缺 break 也不再合法(生产过渡 R 已带 break;精确集 fail-closed)。
    final noBreak = Phase0aSkillBehavior.fromYaml({
      'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 10},
      'effects': [
        {'type': 'damage'},
        {'type': 'stagger'},
      ],
    });
    expect(
      () => Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.clear,
        slot: 'clear',
        skill: tacticalSkill(id: 'clear_no_break', behavior: noBreak),
      ),
      throwsStateError,
    );
  });
}
