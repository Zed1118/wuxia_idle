import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// 红线值统一到 numbers.yaml(2026-05-29 消 hardcode):RedLinesConfig.fromYaml
/// 解析 + fixture 缺段 §5.4 default 兜底 + production yaml 真值 drift guard。
///
/// 沿 numbers_config_pvp_def_test 体例。RedLinesConfig 是 derived_stats /
/// stage_battle_setup / game_repository 各 clamp 点的单一真相源。
void main() {
  group('RedLinesConfig.fromYaml', () {
    test('R1 全字段映射', () {
      final rl = RedLinesConfig.fromYaml(const {
        'player_hp_max': 20000,
        'internal_force_max': 15000,
      });
      expect(rl.playerHpMax, 20000);
      expect(rl.internalForceMax, 15000);
    });

    test('R2 缺段 → §5.4 default 兜底(fixture 兼容)', () {
      final rl = RedLinesConfig.fromYaml(const {});
      expect(rl.playerHpMax, 20000, reason: '§5.4 玩家血量红线 default');
      expect(rl.internalForceMax, 15000, reason: '§5.4 内力红线 default');
    });
  });

  group('production data/numbers.yaml 红线单一真相源', () {
    setUpAll(() async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    test('R3 combat.red_lines 与 §5.4 红线一致(drift guard)', () {
      final rl = GameRepository.instance.numbers.combat.redLines;
      expect(rl.playerHpMax, 20000,
          reason: '§5.4 玩家血量红线 — 改前确认是有意调整,非 drift');
      expect(rl.internalForceMax, 15000,
          reason: '§5.4 内力红线 — 改前确认是有意调整,非 drift');
    });

    test('R4 全 49 realm def internalForceMax ≤ 红线(校验同源)', () {
      final ifMax = GameRepository.instance.numbers.combat.redLines.internalForceMax;
      for (final r in GameRepository.instance.realms) {
        expect(r.internalForceMax, lessThanOrEqualTo(ifMax),
            reason: '${r.tier.name}/${r.layer.name} 内力上限不破红线 $ifMax');
      }
    });
  });
}
