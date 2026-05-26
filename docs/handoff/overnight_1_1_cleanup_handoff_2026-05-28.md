# 过夜自主工作流 handoff · 2026-05-28 1.1 挂账清理

## 起床 first-read 顺序

1. PROGRESS.md 顶段
2. 本 handoff（commit 总览 + 自主决策）
3. RELEASE_CHECKLIST v1.2（C.2 sect recruit R2 验收项）
4. CLAUDE.md v1.16 版本头（1 段）

## commit 总览（3 commit on worktree-overnight-1-1-cleanup）

| commit | 内容 |
|---|---|
| `9e1357d` | **Batch B**: stageBossFailRecoverProb 0.30 wire + Ch1-3 败后叙事 3 篇 + R5 测 3 |
| `de59f77` | **Batch C**: Ch4-6 bossRecruit 池扩 + valley_hermit 新增 + 败后叙事 3 篇 |
| `a5ee559` | **Batch D**: CLAUDE.md v1.16 + ROADMAP v1.6 状态对齐 |

测族：1505 → 1508（+3 failRecover R5）· 0 analyze

## 自主决策清单

| # | 决策 | 理由 |
|---|---|---|
| 1 | candidateRefs rng pick 降级为 spec-only 留 1.2 | 代码注释明确标「1.2 升」+ schema 变更影响面大 |
| 2 | 战败收降用全局 `stageBossFailRecoverProb`（不加 per-stage 字段）| 战败收降是全局 mercy 机制,不需要 per-stage 微调 |
| 3 | 共用 `triggeredBossRecruitStageIds` 防刷（victory/defeat 互斥）| 语义合理:一个 Boss 只触发一次招募 |
| 4 | valley_hermit 新候选选 yinRou | 三系平衡:bamboo=lingQiao / desert=gangMeng / mountain=yinRou / river=lingQiao / blacksmith=gangMeng / **valley=yinRou** |
| 5 | Ch4-6 Boss recruit 候选分配: 04→river / 05→blacksmith / 06→valley | 最大化利用现有池候选 + 新增补缺 |

## 下波候选

| # | 任务 | effort | 备注 |
|---|---|---|---|
| 1 | Codex R2 验收 review | high | Pen 明天开机后执行 |
| 2 | RELEASE_CHECKLIST C.2 勾完 | high | 等 R2 回来 |
| 3 | candidateRefs rng pick spec | high | 1.2 scope,不急 |
