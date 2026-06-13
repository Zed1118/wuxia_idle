import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/battle/domain/battle_replay.dart';
import '../../features/battle/domain/battle_state.dart';
import '../../features/battle/domain/strategy/battle_strategy.dart';
import '../../features/battle/domain/strategy/default_ground_strategy.dart';
import '../../data/defs/skill_def.dart';
import '../../data/defs/stage_def.dart';
import '../../data/game_repository.dart';
import '../domain/character.dart';
import '../domain/equipment.dart';
import '../domain/technique.dart';
import '../../data/numbers_config.dart';
import '../../features/battle/application/battle_resolution.dart';
import '../../features/equipment/application/drop_service.dart';
import '../../features/jianghu/application/npc_relation_service.dart';
import '../../shared/utils/rng.dart';

part 'battle_providers.g.dart';

/// numbers.yaml 配置（[GameRepository] 单例的 provider 包装）。
///
/// 启动时 `GameRepository.loadAllDefs()` 完成后即可读。测试中可通过
/// `numbersConfigProvider.overrideWithValue(testNumbers)` 注入。
@riverpod
NumbersConfig numbersConfig(Ref ref) =>
    GameRepository.instance.numbers;

/// 装备掉落服务（T27 DropService）的 provider。
///
/// 走 [GameRepository] 单例查 EquipmentDef；测试中可 override 注入 mock。
@riverpod
DropService dropService(Ref ref) => DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
    );

/// 战斗状态 Notifier（phase1_tasks T16.1）。
///
/// **immutable state**：[BattleState] copyWith 推进，UI 通过 `ref.watch` /
/// `ref.listen` 监听变化。状态切换流：
/// ```
///                startBattle(left, right)        ┌──── advance() (UI Timer 驱动)
///   initial ──────────────────────────► running ─┤  └─► running (actionLog 追加)
///   (空团)                                       └─► finished (result 非空)
///                       ▲
///                       │ requestUltimate(charId, skill)
///                       │   下次该角色行动消费
/// ```
///
/// `build()` 返回空团 initial 状态，由 [BattleDemoLauncher] 等启动器在
/// initState 中调用 [startBattle] 注入双方角色。
@riverpod
class BattleNotifier extends _$BattleNotifier {
  /// 当前战斗 strategy(1.0 路线图 P0 抽 strategy 层重构,详
  /// `docs/handoff/p0_battle_strategy_spec.md`)。
  ///
  /// 默认 [DefaultGroundStrategy](Demo 阶段唯一实装);P3 §12.3 三战斗形态
  /// 扩展时 startBattle 传 LightFootStrategy / MassBattleStrategy /
  /// PvpStrategy 即可换形态,advance / requestUltimate 自动走对应实装。
  BattleStrategy _strategy = const DefaultGroundStrategy();

  /// 本场战斗的单一 seeded rng(半手动战斗 P0 §3.1 确定性地基)。
  ///
  /// [startBattle] 用注入的 seed 重建;[advance] 全程复用同一实例,确保
  /// 同 seed 逐 action 可复现(手动通关记 seed → 同 seed 重演复刻通关)。
  Random _rng = Random();

  /// 本场战斗的 seed(半手动 P0 步骤5-A)。[startBattle] 注入或自动生成。
  ///
  /// Dart `Random(seed)` 的种子不可从实例回溯,故这里独立存:手动首通通关后
  /// 由落盘层 [BattleReplayRecordService.record] 经 [seed] getter 采集写入,
  /// 自动战斗读出同 seed 确定性重演(`replay`)。
  int _seed = 0;

  /// 本场战斗 seed(可回溯,供手动通关落盘采集)。
  int get seed => _seed;

  /// 本场战斗的手动操作记录(半手动 P0 §2.2 步骤2)。按 [requestUltimate]
  /// 调用顺序追加;[startBattle] 清空。步骤4 重放、步骤5 落盘消费。
  final List<BattleReplayOp> _recordedOps = [];

  /// 本场已记录的手动操作序列(只读视图)。
  List<BattleReplayOp> get recordedOps => List.unmodifiable(_recordedOps);

  @override
  BattleState build() => BattleState.initial(
        leftTeam: const [],
        rightTeam: const [],
      );

