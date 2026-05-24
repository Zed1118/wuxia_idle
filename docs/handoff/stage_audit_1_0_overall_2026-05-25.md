# 1.0 整体进度全谱审查 · 2026-05-25(本批 nightshift T17-T22 跑完后)

> milestone audit · 体量 ≤60(对齐 doc_inflation memory)
> 基线:main HEAD `2f3bc4a` · 1357 pass(本批 0 测改动)/ 0 analyze · GDD v1.16 · ROADMAP v1.3
> **完工率 4/6**(T18/T20/T21/T22 ✅ · T17 半 · T19 fail)

## TL;DR

1.0 整体 **75% → ~78%** · 本批 6 task 实际 4 ✅ + T17 partial(B1+B2 only)+ T19 fail(0 commit) · 主要进展:P1.2 schema+service 落(15%→~50%)、narrative 双补全、跨系统 audit 通过、P4.1 spec 启动。**T17 B3+B4+closeout / T19 技术债 3 项**留下波。

## 1. 本批 T17-T22 实测跳档

| Phase | 会话前 | 会话末 | 增量 | 备注 |
|---|---|---|---|---|
| **P1.2 江湖恩怨+声望** | 15%(spec only)| ~50%(B1+B2 ✅ / B3+B4 留) | +35% | T17 partial · UI/R5 缺 |
| **P3.3 PVP narrative** | stub 1 条 | 完整 11 条 ✅ | +95% | T18 |
| **P3.4 sect narrative** | tournament 2 条 | tournament+mission+crisis 10 条 ✅ | +80% | T18 |
| **技术债 P3 三项** | 3 项挂账 | 仍 3 项 ❌ | 0 | T19 0 commit |
| **P4.1 帮派门派** | 0%(无 spec)| spec ~8%(spec ✅ / 实装 0)| +8% | T21 |
| **跨系统 audit** | R2 风险未压测 | audit doc ✅ + 红线全过 | 风险清 | T20 |
| **1.0 整体** | ~75% | **~78%** | +3% | conservative |

## 2. nightshift 本批实测(commit 维度,无 .nightshift/status/ 文件可读)

| Task | 期望产出 | 实测 commit | 状态 |
|---|---|---|---|
| T17 P1.2 全 4 batch | B1+B2+B3+B4+closeout | 仅 B1(4e79722)+ B2(bdfee91)| 🟡 PARTIAL |
| T18 narrative 双合一 | 18 条 + R4 测 | 10711b1(双合一) | ✅ |
| T19 技术债 3 合一 | PvpDef/SectEventDef + 真持久化 + systemClock | (0 commit) | 🔴 FAIL |
| T20 跨系统 audit | audit doc + R5 6-10 测 | ab514e1 | ✅ |
| T21 P4.1 phase0+spec | phase0 + spec ~150 行 | be6c224 | ✅ |
| T22 总收尾 | 本 doc + ROADMAP v1.3 + handoff + PROGRESS | (本 commit) | ✅ |

(`.nightshift/status/` 目录不存在 · wall 实测靠 commit timestamp · 详 `git log nightshift/T17..T21`)

## 3. 下波候选(按 ROI · 1.0 收尾路径)

| 优先 | 任务 | 估时 | 解锁 |
|---|---|---|---|
| ★★★ | **T17 B3+B4+closeout 补完**(ReputationPanelScreen + UI 入口 + R5.1-5.6 ~10 测 + closeout)| ~30-45min nightshift | P1.2 100% · 解 P1 100% |
| ★★★ | **T19 技术债 3 项补做**(numbers_config 强类型 PvpDef/SectEventDef + Sect/PvpRecord Isar 真持久化 + systemClockProvider)| ~45-60min nightshift / ~30min xhigh | 干净代码 + 真生产 |
| ★★ | P4.1 §12.2 帮派门派 实装(B1-B4)| ~15-20h xhigh / 8-10h nightshift | P4 真闭环 |
| ★★ | inner_demon 7 主题 enemy 立绘异步 MJ | 异步 | 美术 |
| ★ | Supabase 真接 PvpSync(替 NoopPvpSync)| ~30min | PVP 真生产 |
| ★ | P5 上线流程性工作(教程审计 / 音乐外包接洽 / Steam closed beta) | ≥3 个月 lead time | 真上线 |

## 4. 风险点

- **R1 时间线**:本批 4/6 完工 + T17 半成品 + T19 fail,后续 nightshift 仍需提升单批稳定性。1.0 ~78% 距离上线流程性 P5 仍 ~22%。
- **R2 跨系统数值红线**:T20 audit 通过 ✅ · 详 `docs/audit/cross_system_damage_audit_2026-05-25.md`(T20 commit 内)
- **R3 nightshift 单批不完整率**:本批 T17 中断 + T19 0 commit = 2/6 异常 ≈ 33% · 需 dispatcher 加 commit count assertion or per-batch verify
- **R4 PROGRESS 100 行卡**:本 task 加顶段 8 行 → 砍下方 8 行同等(W17-W18 详条段已是长引用,可压)
- **R5 .nightshift/status/ 目录缺失**:本批 6 task 无单独 status 写入,后续 morning.sh 重生 SUMMARY 时若依赖此目录则需检查 dispatcher.sh

## 5. 工作流体系成熟度更新

- nightshift v2 dispatcher 4/6 成功率(T18/T20/T21/T22 ✅ · T17 partial · T19 fail) 🟡
- Phase 0 grep 六维 + spec 起草 task 体例(T21 首跑 ✅,复用 P1.2 体例)
- 多 batch 单 worktree 累积 commit 体例(T17 中断在 B2,需复盘) ⚠

详 git log nightshift/T17..T22 + ROADMAP v1.3。
