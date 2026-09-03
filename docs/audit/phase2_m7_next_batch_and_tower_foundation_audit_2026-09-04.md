# Phase 2 M7 下一批与塔迁移基础门审计（2026-09-04）

## 当前结论

本审计基于 `main == origin/main == 54e79b0466c48f8f624ae2c63b80b91db850abb1` 的 clean 状态。全主线 typed production catalog 为 `76/105`，剩余 `29`；塔为 `0/49`；legacy runtime retirement 仍开放。正式 M7 未关闭，Phase 2 仍为 `1/10`。

下一完整主线门固定为第十七章 `stage_17_01..05`，预期只推进 `76/105 → 81/105`。第十三章剩余 `4/5` 继续隔离：已有 `stage_13_02` 是用户签署的 25-actor 寺院生态路线，而另外四关 StageDef 与正文是单敌合同；不得套用普通章节模板替用户决定生态。

塔迁移不能直接复用当前主线适配器。它须先关闭一个不增加 `0/49` 分子的基础门，再按七层一包推进。基础门负责多敌运行时绑定、护法 ID 翻译与三个生产入口同源；未通过基础门前，不登记任何塔层为 typed migrated。

## 主线剩余分布与执行顺序

| 章 | 已迁移 | 剩余 | 已知特殊机制 |
| --- | ---: | ---: | --- |
| 13 | 1/5 | 4 | 既有 25-actor 寺院生态与其余单敌合同存在决策边界 |
| 17 | 0/5 | 5 | 两个 Boss；17-05 vulnerability `0.20` |
| 18 | 0/5 | 5 | 两个 Boss；两处 vulnerability |
| 19 | 0/5 | 5 | 两个 Boss；vulnerability + cycle |
| 20 | 0/5 | 5 | 两个 Boss；两处 vulnerability + cycle |
| 21 | 0/5 | 5 | 两个 Boss；两处 vulnerability + cycle + survive |

推荐顺序为 `17 → 18 → 19 → 20 → 21 → 13 决策审计`。前五章均可各自形成不竞争的 `5/5` 完整门，先将主线推进至 `101/105`；第十三章只在 25-actor 与单敌合同的生态边界重新签署后施工。

第十七章五关的 StageDef、技能、正文、图标与冻结章级口径均完整，敌队均为单敌。17-01/02/03 使用 defeat-target，17-04/05 使用 defeat-commander；17-04 的 `lingQiao` 是既有签署会话对早期 spec 的明确修正，不是待调数值。施工合同复用第十六章的 RED、exact actor/Boss snapshot、dynamic victory、变异恢复、持锁全量、受控集成与 exact-SHA CI 链。

## 塔基础门为何必须独立

当前塔已经运行在 Phase 0A 内核上，但仍直接消费 `TowerFloorDef`：

1. 可见入口 `Phase0aTowerBattleHost` 直接调用 `Phase0aStageContentMapper.mapTower`。
2. 即时挂机 `Phase0aSweepHeadlessRunner.runTower` 直接调用 `mapTower`。
3. 耐久恢复 `Phase0aSweepHeadlessRunner.runTowerDurable` 直接调用 `mapTower`。

因此塔 `0/49` 不是“仍走旧 3v3”，而是尚未进入 typed catalog / encounter / runtime binding / objective / director 路径。旧 3v3 引擎已经由 Route C 删除；此处所称 legacy retirement 是这些直接 StageDef/TowerFloorDef mapper 与主线 null fallback 的退役。

直接复用主线适配器会产生两个确定性缺陷：

- `CombatRuntimeBindingLoader` 与 `Phase0aMainlineRepositoryRuntimeBindingAdapter` 均要求 StageDef 恰有一个基敌；塔有 49 层、116 个唯一敌人，其中 36 层是多敌队。
- typed factory 把敌人运行时 ID 生成为 `stage/encounter/actor-NNN`，而 42/49 层 `guardianWard.guardianIds` 引用 EnemyDef ID。reducer 只按 actor ID 或其 `_w` 前缀查护法；若不显式翻译，护法减伤、破招代吃与合击会静默失效。

## 塔基础门的最小实现边界

1. 增加 content-kind-aware 的塔 typed route/runtime source，每个 spawn entry 精确绑定一个 `TowerFloorDef.enemyTeam` 成员；不改敌人名、数值、技能、图标、奖励、周目或存档。
2. 每层只建立一个 encounter；目标按现有战斗语义映射为 defeat-all 或 defeat-commander，`activeLimit` 等于当前同时在场敌人数，不猜测新生态。
3. 在 actor ID 分配完成后，将 Boss 的 guardian EnemyDef ID 翻译成同 encounter 的权威 runtime actor ID；悬空、重复、自引用一律 fail closed。
4. 可见入口、即时挂机、耐久恢复三处统一消费同一个 typed host，保持 settlement、首通、奖励与个人进度 owner 不变。
5. 代表层 `1/7/14/32/42/49` 在 cycle 1/2 对比现有 direct mapper 与 typed 路径；精确核对 actor、技能、Boss phase、charge、vulnerability、guardian ward、终局与结算。
6. live/headless 同 seed 保持一致；加入多敌绑定、护法 ID 翻译、三入口切换及反向 mutation。基础门通过仍记塔 `0/49`，之后按 `1–7 / 8–14 / 15–21 / 22–28 / 29–35 / 36–42 / 43–49` 七包迁移。

## 最终退役边界

主线还有两处生产 fallback：可见 host 与 sweep 在 typed encounter 为 null 时回落 `Phase0aStageContentMapper.map`。塔有上述三处 direct `mapTower`，合计五个生产接缝。

当主线达到 `105/105` 后，生产加载必须强制精确覆盖全部 105 个主线 ID，再删除两处 null fallback；当塔达到 `49/49` 后删除三处 direct `mapTower`。纯测试 helper 的 migration coverage 不算生产 fail-closed。只有五个接缝完成 typed-only、回归通过并进入 `main/origin/main`，才能登记 legacy runtime consumers 为 `0`。

## 本次验证与边界

- 当前 main 的第十六章治理尾 exact-SHA CI run `33811930886` 为 `completed/success`。
- 塔宿主、live/headless 同 seed、护法红线、vulnerability 与即时/耐久挂机 focused 回归 `16/16 PASS`。
- 既有更宽塔回归为 `141/141 PASS`；它证明当前 direct mapper 基线健康，不证明 typed 塔迁移已完成。
- 本审计未修改玩法、数值、schema/saveVersion、GDD、CLAUDE、正文或玩家规则；未启动 M8/M9。
- 真人视觉、音频、手感、Mac 桌面实战与 Windows 继续 `DEFERRED`，自动化不代签。
