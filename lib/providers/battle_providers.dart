import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../combat/battle_engine.dart';
import '../combat/battle_state.dart';
import '../data/defs/skill_def.dart';
import '../data/game_repository.dart';
import '../data/numbers_config.dart';

part 'battle_providers.g.dart';

/// numbers.yaml 配置（[GameRepository] 单例的 provider 包装）。
///
/// 启动时 `GameRepository.loadAllDefs()` 完成后即可读。测试中可通过
/// `numbersConfigProvider.overrideWithValue(testNumbers)` 注入。
@riverpod
NumbersConfig numbersConfig(NumbersConfigRef ref) =>
    GameRepository.instance.numbers;

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
  @override
  BattleState build() => BattleState.initial(
        leftTeam: const [],
        rightTeam: const [],
      );

  /// 启动新战斗：重置 state 为 initial，actionLog / pendingUltimates 全清。
  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam,
  ) {
    state = BattleState.initial(leftTeam: leftTeam, rightTeam: rightTeam);
  }

  /// 玩家手动请求大招（phase1_tasks T16.2）。
  ///
  /// 标记 pending；该角色下次行动时 [BattleAI] 优先消费。若内力 / CD 不满足，
  /// 引擎会跳过并从 pendingUltimates 移除（一次机会，不留到下次）。
  void requestUltimate(int characterId, SkillDef ultimate) {
    state = BattleEngine.requestUltimate(state, characterId, ultimate);
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
  /// 也会被 [BattleEngine.runToEnd] 的 1000 maxTicks 兜住，但单次 advance
  /// 不该卡死 UI 线程，限到 100。
  void advance({int maxConsecutiveTicks = 100}) {
    if (state.isFinished) return;
    final n = ref.read(numbersConfigProvider);
    var s = state;
    final originalLogLen = s.actionLog.length;
    var consumed = 0;
    while (s.actionLog.length == originalLogLen &&
        !s.isFinished &&
        consumed < maxConsecutiveTicks) {
      s = BattleEngine.tick(s, n);
      consumed++;
    }
    state = s;
  }
}

/// 派生 provider：左队（避免整 [BattleState] 引用变化触发整屏 rebuild）。
///
/// Phase 1 先做 team 级颗粒度，Windows 首跑 inspector 验若仍整屏 rebuild
/// 再细化到单角色 currentHp（spec §16.1 注：「每个角色一个 currentHp 单独
/// provider 也不过分」）。
@riverpod
List<BattleCharacter> leftTeam(LeftTeamRef ref) =>
    ref.watch(battleNotifierProvider).leftTeam;

@riverpod
List<BattleCharacter> rightTeam(RightTeamRef ref) =>
    ref.watch(battleNotifierProvider).rightTeam;

/// 派生 provider：战斗结果。`null` = 进行中；非空 = 已结束。
/// UI 用 `ref.listen` 监听非空翻转触发结算 overlay。
@riverpod
BattleResult? battleResult(BattleResultRef ref) =>
    ref.watch(battleNotifierProvider).result;