  /// 启动新战斗：重置 state 为 initial，actionLog / pendingUltimates 全清。
  ///
  /// [strategy] 可选注入当前战斗形态(默认 [DefaultGroundStrategy] 地面 3v3
  /// 半横版);P3 三战斗形态扩展时挂自己的 [BattleStrategy] 实装即可。
  /// [seed] 注入本场战斗随机种子(半手动 P0 §3.1):重放时传记录的 seed
  /// 确定性复刻;实战不传则**生成**一个可回溯种子(步骤5-A),供手动通关后
  /// 经 [seed] getter 采集落盘(`Random(null)` 的种子不可回溯,故必须先生成)。
  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    BattleStrategy? strategy,
    int? seed,
  }) {
    _strategy = strategy ?? const DefaultGroundStrategy();
    _seed = seed ?? Random().nextInt(1 << 32);
    _rng = Random(_seed);
    _recordedOps.clear();
    state = BattleState.initial(leftTeam: leftTeam, rightTeam: rightTeam);
  }

  /// 玩家手动请求大招（phase1_tasks T16.2）。
  ///
  /// 标记 pending；该角色下次行动时 [BattleAI] 优先消费。若内力 / CD 不满足，
  /// 引擎会跳过并从 pendingUltimates 移除（一次机会，不留到下次）。
  /// [targetId] 半手动 P0 步骤3a:玩家指定目标 charId;null = 走 AI 默认选目标。
  void requestUltimate(int characterId, SkillDef ultimate, {int? targetId}) {
    // 先委托(校验非 normalAttack 等),成功置 pending 后再记录,避免无效请求
    // 留下脏 op。锚点 = 当前 state.tick(requestUltimate 不推进 tick)。
    state = _strategy.requestUltimate(state, characterId, ultimate,
        targetId: targetId);
    _recordedOps.add(BattleReplayOp(
      anchor: state.tick,
      charId: characterId,
      skillId: ultimate.id,
      targetId: targetId,
    ));
  }

  /// UI Timer 驱动的状态前进（phase1_tasks T16.1 spec 字面写 `advanceTick`，
  /// 实际语义是"前进到下一个 action 或战斗结束"）。
  ///
  /// 单 tick 是 time-based 行动制的最小单位（全员 actionPoint += speed），
  /// 不一定有人累积到 1000 触发行动。若 UI Timer 间隔 = 单 tick 间隔，
  /// 慢角色场景会看到大段空白。所以这里**连续 tick 直到 actionLog 增长或
  /// 战斗结束**，UI 体验上每次 Timer 触发都对应一次动画。
  ///
  /// [maxConsecutiveTicks] 兜底：境界差 3+ 双方近免疫时，多次连续无 action
  /// 也会被 strategy 内部 maxTicks 兜住，但单次 advance 不该卡死 UI 线程，
  /// 限到 100。
  void advance({int maxConsecutiveTicks = 100}) {
    if (state.isFinished) return;
    final n = ref.read(numbersConfigProvider);
    var s = state;
    final originalLogLen = s.actionLog.length;
    var consumed = 0;
    while (s.actionLog.length == originalLogLen &&
        !s.isFinished &&
        consumed < maxConsecutiveTicks) {
      s = _strategy.tick(s, n, rng: _rng);
      consumed++;
    }
    state = s;
  }

  /// 半手动战斗 P0 步骤3b:推进最小一步(spec §八#3「一步=一 actor」)。
  ///
  /// 单步 UI(步骤3c)的驱动入口:每次调用走 [BattleStrategy.stepOne] —— tick
  /// 边界步(填本回合行动队列,无人出手)或结算队列中一个 actor。复用本场
  /// 单一 seeded [_rng],与 [advance] 整 tick 路径 rng 消费顺序一致(同 seed
  /// 两条路径复刻同一场战斗,`battle_step_one_test` 红线锁死)。
  ///
  /// 玩家手动指令仍走 [requestUltimate] 在 step 之间布置;锚点 = `state.tick`。
  void step() {
    if (state.isFinished) return;
    state =
        _strategy.stepOne(state, ref.read(numbersConfigProvider), rng: _rng);
  }

  /// 半手动战斗 P0 步骤4:重放执行(spec §五 P0#4)。
  ///
  /// 给定本场 [seed] + 录制的操作序列 [ops](`{anchor=tick, charId, skillId,
  /// targetId}`),确定性复刻手动通关:同 seed 重建 rng(`startBattle`)+ 用
  /// [step] 逐步推进(与步骤3c 手动录制同粒度,每个整数 tick 都落点)+ 在
  /// `state.tick == op.anchor` 时回放 [requestUltimate](与录制时机一致)。
  ///
  /// **确定性地基**:rng 走 `startBattle(seed:)` 注入的单一 seeded 实例,
  /// stepOne 拆 actor 不改 rng 消费顺序(`battle_step_one_test` /
  /// `battle_seed_determinism_test` 锁死)→ 同 seed + 同 ops 两次重放逐 action
  /// 与胜负全等(`battle_replay_execution_test` 红线)。
  ///
  /// 内部复用 [requestUltimate],会把回放的指令重新写进 [recordedOps](在相同
  /// 锚点 → 重新派生序列与 [ops] 逐字段全等,幂等可溯)。技能由 op 的 skillId
  /// 在该 actor 当前 `availableSkills` 中解析;解析不到则跳过该 op(防脏数据,
  /// 不中断重放)。[maxSteps] 兜底防 near-immunity 死循环卡线程。
  void replay(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    required int seed,
    required List<BattleReplayOp> ops,
    int maxSteps = 20000,
  }) {
    startBattle(leftTeam, rightTeam, seed: seed);
    var opIdx = 0;
    var guard = 0;
    while (!state.isFinished && guard < maxSteps) {
      final tick = state.tick;
      while (opIdx < ops.length && ops[opIdx].anchor == tick) {
        final op = ops[opIdx];
        final skill = _resolveReplaySkill(op.charId, op.skillId);
        if (skill != null) {
          requestUltimate(op.charId, skill, targetId: op.targetId);
        }
        opIdx++;
      }
      step();
      guard++;
    }
  }

  /// 重放:按 charId + skillId 在该 actor 当前 `availableSkills` 中解析 SkillDef。
  /// 找不到返回 null(由 [replay] 跳过该 op)。
  SkillDef? _resolveReplaySkill(int charId, String skillId) {
    for (final c in state.leftTeam) {
      if (c.characterId != charId) continue;
      for (final s in c.availableSkills) {
        if (s.id == skillId) return s;
      }
    }
    for (final c in state.rightTeam) {
      if (c.characterId != charId) continue;
      for (final s in c.availableSkills) {
        if (s.id == skillId) return s;
      }
    }
    return null;
  }

  /// 战斗结算 hook（phase2_tasks T26 §340）。
  ///
  /// caller 在 result 翻转后调用（typically `ref.listen(battleResultProvider,
  /// (prev, next) { if (prev == null && next != null) notifier.resolveBattle(...); })`）。
  /// 服务 in-place 修改 Equipment / Technique，调用方负责 Isar `writeTxn` 写回 +
  /// `BattleResolutionResult.dropResult` 装备入背包 + UI 升层提示。
  ///
  /// 战斗未结束抛 StateError——防 caller 误调（spec §338 战败也结算，但仍要
  /// finalState 已结束）。
  BattleResolutionResult resolveBattle({
    required List<Character> participatingCharacters,
    required Map<int, List<Equipment>> equipmentsByCharacter,
    required Map<int, List<Technique>> techniquesByCharacter,
    required StageDef stageDef,
    required Rng rng,
  }) {
    if (!state.isFinished) {
      throw StateError(
        'BattleNotifier.resolveBattle: 战斗未结束 (state.result == null)，'
        '不能 resolve',
      );
    }
    final numbers = ref.read(numbersConfigProvider);
    final dropSvc = ref.read(dropServiceProvider);
    return BattleResolutionService.resolve(
      finalState: state,
      participatingCharacters: participatingCharacters,
      equipmentsByCharacter: equipmentsByCharacter,
      techniquesByCharacter: techniquesByCharacter,
      stageDef: stageDef,
      rng: rng,
      progressToNextMap: numbers.cultivationProgressToNext,
      techniqueDefLookup: GameRepository.instance.getTechnique,
      dropService: dropSvc,
    );
  }
}

