import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../data/defs/stage_def.dart';
import '../../../../data/defs/tower_floor_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../../shared/battle_shared/combatant_skill_loadout.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../enemy_combatant_snapshot_assembler.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_skill_binding.dart';
import 'phase0a_numeric_skill_binding.dart';
import 'phase0a_player_input_adapter.dart';

/// Phase 1 纵切切片 1(spec 2026-08-19 · P1=α 主线 Ch1 · D1=α 机械映射):
/// 把生产关卡内容(StageDef)装配成 [Phase0aProductionFlowAssembler.assemble]
/// 的全套入参。
///
/// 零口径复制原则:
/// - 敌人 neutral snapshot 直接复用 [EnemyCombatantSnapshotAssembler](旧战斗
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
    required this.numericSkillBindings,
  });

  final Phase0aArenaState initialState;
  final List<Phase0aWave> waves;
  final List<Phase0aCombatantInput> combatants;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aNumericSkillBindings numericSkillBindings;
}

final class Phase0aStageContentMapper {
  const Phase0aStageContentMapper._();

  /// 装配一关的 0A 战斗输入。[playerSnapshot] 由调用方构造(生产侧走
  /// [PlayerCombatantSnapshotAssembler] Isar 路径,纵切测试显式构造)。
  ///
  /// fail-fast:`numbers.phase0aArena` 缺段(isEmpty)拒绝装配——纵切不得
  /// 静默用零参数竞技场冒充配置;`stage.enemyTeam` 为空拒绝(剧情空关
  /// 不走战斗装配)。
  static Phase0aStageMapping map({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
  }) => _mapContent(
    contentId: stage.id,
    enemyTeam: stage.enemyTeam,
    isTower: false,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
    playerId: playerId,
  );

  /// 把一层生产塔定义装配到与主线相同的 Phase 0A 输入。这里只做 D1
  /// 敌队机械映射；Boss 阶段、守护和破绽等动态机制须由调用方在进入 mapper
  /// 前按能力 manifest 拦截，不能把可构造误报成语义已迁移。
  static Phase0aStageMapping mapTower({
    required TowerFloorDef floor,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
  }) => _mapContent(
    contentId: 'tower_${floor.floorIndex}',
    enemyTeam: floor.enemyTeam,
    isTower: true,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
    playerId: playerId,
  );

