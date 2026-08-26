# N11 变异测试探针首轮报告（2026-08-26）

## 结论与守恒账

本轮把“生成”按任务契约解释为**已登记结果的 mutant 候选**，包括预算采样而未实际写入源码的候选；否则“未能生成/跳过”无法进入同一守恒分母。

- **五个互斥结果桶**：`总 mutant 记录 1350 = 有效被杀 4 + 存活 6 + 编译失败/测试崩溃 5 + 非目标测试杀 0 + 跳过/未能生成/超时 1335`，即 **`1350 = 4 + 6 + 5 + 0 + 1335`**。
- **协调者所称四项汇总**：`1350 = 有效被杀 4 + 存活 6 + 非有效异常 5（编译/崩溃 5 + 非目标杀 0）+ 跳过/未能生成/超时 1335`，即 **`1350 = 4 + 6 + 5 + 1335`**。
- 实际写入并执行的 16 个 mutant 另有守恒式：**`16 = 被杀 4 + 存活 6 + 编译/崩溃 5 + 非目标杀 0 + 超时 1`**。
- 可解释存活率：**`6 / (4 + 6) = 60.0%`**。分母只含得到有效测试判定的 10 个 mutant；编译/崩溃、非目标杀、超时和采样跳过均不进入得分。
- 执行样本中的原始存活占比：`6 / 16 = 37.5%`；候选执行覆盖率：`16 / 1350 = 1.19%`。本轮是预算内探针，不得把 60.0% 外推成两个文件的总体存活率。

首轮运行时间为 `2026-08-26 23:21:16 +0800` 至 `2026-08-27 02:55:02 +0800`，真实墙钟 `3:33:46`，低于 5 小时上限。原始 JSON（本机临时证据）为 `/tmp/n11-mutation-round1-20260826.json`，大小约 1.2 MiB，SHA-256：`e3bd981d6bc859e7838a6d844cbffb3e43d24ccf660b47f6b15b06e0cc8eff50`。

## 定向测试子集推导规则（原文）

> Parse every Dart import/export/part URI under lib/ and test/, add exact source-path reference edges, reverse-traverse from the mutated file, and select every reachable test/**/*_test.dart.

中文展开：扫描 `lib/` 与 `test/` 下全部 Dart 文件，解析每条 `import` / `export` / `part` URI（含条件 URI）；对“把生产源码当文本读取”的 source-contract 测试，补一条精确仓库相对路径或 `package:` URI 引用边。从被变异文件沿依赖图反向遍历，所有可达的 `test/**/*_test.dart` 构成定向子集。算法不含手工测试名单或“我觉得相关”的判断。

执行时使用 Flutter JSON reporter，并核对预期路径与实际 `suite` 事件集合。预期 suite 少加载一个即不得判绿，规避多显式路径静默漏跑。

| 目标 | 推导 suite | 基线实际加载 | 基线判定 | 基线墙钟 |
|---|---:|---:|---|---:|
| `phase0a_combat_reducer.dart` | 177 | 177 | 全绿 | 184.029 s |
| `phase0a_battle_screen.dart` | 83 | 83 | 全绿 | 90.115 s |

复现命令别名：

- **R**：`python3 tools/mutation/mutation_probe.py test --target lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart --timeout 900`
- **S**：`python3 tools/mutation/mutation_probe.py test --target lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart --timeout 900`

每个 mutant 的“定向测试命令”均为所在目标对应的 R 或 S；命令会重新计算子集并校验 suite 完整性。

## 算子与预算采样

工具支持并生成以下四类候选：

1. 比较符翻转：`>` ↔ `>=`、`==` ↔ `!=`；
2. 布尔常量替换：`true` ↔ `false`；
3. 数值常量替换：非零 `n` → `0`，以及所有 `n` → `n+1`；
4. 条件短路：完整 `if` / `while` 条件 → `true` 或 `false`。

字符串与注释先按等长 mask 排除；单独排除 Dart 泛型闭合 `>`。候选按 `target × 算子类` 分层，每层最多执行 2 个；层内先按变体 family 轮转，再按稳定 SHA-256 mutant ID 排序。所有未抽中候选逐条输出为 `skipped_sampling`，本报告按文件与算子聚合如下。

| 目标 | 布尔候选/跳过 | 比较候选/跳过 | 数值候选/跳过 | 条件候选/跳过 | 合计候选/执行/跳过 |
|---|---:|---:|---:|---:|---:|
| reducer | 24 / 22 | 142 / 140 | 160 / 158 | 198 / 196 | 524 / 8 / 516 |
| screen | 41 / 39 | 115 / 113 | 514 / 512 | 156 / 154 | 826 / 8 / 818 |
| **合计** | **65 / 61** | **257 / 253** | **674 / 670** | **354 / 350** | **1350 / 16 / 1334** |

