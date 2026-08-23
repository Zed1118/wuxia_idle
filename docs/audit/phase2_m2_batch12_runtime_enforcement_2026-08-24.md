# 二阶段 M2 Batch12 运行时执行接缝审计（2026-08-24）

## 基线与授权

- 基线：Batch11 READY `57f04b397d1412128535ba8f74a7e61ecdfb4577`。
- 用户已授权持续自动推进，并明确要求充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent。
- 本批不需要新的产品语义决策；候选数值晋升、真人试玩与 production host 切换继续保持 Gate。

## 范围

- R05：攻击 token director 的批次 intent 执行接缝。
- R06：objective controller 的原子运行时跟踪接缝。
- R07：combat encounter content + spawn director 到精确 enemy roster 的显式映射接缝。
- 集成态验证三项可组合，但不接 production data/host/UI/save/reward/injury。

## 预注册风险与控制

- intent 注入或重排：R05 输出只能是输入 identity 的稳定子序列；失败发生在 observer/reducer 前。
- 目标身份误推断：R06 仅消费显式 event 或调用方显式 defeat classifier；不按字符串或角色类型猜测 commander。
- content/runtime roster 漂移：R07 在 actor factory 调用前比较 entry-id 集合，并保持 runtime enemy id 的显式权威来源。
- candidate 值误晋升：生产路径、YAML 与 host 不在 owned files；最终审计再次检查 production path isolation。
- 工作树污染：实现和集成均在独立 branch/worktree，main/origin main 只读核对。

## 验证记录

待 R05 / R06 / R07 READY 后补充来源 commit、工具证据、targeted/analyze/full test 与独立审查结论。
