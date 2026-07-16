import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_battle_runner.dart';

import '../../support/test_data.dart';

/// C1.3.3a：断魂庄单关 headless 战斗驱动（§5.2-5.5）。
///
/// `GauntletBattleRunner.runStage` = 敌队合成（`StageBattleSetup.buildEnemyTeam`）+
/// `ExpeditionBattleRunner.runNodeBattle`（沿 Phase B 同 wiring · `Random(seed)` 确定性）。
/// 承伤机制（vulnerability 窗口 / guardianWard / bossPhases 三阶段）与 qi_drain 均在
/// 引擎/strategy 层自动生效——EnemyDef→BattleCharacter 由 `buildEnemyTeam` 灌入机制字段
/// （`vulnerabilityMult`/`guardianWardMult`/`bossPhases`），qi_drain 在 C1.3.1 已接进
/// `default_ground_strategy._resolveAction`。**runner 无需额外注入**（Phase 0.5 订正
/// plan「另注入 QiDrainEffect 与承伤乘子」的过时假设）。
/// 玩家普攻招 fixture（战斗 AI 兜底要求至少一个 `SkillType.normalAttack`）。
const _playerNormal = SkillDef(
  id: 'skill_gauntlet_test_normal',
  name: '普攻',
  description: 'C1.3.3a 玩家普攻 fixture',
  type: SkillType.normalAttack,
  powerMultiplier: 60,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'stub',
);

BattleCharacter _pc(
  int id, {
  int atk = 1500,
  int hp = 18000,
  RealmTier tier = RealmTier.erLiu,
}) => BattleCharacter(
  characterId: id,
  name: '玩家$id',
  realmTier: tier,
  realmLayer: RealmLayer.yuanShu,
  school: TechniqueSchool.gangMeng,
  maxHp: hp,
  currentHp: hp,
  internalForce: 3000,
  maxQi: 140,
  currentQi: 80,
  speed: 120,
  criticalRate: 0.1,
  evasionRate: 0.05,
  defenseRate: 0.15,
  totalEquipmentAttack: atk,
  mainCultivationLayer: CultivationLayer.daCheng,
  availableSkills: const [_playerNormal],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: id - 1,
);

void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  List<BattleCharacter> players() => [_pc(1), _pc(2), _pc(3)];

  test('runStage 确定性：同 seed 两跑 result / leftWin 一致', () {
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    final enemyDefs = config.enemiesForTeam(config.stages[0].enemyTeamId);
    expect(enemyDefs, isNotEmpty, reason: '关1 敌队应解析非空');

    final r1 = GauntletBattleRunner.runStage(
      playerTeam: players(),
      enemyDefs: enemyDefs,
      numbers: numbers,
      seed: 424242,
    );
    final r2 = GauntletBattleRunner.runStage(
      playerTeam: players(),
      enemyDefs: enemyDefs,
      numbers: numbers,
      seed: 424242,
    );

    expect(r1.finalState.result, r2.finalState.result);
    expect(r1.leftWin, r2.leftWin);
    // leftWin 与 finalState.result 自洽
    expect(r1.leftWin, r1.finalState.result == BattleResult.leftWin);
  });

  test('三关敌队机制字段进战斗态（vuln 0.65 / ward 0.25 / bossPhases 3）', () {
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    final teams = [for (final s in config.stages) s.enemyTeamId];

    // 关1 苏无咎：vulnerabilityMult 0.65（破招脆弱窗）
    final s1 = GauntletBattleRunner.runStage(
      playerTeam: players(),
      enemyDefs: config.enemiesForTeam(teams[0]),
      numbers: numbers,
      seed: 1,
    );
    expect(
      s1.finalState.rightTeam.any(
        (e) => e.vulnerabilityMult != null &&
            (e.vulnerabilityMult! - 0.65).abs() < 1e-9,
      ),
      isTrue,
      reason: '关1 苏无咎 vulnerabilityMult 0.65 应进战斗态',
    );

    // 关2 石镇岳：guardianWardMult 0.25（护法结界）
    final s2 = GauntletBattleRunner.runStage(
      playerTeam: players(),
      enemyDefs: config.enemiesForTeam(teams[1]),
      numbers: numbers,
      seed: 1,
    );
    expect(
      s2.finalState.rightTeam.any(
        (e) => e.guardianWardMult != null &&
            (e.guardianWardMult! - 0.25).abs() < 1e-9,
      ),
      isTrue,
      reason: '关2 石镇岳 guardianWardMult 0.25 应进战斗态',
    );

    // 关3 闻九针：bossPhases 三阶段
    final s3 = GauntletBattleRunner.runStage(
      playerTeam: players(),
      enemyDefs: config.enemiesForTeam(teams[2]),
      numbers: numbers,
      seed: 1,
    );
    expect(
      s3.finalState.rightTeam.any((e) => e.bossPhases?.length == 3),
      isTrue,
      reason: '关3 闻九针 bossPhases 三阶段应进战斗态',
    );
  });

  test('玩家高一阶满配可破关1精英（战斗真跑通·leftWin）', () {
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    // 关1 苏无咎队为三流；玩家二流（高一阶）+ 高攻，应可清场。
    final strong = [
      _pc(1, atk: 1900),
      _pc(2, atk: 1900),
      _pc(3, atk: 1900),
    ];
    final r = GauntletBattleRunner.runStage(
      playerTeam: strong,
      enemyDefs: config.enemiesForTeam(config.stages[0].enemyTeamId),
      numbers: numbers,
      seed: 20260716,
    );
    expect(
      r.leftWin,
      isTrue,
      reason: '高一阶满配玩家应能破关1（战斗链路真跑通），实际 ${r.finalState.result}',
    );
  });
}
