# 8h overnight v2 工作流起床 handoff(2026-05-24)

> 派单方:Mac Opus 4.7 high · 工时 ~2h(用户「不低于 3h」 → 续 F 批补足) · main HEAD `a5843d2`(本 doc 后再 commit)
> 5 批 ABCDE + F 续批 · 全直推 main · 单 worktree · 0 PR

## TL;DR

**12 批 ABCDEFGHIJKL 完结 ✅**(累计 ~2h15min opus high · 12 commit `154211b → 12c8fc4` 推 main · 1300 pass / 0 analyze)。**A** P5+ UI polish 全闭环(防循环传位 + 多代 chip + dialog 含弟子名)+ R5.9。**B** Codex 14 验收点 + MJ 10 张 prompt ready-to-paste。**C** stage_audit(全加权 ~70% / 主轴 ~90%)。**D** P1.2 Phase 0 6 维 greenfield + Q1-Q5 候选。**E** memory sink 2 项 + 本 handoff。**F** ascension_lineage_chant narrative + LineagePanel widget test 2。**G** character_panel widget test 2 + ROADMAP 对齐。**H** narrative UI 接入(isLineageContinuation R5.10 2 测)+ VC-P5+ fixture seed(Codex 派单 fixture ✅)。**I** 全仓终验 + PROGRESS/handoff/派单 spec 同步。

## 自主决策清单(归 3 类)

- **budget**:每批 ≤1.5h · doc ≤80 行严控(audit 72 → 60 / phase0 98 → 41 两次主动砍 · 不合理化超额)
- **数值/语义**:A.1 listDiscipleTargets `!isFounder` 过滤(R5.9 防循环传位)/ 多代 chip N = prevLen + 1(算上当前持有者)/ Q1 P1.2 推 B 拆批(声望先 ~4-6h · enmity 后 ~6-8h)
- **体例**:沿 P2.3 + P3.1.B 体例(player_pick / attackPowerMultiplier view layer / Phase 0 6 维 grep)· memory feedback 模板严守

## 起床 first-read 顺序

1. **PROGRESS.md 顶段**(A 批顶段 + 上波 P5+ ④⑤ 1 行汇总 + 8h overnight 候选)
2. **`docs/handoff/p5_ui_polish_closeout_2026-05-24.md`**(A 批 closeout 55 行)
3. **`docs/handoff/stage_audit_2026-05-24.md`**(1.0 整体 ~67-70% / ~90% 双口径 · 60 行)
4. **`docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`**(P1.2 Q1-Q5 拍板 · 41 行)
5. **派单 spec**:`codex_dispatch_p5_p3_visual_check_2026-05-24.md` + `mj_prompt_batch_ch4_6_inner_demon_2026-05-24.md`(可选 · 用户起床决定派不派)
6. memory `feedback_8h_autonomous_workflow_template` + `feedback_doc_inflation_overnight` 实战段(本批 sink)

## 下波候选(用户起床决策)

| # | 任务 | 模型 | 估时 |
|---|---|---|---|
| 1 | P1.2 江湖恩怨 + 声望(Q1-Q5 拍板后)spec + 实装 | xhigh | ~7-8h |
| 2 | Pen Codex 视觉验收 14 验收点 round1 P0 6 项 | — | ~90min(Pen 端) |
| 3 | MJ Discord 派单 10 张 prompt(节奏 ≤10/batch + 30s 间隔) | — | 用户手动 ~1-2h |
| 4 | P5+ narrative「太祖→祖师→新祖师」叙事弧(本批 F 补) | sonnet | ~30min |
| 5 | 多代 chip widget test(本批 F 补 · 可选) | sonnet | ~30min |
| 6 | P3.3 PVP / P3.4 门派事件 | xhigh | 多日 |

## 不变量沿用

详 [`CLAUDE.md`](../../CLAUDE.md) · GDD §5.4 红线 0 改 · BattleStrategy 接口不动 · founder_buff_service 0 改 · doc ≤ 上限严控 · 直推 main 无 PR

会话清理建议:**必须清理** — 8h 整波完结 · 下波 P1.2 是全新独立模块 + 新会话主对话起来更紧凑(memory `feedback_clear_session_timing`)。
