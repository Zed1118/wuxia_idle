import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// T19b 技术债清账:SectEventDef 强类型 fromYaml 解析 + 缺字段 default 兜底测族。
void main() {
  group('SectEventDef.fromYaml 全字段解析', () {
    final yaml = <String, dynamic>{
      'tournament': {
        'trigger_probability': 0.30,
        'cooldown_days': 30,
        'trigger_realm_min': 'yiLiu',
        'expire_days': 7,
      },
      'reputation': {
        'initial': 50,
        'win_delta': 10,
        'loss_delta': -5,
        'decay_per_month_idle': 5,
        'max': 100,
        'min': 0,
      },
      'sect_level': {
        'max': 7,
        'initial': 1,
        'promote_wins_threshold': 3,
      },
      'active_events_max': 3,
    };

    test('R2.1 tournament 段完整映射', () {
      final def = SectEventDef.fromYaml(yaml);
      expect(def.tournament.triggerProbability, closeTo(0.30, 1e-9));
      expect(def.tournament.cooldownDays, 30);
      expect(def.tournament.triggerRealmMin, 'yiLiu');
      expect(def.tournament.expireDays, 7);
    });

    test('R2.2 reputation 段 win_delta / loss_delta / clamp', () {
      final def = SectEventDef.fromYaml(yaml);
      expect(def.reputation.winDelta, 10);
      expect(def.reputation.lossDelta, -5);
      expect(def.reputation.max, 100);
      expect(def.reputation.min, 0);
      expect(def.reputation.decayPerMonthIdle, 5);
    });

    test('R2.3 sect_level 段 promote_wins_threshold / max', () {
      final def = SectEventDef.fromYaml(yaml);
      expect(def.sectLevel.max, 7);
      expect(def.sectLevel.initial, 1);
      expect(def.sectLevel.promoteWinsThreshold, 3);
      expect(def.activeEventsMax, 3);
    });
  });

  group('SectEventDef.fromYaml 空段兜底', () {
    test('R2.4 null 段 → SectEventDef.empty 默认 activeEventsMax=3', () {
      final def = SectEventDef.fromYaml(null);
      expect(identical(def, SectEventDef.empty), isTrue);
      expect(def.activeEventsMax, 3);
      expect(def.tournament.cooldownDays, 30);
      expect(def.reputation.winDelta, 10);
      expect(def.sectLevel.max, 7);
    });

    test('R2.5 缺 reputation 子段 → 子段 default(winDelta=10)', () {
      final def = SectEventDef.fromYaml(<String, dynamic>{
        'tournament': {'cooldown_days': 7},
      });
      expect(def.tournament.cooldownDays, 7);
      expect(def.reputation.winDelta, 10,
          reason: 'reputation 段缺 → 走 SectReputationDef.empty 默认');
    });
  });
}