  static Phase0aStageMapping _mapContent({
    required String contentId,
    required List<EnemyDef> enemyTeam,
    required bool isTower,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    required String playerId,
  }) {
    final arena = numbers.phase0aArena;
    if (arena.isEmpty) {
      throw StateError(
        'Phase0a 纵切装配 $contentId: numbers.yaml 缺 phase0a_arena 段,'
        '不得静默装配零参数竞技场',
      );
    }
    if (enemyTeam.isEmpty) {
      throw ArgumentError.value(contentId, 'content', 'Phase0a 纵切装配拒绝空敌队内容');
    }

    // —— 敌人 neutral snapshot:复用旧战斗同一口径(零数值复制)——
    final enemySnapshots = EnemyCombatantSnapshotAssembler.assembleAll(
      enemyTeam,
      isTower: isTower,
    );
    final numericSkillBindings = _numericSkillBindings(playerSnapshot, arena);

    // —— 空间排布:确定性,玩家在左,敌人右侧按 slot 均匀散开 ——
    final playerPosition = ArenaVector(arena.arenaMinX * 0.5, 0);
    final waveEnemies = <Phase0aActor>[
      for (var i = 0; i < enemySnapshots.length; i++)
        _enemyActor(
          arena: arena,
          snapshot: enemySnapshots[i],
          actorId: enemyTeam.length == 1
              ? enemyTeam[i].id
              : '${enemyTeam[i].id}_w0s$i',
          position: _enemyPosition(
            arena: arena,
            slot: i,
            count: enemySnapshots.length,
          ),
        ),
    ];

    final playerActor = Phase0aActor(
      id: playerId,
      side: Phase0aSide.player,
      position: playerPosition,
      facing: const ArenaVector(1, 0),
      maxHealth: playerSnapshot.maxHp,
      currentHealth: playerSnapshot.currentHp,
      moveSpeed: arena.playerMoveSpeed,
      qiCurrent: playerSnapshot.currentQi,
      qiMax: playerSnapshot.maxQi,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );

    final enemySkillBindingsByActor = <String, List<Phase0aEnemySkillBinding>>{
      for (var i = 0; i < enemySnapshots.length; i++)
        waveEnemies[i].id: _enemyPhaseSkillBindings(
          arena: arena,
          snapshot: enemySnapshots[i],
        ),
    };
    final enemyBasicQiDeltaByActor = <String, int>{
      for (var i = 0; i < enemySnapshots.length; i++)
        waveEnemies[i].id: enemySnapshots[i].bossPhases == null
            ? 0
            : _basicSkillOf(enemySnapshots[i])?.qiDelta ?? 0,
    };

    final combatants = <Phase0aCombatantInput>[
      Phase0aCombatantInput(actorId: playerId, snapshot: playerSnapshot),
      for (var i = 0; i < enemySnapshots.length; i++)
        Phase0aCombatantInput(
          actorId: waveEnemies[i].id,
          snapshot: enemySnapshots[i],
        ),
    ];

    return Phase0aStageMapping(
      initialState: Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: playerActor,
        enemies: waveEnemies,
        skillSlots: _skillSlots(
          arena,
          numericSkillBindings,
          playerSnapshot.currentQi,
        ),
      ),
      waves: [Phase0aWave(enemies: waveEnemies)],
      combatants: List.unmodifiable(combatants),
      moveBindings: _moveBindings(arena, playerSnapshot, numericSkillBindings),
      playerAdapter: _playerAdapter(
        arena: arena,
        playerId: playerId,
        numericSkillBindings: numericSkillBindings,
        attackQiDelta: arena.basicQiDelta,
      ),
      enemyAiAdapter: Phase0aEnemyAiAdapter(
        attackRange: arena.enemyAttackRange,
        attackHalfArcRadians: arena.enemyAttackHalfArcRadians,
        attackCooldownSeconds: arena.enemyAttackCooldownSeconds,
        skillBindingsByActor: Map.unmodifiable(enemySkillBindingsByActor),
        basicQiDeltaByActor: Map.unmodifiable(enemyBasicQiDeltaByActor),
      ),
      numericSkillBindings: numericSkillBindings,
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
    required CombatantSnapshot snapshot,
    required String actorId,
    required ArenaVector position,
  }) {
    final phases = snapshot.bossPhases;
    final initialUnlocks = phases == null || phases.isEmpty
        ? const <String>[]
        : List<String>.unmodifiable(phases.first.unlockSkillIds);
    final openingCooldowns = <String, double>{
      for (final entry in snapshot.openingSkillCooldowns.entries)
        if (entry.value > 0)
          entry.key: entry.value * arena.enemyAttackCooldownSeconds,
    };
    final hasPhases = phases != null;
    return Phase0aActor(
      id: actorId,
      side: Phase0aSide.enemy,
      position: position,
      facing: const ArenaVector(-1, 0),
      maxHealth: snapshot.maxHp,
      currentHealth: snapshot.currentHp,
      moveSpeed: arena.enemyMoveSpeed,
      qiCurrent: hasPhases ? snapshot.currentQi : arena.enemyQi,
      qiMax: hasPhases ? snapshot.maxQi : arena.enemyQi,
      attackCooldownRemaining: arena.enemyInitialAttackCooldown,
      defeatKind: snapshot.isBoss
          ? Phase0aDefeatKind.elite
          : Phase0aDefeatKind.normal,
      autoUltimate: snapshot.autoUltimate,
      bossPhases: phases,
      unlockedEnemySkillIds: initialUnlocks,
      enemySkillCooldowns: hasPhases
          ? Map.unmodifiable(openingCooldowns)
          : const {},
    );
  }

  static List<Phase0aEnemySkillBinding> _enemyPhaseSkillBindings({
    required Phase0aArenaConfig arena,
    required CombatantSnapshot snapshot,
  }) {
    final phaseSkills = snapshot.bossPhaseUnlockSkills;
    if (phaseSkills == null) return const [];
    final byId = <String, SkillDef>{};
    for (final skills in phaseSkills) {
      for (final skill in skills) {
        byId[skill.id] = skill;
      }
    }
    final ids = byId.keys.toList()..sort();
    return List.unmodifiable([
      for (final id in ids)
        Phase0aEnemySkillBinding(
          skill: byId[id]!,
          attackRange: arena.enemyAttackRange,
          halfArcRadians: arena.enemyAttackHalfArcRadians,
          effectRadius: arena.enemyAttackRange,
          cooldownSeconds:
              byId[id]!.cooldownTurns * arena.enemyAttackCooldownSeconds,
        ),
    ]);
  }

  static SkillDef? _basicSkillOf(CombatantSnapshot snapshot) {
    final bound = snapshot.skillLoadout.basicAttack;
    if (bound != null) return bound;
    for (final skill in snapshot.availableSkills) {
      if (skill.type == SkillType.normalAttack) return skill;
    }
    return null;
  }

  static List<Phase0aSkillSlot> _skillSlots(
    Phase0aArenaConfig arena,
    Phase0aNumericSkillBindings numericSkills,
    int openingQi,
  ) => List.unmodifiable([
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
    for (final binding in numericSkills.equipped)
      Phase0aSkillSlot(
        slot: binding.slotId,
        cooldownRemaining: 0,
        qiCost: binding.skill.qiCost,
        availability: availabilityOf(
          cooldownRemaining: 0,
          qiCurrent: openingQi,
          qiCost: binding.skill.qiCost,
        ),
      ),
  ]);

  /// 招式绑定:basic/clear 伤害招走形态段倍率;gather 为 control-only(null)。
  static Map<Phase0aDamageKind, SkillDef?> _moveBindings(
    Phase0aArenaConfig arena,
    CombatantSnapshot player,
    Phase0aNumericSkillBindings numericSkills,
  ) => Map.unmodifiable({
    Phase0aDamageKind.basic:
        player.skillLoadout.basicAttack ??
        _moveSkill(
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
    for (final binding in numericSkills.equipped)
      phase0aDamageKindForSkillHotkey(binding.hotkey): binding.skill,
  });

  static Phase0aNumericSkillBindings _numericSkillBindings(
    CombatantSnapshot player,
    Phase0aArenaConfig arena,
  ) {
    Phase0aNumericSkillBinding? binding(int hotkey) {
      final loadoutSlot = CombatantSkillLoadout.numericSlots[hotkey - 1];
      final skill = player.skillLoadout.skillFor(loadoutSlot);
      // 正式控制已拍板「鼠标左键 = 普攻」；autoFill 仍可能把 normalAttack
      // 放进 main1/2（旧 3v3 兼容语义），Phase 0A 数字栏必须排除，避免同拍
      // 鼠标 basic + 数字 basic 双入口重复结算。
      if (skill == null || skill.type == SkillType.normalAttack) return null;
      return Phase0aNumericSkillBinding(
        hotkey: hotkey,
        loadoutSlot: loadoutSlot,
        skill: skill,
        slotId: 'phase0a_skill_$hotkey',
        attackRange: arena.playerAttackRange,
        halfArc: arena.playerAttackHalfArcRadians,
        effectRadius: arena.clearEffectRadius,
        cooldownSeconds:
            skill.cooldownTurns * arena.playerAttackCooldownSeconds,
      );
    }

    return Phase0aNumericSkillBindings(
      one: binding(1),
      two: binding(2),
      three: binding(3),
      four: binding(4),
      five: binding(5),
      six: binding(6),
    );
  }

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
    required Phase0aNumericSkillBindings numericSkillBindings,
    required int attackQiDelta,
  }) => Phase0aPlayerInputAdapter(
    playerId: playerId,
    attackRange: arena.playerAttackRange,
    attackHalfArcRadians: arena.playerAttackHalfArcRadians,
    attackCooldownSeconds: arena.playerAttackCooldownSeconds,
    attackQiDelta: attackQiDelta,
    gatherSlot: arena.gatherSlot,
    gatherRingRadius: arena.gatherRingRadius,
    gatherEffectRadius: arena.gatherEffectRadius,
    gatherQiCost: arena.gatherQiCost,
    gatherCooldownSeconds: arena.gatherCooldownSeconds,
    clearSlot: arena.clearSlot,
    clearEffectRadius: arena.clearEffectRadius,
    clearQiCost: arena.clearQiCost,
    clearCooldownSeconds: arena.clearCooldownSeconds,
    numericSkillBindings: numericSkillBindings,
  );
}
