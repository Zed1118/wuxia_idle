import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../data/defs/stage_def.dart';
import '../../../../data/numbers_config.dart';
import '../../domain/battle_state.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../stage_battle_setup.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_player_input_adapter.dart';

/// Phase 1 纵切切片 1(spec 2026-08-19 · P1=α 主线 Ch1 · D1=α 机械映射):
/// 把生产关卡内容(StageDef)装配成 [Phase0aProductionFlowAssembler.assemble]
/// 的全套入参。
///
/// 零口径复制原则:
/// - 敌人 BattleCharacter 直接复用 [StageBattleSetup.buildEnemyTeam](旧战斗
///   同一口径:境界内力查表/红线 clamp/周目 scale=1 零回归),不重算任何数值;
/// - 空间/能量/动作维度(stages.yaml 没有的 0A 特有轴)全部取
///   [NumbersConfig.phase0aArena] 段,不硬编码;
/// - 敌队→波次为 D1 机械映射:StageDef.enemyTeam 整队一波(主线关 ≤3 敌,
///   无首发/后备之分;远征/塔的续波语义绑内容迁移后续切片)。
final class Phase0aStageMapping {
  const Phase0aStageMapping({
    required this.initialState,
    required this.waves,
    required this.combatants,
    required this.moveBindings,
    required this.playerAdapter,
    required this.enemyAiAdapter,
  });

  final Phase0aArenaState initialState;
  final List<Phase0aWave> waves;
  final List<Phase0aCombatantInput> combatants;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
}

final class Phase0aStageContentMapper {
  const Phase0aStageContentMapper._();

  /// 装配一关的 0A 战斗输入。[playerCharacter] 由调用方构造(生产侧走
  /// `BattleCharacter.fromCharacter` Isar 路径,纵切测试显式构造)。
  ///
  /// fail-fast:`numbers.phase0aArena` 缺段(isEmpty)拒绝装配——纵切不得
  /// 静默用零参数竞技场冒充配置;`stage.enemyTeam` 为空拒绝(剧情空关
  /// 不走战斗装配)。
  static Phase0aStageMapping map({
    required StageDef stage,
    required BattleCharacter playerCharacter,
    required NumbersConfig numbers,
    String playerId = 'player',
  }) {
    final arena = numbers.phase0aArena;
    if (arena.isEmpty) {
      throw StateError(
        'Phase0a 纵切装配 ${stage.id}: numbers.yaml 缺 phase0a_arena 段,'
        '不得静默装配零参数竞技场',
      );
    }
    if (stage.enemyTeam.isEmpty) {
      throw ArgumentError.value(stage.id, 'stage', 'Phase0a 纵切装配拒绝空敌队关卡');
    }

    // —— 敌人 BattleCharacter:复用旧战斗同一口径(零数值复制)——
    final enemyCharacters = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);

    // —— 空间排布:确定性,玩家在左,敌人右侧按 slot 均匀散开 ——
    final playerPosition = ArenaVector(arena.arenaMinX * 0.5, 0);
    final waveEnemies = <Phase0aActor>[
      for (var i = 0; i < enemyCharacters.length; i++)
        _enemyActor(
          arena: arena,
          character: enemyCharacters[i],
          actorId: stage.enemyTeam.length == 1
              ? stage.enemyTeam[i].id
              : '${stage.enemyTeam[i].id}_w0s$i',
          position: _enemyPosition(
            arena: arena,
            slot: i,
            count: enemyCharacters.length,
          ),
        ),
    ];

    final playerActor = Phase0aActor(
      id: playerId,
      side: Phase0aSide.player,
      position: playerPosition,
      facing: const ArenaVector(1, 0),
      maxHealth: playerCharacter.maxHp,
      currentHealth: playerCharacter.currentHp,
      moveSpeed: arena.playerMoveSpeed,
      qiCurrent: playerCharacter.currentQi,
      qiMax: playerCharacter.maxQi,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );

    final combatants = <Phase0aCombatantInput>[
      Phase0aCombatantInput(actorId: playerId, character: playerCharacter),
      for (var i = 0; i < enemyCharacters.length; i++)
        Phase0aCombatantInput(
          actorId: waveEnemies[i].id,
          character: enemyCharacters[i],
        ),
    ];

