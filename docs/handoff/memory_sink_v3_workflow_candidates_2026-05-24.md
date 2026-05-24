# memory sink 候选(v3 workflow 实战教训 · 2026-05-24) · 待用户审稿

> 主 cwd HEAD `02370b4` · 上波 candidates 已被 PR #8 取代(memory_sink_ready_to_paste_2026-05-24.md 加 deprecated 头注)
> **本 doc 是新 candidate · 用户审稿后手动 Edit memory · 我不越权直 Edit**
> 沉淀场景:overnight v3 5 worktree 真并行 wall clock ~54min(派单 spec 30 + claude --print 8 + reviewer 3 + merge 5 + 清理 3 + closeout 5)

## 候选 1 · 追加到 `feedback_8h_autonomous_workflow_template.md`

**段名**:「## v3 实测(2026-05-24 wuxia_idle 5 worktree 真并行)」

**内容要点**(用户审稿时可改):
- v3 转向(对比 v2):**1 子系统 = 1 worktree = 1 子 Claude session(--print)= 1 草稿 PR**
- 物理:主 cwd 写 spec + push → 起 worktree → claude --print 后台 5 子进程 → reviewer agent 并行审 → merge
- 实测加速比:v3 ~54min 完成 5 PR(对比 v2 12 批累 ~2h15min)· **包含 reviewer gate**
- 失败兜底:claude --print 单轮无 retry,spec 必须自洽,prompt 用 stdin redirect(heredoc + background 不可靠)

## 候选 2 · 新建 memory `feedback_claude_print_subprocess_isolation.md`

**触发场景**:多子系统隔离任务 · 用户在场或离场均可

**规则**:
- `claude --print --model X --effort Y --permission-mode bypassPermissions --max-budget-usd N --add-dir /path < prompt.md > log 2>&1` 后台启动
- prompt 用 **stdin redirect** 不用 heredoc(heredoc + run_in_background 在 Claude Code 主 session 中失败 · 实测 stdin 体例稳)
- spec 必须自洽包含**默认决议**(--print 单轮无交互 · 遇到拍板会卡)
- budget 给 1.5-2× 估时 token cost(opus xhigh spec 类 ~$5-10 / sonnet narrative ~$3-5)
- 完成自动 push + gh pr create --draft · reviewer agent 并行审 quality gate

**反例**:
- ❌ heredoc inline prompt(`"$(cat <<EOF ... EOF)"` 在 background mode 解析失败)
- ❌ git worktree add 相对路径 worktree 建到主项目子目录(污染 ls)
- ❌ spec 留主轴拍板 · --print 子进程会进死循环或猜决议

## 候选 3 · 追加到 `feedback_subagent_parallel_vs_serial.md`

**段名**:「## v3 reviewer agent 并行体例(2026-05-24)」

**内容**:
- 5 PR 互独立 → 5 reviewer agent (general-purpose) 并行 dispatch · wall clock ~3min 全 review
- 每 reviewer prompt 自洽:`gh pr view/diff` + 上游 spec + 沿例 doc + grep VERIFY 抽样 + 输出格式(bug / 评分 / 建议)
- 实测加速 5×(对比串行 5 ~15min)· 主对话 context 干净(每 reviewer 独立 output 不污染主对话)
- 反例:强依赖 phase 链 NOT 并行 · 但独立 PR review 是「调研」类完美适合 parallel agent

## 候选 4 · 追加到 `feedback_doc_inflation_overnight.md`

**段名**:「## v3 实测 doc 体量(2026-05-24)」

- closeout overnight_v3 70 行 ≤80 ✅ · handoff p1_2_spec_pending 45 行 ≤50 ✅ · audit memory_sink_v3 50 行 ≤60 ✅
- 5 spec doc 起 30min · 全 ≤150 行(派单 spec 不超 150 是 launch quality 关键)
- PROGRESS 加新顶段 11 行 + 砍 v2 12 行 → 净增长 -1 行(守 100 行)

## 不变量沿用

- 用户审稿后手动 Edit memory · 我不越权直改 memory 文件
- 审稿后建议 `git rm` 本 audit doc(或归 archive)· 不长留 docs/handoff
