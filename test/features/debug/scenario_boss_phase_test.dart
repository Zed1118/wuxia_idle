import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';

/// 第七阶段批二目检路由 `battle_boss_phase` 的场景工厂结构契约。
///
/// 守住：Boss 是真 stage_01_05 撑伞高人（bossPhases / 弱点抗性全真，仅 HP 抬高），
/// 玩家队流派配比正确（2 刚猛触发会心 + 1 灵巧吃抗性）。防 stage id / 字段接线 drift。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('scenarioBossPhase：Boss 带真 bossPhases + 弱点/抗性，玩家队流派正确', () {
    final (left, right) = BattleScenarioData.scenarioBossPhase();

    // ── 右队首位 = 真 stage_01_05 撑伞高人 Boss ──
    final boss = right.first;
    expect(boss.isBoss, isTrue);
    expect(boss.school, TechniqueSchool.yinRou);
    expect(boss.maxHp, 16000, reason: 'HP 抬到 16000 给两阶段演出步数');
    expect(boss.currentHp, 16000);
    expect(boss.bossPhases, isNotNull);
    expect(
      boss.bossPhases!.length,
      greaterThanOrEqualTo(2),
      reason: '至少起始 + 背水一击两阶段',
    );
    // 弱点/抗性按流派（阴柔怕刚猛 ×1.25 / 阴柔克灵巧 ×0.75）。
    expect(boss.schoolDamageTakenMult[TechniqueSchool.gangMeng], 1.25);
    expect(boss.schoolDamageTakenMult[TechniqueSchool.lingQiao], 0.75);

    // ── 左队：3 人，2 刚猛（会心来源）+ 1 灵巧（示抗性）──
    expect(left.length, 3);
    expect(
      left.where((c) => c.school == TechniqueSchool.gangMeng).length,
      2,
    );
    expect(
      left.where((c) => c.school == TechniqueSchool.lingQiao).length,
      1,
    );
    // at-level（学徒阶），非终局错配。
    expect(left.every((c) => c.realmTier == RealmTier.xueTu), isTrue);
  });
}