/// 派生 provider：战斗结果。`null` = 进行中；非空 = 已结束。
/// UI 用 `ref.listen` 监听非空翻转触发结算 overlay。
@riverpod
BattleResult? battleResult(Ref ref) =>
    ref.watch(battleProvider).result;

/// P1.2 §5 江湖恩怨 attackPowerMultiplier 烘焙(spec §5 · battle setup 阶段一次性 SET)。
///
/// 沿 `light_foot_strategy.dart:120` / `mass_battle_strategy.dart:182` 体例:
/// 直接 `copyWith(attackPowerMultiplier: mult)` SET 不乘 · 双方对等。
///
/// **不变量**:
/// - 双向对等:enemy 端按 (player→enemy) 各自 mult SET;player 端取
///   `max(across enemies)` 合并 SET(任一敌人有 enmity → 玩家享最高档)。
/// - clamp ≤ `enmityCombatModifier.clampMax`(NpcRelationService.attackPowerMultFor 已保).
/// - 0 strategy 改:damage_calculator 已支持 attackPowerMultiplier(P3.1.B)。
/// - leftTeam.first.characterId < 0 / 空 → noop return(EnemyDef 占位场景兜底)。
/// - Demo enemy id 是负 slotIndex placeholder(EnemyDef 无真 NPC id),NpcRelation
///   查不到 → 返 1.0 noop · 真 NPC 接入 1.1+ 走 StageDef.npcId schema 扩。
///
/// 调用方负责 await 后再调 `BattleNotifier.startBattle(left, right)`(本函数
/// 不写 Isar,只装配快照)。
Future<(List<BattleCharacter>, List<BattleCharacter>)> bakeEnmityMultipliers({
  required NpcRelationService npcService,
  required List<BattleCharacter> leftTeam,
  required List<BattleCharacter> rightTeam,
}) async {
  if (leftTeam.isEmpty || rightTeam.isEmpty) return (leftTeam, rightTeam);
  final playerCharId = leftTeam.first.characterId;
  if (playerCharId < 0) return (leftTeam, rightTeam);

  var maxMult = 1.0;
  final newRight = <BattleCharacter>[];
  for (final enemy in rightTeam) {
    final mult =
        await npcService.attackPowerMultFor(playerCharId, enemy.characterId);
    if (mult > 1.0) {
      newRight.add(enemy.copyWith(attackPowerMultiplier: mult));
      if (mult > maxMult) maxMult = mult;
    } else {
      newRight.add(enemy);
    }
  }

  if (maxMult <= 1.0) return (leftTeam, newRight);
  final newLeft = <BattleCharacter>[
    leftTeam.first.copyWith(attackPowerMultiplier: maxMult),
    ...leftTeam.skip(1),
  ];
  return (newLeft, newRight);
}