## 存活 mutant 清单（6）

以下均为失败数 0、预期 suite 全部加载、命令退出 0。语法与上下文人工复核未发现疑似等价项；即使后续证明等价，也仍应保留在“存活”而不能转入“被杀”。

| ID | 位置 | 算子（原值 → 变异值） | 命令 | 失败数 | 判定 |
|---|---|---|---|---:|---|
| `48cabebfb9193b52` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:259` | `comparison_gt_to_gte`：`>` → `>=` | R | 0 | 存活 |
| `a2e825a7994d9318` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:505` | `numeric_increment`：`0` → `1` | R | 0 | 存活 |
| `4f8be52f67b5dde7` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1369` | `condition_to_true`：`cooldownSeconds > 0` → `true` | R | 0 | 存活 |
| `c21b6624fbe14537` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:453` | `condition_to_false`：`event is! KeyDownEvent` → `false` | S | 0 | 存活 |
| `5b0c134466fe14cb` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1223` | `numeric_to_zero`：`2` → `0` | S | 0 | 存活 |
| `deec0b4d0e031efb` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:2096` | `numeric_increment`：`0` → `1` | S | 0 | 存活 |

这些位置是下一批补测试的输入，本单未修改测试或生产代码。

## 有效被杀 mutant（4）

四项均为 JSON reporter 的 assertion `failure`，不是 compiler/load error 或测试 `error`；实际杀手 suite 均在推导子集中。

| ID | 位置 | 算子 | 命令 | 失败数 | 实际杀手 |
|---|---|---|---|---:|---|
| `80d34c62fb9b2785` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:410` | `boolean_true_to_false` | R | 1 | `phase0a_defense_vertical_slice_test.dart`：`defense plus player attack is rejected as one invalid action bundle` |
| `630c95c70b4a1c7c` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:733` | `comparison_eq_to_ne` | R | 1 | `phase0a_boss_phase_runtime_test.dart`：`AI casts only unlocked phase skill and reducer applies qi/cooldown/damage` |
| `60d3a9d336a1ad1c` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1457` | `numeric_to_zero` | R | 1 | `phase0a_guardian_coop_test.dart`：`两护法按稳定顺序各 resolver 一次、合并一次扣血并消费 partner intent` |
| `de77b5482212733c` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1586` | `boolean_false_to_true` | R | 1 | `phase0a_reducer_test.dart`：`前向扇形接线保留 guardian 过滤并只结算一个最近合法目标` |

## 必须单列 1：编译失败 / 测试崩溃（5，不算被杀）

本轮这 5 个没有 compiler/load pattern，也没有 suite 漏载；均由 JSON reporter 给出测试 `error`，因此保守归入“测试崩溃”，不把“页面挂了”算 mutation kill。

| ID | 位置 | 算子 | 命令 | error 数 | 代表性 error suite |
|---|---|---|---|---:|---|
| `b58b940d77d5ac81` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:134` | `boolean_true_to_false` | S | 1 | `phase0a_battle_screen_test.dart` |
| `0f4a7c1f2322ecf7` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:158` | `boolean_false_to_true` | S | 1 | `phase0a_battle_screen_test.dart` |
| `8cf038e1b11d7e43` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:169` | `comparison_eq_to_ne` | S | 14 | `phase0a_focus_nav_test.dart`、`phase0a_battle_screen_test.dart`、`phase0a_mainline_wiring_test.dart` 等 6 个 suite |
| `69cb511b562cbee7` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:389` | `condition_to_true` | S | 10 | `phase0a_battle_screen_test.dart`、`phase0c_embed_verification_test.dart`、`phase0a_mainline_wiring_test.dart` 等 5 个 suite |
| `2212b5a5758ce6e2` | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:940` | `comparison_gt_to_gte` | S | 3 | `phase0a_battle_screen_test.dart` |

## 必须单列 2：被非目标测试杀掉（0）

计数为 **0**。四个有效被杀项的失败 suite 全部属于各自静态推导的定向子集；运行时也没有加载任何推导集合之外的 suite。因此不存在可说明的非目标实际杀手，本桶不并入“被杀”。

## 必须单列 3：跳过 / 未能生成 / 超时（1335）

### 预算采样跳过（1334）

分解见“算子与预算采样”表：reducer 跳过 516，screen 跳过 818，合计 1334。每个候选仍有稳定 ID、文件、行、算子、定向命令、失败数 0 与 `skipped_sampling` 判定，由探针逐条输出；报告使用聚合表避免 1334 行淹没有效证据。无静默截断。

### 超时（1）

| ID | 位置 | 算子 | 命令 | 失败/error 数 | 判定 |
|---|---|---|---|---:|---|
| `8ad2e1751eccc9bc` | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1469` | `condition_to_false`：完整四分支 guard → `false` | R | 83 / 83 | timeout，不算被杀 |

