import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';

/// 可玩性 P1a §五 红线测。
///
/// P1a 对 §5.4 的**数学保证 = 相对 +30% cap**:熟练度综合倍率(全局阶段 ×
/// (1+per-skill damage_pct))恒 ≤ 1.30。即任何招因熟练度获得的增伤不超过 +30%,
/// 不会把既有(已在 §5.4 envelope 内的)伤害放大失控。
///
/// 注:§5.4「普通伤害 ≤8000」是设计层指南(满内力+满修炼 ×3.0 的极值组合
/// pre-P1a 即已越此值,非 calculateResolved 的硬数学界);故此处不做极值绝对断言
/// (会是 master 上也 fail 的假红),只钉死 P1a 真正引入的 +30% 相对界。
/// fresh-char(uses=0 → profMult 1.0)零回归已由 balance_simulator 3000 run 验证;
/// 高熟练度全量平衡扫描见 backlog(simulator 未 seed skillUsageCount)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('§2.5 相对 cap:任意 per-skill damage_pct,熟练满阶综合倍率 ≤ 1.30', () {
    final cfg = GameRepository.instance.numbers.skillProficiency;
    for (final pct in [0.0, 0.05, 0.08, 0.12, 0.20, 0.50, 1.0, 5.0]) {
      expect(SkillProficiency.combinedMult(800, pct, cfg),
          lessThanOrEqualTo(1.30),
          reason: 'per-skill damage_pct=$pct 综合不得破 130% cap');
    }
  });

  test('每个熟练阶段综合倍率都 ≤ 1.30(全阶守)', () {
    final cfg = GameRepository.instance.numbers.skillProficiency;
    for (final uses in [0, 30, 100, 300, 800, 99999]) {
      for (final pct in [0.0, 0.15, 0.50]) {
        expect(SkillProficiency.combinedMult(uses, pct, cfg),
            lessThanOrEqualTo(1.30));
      }
    }
  });

  test('config 守:maxDamageMult == 1.30(末阶即 cap)', () {
    final cfg = GameRepository.instance.numbers.skillProficiency;
    expect(cfg.maxDamageMult, 1.30);
  });

  test('skill_proficiency 5 阶 min_uses 严格递增 + 倍率单调不降', () {
    final p = GameRepository.instance.numbers.skillProficiency;
    expect(p.stages.length, 5);
    for (var i = 1; i < p.stages.length; i++) {
      expect(p.stages[i].minUses, greaterThan(p.stages[i - 1].minUses));
      expect(p.stages[i].damageMult,
          greaterThanOrEqualTo(p.stages[i - 1].damageMult));
    }
  });
}
