# P2 Batch8：M1 合同复验与 G0 决策证据包

## 目标

从 Batch7 READY `1a4e1dd3` 出发，整合 M1 C02–C10 九合同复验及 C06 非有限减速倍率修复，并把 G0 未决产品项收束为可由用户回答的证据包。本批不批准任何 `PROPOSED` / `proposed_reopen`，不把 tuning 候选值直接写入生产。

## 整合来源

- M1 复验分支 READY：`b66f8a74`；只选择六个非空实现/审计提交，跳过两个空 READY。
- G0 证据包分支 READY：`0ae5f45a`；只选择文档实现提交 `8a0e2ecc`，跳过空 READY。
- 两路与 Batch7 READY 文件交集为 0，补丁预检与 `git diff --check` 通过。

## 冻结边界

- 仅 C06 `TimedStatusSpec` 新增 `movementMultiplier.isFinite` 校验，不改状态产品语义。
- G0 证据包只给互斥选项、当前事实、已否冲突、安全暂停态和用户问题；不替用户拍板。
- 已冻结的六类地域锚、断魂庄首通后 headless 重刷等边界不得被重新包装为待决或回退。
- 用户直接给出的 tuning 数字仅是候选目标；经 YAML、红线、自动模拟和适用的实机/手感验证前，不得标记 frozen 或接入生产。
- 不修改 production data、host routing、save、UI、奖励、长寿设计文档或 `main` / `origin/main`。

## 验收 checklist

- [x] M1 分支独立审查 P0/P1/P2 为 0，建议提交链已整合。
- [x] G0 证据包完整阅读，已识别 5 个 P1 与 3 个 P2 文档问题。
- [ ] 修正 G0 边界回退、父项签字缺口、tuning Gate 和文档事实漂移，独立复审清零。
- [ ] C06 targeted、M1 九合同 targeted、scoped analyze、YAML/Markdown 静态检查和 `git diff --check` 通过。
- [ ] registry 与当前恢复点一致，集成分支以 `[READY][CODEX][P2-BATCH8]` 空提交封签。

## 当前恢复点

- 状态：M1 复验链与 G0 证据包已整合；G0 终审问题正在修正，Batch8 尚未 READY。
- 最后完成：Batch7 READY 之后的两路无冲突 cherry-pick；M1 独立复核 P0/P1/P2 为 0。
- 下一步：收口 G0 修正、运行针对性动态验证和最终只读审查。
- 阻塞项：无工程阻塞；未决产品项保持暂停，不阻塞证据包本身收口。