该项在 900 秒测试上限处触发 timeout，但首版探针只终止 Flutter 父进程，编译后代仍持有输出管道，导致实际等待 `10790.882 s`；停止时 89/177 个 suite 尚未加载。主分类按互斥优先级记为 timeout，不再重复计入 compiler/crash。跑批完成后工具已改成独立 POSIX 进程组，超时先 TERM 全组、5 秒后仍存活则 KILL 全组；新增“子进程持有输出管道”回归测试，探针自测 10/10。为保持测量诚实，本报告不重写首轮原始结果。

本轮“未能生成”另计 0；所有 1350 个候选均成功形成结果记录。

## 逐执行 mutant 账本

| # | ID | `file:line` | 算子 | 命令 | 失败数 | 判定 |
|---:|---|---|---|---|---:|---|
| 1 | `48cabebfb9193b52` | reducer:259 | `>` → `>=` | R | 0 | survived |
| 2 | `80d34c62fb9b2785` | reducer:410 | `true` → `false` | R | 1 | killed |
| 3 | `a2e825a7994d9318` | reducer:505 | `0` → `1` | R | 0 | survived |
| 4 | `630c95c70b4a1c7c` | reducer:733 | `==` → `!=` | R | 1 | killed |
| 5 | `4f8be52f67b5dde7` | reducer:1369 | condition → `true` | R | 0 | survived |
| 6 | `60d3a9d336a1ad1c` | reducer:1457 | `1` → `0` | R | 1 | killed |
| 7 | `8ad2e1751eccc9bc` | reducer:1469 | condition → `false` | R | 83 | timeout |
| 8 | `de77b5482212733c` | reducer:1586 | `false` → `true` | R | 1 | killed |
| 9 | `b58b940d77d5ac81` | screen:134 | `true` → `false` | S | 1 | compile_or_crash |
| 10 | `0f4a7c1f2322ecf7` | screen:158 | `false` → `true` | S | 1 | compile_or_crash |
| 11 | `8cf038e1b11d7e43` | screen:169 | `==` → `!=` | S | 14 | compile_or_crash |
| 12 | `69cb511b562cbee7` | screen:389 | condition → `true` | S | 10 | compile_or_crash |
| 13 | `c21b6624fbe14537` | screen:453 | condition → `false` | S | 0 | survived |
| 14 | `2212b5a5758ce6e2` | screen:940 | `>` → `>=` | S | 3 | compile_or_crash |
| 15 | `5b0c134466fe14cb` | screen:1223 | `2` → `0` | S | 0 | survived |
| 16 | `deec0b4d0e031efb` | screen:2096 | `0` → `1` | S | 0 | survived |

## 单 mutant、还原与范围证据

- 跑批前 `git status -sb` 原文：

  ```text
  ## codex/p2-mutation-probe-20260826
  ```

- 跑批后 `git status -sb` 原文：

  ```text
  ## codex/p2-mutation-probe-20260826
  ```

- 每次只写一个 target 的一个 span；测试子进程结束后在 per-mutant `finally` 写回原始 bytes，再校验目标 SHA-256。
- reducer 跑前/跑后 SHA-256：`6b7fa8f5d7e0ed1869294622ce2e364e541c1d7300557a4429d727c211700f3e`。
- screen 跑前/跑后 SHA-256：`8c2758a7b253d923a79696c2a91b7aa0759b230f728f449be3d3b1d6a7e9794a`。
- 跑批后 `git diff --quiet -- lib test data` 退出 0；生产代码、测试与数据最终改动均为 0。
- 本单未修改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart` 或 `pubspec.yaml`；未 push、未 merge、未碰 main、未改测试或生产代码来提高分数。

## 风险与下一批输入

1. 6 个存活点表明样本内确有测试守护缺口；优先级建议从 reducer 三处开始，因为它们位于结算核心且不是纯视觉差异。
2. 5 个 screen mutant 只得到测试 `error`，不能作为承重断言证据；后续应把相关 widget 测试的失败方式收敛为可归因 assertion，但本单不修。
3. 本轮只执行 1.19% 候选。扩大覆盖前应先按真实耗时进一步缩窄映射或增加基于符号/行的可复现映射规则；不能直接把 177-suite reducer 子集乘到全部候选。
