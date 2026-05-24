import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/battle_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/pvp/domain/strategy/pvp_strategy.dart';

/// PvpStrategy R5 单测(spec p3_3_pvp_spec_2026-05-24 §7 R2 复用 3 测):
///   - R2.1 implements BattleStrategy(组合委派契约,ctor 0 引入 attackPowerMultiplier
///     §5.4 红线兜底)
///   - R2.2 requestUltimate 转发 DefaultGroundStrategy(pendingUltimates 写入)
///   - R2.3 runToEnd 入口把 opponentTeam 注入 rightTeam(已结束状态短路 _delegate
///     主循环,只验 hydrate 语义)
///
/// 不测 tick 主循环数值(沿 DefaultGroundStrategy e2e 测路径覆盖,
/// memory `feedback_red_line_test_semantics` 写约束语义不写瞬时事实)。
void main() {
  late NumbersConfig numbersCfg;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    numbersCfg = repo.numbers;
  });

  group('PvpStrategy 组合委派契约 (R2)', () {
    test('R2.1 implements BattleStrategy + immutable ctor(只接 opponentTeam · '
        'R3.6 §5.4 红线:0 attackPowerMultiplier)', () {
      const strategy = PvpStrategy(opponentTeam: []);
      expect(strategy, isA<BattleStrategy>());
      expect(strategy.opponentTeam, isEmpty);
    });

    test('R2.2 requestUltimate 转发到 DefaultGroundStrategy '
        '(pendingUltimates 写入 + 与 DefaultGroundStrategy 同效)', () {
      final state = BattleState.initial(
        leftTeam: [_makeChar(characterId: 1, teamSide: 0)],
        rightTeam: [_makeChar(characterId: -1, teamSide: 1)],
      );
      const ultimate = SkillDef(
        id: 'skill_ut_stub',
        name: '测试大招',
        description: 'R2.2 stub',
        type: SkillType.ultimate,
        powerMultiplier: 5000,
        internalForceCost: 500,
        cooldownTurns: 5,
        requiresManualTrigger: true,
        visualEffect: 'stub',
      );

      const strategy = PvpStrategy(opponentTeam: []);
      final after = strategy.requestUltimate(state, 1, ultimate);

      expect(after.pendingUltimates.containsKey(1), isTrue);
      expect(after.pendingUltimates[1]?.id, 'skill_ut_stub');

      final reference =
          const DefaultGroundStrategy().requestUltimate(state, 1, ultimate);
      expect(after.pendingUltimates, equals(reference.pendingUltimates));
    });

    test('R2.3 runToEnd 入口把 opponentTeam 注入 rightTeam(已结束状态短路 '
        '_delegate 主循环,只验 hydrate)', () {
      final opponentTeam = [
        _makeChar(characterId: -100, teamSide: 1, slotIndex: 0),
        _makeChar(characterId: -101, teamSide: 1, slotIndex: 1),
        _makeChar(characterId: -102, teamSide: 1, slotIndex: 2),
      ];
      // 初始 rightTeam 故意只 1 角色,验入口确实被 opponentTeam 覆盖。
      // result 非 null → _delegate.runToEnd while 循环 short-circuit,
      // numbers 字段不访问。
      final initial = BattleState(
        leftTeam: [_makeChar(characterId: 1, teamSide: 0)],
        rightTeam: [_makeChar(characterId: -999, teamSide: 1)],
        tick: 0,
        result: BattleResult.leftWin,
        actionLog: const [],
      );

      final strategy = PvpStrategy(opponentTeam: opponentTeam);
      final after = strategy.runToEnd(initial, numbersCfg);

      expect(after.rightTeam.length, 3,
          reason: 'opponentTeam 替换原 rightTeam');
      expect(
        after.rightTeam.map((c) => c.characterId).toList(),
        equals([-100, -101, -102]),
        reason: 'opponentTeam 顺序保留',
      );
      expect(after.leftTeam.length, 1, reason: 'leftTeam 不变');
      expect(after.result, BattleResult.leftWin,
          reason: 'short-circuit 不动 result');
    });
  });
}

BattleCharacter _makeChar({
  required int characterId,
  required int teamSide,
  int slotIndex = 0,
}) =>
    BattleCharacter(
      characterId: characterId,
      name: teamSide == 0 ? '玩家' : '对手',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.jingTong,
      school: TechniqueSchool.gangMeng,
      maxHp: 8000,
      currentHp: 8000,
      maxInternalForce: 5000,
      currentInternalForce: 5000,
      speed: 200,
      criticalRate: 0.10,
      evasionRate: 0.05,
      defenseRate: 0.20,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
    );
