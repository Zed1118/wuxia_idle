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
| `P2-M2-C01-CATALOG-SCHEMA-GATEWAY` | Codex high | running | 内容中立、fail closed、无生产默认 |
| `P2-M2-R01-MAINLINE-RUN-PARTICIPATION` | Qoder / Qwen3.8-Max high | running | 纯合同、无 host/save/UI/双 preset |
| `P2-M2-R02-MENTOR-INSIGHT-CONTRACT` | Pi / DeepSeek V4 Flash high | running | 无 rate/cap/生产发放/持久化 |

## 后续唤醒条件

- C01 READY：可启动 objective/token runtime 及 Ch1 候选数据 fixture；候选仍不得直接提升为 production YAML。
- R01 READY：只解除 mainline policy 合同层；生产 host、sweep、结果页另立集成任务。
- R02 READY：只解除占用和 claim 合同层；主修熟练度实际发放继续等待 rate/cap 证据 Gate。
- M2/G2 最终通过仍需用户完成八项真人试玩签字，自动测试不能代替。

## 验证记录

待来源 READY 后补写：提交链、主控 diff 复审、targeted、scoped analyze、联合测试、独立审查和最终 READY tip。
