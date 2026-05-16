import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// CLAUDE.md §12.1 #7 v1.4 数值落地红线:numbers.yaml 解析后的 4 段字段值
/// 与 v1.4 决议一致(改动需同步更新 CLAUDE.md + PROGRESS,test 是约束语义锚点)。
///
/// 沿 `feedback_red_line_test_semantics` 纪律 — 字段存在 + 类型 + v1.4 数值锁。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('§12.1 #7 v1.4 · combat.schools.gang_meng_quake', () {
    test('damage=500 + 穿透防御 + 不暴击 + 主攻击命中才触发', () {
      final q = GameRepository.instance.numbers.schoolCounter.gangMengQuake;
      expect(q.damage, 500, reason: 'v1.4 决议:刚猛震伤固定 +500');
      expect(q.piercesDefense, isTrue,
          reason: '穿透守方防御率(语义上是震的硬伤)');
      expect(q.piercesCritical, isTrue,
          reason: '不被暴击乘(独立于 critical_multiplier)');
      expect(q.followsMainHit, isTrue, reason: '主攻击命中才追加,闪避不触发');
    });
  });

  group('§12.1 #7 v1.4 · combat.schools.yin_rou_internal_injury', () {
    test('N=3 守方 tick × 200/tick + 穿透防御 + 同源刷新覆盖', () {
      final i =
          GameRepository.instance.numbers.schoolCounter.yinRouInternalInjury;
      expect(i.turnsPersist, 3, reason: 'v1.4 决议:N=3 守方 tick');
      expect(i.damagePerTick, 200,
          reason: 'v1.4 决议:每 tick 扣 200 固定');
      expect(i.piercesDefense, isTrue, reason: '穿透防御 + 可致死');
      expect(i.stackRule, 'refresh',
          reason: '同源刷新(覆盖)不叠层 — 重复触发重置 turns');
      expect(i.followsMainHit, isTrue,
          reason: '主攻击命中才施加,闪避不施加');
    });
  });

  group('§12.1 #7 v1.4 · retreat.time_of_day_bonus[zhengWu]', () {
    test('+20% 乘到 internal_force_points + 仅 gangMeng 触发', () {
      final r = GameRepository.instance.numbers.retreat;
      expect(r.zhengWuYangSchoolMultiplier, closeTo(1.20, 0.001),
          reason: 'v1.4 决议:正午阳刚 +20%');
      expect(r.zhengWuTargetAttribute, 'internal_force_points',
          reason: '加成乘到 internalForcePoints 维度(刚猛=内力外放)');
      expect(r.zhengWuAppliesToSchool, TechniqueSchool.gangMeng,
          reason: '仅刚猛流派 character 触发,非刚猛不加成');
    });
  });
}
