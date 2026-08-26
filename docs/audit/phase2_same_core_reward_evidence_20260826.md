# 二阶段同核奖励证据（N14 / C12 + C14）

## 组数溯源

现取 `/Users/a10506/Desktop/Projects/挂机武侠-p2-spec-audit/docs/audit/phase2_spec_reality_audit_20260826.md:56`，计数确为 7；对应 `/Users/a10506/Desktop/二阶段优化方案.md:338-343` 六条和 `:517` 一条，无拆分或合并。

| 组 | 原文断言 | N14 前为何无法判定 |
|---:|---|---|
| 1 | 手动控制：键鼠转为领域 intent； | 只有黑风岭三路径终态记录，未给键鼠→intent 与四模式逐 tick 证据。 |
| 2 | 自动战斗：player bot 产生同样 intent； | 只有黑风岭 manual/auto/headless parity，不能覆盖生产 sweep。 |
| 3 | 差遣/扫荡/离线：headless 以更快速度推进相同 fixed tick； | 未见四模式 fixed tick/hash 对照。 |
| 4 | 相同角色快照、内容 seed、战术和输入序列必须得到相同领域事件与结算 hash； | 缺同快照、同 seed、同输入的逐 tick/事件/结算矩阵。 |
| 5 | 不允许为离线另写一套“战力比较公式”绕开技能、姿态、受伤与敌人机制； | 启动门仍分流离线系统，未用生产终局反校验同核 trace。 |
| 6 | 允许表现层不渲染、时间批量推进，但不能改变规则。 | 未证明 sync 与 async 批量推进逐 tick/事件相等。 |
| 7 | 同一活动的手动、自动和差遣使用同一重复掉落表，不设置“手动收益 +50%”。 | 未见四模式实际重复结算后的多重集 profile。 |

## 固定 seed 模式矩阵

- 关卡：真实主线 `stage_01_01`（不是黑风岭 `stage_01_03`）；周目 1；同一 P3 生产角色快照；战术 `steadyGuard`。
- 战斗 seed `2026082701`：manual 通过生产 `Phase0aBattleController` 回放 bot 冻结 command；前台 bot 通过同 controller 逐拍生成 command；headless 走生产 `Phase0aHeadlessRunner.runToEnd`；sweep trace 走 sweep 使用的同 mapper/assembler 与 `runToEndAsync`，并以真实 `Phase0aSweepHeadlessRunner.runMainline` 终局反校验。
- 奖励 seed `2026082702`：`rngProvider.overrideWithValue(DefaultRng(seed: ...))`；战斗沿既存 `mathRandomProvider` override，不新增 `Random` 签名 service。每模式独立同初始存档，真实结算链连续重打 3 次。
- hash 为测试内稳定 FNV-1a 64-bit 摘要；每 tick 输入含全状态与有序 `CombatEventRecord`，不使用进程随机化的 Dart `hashCode`。

| 模式 | tick | 战斗 trace hash | 生产结算 | 重复掉落 profile hash |
|---|---:|---|---|---|
| manual | 76 | `3898e0822cd4fc59`（四模式矩阵总摘要） | `leftWin`，与其余模式摘要相同 | `3f5cec5f1b4acbbb` |
| bot | 76 | 同 manual（逐 tick 列表相等） | 同 manual | 同 manual |
| headless | 76 | 同 manual（逐 tick 列表相等） | 同 manual | 同 manual |
| sweep | 76 | 同 manual（async 逐 tick 列表相等） | 真实 sweep runner 终局与 trace 相同 | 同 manual |

重复 profile（保留多重计数，不转 set）：`equipment={armor_xunchang_bu_yi:3, accessory_xunchang_tong_ling:2}`；`items={item_mojianshi:3, item_silver:16}`；`exp=15`。

## 逐组结论

| 组 | 结论 | 机器断言 |
|---:|---|---|
| 1 | PASS | manual 每拍 command 经生产 input adapter 产生非空领域 intent，四模式 tick hash 相同。 |
| 2 | PASS | 前台 bot command 序列与 manual 冻结回放逐项相同，四模式 tick hash 相同。 |
| 3 | PASS | headless/sweep 均 76 fixed ticks，四模式逐 tick hash 相同且 sweep 未 timeout。 |
| 4 | PASS | 四模式状态、领域事件、有序事件记录和结算摘要相同。 |
| 5 | PASS | 真实生产 sweep runner 的终局与同核 trace 结算摘要相同。 |
| 6 | PASS | sync headless 与 async sweep 的逐 tick 状态、有序事件完全相同。 |
| 7 | PASS | 四条真实结算链的三次重复掉落多重集、物品数量与经验完全相同。 |

确定答案：`7/7 PASS`，无 FAIL、无 `skip:`、无需改 `lib/`，满足 `[READY]` 条件。本证据只回答该真实主线活动的四模式同核，不外推到塔、远征、断魂庄或所有关卡。

## 可复跑证据

```text
flutter test --no-pub test/features/mainline/application/phase2_same_core_reward_evidence_test.dart --reporter expanded
run 1: exit 0; 7 passed; battle=3898e0822cd4fc59; ticks=76; reward=3f5cec5f1b4acbbb
run 2: exit 0; 7 passed; battle=3898e0822cd4fc59; ticks=76; reward=3f5cec5f1b4acbbb
post-format run: exit 0; 7 passed; hashes unchanged
flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact
exit 0; 27 passed（真实 WASD/J/鼠标→controller/reducer）
flutter test --no-pub test/features/mainline --reporter compact
exit 0; All tests passed
flutter test --no-pub test/features/sweep --reporter compact
exit 0; 50 passed
flutter analyze --no-pub test/features/mainline/application/phase2_same_core_reward_evidence_test.dart
exit 0; No issues found
```
