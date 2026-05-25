import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// T19b 技术债清账:PvpDef 强类型 fromYaml 解析 + 缺字段 default 兜底测族。
///
/// 沿 JianghuConfig.fromYaml 体例 — 缺整段返 [PvpDef.empty]、缺单字段返子项 default。
void main() {
  group('PvpDef.fromYaml 全字段解析', () {
    final yaml = <String, dynamic>{
      'elo': {
        'initial': 1200,
        'k_factor': 32,
        'draw_factor': 0.5,
      },
      'match_range': {
        'elo_window': 100,
        'fallback_window': 300,
        'min_pool_size': 3,
      },
      'sync': {
        'impl': 'noop',
        'snapshot_ttl_hours': 168,
      },
      'history': {
        'max_records': 200,
      },
      'unlock': {
        'requires_stage': 'stage_05_05',
      },
    };

    test('R1.1 elo / match_range / sync / history / unlock 全字段映射', () {
      final pvp = PvpDef.fromYaml(yaml);

      expect(pvp.elo.initial, 1200);
      expect(pvp.elo.kFactor, 32);
      expect(pvp.elo.drawFactor, closeTo(0.5, 1e-9));

      expect(pvp.matchRange.eloWindow, 100);
      expect(pvp.matchRange.fallbackWindow, 300);
      expect(pvp.matchRange.minPoolSize, 3);

      expect(pvp.sync.impl, 'noop');
      expect(pvp.sync.snapshotTtlHours, 168);

      expect(pvp.history.maxRecords, 200);

      expect(pvp.unlockRequiresStage, 'stage_05_05');
    });
  });

  group('PvpDef.fromYaml 空段兜底', () {
    test('R1.2 null 段 → PvpDef.empty (默认 kFactor=32 / initial=1200)', () {
      final pvp = PvpDef.fromYaml(null);
      expect(identical(pvp, PvpDef.empty), isTrue);
      expect(pvp.elo.kFactor, 32);
      expect(pvp.elo.initial, 1200);
    });

    test('R1.3 空 map 段 → PvpDef.empty', () {
      final pvp = PvpDef.fromYaml(const <String, dynamic>{});
      expect(identical(pvp, PvpDef.empty), isTrue);
    });

    test('R1.4 缺 elo 段 → EloConfig.empty 默认 kFactor=32', () {
      final pvp = PvpDef.fromYaml(<String, dynamic>{
        'match_range': {'elo_window': 100},
      });
      expect(pvp.elo.kFactor, 32);
      expect(pvp.elo.initial, 1200);
      expect(pvp.matchRange.eloWindow, 100);
    });

    test('R1.5 unlock 段缺 → unlockRequiresStage null', () {
      final pvp = PvpDef.fromYaml(<String, dynamic>{
        'elo': {'k_factor': 16},
      });
      expect(pvp.unlockRequiresStage, isNull);
      expect(pvp.elo.kFactor, 16);
    });
  });
}
