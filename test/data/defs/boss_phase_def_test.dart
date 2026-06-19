import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';

void main() {
  group('BossPhaseDef.fromYaml', () {
    test('解析全字段', () {
      final p = BossPhaseDef.fromYaml({
        'hpThresholdPct': 0.5,
        'unlockSkillIds': ['skill_a'],
        'aiMode': 'aggressive',
        'onEnterMechanic': 'chargeCounter',
        'titleKey': 'bossPhase2_demo',
      });
      expect(p.hpThresholdPct, 0.5);
      expect(p.unlockSkillIds, ['skill_a']);
      expect(p.aiMode, BossAiMode.aggressive);
      expect(p.onEnterMechanic, BossPhaseMechanic.chargeCounter);
      expect(p.titleKey, 'bossPhase2_demo');
    });
    test('缺省字段默认值', () {
      final p = BossPhaseDef.fromYaml({'hpThresholdPct': 1.0});
      expect(p.unlockSkillIds, isEmpty);
      expect(p.aiMode, BossAiMode.normal);
      expect(p.onEnterMechanic, isNull);
      expect(p.titleKey, isNull);
    });
    test('parseList 阈值非降序抛 StateError', () {
      expect(
        () => BossPhaseDef.parseList([
          {'hpThresholdPct': 1.0},
          {'hpThresholdPct': 0.7},
          {'hpThresholdPct': 0.8},
        ]),
        throwsStateError,
      );
    });
    test('parseList 首项非 1.0 抛 StateError', () {
      expect(
        () => BossPhaseDef.parseList([{'hpThresholdPct': 0.9}]),
        throwsStateError,
      );
    });
    test('parseList 有效降序返回完整列表(order/length)', () {
      final list = BossPhaseDef.parseList([
        {'hpThresholdPct': 1.0},
        {'hpThresholdPct': 0.6, 'unlockSkillIds': ['skill_b']},
        {'hpThresholdPct': 0.3},
      ]);
      expect(list.length, 3);
      expect(list[0].hpThresholdPct, 1.0);
      expect(list[1].hpThresholdPct, 0.6);
      expect(list[1].unlockSkillIds, ['skill_b']);
      expect(list[2].hpThresholdPct, 0.3);
    });
    test('parseList 空输入返回空列表(不抛)', () {
      expect(BossPhaseDef.parseList([]), isEmpty);
    });
  });
}
