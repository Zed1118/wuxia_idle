# Phase 2 战斗核心四条决策候选（2026-08-26）

## 覆盖、边界与重跑

- 覆盖 `4/4`：`TUNE-POSTURE-01`、`TUNE-WEAPON-TIMELINE-01`、`TUNE-ATTACK-TOKEN-01`、`TUNE-WEAPON-QI-01`；无未覆盖项。
- 仅生成 `TUNING/candidate`，未替用户决定，未改生产数值/YAML，未给 PARKED 合同接线。
- 重跑：`flutter test --no-pub test/tuning/phase2_combat_core_tuning_candidates_test.dart`；输出很小，直接打印，未另落大文件。
- 样本：脚本读取 105 个生产主线（Boss 42 个）、221 个生产招式，以及黑风岭 40 敌/12 active 的生产 encounter；每个场景按生产 `0.1s` tick 跑 `300s`。
- 来源缩写：`S`=`test/tuning/phase2_combat_core_tuning_candidates_test.dart` + 上述实测输出；`NQ`=`data/numbers.yaml:73-86`；`NT`=`data/numbers.yaml:510-540`；`SK`=`data/skills.yaml:77-119`；`EC`=`data/combat/encounters/black_wind_ridge.yaml:4-14`；`RB`=`data/combat/runtime_bindings.yaml:42-78`。每个候选数值只标生产锚点或 `S`，无第三类来源。

## TUNE-POSTURE-01

`PostureConfig` 全参顺序为 `capacity / vulnerabilityTicks / recoveryPolicy / postVulnerabilityAccumulated`；Boss 折算另列 `conversionFactor`。输入节奏锚定 `NT`，Boss 破招点取 `data/skills.yaml:55-71`，候选值均由 `S` 跑批筛出。

| 参数 | A | B | C | 来源 |
|---|---:|---:|---:|---|
| capacity | 10 | 14 | 18 | A/B/C=`S` |
| vulnerabilityTicks | 3 | 4 | 5 | A/B/C=`S` |
| recoveryPolicy | reset | recover | recover | A/B/C=`S` |
| postVulnerabilityAccumulated | 0 | 4 | 9 | A/B/C=`S` |
| Boss conversionFactor | 2 | 3 | 4 | A/B/C=`S` |

| 实测指标（42 Boss） | A | B | C |
|---|---:|---:|---:|
| 平均首次破防 | 2.21s | 2.87s | 3.64s |
| 每分钟进入破防窗 | 21.81 | 22.32 | 25.18 |
| 破防窗时间占比 | 10.90% | 14.88% | 20.98% |
| 窗内被抑制姿态命中/分钟 | 7.58 | 11.44 | 14.06 |

- A 优化最快读懂“打满即开窗”，代价是 0 累积重置使连续压制收益最低。
- B 优化可重复的攻防循环且窗占比控制在约 15%，代价是首次破防比 A 晚 0.66s。
- C 优化长窗口与连续压制密度，代价是约 21% 时间处于破防且每分钟 14.06 次姿态命中被吞，过控风险最高。

## TUNE-WEAPON-TIMELINE-01

每格为 `windupTicks / activeTicks / recoveryTicks / firstEffectTick / cancelWindowStartTick / cancelWindowEndTick / interruptedCooldownTicks / cancelledCooldownTicks / failedCooldownTicks`，即 `ActionTimelineConfig` 9 个构造参数全量；候选均为 `S`，tick 与当前普攻 0.55s 锚定 `NT`。

| 武器 | A | B | C | 来源 |
|---|---|---|---|---|
| sword | 1/2/2/1/1/3/2/1/3 | 1/2/3/1/1/4/3/2/4 | 1/3/2/1/2/4/2/2/3 | A/B/C=`S` |
| heavy | 2/2/2/2/2/4/3/2/4 | 2/3/3/2/2/5/4/3/5 | 2/4/2/2/3/6/3/2/4 | A/B/C=`S` |
| flexible | 1/3/2/1/1/4/2/1/3 | 1/4/2/1/1/4/3/2/4 | 1/5/1/1/2/5/2/2/3 | A/B/C=`S` |
| dual | 0/3/2/0/0/3/2/1/3 | 0/4/2/0/0/4/2/1/3 | 0/5/1/0/1/5/2/1/3 | A/B/C=`S` |
| hidden | 0/1/3/0/0/2/2/1/3 | 0/2/3/0/0/3/2/1/3 | 0/3/2/0/1/3/2/1/3 | A/B/C=`S` |

| 实测指标（105 主线 × 5 武器） | A | B | C |
|---|---:|---:|---:|
| 首效/分钟 | 94.41 | 92.76 | 63.57 |
| 完整收招/分钟 | 5.83 | 2.11 | 2.21 |
| 平均输入→首效 | 33.42ms | 32.35ms | 22.87ms |
| active 时间占比 | 19.45% | 19.43% | 17.93% |
| 威胁到来时成功取消 | 78.37% | 77.33% | 38.96% |
| 首效前被打断 | 18.34% | 20.81% | 59.61% |

