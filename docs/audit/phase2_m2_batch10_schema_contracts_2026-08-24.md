# 二阶段 M2 Batch10 Schema 与运行策略合同审计（2026-08-24）

## 基线与目的

- 基线：G0 READY `44e42497b9e4968e6baa64ed10ad940034664220`。
- 目标：关闭 Ch1 黑风岭生产纵切前的 catalog 表达能力、主线参与/连续 run、随行听剑占用与 claim 三条合同关键路径。
- 本批不切生产数据、host、save、UI 或奖励，不把 tuning 候选提升为生产值。

## 预检发现

- Batch7 catalog schema 只有单一 objective；二阶段 §14 明确七模板由八个原语组合，因此完整 M2 模板不能直接表达。
- spawn entry 只有 archetype/role 引用，尚无入口/位置/行为引用；archetype role 也缺攻击集合、tags、posture、drop、SFX、visual 引用。
- G0 已冻结 replay/run/听剑产品语义，但 exact count、activeLimit、补兵阈值、token budget、武器/防御参数仍为 tuning，当前仅允许生成候选。

## 来源包

| ID | 执行端 | 当前状态 | 受保护边界 |
|---|---|---|---|
| `P2-M2-C01-CATALOG-SCHEMA-GATEWAY` | Codex high | ready_reviewed | 内容中立、fail closed、无生产默认 |
| `P2-M2-R01-MAINLINE-RUN-PARTICIPATION` | Qoder / Qwen3.8-Max high | ready_reviewed | 纯合同、无 host/save/UI/双 preset |
| `P2-M2-R02-MENTOR-INSIGHT-CONTRACT` | Pi / DeepSeek V4 Flash high | ready_reviewed | 无 rate/cap/生产发放/持久化 |
| `P2-G7-BALANCE-REFERENCE-CLOSEOUT` | Codex high + Pi/Qoder 复审 | ready_reviewed | 只订正退役诊断标签，不改公式/断言/生产行为 |

## 后续唤醒条件

- C01 READY：可启动 objective/token runtime 及 Ch1 候选数据 fixture；候选仍不得直接提升为 production YAML。
- R01 READY：只解除 mainline policy 合同层；生产 host、sweep、结果页另立集成任务。
- R02 READY：只解除占用和 claim 合同层；主修熟练度实际发放继续等待 rate/cap 证据 Gate。
- M2/G2 最终通过仍需用户完成八项真人试玩签字，自动测试不能代替。

## 验证记录

- C01：实现 `fb420893`、READY `925f2908`、集成 `b195571b`；主控复跑 137/137，scoped analyze 0，独立复审 P0/P1/P2=0。
- R02：实现链 `e6800ace` → `56ff3169` → `ef18fcb0`、READY `150e518a`、集成链 `c40921cd` → `c87bb751` → `dc9f7c69`；主控复跑 60/60，scoped analyze 0，独立复审 P0/P1/P2=0。
- R02 首版自造 claim codec/ledger 与第二版 canonical alias 均在集成前被拒绝并修复；最终复用 shared `RewardClaimKey`，不声称进程内 guard 具备 durable exactly-once。
- R01：实现 `eefab0aa`、READY `b9d07314`、集成 `f5e6abe0`；主控复跑 36/36，scoped analyze 0，独立复审 P0/P1/P2=0。实时 replay 只允许合格闲置人类/机器人，headless replay、扫荡与首通继续使用当前领队；连续 run 锁定参与者与不透明 loadout snapshot，并要求外部 battle-eligibility 事实后才能推进下一关。
- C01 READY 已唤醒 `P2-M2-R03-OBJECTIVE-CONTROLLER`；R03 实现 `4c2c44e2`、READY `02ab6df5`，主控复跑 29/29、scoped analyze 0、独立复审 P0/P1/P2=0。该后续运行时切片以 `b195571b` 为基线，将在 Batch10 READY 后进入下一集成批，不属于 Batch10 READY 的替代验收。
- G7：实现 `381d591b`、验证记录 `ffd32597`、READY `df6dafc5`、集成 `993e1189` → `99c6dd3f`；主控复跑 45/45，scoped analyze 0，Codex 独立复审 P0/P1/P2=0。13.5–21 万只保留为旧 3v3 历史测量记录；当前证据明确拆分 calculator 满 build 探针与 Ch1 起手画像 2310 次真实 reducer 路径，未伪称后者覆盖满 build。

## 集成态联合验证

- C01 + R01 + R02 + G7 联合 targeted：23 个测试文件，265/265 通过；其中 Phase 0A 全内容报告 `content=154; proficiencyStages=5; runs=2310; maxDamage=4419`。
- `flutter analyze --no-pub`：34 个变更 Dart 项 0 issue；额外 Phase 0A 全内容诊断与 truth-source guard 2 项 0 issue。
- task/decision registry YAML parse、试玩脚本 `bash -n`、活动范围退役 simulator 引用扫描、`git diff --check` 全部通过。
- `main` 与 `origin/main` 均保持 `e292d3a0`，本批全部变更留在独立集成分支。
- Batch10 仅待最终集成态独立 P0/P1/P2 复审和 READY tip。
