# P0 battle_engine 抽 strategy 层重构 · 完整 spec

> **任务级别**:P0 阶段最后一波(1.0 路线图 `docs/ROADMAP_1_0.md` v1.1 §P0,原 P0.2 升回 P0;P0.3 #41 已方案 C 砍归档推 P5.4b)
> **预估**:opus xhigh **6-12h**(R4 风险条:实测可能更长,2 batch 拆),用户拍板 **B 方案 2 batch**(Batch 1 抽象+实装+链路 ~5-7h / Batch 2 e2e+closeout ~2-3h)
> **开工模型**:必须 **opus xhigh**(跨模块战斗引擎重构,memory `feedback_model_selection` 实战锚点)
> **commit 前缀**:`[refactor]` 或 `[arch]`(strategy 抽象层)
> **作者**:Mac + Opus 4.7 · 2026-05-17 晚续起草

---

## 1. 背景

W18 Demo 主战场全收口 + P0.1 #38 数值重平衡 + P0.2 #40 本地排行榜两波销账后,P0 真正剩余 1 项:**battle_engine 抽 strategy 层重构**。

**根因**:`lib/features/battle/domain/battle_engine.dart`(467 行)当前是**单形态硬编码**(半横版 3v3 + actionPoint 累 1000 行动制 + 阴柔内伤 dot + 刚猛震伤全内嵌 `_resolveAction`/`_calculateInBattle`),`BattleEngine.tick / runToEnd / requestUltimate` 全部 static method。

**阻塞影响**(1.0 路线图 P3 §12.3):
- 轻功对决(水面/屋脊/竹林特殊战斗形态)
- 群战守城(5v5+ 大规模)
- PVP(Supabase 异步对战)

三种新形态战斗主循环差异巨大(参与人数/地形修正/异步快照),P3 阶段直接 fork battle_engine.dart 会产生 3 份 ~400 行高度重复代码 + 后续公式修改 3 处同步成本爆炸。**P0 期付 strategy 抽象层重构债** = P3 期三形态扩展不卡 strategy 层接口设计。

**根治目标**:抽 `BattleStrategy` 抽象基类 + `DefaultGroundStrategy` 实装(地面 3v3 100% 等价行为搬迁),`BattleEngine` 改 facade 委派给 strategy,Demo 阶段无视觉差异 / 无数值变化 / 无 e2e 退步;P3 期挂 `LightFootStrategy` / `MassBattleStrategy` / `PvpStrategy` 各自实装。

## 2. Reality check 现状盘点

**(本 spec 起草同会话已完成,详细 grep 结果见会话报告 1-5。下面是关键结论摘要。)**

### 2.1 battle_engine 链路依赖度

| 文件 | 行数 | 角色 | 进 strategy 边界? |
|---|---|---|---|
| `lib/features/battle/domain/battle_engine.dart` | 467 | static `tick`/`runToEnd`/`requestUltimate`/`_resolveAction`/`_calculateInBattle`(含阴柔内伤 dot + 刚猛震伤 v1.4) | ✅ 主循环全进 |
| `lib/features/battle/domain/battle_state.dart` | 381 | 纯 data class:BattleCharacter/BattleState/AttackResult/InternalInjurySlot | ❌ 数据载体不动 |
| `lib/features/battle/domain/damage_calculator.dart` | 303 | static `calculate`,view 预览路径用 | ❌ 不进(Q4 拍板) |
| `lib/features/battle/domain/battle_ai.dart` | 101 | static `BattleAI.decide`(选招/选目标) | ❌ 不进(Q4 拍板) |
| `lib/features/battle/application/stage_battle_setup.dart` | 245 | view 层 `_playerToBattle` + `applySynergy`(W18-A1 注入点) | ❌ 排除(Q5 拍板) |
| `lib/features/battle/application/battle_resolution.dart` | 303 | victory/defeat 后处理,读 finalState | ❌ 不动 |
| `lib/core/application/battle_providers.dart` | — | `BattleNotifier` Riverpod codegen:`startBattle/advance/requestUltimate` | ⚠️ 改 1 处 `BattleEngine.tick` 调用 |

### 2.2 生产 callsite 极小半径

直调 `BattleEngine.tick/runToEnd/requestUltimate` 的生产代码 **唯一 1 处**:`lib/core/application/battle_providers.dart:70/93`(BattleNotifier.advance 内)。

所有战斗入口走 `startBattle(left, right)` → BattleNotifier 持有 state → advance 驱动 tick:
- 主线:`lib/features/mainline/presentation/stage_entry_flow.dart:247`(15 关全走)
- 爬塔:`lib/features/tower/presentation/tower_entry_flow.dart:441`(30 层全走)
- Debug:`lib/features/debug/presentation/battle_test_menu.dart:338`
- Demo:`lib/features/battle/presentation/battle_demo.dart:189`

**结论**:strategy 注入 1 处生效全场景。

### 2.3 测试现状

test 数量:**888/888**(P0.2 #40 销账后基线),analyze 0 issues。

battle 相关 test 文件(直调 `BattleEngine.*` static 共 ~25+ 处):
- `test/combat/battle_engine_test.dart`(15+ 处 `BattleEngine.tick/runToEnd/requestUltimate`)
- `test/combat/t17_scenarios_test.dart`(5 处 `BattleEngine.runToEnd`)
- `test/combat/battle_log_test.dart`(1 处)
- `test/combat/battle_state_test.dart`
- `test/features/battle/application/battle_resolution_test.dart`(1004 行,走 finalState 不直调 tick)
- `test/features/battle/application/master_disciple_battle_test.dart`(180 行)
- `test/features/battle/application/stage_battle_setup_test.dart`(285 行,setup 层不动)
- `test/balance/maxhp_extremum_redline_test.dart`(117 行)
- `test/balance/synergy_hot_loop_upgrade_test.dart`(233 行,applySynergy 直调,setup 层不动)

### 2.4 全战斗场景实测(45 + 5)

| 场景 | 实测数量 | 入口 | 备注 |
|---|---|---|---|
| 主线关 | **15** | `stage_entry_flow.runStageFlow` | data/stages.yaml 15 条 |
| 爬塔层 | **30** | `tower_entry_flow.runTowerFlow` | data/towers.yaml floorIndex 1-30 |
| **闭关地图战斗** | **0** | — | `SeclusionService.computeOutputs` 不调 BattleEngine,原 R4 prompt "5 闭关地图战斗"是误解 |
| 心法相生组合 | 5 | view 层 W18-A1 注入,setup 内 | applySynergy 在 strategy 边界外 |

**真正 e2e 矩阵**:45 战斗场景 + 心法相生 5 组合在 BattleCharacter 入口注入后下沉 strategy 不感知。

## 3. 决议(用户拍板 5 项,2026-05-17 晚续)

| Q | 选项 | 拍板 |
|---|---|---|
| Q1 分 batch | A 1 batch / **B 2 batch** / C 3 batch | **B**(Batch 1 抽象+实装+链路迁移 ~5-7h / Batch 2 e2e+closeout ~2-3h) |
| Q2 抽象粒度 | **粗粒度** / 细粒度 | **粗粒度**(`BattleStrategy.tick/runToEnd/requestUltimate` 3 个 abstract method 一波抽,不拆 hook) |
| Q3 e2e 覆盖 | **A 全场景一波切** / B 分批迁移 | **A**(45 场景 + 心法相生 5 + 现有 t17/battle_engine_test/balance 全过) |
| Q4 边界含 DamageCalculator/BattleAI? | A 都进 / **B 都不进** | **B**(只圈 tick 循环 + `_resolveAction` + `_calculateInBattle`) |
| Q5 含 applySynergy? | 进 / **排除** | **排除**(view 层 setup 子步骤,strategy 不感知 synergy 概念) |

**核心边界**:
- ✅ **strategy 含**:`tick` / `runToEnd` / `requestUltimate` 主循环 + `_resolveAction` + `_calculateInBattle` + 阴柔内伤 dot + 刚猛震伤
- ❌ **strategy 排除**:BattleState/BattleCharacter(数据)/ DamageCalculator(view 路径)/ BattleAI(选招通用)/ applySynergy(setup 视角注入)/ battle_resolution(后处理)

## 4. 实装拆解(2 Batch × 5 Phase)

### Batch 1:抽象 + 实装 + 链路迁移(~5-7h,1 commit cluster)

#### Phase 1:`BattleStrategy` abstract + `DefaultGroundStrategy` 实装(~3h)

**新建 `lib/features/battle/domain/strategy/battle_strategy.dart`**(~30 行):

```dart
abstract class BattleStrategy {
  const BattleStrategy();

  /// 推进一个 tick(对应原 BattleEngine.tick)。
  BattleState tick(BattleState state, NumbersConfig n, {Random? rng});

  /// 跑完整场战斗(对应原 BattleEngine.runToEnd)。
  BattleState runToEnd(BattleState initial, NumbersConfig n,
      {int maxTicks = 1000, Random? rng});

  /// 玩家手动请求大招(对应原 BattleEngine.requestUltimate)。
  BattleState requestUltimate(
      BattleState state, int characterId, SkillDef ultimate);
}
```

**新建 `lib/features/battle/domain/strategy/default_ground_strategy.dart`**(~430 行):

把 `battle_engine.dart` 467 行内的 `tick`/`runToEnd`/`requestUltimate`/`_resolveAction`/`_calculateInBattle`/`_advanceTick`/`_actorOrder`/`_findById`/`_replaceById`/`_formatAction`/`_fmt` 11 个 static method 全部搬迁到本类,改 `static` → instance method,签名不变。

**关键搬迁规则**:
- 公式语义零变化(GDD §5.3-§5.6 + §12.1 #7 v1.4 阴柔/刚猛)
- `defender.defenseRate` 读字段路径不变(W18-A1.2 hot-loop 升级版 hotfix 已落)
- `n.schoolCounter.yinRouInternalInjury.turnsPersist/damagePerTick` 读路径不变
- `_replaceById` static helper 同步迁(本类私有 helper)

#### Phase 2:`BattleEngine` 改 facade(~30min)

`lib/features/battle/domain/battle_engine.dart` 整体替换为 ~50 行 facade:

```dart
/// 战斗引擎门面(Phase 5 第 7 批 P0 strategy 重构后)。
///
/// 历史:Phase 1 T12 起为单形态硬编码 static 类。1.0 路线图 P0 抽 strategy
/// 层(详 docs/handoff/p0_battle_strategy_spec.md),本类保留为 facade,
/// 委派给注入的 BattleStrategy 实现(默认 DefaultGroundStrategy)。
///
/// 直接使用 BattleEngine.* 等价于使用 DefaultGroundStrategy(向后兼容旧
/// test/combat/* 体例);BattleNotifier 走 strategy 注入,P3 三战斗形态
/// (轻功/群战/PVP)分别挂自己的 BattleStrategy 实现。
class BattleEngine {
  BattleEngine._();

  static final BattleStrategy _default = DefaultGroundStrategy();

  static BattleState tick(BattleState state, NumbersConfig n, {Random? rng}) =>
      _default.tick(state, n, rng: rng);

  static BattleState runToEnd(BattleState initial, NumbersConfig n,
          {int maxTicks = 1000, Random? rng}) =>
      _default.runToEnd(initial, n, maxTicks: maxTicks, rng: rng);

  static BattleState requestUltimate(
          BattleState state, int characterId, SkillDef ultimate) =>
      _default.requestUltimate(state, characterId, ultimate);
}
```

**理由**:test/combat/* 25+ 处直调 `BattleEngine.*` 不动(沿向后兼容),只在生产路径 `BattleNotifier` 注入真 strategy,P3 三形态扩展时 BattleNotifier 接 strategy 参数即可。

#### Phase 3:`BattleNotifier` 接 strategy injection(~1h)

`lib/core/application/battle_providers.dart`:

```dart
@Riverpod(keepAlive: true)
class BattleNotifier extends _$BattleNotifier {
  @override
  BattleState build() => BattleState.initial(...);

  /// 当前战斗的 strategy。startBattle 时由调用方注入(默认 DefaultGroundStrategy)。
  /// P3 期轻功对决 startBattle 传 LightFootStrategy 即可换形态。
  BattleStrategy _strategy = DefaultGroundStrategy();

  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    BattleStrategy? strategy,
  }) {
    _strategy = strategy ?? DefaultGroundStrategy();
    state = BattleState.initial(leftTeam: leftTeam, rightTeam: rightTeam);
  }

  void requestUltimate(int characterId, SkillDef ultimate) {
    state = _strategy.requestUltimate(state, characterId, ultimate);
  }

  void advance() {
    var s = state;
    final n = ref.read(numbersConfigProvider);
    for (var i = 0; i < advanceTicksPerFrame; i++) {
      if (s.isFinished) break;
      s = _strategy.tick(s, n);
    }
    state = s;
  }
  // ... resolveBattle 不动(读 finalState)
}
```

**4 个 startBattle callsite 不必改**(strategy 参数 nullable 默认 DefaultGroundStrategy):
- `stage_entry_flow.dart:247`
- `tower_entry_flow.dart:441`
- `battle_test_menu.dart:338`
- `battle_demo.dart:189`

P3 期改为 `startBattle(left, right, strategy: LightFootStrategy())` 三形态自然 plug-in。

**Batch 1 commit cluster(预期 2-3 commit)**:
1. `[arch] Phase 1 BattleStrategy abstract + DefaultGroundStrategy 实装(11 method 搬迁,公式零变化)`
2. `[refactor] Phase 2 BattleEngine 改 facade 委派 DefaultGroundStrategy(test/combat 向后兼容)`
3. `[refactor] Phase 3 BattleNotifier 接 strategy injection(默认 DefaultGroundStrategy,P3 三形态 plug-in)`

### Batch 2:e2e + closeout(~2-3h)

#### Phase 4:e2e 全场景红线压测(~1.5h)

**新建 `test/balance/battle_strategy_e2e_test.dart`**(~250 行):

| 测试组 | case 数 | 红线语义 |
|---|---|---|
| 主线 15 关 e2e | 15 | 每关 `BattleEngine.runToEnd` 推完不抛 + result ∈ {leftWin, rightWin, draw} + maxTicks 1000 不撞 |
| 爬塔 30 层 e2e | 30 | 每层 `BattleEngine.runToEnd` 推完不抛 + result 有解 + 1000 maxTicks 不撞 |
| 心法相生 5 组合不退步 | 5 | applySynergy 5 组合分别注入 → runToEnd 推完不抛 + finalState.tick > 0 |
| backwards compat | 5 | `BattleEngine.tick/runToEnd/requestUltimate` static 直调结果与 `DefaultGroundStrategy().tick/...` 等价 |

**红线语义(memory `feedback_red_line_test_semantics` 实践)**:
- ✅ 写约束:「runToEnd 不抛 / result 有解 / maxTicks 不撞」
- ❌ 不写瞬时事实:「主线 1-1 finalState.tick 必须等于 N」(数值会随心法/装备成长漂移)

**现有 test 不退步**(命中 ~30+ test file):
- `test/combat/battle_engine_test.dart` 15+ 处直调 `BattleEngine.*` → 走 facade 等价,**预期 0 改动**
- `test/combat/t17_scenarios_test.dart` 5 处直调 `BattleEngine.runToEnd` → 等价
- `test/combat/battle_log_test.dart` 1 处 → 等价
- `test/balance/synergy_hot_loop_upgrade_test.dart` applySynergy 不动 → 0 改动
- `test/features/battle/application/battle_resolution_test.dart` 1004 行 → 走 finalState 不直调 tick → 0 改动

#### Phase 5:closeout + PROGRESS 销账(~30min)

**closeout 文件**:`docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`

体例沿 P0.1 #38 / P0.2 #40 closeout:
- §1 总览(Phase 1-5 全过)
- §2 关键产出(BattleStrategy + DefaultGroundStrategy + facade + BattleNotifier injection)
- §3 文件清单(增 2 / 改 2 / test 增 1)
- §4 e2e 红线矩阵实测
- §5 commit 链(Batch 1 cluster + Batch 2 cluster)
- §6 风险落地(R4 实测时长 vs 预估)
- §7 memory 引用(feedback_avoid_over_engineer_abstraction / feedback_layered_bugs / feedback_red_line_test_semantics)
- §8 下一步(P0 阶段全销账,进 P1 §12.4 节日内容 + A1 师徒 E.1/E.5)

**PROGRESS.md 修订**:
- 「当前阶段」段顶加「P0 battle_engine strategy 重构销账(2 batch,~6-10h)」
- 「下一步」改「P0 全销账,进 P1 系统纵深 + 美术 PoC」
- 销账条目列表加 「P0 strategy 重构销账」

**ROADMAP_1_0.md** 修订:
- §P0 段 P0.2 行加销账日期 + closeout 链接
- §修订记录加 v1.2 条目(P0 全销账)

## 5. 验收红线

### 5.1 行为等价(零退步)

- **888/888 test 不退步**(P0.2 #40 销账后基线)
- **analyze 0 issues**
- 主线 15 关 + 爬塔 30 层在 Phase 4 e2e 全过(45 场景)
- 心法相生 5 组合 applySynergy → runToEnd 全过
- `BattleEngine.tick(s, n) == DefaultGroundStrategy().tick(s, n)` 等价(同 rng seed)

### 5.2 数值红线(GDD §5.4 守护)

不退步:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000。

**Strategy 抽象层不改公式**,数值红线由现有 `test/balance/maxhp_extremum_redline_test.dart`(117 行)+ `test/balance/synergy_hot_loop_upgrade_test.dart`(233 行)兜底,本批 spec 不新增数值红线 case。

### 5.3 公式语义(GDD §5.3/§5.6 + §12.1 #7 v1.4)

零变化:
- 基础伤害公式系数(内力 ×0.4 + 装备 ×1.0 + 招式倍率)
- 最终伤害 6 维度乘积(修炼度 × 流派克制 × 暴击 × 防御率 × 境界差)
- 阴柔内伤 dot(turnsPersist=3 / damagePerTick=200,§12.1 #7 v1.4)
- 刚猛震伤(穿透防御 +500,§12.1 #7 v1.4)
- 灵巧暴击 ×2.0(v1.0 起)
- defender.defenseRate(W18-A1.2 hotfix 加法叠加 + clamp ≤ 0.95)

### 5.4 接口稳定性

- `BattleEngine.tick/runToEnd/requestUltimate` 签名不变(facade 等价)
- `BattleState` / `BattleCharacter` / `AttackResult` 字段不变
- `BattleNotifier.startBattle` 加可选 `strategy` 参数,4 callsite 不必改

### 5.5 P3 三形态预留

`BattleStrategy` abstract 3 method 签名足够 P3 三形态自然 plug-in:
- `LightFootStrategy`:复用 `runToEnd` 接口,内部 tick 实装水面/屋脊地形修正
- `MassBattleStrategy`:复用 `runToEnd` 接口,内部 tick 处理 5v5+ 阵型
- `PvpStrategy`:复用 `runToEnd` 接口,异步快照对战(P3 期 Supabase 接入)

## 6. 风险列表

### R1 公式语义漏迁(高)

**风险**:`battle_engine.dart` 467 行内 11 个 method 搬迁过程中遗漏边角分支(尤其是 `_resolveAction` 阴柔内伤 dot 致死分支 / 排序破平局 `_actorOrder`)。

**对策**:
- Phase 1 搬迁前先 `cp battle_engine.dart strategy/default_ground_strategy.dart` 完整复制,再改 `class BattleEngine` → `class DefaultGroundStrategy` + static → instance
- Phase 4 backwards compat 5 case 强制 `BattleEngine.tick == strategy.tick`(同 rng seed)
- 现有 t17_scenarios_test.dart 5 场景 + battle_engine_test.dart 15+ case 是公式语义守门员

### R2 实测时长爆 12h 上限(中)

**风险**:strategy 重构看似机械搬迁,实测 BattleNotifier injection + test 适配可能撞坑(尤其是若发现搬迁过程中需调整 BattleState 字段)。

**对策**:
- Batch 1 完成后若实测已 >7h,Batch 2 拆独立会话(不堵 commit cluster 一波)
- Batch 1 commit cluster 必 push 后再开 Batch 2

### R3 上层 fail 掩盖下层(中,memory `feedback_layered_bugs` 实战)

**风险**:strategy 抽出 → Phase 2 facade 替换 BattleEngine 后,test 全过未必证明下层无 bug(尤其是 instance 化后某个 instance field 误共享导致跨场景污染)。

**对策**:
- DefaultGroundStrategy 内**不持任何 mutable state**(所有 method 接 `BattleState` 入参输出新 state,与原 static method 行为完全一致)
- Phase 1 落地后强制 `final BattleStrategy _default = DefaultGroundStrategy()`(单例,验证无状态)

### R4 修改 BattleNotifier `_strategy` 字段引入 race(低)

**风险**:`_strategy` 在 startBattle 时写入,advance 时读取,Riverpod codegen 单线程 ok 但若 P3 PVP 异步对战会暴露 race。

**对策**:
- Demo 阶段 PVP 不实装(P3 才接),本 spec _strategy 单线程读写够用
- P3 期若需多并发,改 strategy 跟 state 一起进 BattleState(passed-with-state)再设计

### R5 e2e 45 场景执行慢(低)

**风险**:Phase 4 e2e 每场景跑 runToEnd 上限 1000 tick,45 场景 + 5 synergy 总执行 ~50 × 1000 = 50000 tick 单元,~30s 执行可能影响 CI 跑 test 总时长。

**对策**:
- e2e 走 NumbersConfig 真值 + Random(seed=42) 复现,不 mock
- 若实测单文件 >10s,可拆为 `test/balance/battle_strategy_e2e_mainline_test.dart`(主线 15 + synergy 5)+ `test/balance/battle_strategy_e2e_tower_test.dart`(爬塔 30)

### R6 P3 三形态预留接口不足(低)

**风险**:粗粒度 3 method 抽象未必满足 P3 群战守城(可能需 N v N 协作 AI hook)/ PVP(可能需异步快照接口)。

**对策**:
- 用户拍板 Q2 粗粒度(memory `feedback_avoid_over_engineer_abstraction` 不预先抽象)
- P3 期遇真痛点时再加 hook(从 `runToEnd` 内部抽 `_pickAction` 等),P0 期不预设

## 7. 测试矩阵

### 7.1 新增 test(Phase 4)

| 文件 | case 数 | 用途 |
|---|---|---|
| `test/balance/battle_strategy_e2e_test.dart` | ~55 | 45 场景 e2e + 心法相生 5 + backwards compat 5 |

预估 test 总数:**888 → ~943**(+55)。

### 7.2 现有 test 0 改动(Phase 1-3 落地后必过)

| 文件 | case 数 | 验证 |
|---|---|---|
| `test/combat/battle_engine_test.dart` | 15+ | `BattleEngine.tick/runToEnd/requestUltimate` facade 等价 |
| `test/combat/t17_scenarios_test.dart` | 5 | `BattleEngine.runToEnd` 主线场景等价 |
| `test/combat/battle_log_test.dart` | 1 | runToEnd 路径等价 |
| `test/combat/battle_state_test.dart` | — | BattleState 不动 |
| `test/features/battle/application/battle_resolution_test.dart` | 1004 行 | finalState 路径不动 |
| `test/features/battle/application/master_disciple_battle_test.dart` | 180 行 | 师徒战斗 finalState 不动 |
| `test/features/battle/application/stage_battle_setup_test.dart` | 285 行 | setup 层不动 |
| `test/balance/maxhp_extremum_redline_test.dart` | 117 行 | applySynergy 直调不动 |
| `test/balance/synergy_hot_loop_upgrade_test.dart` | 233 行 | applySynergy 直调不动 |

**Phase 1-3 落地后所有现有 test 必须 0 改动通过**(facade 等价兜底)。

### 7.3 红线断言语义(memory `feedback_red_line_test_semantics` 实践)

**正例**(本 spec 采用):
- `BattleEngine.runToEnd(initial, n) 不抛`
- `finalState.result ∈ {leftWin, rightWin, draw}`
- `finalState.tick < 1000`(maxTicks 不撞)
- `BattleEngine.tick(s, n, rng: Random(42)) == strategy.tick(s, n, rng: Random(42))`(行为等价)

**反例**(本 spec 不采用):
- ❌ `主线 1-1 finalState.tick == 23`(数值层会漂移)
- ❌ `爬塔 floor 5 finalState.leftTeam[0].currentHp == 4523`(随心法/装备成长漂移)
- ❌ `心法相生阴阳调和 finalState 必 leftWin`(随敌人 EnemyDef 调整漂移)

## 8. memory 引用

| memory | 引用位置 |
|---|---|
| `feedback_model_selection` | §0 必须 opus xhigh 锚点 |
| `feedback_phase0_grep_two_axes` | §2.1 reality check 两维 grep(维度 A:0 abstract BattleStrategy 命中 / 维度 B:有 P3 三形态多实现真痛点)→ 「0→1 全新」格子 |
| `feedback_avoid_over_engineer_abstraction` | §3 Q2 粗粒度拍板理由 + §6 R6 对策 |
| `feedback_layered_bugs` | §6 R3 上层 fail 掩盖下层风险条 |
| `feedback_red_line_test_semantics` | §5 + §7.3 红线断言语义(写约束不写瞬时事实) |
| `feedback_session_close_prompt_on_demand` | §4 Phase 5 closeout 段格式 |
| `feedback_closeout_numbers_grep` | §4 Phase 5 closeout 数字 grep 实测纪律 |

## 9. 决策日志

| 决策 | 拍板 | 理由 |
|---|---|---|
| 分 batch | B 2 batch | 战斗主循环紧,1 batch 切完不留中间态;e2e 单独一批让 closeout 体例稳 |
| 抽象粒度 | 粗粒度 3 method | memory `feedback_avoid_over_engineer_abstraction`:Demo 1 实现,P3 三形态真痛点在主循环不在 hook,粗粒度足够 |
| e2e 覆盖 | A 全场景一波 | memory `feedback_layered_bugs`:上层 fail 易掩盖下层,strategy 是骨架重构必须一波全过 |
| DamageCalculator/BattleAI 边界 | B 都不进 | DamageCalculator 是 view-out 路径不在战斗循环 / BattleAI 选招逻辑跨形态通用,留 domain |
| applySynergy 边界 | 排除 | view 层 setup 子步骤(BattleCharacter 装配阶段一次性注入),strategy 只接受已注入的 BattleCharacter 快照 |
| Facade 保留 | 是 | test/combat/* 25+ 处直调 `BattleEngine.*` 向后兼容,免去 25+ 处 test 改动 |
| BattleNotifier `_strategy` 字段位置 | instance field | startBattle 注入,advance 读取;Demo 单线程足够,P3 PVP 异步时再设计 |
| commit 前缀 | `[arch]` / `[refactor]` | Phase 1 抽象用 `[arch]`,Phase 2-3 改 facade/notifier 用 `[refactor]`,e2e 用 `[test]`,closeout 用 `[docs]` |

---

## 附:Phase 0 reality check 二度自审(起草 spec 末尾再 grep 一次)

| 自审项 | 实测 | 结论 |
|---|---|---|
| `battle_engine.dart` 行数 | 467 | ✅ 与 spec §2.1 一致 |
| 生产直调 `BattleEngine.*` 数 | 1 处(battle_providers.dart) | ✅ 与 spec §2.2 一致 |
| test 直调 `BattleEngine.*` 数 | 25+ 处(test/combat/*) | ✅ facade 兜底必要性确认 |
| applySynergy 战斗主循环外? | 是(setup 层 view) | ✅ Q5 排除决议正确 |
| 主线关数 | 15 | ✅ data/stages.yaml 实测 |
| 爬塔层数 | 30 | ✅ data/towers.yaml floorIndex 1-30 |
| 闭关战斗数 | **0** | ✅ 修正原 prompt "5 闭关地图"误解 |
| 心法相生组合数 | 5 | ✅ data/synergies.yaml 实测 |
| test 基线 | 888/888 + analyze 0 | ✅ P0.2 #40 销账后 |

**Spec 起草完毕,~510 行,9 段全落,2 batch × 5 phase 拆解 + 6 风险 + 7 memory + 9 决策日志。等用户拍板可否开 Batch 1。**