- A 优化高频出手与随时收手，代价是五武器承诺感最接近。
- B 在首效密度仅降 1.75% 时拉开重武器/软兵器 active 与 recovery，代价是完整收招降至 2.11/分钟、首效前打断增至 20.81%。
- C 优化 0–0.2s 内立即见效和持续命中段，代价是取消率腰斩、首效前打断 59.61%，不适合作默认但可作为高承诺对照。

## TUNE-ATTACK-TOKEN-01

四项即 `AttackTokenBudgets` 全构造参数；A 锚定当前生产 `EC`，B/C 由 `S` 在 `RB` 的真实四类/优先级与 40 敌轮转中跑出。

| 参数 | A | B | C | 来源 |
|---|---:|---:|---:|---|
| melee | 1 | 2 | 3 | A=`EC:11`；B/C=`S` |
| ranged | 1 | 2 | 1 | A=`EC:12`；B/C=`S` |
| charge | 1 | 1 | 2 | A=`EC:13`；B/C=`S` |
| support | 1 | 1 | 1 | A=`EC:14`；B/C=`S` |

| 实测指标（300 批 × 每批 12 请求） | A | B | C |
|---|---:|---:|---:|
| 平均授予/批 | 2.07 | 3.24 | 3.85 |
| 总授予率 | 17.28% | 27.03% | 32.06% |
| 平均连续拒绝批数 | 10.64 | 9.95 | 9.55 |
| melee/ranged/charge/support 授予率 | 13.30/17.32/17.73/54.17% | 25.69/33.01/17.73/54.17% | 37.18/17.32/33.69/54.17% |

- A 优化最低并发压力，代价是 82.72% 请求无令牌，群敌参与感最低。
- B 优化近战与远程同时参与（分别 25.69%/33.01%），代价是平均并发由 2.07 升至 3.24。
- C 优化贴身/冲锋压力和最高总参与率，代价是远程仍停在 17.32%，攻势更偏科且防御负荷最高。

## TUNE-WEAPON-QI-01

每格为 `QiResourceLedger(capacity,current) / basic gainAction / power reserve / ultimate reserve / kill gainKill / kill windowCap`，即 `capacity/opening/basicGain/powerCost/ultimateCost/killGain/killWindowCap`；恢复策略另列。100/40 来自 `NQ:74-75`，A 的 20/30/60 来自 `SK:83,98,113`，其余候选收支为 `S`。

| 武器/策略 | A | B | C | 来源 |
|---|---|---|---|---|
| recoveryPolicy | basicOnly | weaponWeightedBasic | basicAndCappedKill | A/B/C=`S` |
| sword | 100/40/20/30/60/0/0 | 100/40/22/32/60/0/0 | 100/40/20/28/52/5/15 | cap/open=`NQ`；A 收支=`SK`+`S`；B/C=`S` |
| heavy | 100/40/20/30/60/0/0 | 100/40/28/40/70/0/0 | 100/40/24/34/60/5/15 | 同上 |
| flexible | 100/40/20/30/60/0/0 | 100/40/24/34/62/0/0 | 100/40/22/30/54/5/15 | 同上 |
| dual | 100/40/20/30/60/0/0 | 100/40/18/28/54/0/0 | 100/40/18/24/46/5/15 | 同上 |
| hidden | 100/40/20/30/60/0/0 | 100/40/20/30/56/0/0 | 100/40/18/26/48/5/15 | 同上 |

| 实测指标（105 主线 × 5 武器） | A | B | C |
|---|---:|---:|---:|
| 成功招式/分钟 | 48.47 | 49.29 | 52.53 |
| 真气不足拒绝 | 14.72% | 13.28% | 7.59% |
| 低于本武器 powerCost 的时间 | 16.63% | 18.74% | 13.43% |
| 平均真气 | 49.14 | 55.96 | 55.96 |
| 收益溢出 | 2.28% | 7.06% | 5.70% |

- A 优化规则最易读并复用现有 20/30/60，代价是每分钟少 4.06 次招式且不足拒绝最高。
- B 优化五武器气感差异，代价是高收费重武器使低于 powerCost 时间反升至 18.74%，且溢出最高。
- C 优化击杀后立刻续招并把不足拒绝压到 7.59%，代价是表现依赖击杀节奏，Boss 单体段收益会收窄。

## 用户需要拍什么

- `TUNE-POSTURE-01`：破防循环选 A/B/C？我推荐 **B**，约 15% 窗占比兼顾读懂循环与不过控。
- `TUNE-WEAPON-TIMELINE-01`：五武器动作承诺选 A/B/C？我推荐 **B**，保住 92.76 首效/分钟同时建立武器差异。
- `TUNE-ATTACK-TOKEN-01`：敌方并发预算选 A/B/C？我推荐 **B**，参与率提升 9.75 个百分点而不把压力集中到冲锋。
- `TUNE-WEAPON-QI-01`：真气恢复选 A/B/C？我推荐 **C**，招式频率最高且不足拒绝最低，但需接受击杀驱动语义。
