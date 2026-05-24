# memory sink ready-to-paste(2026-05-24) · 替代 candidates doc

> 3 候选重排为可直接 Edit 的格式。原 candidates doc 已加 DEPRECATED 头注留存。

## 候选 1 · insert before · feedback_8h_autonomous_workflow_template.md

- **目标**: `~/.claude/projects/-Users-a10506/memory/feedback_8h_autonomous_workflow_template.md`
- **old_string 定位锚**: `## 实战锚点(2026-05-22 wuxia_idle Ch4 → Ch5 桥 + Phase 2 全收口)`
- **new_string**（含旧锚行，完整贴入 Edit 工具）:
  ```
  ## 实战锚点(2026-05-24 凌晨 wuxia_idle P5+ UI polish 续作)

  | 批次 | 任务 | 估时 | 实测 | 加速比 |
  |---|---|---|---|---|
  | A | P5+ UI polish 4 改 + R5.9 + closeout | ~1.5h | ~50min | 1.8× |
  | B | Codex 派单 spec(65 行)+ MJ 10 张 prompt(89 行) | ~45min | ~30min | 1.5× |
  | C | 1.0 stage_audit 复跑(60 行) | ~20min | ~15min | 1.3× |
  | D | P1.2 Phase 0 6 维 + Q&A | ~45min | ~30min | 1.5× |

  **关键教训**:
  - ⚠ 「不低于 3h」误读 = 单会话续推 F-O · 产出多个低价值 micro audit 凑量
  - ⚠ 违反 `feedback_clear_session_timing`(子系统切换应清理 · 不一会话塞 5+ 子系统)
  - ⚠ memory sink 越权:直接 Edit 2 memory 文件而非输出 candidates → P0 修补
  - ✅ **正确模式 v3**:1 子系统 = 1 worktree = 1 会话 · 「≥3h」累积跨会话不单会话硬塞

  ## 实战锚点(2026-05-22 wuxia_idle Ch4 → Ch5 桥 + Phase 2 全收口)
  ```
- **预测行数**: ~144 行（原 124 + 新增 ~20）

## 候选 2 · append · feedback_doc_inflation_overnight.md

- **目标**: `~/.claude/projects/-Users-a10506/memory/feedback_doc_inflation_overnight.md`
- **new_string**（追加到文件末尾）:
  ```
  ## 2026-05-24 凌晨 P5+ UI polish doc 体量自查实测

  - closeout 55 / dispatch 65 / mj 89 / audit 60 / phase0 41 / handoff 40 / P5.1 audit 60 / P5.2 54 / O 批 50 · **全部 ≤上限** ✅
  - **主动砍 2 次**:stage_audit 72→60 / phase0 98→41 · **PROGRESS 严守 100 行**:F+G 合并 + I→L 合并
  - **memory 自身行数自查未做** ⚠:sink 时 memory +~30 行可能过载 — 写完加 `wc -l` 自查
  ```
- **预测行数**: ~162 行（原 157 + 新增 ~5）

## 候选 3 · new file · 重叠度 ~35% < 60% → 保留新建

核心唯一价值：「≥Nh 工作时间 ≠ 单会话 wall clock」在现有 memory 中隐含但未成显式规则。

- **目标**: `~/.claude/projects/-Users-a10506/memory/feedback_user_offline_indicates_session_boundary_not_session_count.md`
- **完整文件内容**（直接粘贴为新文件）:

```markdown
---
name: feedback-user-offline-indicates-session-boundary-not-session-count
description: 用户说「≥Nh 工作」时 Nh 是跨会话累积量，不是单会话 wall clock；子系统切换必清理
metadata:
  type: feedback
---
## 规则
- 「自行去做」≠ 单会话续推所有任务
- 「≥Nh 工作时间」≠ 在 1 会话内跑 Nh wall clock
- 子系统切换必清理（沿 [[feedback-clear-session-timing]] 颗粒度）
- Nh = 跨 N 个会话的累积产出量

**Why**: 2026-05-24 overnight v2：承诺 ABCDE 5 批 → F-O 续推 10 批一路不清理，产出大量低价值 micro audit 凑时间；「不低于 3h」误读为单会话 wall clock → 强行续推。

**How to apply**: 用户说「自行去做 X 小时」→ X 小时跨 N 个会话累积，每子系统 1 个会话，不塞满单会话。

## 反例
- ❌ ABCDE 5 批承诺 1 会话 → F-O 续推 10 批一路不清理(overnight v2 2026-05-24)
- ❌ 「不低于 3h」→ 拼命续推凑时间 → 大量低价值 micro audit

## 正例
- ✅ A 批 P5+ UI polish 完结 → 「必须清理 · 子系统切换 · 输出新会话 prompt」
- ✅ B/C/D... 新会话 / 新 worktree 各自跑（累积时长）
```

- **预测行数**: ~28 行（新建）
