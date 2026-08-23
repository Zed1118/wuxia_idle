# 二阶段 M2 Batch17 听剑事务边界审计（2026-08-24）

## 基线与授权

- 集成基线：Batch16 READY `abefcee74a5b4749662a534a0793f995c2a2f891`。
- 用户已授权持续自动推进、充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 frozen host-neutral 合同。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- R18 没有保存“本次 admission 真正新增的 companion”；empty choice 叠加旧 occupancy 时若下游直接读 snapshot，可能误 release 或误 claim。R19 必须显式保存 nullable provenance。
- R15 已冻结四种 release reason 与 owner-bound prepared successor；R19 可机械组合，但不能推断结算事实或宣称 durable transaction。
- R02/R15 已冻结听剑同伴与四类阻塞活动；R20 只需对 immutable occupancy snapshot 做 exact-character 反向 guard。
- 既有 mentor claim policy 与 canonical `RewardClaimKey` 足以支撑 R21 的“观察事实→决策”边界，但 durable truth source、CAS、grant/outbox 尚未冻结。

## 风险控制

- provenance 漂移：empty choice 的 `admittedCompanion` 必须恒为 null，即使 predecessor 已占用；非空只取本次 R15 exact successor。
- composite commit 绕过：R19 的 committable R15 successor 必须 private，只暴露 read-only views，并保持 exact-predecessor/single-use。
- 活动真相过报：R20 不查实际活动状态、不修改 shared occupancy，只拒绝 exact active companion 的四种请求。
- durable 过报：R21 不查询或写入 durable store；成功场景只接受 caller 提供的 exact-key observation，错误或缺失 fail closed。
- production/candidate/objective/timeline/tuning/Profile/G2/真人验收继续 Gate。

## 待完成验证

待来源 READY 后补充外部工具证据、来源/集成提交、targeted/analyze/format/full、仓库闸门、独立终审与最终 READY。
