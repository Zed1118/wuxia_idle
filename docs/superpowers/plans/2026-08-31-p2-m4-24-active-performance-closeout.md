# M4 24-active 性能收口计划

## 结果合同

- 单一目标：在 M2 + M4 A-G 受控集成候选上关闭 24-active macOS 帧门，不启动 M3，不把真人目检挂账改写为 PASS。
- 分支：`codex/p2-m4-24-active-performance-closeout-20260831`。
- 基线：`56a08563b5a63c352afac4e0c247fdeafaee1ce4`，正式 1280×720 / 1440×900 各 3 轮均 FAIL，p99 total span 平均 `46.5945ms`。
- 分母：24-active 性能 Gate `0/1`；只有统一候选在两个视口各 3 轮全部通过复合帧门、回归与独立 Gate 后才记 `1/1`。
- 最高杠杆阻塞：build p99 约 19ms、raster p99 约 28–30ms；先用 Profile trace 确认根级重建与光栅热点，不继续猜测式微优化。
- 成本边界：无可靠 token/用量读数，按真实墙钟；约 90 分钟没有可测 Gate 改善时停止扩张并重评。

## 验收标准

1. 候选从 M4-G 建立，不包含 M4-H；移除与本 Gate 无关的 Isar 测试超时放宽，不改其业务断言。
2. 真实 `Phase0aBattleScreen`、controller、bot、生产 flow assembler 与 reducer 下保持玩家 + 24 active 敌人；不改实体、攻击令牌、难度、数值、存档或 checkpoint 语义。
3. 1280×720 与 1440×900 各 3 轮：每轮 sampled frames ≥3000、p99 total span <16.6ms、max consecutive severe frames ≤1、frame streak Gate PASS、GC 遥测完整、RSS 守门通过。
4. 性能结构守卫必须可通过移除生产接线而变红；不以静态 widget 数量代替 Profile 结果。
5. targeted、相邻回归、`flutter analyze --no-pub lib test`、全仓 format、持锁全量、组合 receipt、独立 Gate 全部通过；worktree clean，tip 以 `[READY]` 或如实 `[BLOCKED]` 收口。
6. 主 checkout 保持 clean；不 merge、不 push、不修改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、schema/saveVersion。

## 任务切片

1. 建立受控候选并复核现有 Profile 原始证据。
2. 采集可定位 build/raster 热点的 trace，验证根级重建假设。
3. 先做一个最高收益的表现层修复，跑 targeted 与单轮双视口诊断。
4. 只有单轮显示明确改善才跑正式 3×2 矩阵；否则回退并改走 trace 指向的下一热点。
5. 过线后统一跑回归、receipt、全量与独立 Gate。

## 当前恢复点

- 状态：WIP，24-active 性能 Gate `0/1`。
- 最后完成：从 M4-G 建立独立 worktree；确认 M4-H 未进入候选；开始剥离无关 Isar 测试超时。
- 下一步：完成环境前置，复现单轮 Profile 并采集/分析 trace。
- 已跑验证：历史正式矩阵 6/6 FAIL；本分支尚未产生新的性能样本。
- 阻塞项：当前无产品决策阻塞；真人可读性、手感、音频与 Windows/DPR2 继续挂账。
