import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  /// 本场战斗的单一 seeded rng(确定性地基,balance_simulator 数千局依赖)。
  ///
  /// [startBattle] 用注入或自动生成的 seed 重建;[advance] / [step] 全程复用同一
  /// 实例,确保同 seed 逐 action 可复现(测试服务 + balance sim)。
  Random _rng = Random();

  @override
  BattleState build() => BattleState.initial(
        leftTeam: const [],
        rightTeam: const [],
      );

  /// 启动新战斗：重置 state 为 initial，actionLog / pendingUltimates 全清。
  ///
  /// [strategy] 可选注入当前战斗形态(默认 [DefaultGroundStrategy] 地面 3v3
  /// 半横版);P3 三战斗形态扩展时挂自己的 [BattleStrategy] 实装即可。
  /// [seed] 注入本场战斗随机种子(确定性地基):测试 / balance sim 传固定 seed
  /// 复刻;实战不传则生成一个种子。
  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    BattleStrategy? strategy,
    int? seed,
  }) {
    _strategy = strategy ?? const DefaultGroundStrategy();
    _rng = Random(seed ?? Random().nextInt(1 << 32));
    state = BattleState.initial(leftTeam: leftTeam, rightTeam: rightTeam);
  }

  /// 玩家手动请求大招（phase1_tasks T16.2）。
  ///
  /// 标记 pending；该角色下次行动时 [BattleAI] 优先消费。若内力 / CD 不满足，
  /// 引擎会跳过并从 pendingUltimates 移除（一次机会，不留到下次）。
  /// [targetId] 半手动 P0 步骤3a:玩家指定目标 charId;null = 走 AI 默认选目标。
  void requestUltimate(int characterId, SkillDef ultimate, {int? targetId}) {
    // 委托 strategy 校验(非 normalAttack 等)并置 pending;该角色下次行动消费。
    // Phase 4 拖招命中走此入口(targetId = 命中的敌人)。
    state = _strategy.requestUltimate(state, characterId, ultimate,
        targetId: targetId);
  }

  /// 主线二 2.3:玩家拖招立即插队出手(委托 strategy,消费本场同一 [_rng])。
  ///
  /// 仅玩家 interactive 路径(`_onSkillCommand` gate 后)调用。委托
  /// [BattleStrategy.interveneNow]:[DefaultGroundStrategy] 立即结算 + 预支归零,
  /// 其它形态降级 pending。战斗已结束则 noop。
  void interveneNow(int characterId, SkillDef skill, {int? targetId}) {
    if (state.isFinished) return;
    state = _strategy.interveneNow(
      state,
      characterId,
      skill,
      targetId: targetId,
      n: ref.read(numbersConfigProvider),
      rng: _rng,
    );
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

  /// 常速 UI 播放驱动：推进到「下一个 action」即停（区别于 [advance] 排空整
  /// tick）。循环 [BattleStrategy.stepOne] 直到 actionLog 恰好 +1 或战斗结束，
  /// 自动跳过无人出手的 tick 边界空步。复用本场单一 seeded [_rng]，逐 action
  /// rng 消费顺序与 [advance] / [step] 完全一致 → 战斗结果逐位不变
  /// （`battle_advance_one_action_test` 红线锁死）。
  ///
  /// [maxConsecutiveSteps] 兜底：境界差 3+ 近免疫时连续空 tick 也会被
  /// strategy maxTicks 兜住，但单次调用不该卡死 UI 线程，限到 300
  /// （> [advance] 的 100：stepOne 含边界步 + 逐 actor 出队步，粒度更细）。
  void advanceOneAction({int maxConsecutiveSteps = 300}) {
    if (state.isFinished) return;
    final n = ref.read(numbersConfigProvider);
    var s = state;
    final originalLogLen = s.actionLog.length;
    var consumed = 0;
    while (s.actionLog.length == originalLogLen &&
        !s.isFinished &&
        consumed < maxConsecutiveSteps) {
      s = _strategy.stepOne(s, n, rng: _rng);
      consumed++;
    }
    state = s;
  }

  /// 推进最小一步:走 [BattleStrategy.stepOne] —— tick 边界步(填本回合行动
  /// 队列,无人出手)或结算队列中一个 actor。复用本场单一 seeded [_rng],与
  /// [advance] 整 tick 路径 rng 消费顺序一致(`battle_step_one_test` 红线锁死)。
  ///
  /// 战斗交互重做 Phase 4「拖招立即触发」消费:拖招命中 [requestUltimate] 置
  /// pending 后,连续 [step] 快进到该角色出手(确定性安全,不真插队)。
  void step() {
    if (state.isFinished) return;
    state =
        _strategy.stepOne(state, ref.read(numbersConfigProvider), rng: _rng);
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
/// **UNUSED-PENDING-1.1**(全系统审计 2026-06-24 B3·诚实标注延期·非误删死码):
/// 本函数 0 生产 caller(仅 `jianghu_r5_test` 引用)。整条恩怨→战斗链 dormant:
/// 上游 [NpcRelationService.upsert] 无生产写入(关系永不建立)+ 本烘焙未接入
/// stage_battle_setup → APM 末端乘永不触发。**故意延期 1.1**:真 NPC 恩怨需先
/// 扩 `StageDef.npcId` schema(与审计 D3 npcId 死字段同源),给 stage_boss_kill /
/// encounter 写入真 NPC 关系后,再在 battle setup await 调本函数。service +
/// provider + R5.7 红线测全建好,1.1 接 schema 即可激活,不删。
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