    return Phase0aStageMapping(
      initialState: Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: playerActor,
        enemies: waveEnemies,
        skillSlots: _skillSlots(arena),
      ),
      waves: [Phase0aWave(enemies: waveEnemies)],
      combatants: List.unmodifiable(combatants),
      moveBindings: _moveBindings(arena),
      playerAdapter: _playerAdapter(arena: arena, playerId: playerId),
      enemyAiAdapter: Phase0aEnemyAiAdapter(
        attackRange: arena.enemyAttackRange,
        attackHalfArcRadians: arena.enemyAttackHalfArcRadians,
        attackCooldownSeconds: arena.enemyAttackCooldownSeconds,
      ),
    );
  }

  /// 敌人空间位:右侧纵深固定,纵向按 slot 数均匀展开(确定性,无 RNG)。
  static ArenaVector _enemyPosition({
    required Phase0aArenaConfig arena,
    required int slot,
    required int count,
  }) {
    final x = arena.arenaMaxX * 0.4;
    if (count == 1) return ArenaVector(x, 0);
    final usableHeight = arena.arenaMaxY - arena.arenaMinY;
    final y = arena.arenaMinY + usableHeight * (slot + 0.5) / count;
    return ArenaVector(x, y);
  }

  static Phase0aActor _enemyActor({
    required Phase0aArenaConfig arena,
    required BattleCharacter character,
    required String actorId,
    required ArenaVector position,
  }) {
    // 敌人真气/CD 取形态默认段(Ch1 敌人不用技能,中性值)。
    return Phase0aActor(
      id: actorId,
      side: Phase0aSide.enemy,
      position: position,
      facing: const ArenaVector(-1, 0),
      maxHealth: character.maxHp,
      currentHealth: character.currentHp,
      moveSpeed: arena.enemyMoveSpeed,
      qiCurrent: arena.enemyQi,
      qiMax: arena.enemyQi,
      attackCooldownRemaining: arena.enemyInitialAttackCooldown,
      defeatKind: character.isBoss
          ? Phase0aDefeatKind.elite
          : Phase0aDefeatKind.normal,
    );
  }

  static List<Phase0aSkillSlot> _skillSlots(Phase0aArenaConfig arena) =>
      List.unmodifiable([
        Phase0aSkillSlot(
          slot: arena.gatherSlot,
          cooldownRemaining: 0,
          qiCost: arena.gatherQiCost,
          availability: Phase0aSkillAvailability.ready,
        ),
        Phase0aSkillSlot(
          slot: arena.clearSlot,
          cooldownRemaining: 0,
          qiCost: arena.clearQiCost,
          availability: Phase0aSkillAvailability.ready,
        ),
      ]);

  /// 招式绑定:basic/clear 伤害招走形态段倍率;gather 为 control-only(null)。
  static Map<Phase0aDamageKind, SkillDef?> _moveBindings(
    Phase0aArenaConfig arena,
  ) => Map.unmodifiable({
    Phase0aDamageKind.basic: _moveSkill(
      id: arena.basicSkillId,
      powerMultiplier: arena.basicPowerMultiplier,
      qiDelta: arena.basicQiDelta,
    ),
    Phase0aDamageKind.gather: null,
    Phase0aDamageKind.clear: _moveSkill(
      id: arena.clearSkillId,
      powerMultiplier: arena.clearPowerMultiplier,
      qiDelta: arena.clearQiDelta,
    ),
  });

  static SkillDef _moveSkill({
    required String id,
    required int powerMultiplier,
    required int qiDelta,
  }) => SkillDef(
    id: id,
    name: id,
    description: id,
    type: SkillType.normalAttack,
    powerMultiplier: powerMultiplier,
    qiDelta: qiDelta,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  static Phase0aPlayerInputAdapter _playerAdapter({
    required Phase0aArenaConfig arena,
    required String playerId,
  }) => Phase0aPlayerInputAdapter(
    playerId: playerId,
    attackRange: arena.playerAttackRange,
    attackHalfArcRadians: arena.playerAttackHalfArcRadians,
    attackCooldownSeconds: arena.playerAttackCooldownSeconds,
    gatherSlot: arena.gatherSlot,
    gatherRingRadius: arena.gatherRingRadius,
    gatherEffectRadius: arena.gatherEffectRadius,
    gatherQiCost: arena.gatherQiCost,
    gatherCooldownSeconds: arena.gatherCooldownSeconds,
    clearSlot: arena.clearSlot,
    clearEffectRadius: arena.clearEffectRadius,
    clearQiCost: arena.clearQiCost,
    clearCooldownSeconds: arena.clearCooldownSeconds,
  );
}
