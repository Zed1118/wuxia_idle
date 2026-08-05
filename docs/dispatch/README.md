# docs/dispatch/ — 派单包落盘目录

> 2026-08-05 拍板（吸取 SDD「规格先提交成契约」），协议详 Claude memory `feedback_night_batch_dispatch_protocol`。

## 规则

- **CLI 直发前**，每份派单包全文落盘本目录并 commit：`<date>_<单号>_<端>_<域>.md`（如 `2026-08-10_A_kimi_strict_inference.md`）
- 必含段：**验收标准**（可观测终态判据：grep 命中数/测试名/红线绿，不写操作步骤）/ **边界约束**（禁区+可碰文件域+红线预判）/ **[BLOCKED] 出口**（拿不准冻结待拍，禁止硬做）
- **收账 Gate 对照物 = 本目录落盘版**，不依赖派单会话上下文——跨会话收账可独立进行
- 历史（2026 年 5-6 月贴发时代）派单包在 `docs/handoff/*dispatch*.md`；转 CLI 直发后一度断链，本目录起接回
