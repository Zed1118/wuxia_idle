import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_combat_session.dart';
import 'phase0a_damage_calculator_adapter.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_numeric_skill_binding.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_wave_battle_flow.dart';

/// Phase 0A 生产 flow 装配器(第六批派单):唯一生产装配入口。
///
/// 把既有 `Phase0aBattleSnapshotFactory` → `Phase0aDamageCalculatorAdapter`
/// → `Phase0aCombatSession` → `Phase0aWaveBattleFlow` 一次性装配为已接好
/// 真实伤害的 [Phase0aWaveBattleFlow],消除调用方手工接线与「配置错误延迟到
/// 首击才暴露」的缺口。本类只做组合与启动期结构校验,不复制其中任何伤害、
/// 移动、AI、CD、真气、波次或终局规则。
///
/// 冻结契约(第六批协调计划 + 派单):
/// - 结构校验全部不消费 RNG,且先于一切伤害组件构造:全场 actor 精确覆盖 →
///   playerId 一致 → 招式 kind 绑定完整;任何结构错误不得推进 RNG。
/// - 全场 expected actor ids = `initialState.player.id` + 每一波 `enemy.id`;
///   [combatants] 的显式 actor ids 必须精确覆盖,missing/extra 均 fail-fast,
///   错误信息列出稳定排序后的 id。
/// - `playerAdapter.playerId` 必须等于 `initialState.player.id`。
/// - [moveBindings] 必须显式覆盖 basic/gather/clear；数字技能只在真实槽
///   非空时出现，并与 player Adapter 的 skill id 精确一致。
/// - 结构校验完成后才调快照工厂;其动态机制/吸血 fail-fast 原样穿透,
///   不包装、不延迟到首击。
/// - 只创建一个伤害 adapter,并把同一个显式 [rng] 实例交给它;换波重建
///   session 由 flow 复用同一 resolver 实例,保证 RNG 连续、不按波重置。
/// - 首态/波次 side、首波一致性、跨波 actor id 唯一继续交给
///   [Phase0aWaveBattleFlow] 既有构造期校验,本类不复制其规则。
/// - 防御性副本沿既有体例(工厂 bundle / adapter / flow 均已不可修改化):
///   装配完成后外部 combatants/waves/moveBindings mutation 不影响 flow。
final class Phase0aProductionFlowAssembler {
  const Phase0aProductionFlowAssembler._();

  /// 唯一装配入口:返回已接好真实伤害的 [Phase0aWaveBattleFlow]。
  static Phase0aWaveBattleFlow assemble({
    required Phase0aArenaState initialState,
    required List<Phase0aWave> waves,
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required NumbersConfig numbers,
    required Random rng,
    required Phase0aPlayerInputAdapter playerAdapter,
    required Phase0aEnemyAiAdapter enemyAiAdapter,
  }) {
    // —— 结构校验(零 RNG 消费,先于一切伤害组件构造)——
    _checkActorCoverage(
      initialState: initialState,
      waves: waves,
      combatants: combatants,
    );
    if (playerAdapter.playerId != initialState.player.id) {
      throw ArgumentError.value(
        playerAdapter.playerId,
        'playerAdapter',
        'playerId 必须等于首态玩家 id(${initialState.player.id})',
      );
    }
    _checkMoveBindings(moveBindings, playerAdapter.numericSkillBindings);

    // —— 组合既有组件(工厂动态机制 fail-fast 原样穿透)——
    final bundle = Phase0aBattleSnapshotFactory(
      numbers: numbers,
    ).create(combatants: combatants, moveBindings: moveBindings);
    final damageResolver = Phase0aDamageCalculatorAdapter(
      combatants: bundle.combatants,
      moveBindings: bundle.moveBindings,
      numbers: numbers,
      rng: rng,
    );
    return Phase0aWaveBattleFlow(
      session: Phase0aCombatSession(
        initialState: initialState,
        playerAdapter: playerAdapter,
        enemyAiAdapter: enemyAiAdapter,
        damageResolver: damageResolver,
        enemySkillDamageResolver: damageResolver,
      ),
      waves: waves,
    );
  }

  /// 全场 actor 精确覆盖:expected = 首态玩家 + 每一波敌人;missing/extra
  /// 均 fail-fast,错误 id 稳定排序。
  static void _checkActorCoverage({
    required Phase0aArenaState initialState,
    required List<Phase0aWave> waves,
    required List<Phase0aCombatantInput> combatants,
  }) {
    final expected = <String>{initialState.player.id};
    for (final wave in waves) {
      for (final enemy in wave.enemies) {
        expected.add(enemy.id);
      }
    }
    final actual = combatants.map((combatant) => combatant.actorId).toSet();
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw ArgumentError(
        'Phase0a 装配 actor 覆盖错误: missing=$missing, extra=$extra',
      );
    }
  }

  /// 招式绑定完整覆盖:每个 kind 必须显式 containsKey;null 为合法
  /// control-only,缺 key 才 fail-fast。
  static void _checkMoveBindings(
    Map<Phase0aDamageKind, SkillDef?> moveBindings,
    Phase0aNumericSkillBindings numericSkills,
  ) {
    const requiredKinds = [
      Phase0aDamageKind.basic,
      Phase0aDamageKind.gather,
      Phase0aDamageKind.clear,
    ];
    final missing = <String>[
      for (final kind in requiredKinds)
        if (!moveBindings.containsKey(kind)) kind.name,
    ];
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'Phase0a 装配招式绑定缺失(按 enum 序): $missing;'
        'null 为合法 control-only 绑定,缺 key 不允许',
      );
    }
    for (final binding in numericSkills.equipped) {
      final kind = phase0aDamageKindForSkillHotkey(binding.hotkey);
      final bound = moveBindings[kind];
      if (bound?.id != binding.skill.id) {
        throw ArgumentError(
          'Phase0a 数字技能绑定不一致: hotkey=${binding.hotkey}, '
          'adapter=${binding.skill.id}, damage=${bound?.id}',
        );
      }
    }
  }
}
