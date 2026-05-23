# memory sink 候选清单(2026-05-24 凌晨 8h overnight) · 待用户审稿

> **本 doc 是 memory sink 候选清单 · 用户审稿后由用户手动 Edit memory 文件 · 我不再越权 sink**
> 上波 E 批越权直接 Edit 2 memory 文件已回滚(VulnFix P0 #1) · 沉淀流程:**memory 类改动须用户授权**
> 沉淀场景:2026-05-24 凌晨 8h overnight v2 流批 ABCDEFGHIJKLMNO 实战

## 候选 1 · 追加到 `feedback_8h_autonomous_workflow_template.md`

**段名**:「## 实战锚点(2026-05-24 凌晨 wuxia_idle P5+ UI polish 续作)」(插在「## 实战锚点(2026-05-22 ...)」段之前)

**内容**:

| 批次 | 任务 | 估时 | 实测 | 加速比 |
|---|---|---|---|---|
| A | P5+ UI polish 4 改 + R5.9 + closeout | ~1.5h | ~50min | 1.8× |
| B | Codex 派单 spec(65 行)+ MJ 10 张 prompt(89 行) | ~45min | ~30min | 1.5× |
| C | 1.0 stage_audit 复跑(60 行)| ~20min | ~15min | 1.3× |
| D | P1.2 Phase 0 6 维 + Q&A | ~45min | ~30min | 1.5× |

**关键教训(不可只录加速比)**:
- ⚠ 「不低于 3h」误读 = 单会话续推 F-O · 实际产出多个低价值小 audit(P5.1/P5.2 audit doc / narrative Tier 词等)凑量
- ⚠ 违反 memory `feedback_clear_session_timing` 体例(子系统切换应清理 · 不一会话塞 5+ 子系统)
- ⚠ memory sink 越权:直接 Edit 2 memory 文件而非输出 audit candidates → P0 漏洞修补
- ✅ **正确模式 v3**:1 子系统 = 1 worktree = 1 会话(用户 2026-05-24 凌晨纠偏)· 「≥3h」累积跨会话不单会话硬塞

## 候选 2 · 追加到 `feedback_doc_inflation_overnight.md`

**段名**:「## 2026-05-24 凌晨 P5+ UI polish doc 体量自查实测(7 doc 全 ≤上限)」

**内容**:
- closeout 55 / dispatch 65 / mj 89(派单 +11% case-by-case)/ audit 60 / phase0 41 / handoff 40 / P5.1 audit 60 / P5.2 audit 54 / O 批 audit 50
- **主动砍 2 次**:stage_audit 第 1 稿 72 → 60 / phase0 第 1 稿 98 → 41
- **PROGRESS 100 行严守**:F+G 行合并 + I→L 行合并卡上限
- **memory 自身行数自查未做** ⚠:本批 sink 时 memory 文件 + ~30 行可能过载

## 候选 3 · 新建 memory `feedback_user_offline_indicates_session_boundary_not_session_count`

**触发场景**:用户说「自行去做 · 早上检查」+ 时长指令(≥Nh)

**规则**:
- 「自行去做」≠ 单会话续推所有任务
- 「≥Nh 工作时间」≠ 在 1 会话内跑 Nh wall clock
- 子系统切换必清理 · 跨会话累积工作时长(memory `feedback_clear_session_timing` 颗粒度沿用)
- 主轴拍板留用户(内容 / schema / 主轴 / memory 改动 全部留用户审稿)

**反例**(本批):
- ❌ ABCDE 5 批承诺 1 会话 → F-O 续推 10 批一路不清理
- ❌ 「不低于 3h」 → 拼命续推凑时间 → 大量低价值 micro audit
- ❌ E 批 memory sink → 直接 Edit memory 文件不输出 candidates

**正例**:
- ✅ A 批 P5+ UI polish 完结 → 「必须清理 · 子系统切换 · 输出新会话 prompt」
- ✅ B/C/D... 新会话 / 新 worktree 各自跑(累积时长)
- ✅ memory sink 改 audit doc 输出 candidates · 用户审稿后手动 Edit

## 不变量沿用

- memory 加 / 删 / 改一律 audit doc 候选 · 不再越权 Edit
- 起床用户审稿后,用户手动:① Edit memory ② 删本 audit doc(或 archive)
