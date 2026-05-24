# 8h overnight v3 · 5 worktree 4/5 PR 合并收尾 closeout(2026-05-24)

> 日期:2026-05-24 / 模型:Mac+Opus 4.7 主 cwd + 5 子 Claude session(--print)+ 5 reviewer agent
> main HEAD `02370b4` 同 origin · 工作树 1(`wuxia_idle-p12-spec` 保留待 E fix)
> 体例:1 子系统 = 1 worktree = 1 子 Claude session = 1 草稿 PR(VulnFix v2 教训修正)

## TL;DR

v3 5 worktree 真并行 wall clock ~8min 全跑完 → 5 reviewer agent 并行审 均分 8.9/10 → 4 PR 直 merge(C/D/B + A 1 字 fix)→ 1 PR(E)待 4 项 minor fix 用户决策。analyze 0 issue / narrative loader 13 测全过 ✅。

## 时间线

| 阶段 | 实测 | 产出 |
|---|---|---|
| Phase 1 派单 spec(5 worktree)| ~30min | 5 spec doc `docs/spec/overnight_v3_2026-05-24/` |
| Phase 2 worktree 起 + 主 cwd commit push | ~5min | 5 worktree `~/Desktop/wuxia_idle-*` 同级 |
| Phase 3 5 子 Claude --print 并行跑 | **~8min** | 5 commit · 5 草稿 PR |
| Phase 4 5 reviewer agent 并行审 | ~3min | 5 review report 含评分 + bug 列表 |
| Phase 5 4 PR squash merge(C/D/B/A)+ A 1 字 fix | ~5min | main HEAD a6812c2 → 02370b4 |
| Phase 6 worktree 清理 + sanity check | ~3min | 4 worktree remove · analyze 0 issue · narrative 13 测过 |

**总 wall clock ~54min**(对比 v2 单会话 ABCDEFGHIJKL 累计 ~2h15min)。

## 评分汇总

| PR | 评分 | 关键 finding |
|---|---|---|
| #4 C PVP Phase 0 | 10/10 | 6 维 grep 准确率 100% · Q&A 中立性满 · GDD/ROADMAP 行号全核对 |
| #5 D sect Phase 0 | 9.5/10 | 2 处小行号 drift(C 维漏 _providers.dart + .g.dart / F 维行号虚长)不阻塞 |
| #8 B memory sink + GDD §10 | 9/10 | 行号实证全过(main_menu:174/:223 + save_data:39)· VulnFix P0 红线守住 · 修正上波 p5_1_tutorial 2 处偏差 |
| #7 A Ch4-5 yiLiu | 8→10/10 | 1 字 fix「老练得→地」(语法状语标记)· 8 词命中均匀 · 0 数值改 |
| #6 E P1.2 spec | 8/10 ⏸ | 4 项 minor fix 待决策(详 handoff `p1_2_spec_pending_e_fix_handoff_2026-05-24.md`) |

## v3 体例验证

**成功项**:
1. ✅ `claude --print --permission-mode bypassPermissions --max-budget-usd N` 后台子进程隔离体例可行
2. ✅ stdin redirect prompt(`< /tmp/v3_X_prompt.md`)解决 heredoc 失败问题
3. ✅ 5 reviewer agent 并行审保证质量 gate(对比直接 merge 会漏 A 语法 / E 4 项 fix)
4. ✅ 1 子系统 = 1 worktree 体例真隔离(对比 v2 单 cwd 累积 12 批)
5. ✅ memory sink audit doc 候选体例守住 VulnFix P0 红线

**改进项**:
- ⚠ heredoc + run_in_background 不可靠 · 必须 stdin redirect 体例
- ⚠ 主 cwd worktree add 默认相对仓库 root 路径 · 必须用绝对路径让 worktree 同级建在 `~/Desktop/`

## 挂账

- **E PR #6 4 项 minor fix**:详 `docs/handoff/p1_2_spec_pending_e_fix_handoff_2026-05-24.md`
- **memory sink 候选**:详 `docs/handoff/memory_sink_v3_workflow_candidates_2026-05-24.md`(用户审稿后手动 Edit)
- **上波 candidates 旧 doc**:`memory_sink_candidates_2026-05-24.md` 已被 B PR `memory_sink_ready_to_paste_2026-05-24.md` 取代(加 deprecated 头注)

## 不变量沿用

- 0 GDD.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md 改
- 4 PR 全是 doc 类(narrative / phase0 / audit / spec)· 0 dart code / 0 schema / 0 测试改
- doc 体量全 ≤上限(closeout ≤80 / handoff ≤50 / audit ≤60 / phase0 ≤80 / spec ≤150)
