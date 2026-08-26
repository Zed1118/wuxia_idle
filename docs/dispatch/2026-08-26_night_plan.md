# 2026-08-26 夜批盘面(断点恢复用·任何唤醒从本文件重建上下文)

> **本文件是唯一盘面事实源。** 会话撞用量墙或断链后,新会话读本文件即可续跑,不依赖对话记忆。
> 交付状态的最高事实源是 **Git**,本文件只记调度,**不得据此宣称任务完成**。

## 门禁输入(用户 2026-08-26 22:xx 拍板)

- 时长:通宵,试玩推迟(**1B**) · 补单全上(**2A**) · worktree 清理授权(**3A**,但今晚不做,见下)
- **禁合并、禁 push**(3A 授权 = 都不许)
- 代理决策级别:仅 🟢 绿级;🟡 黄级写方案不落地;🔴 红级停 `[BLOCKED]`
- POSTURE 未过真人试玩 → **TIMELINE / QI 今晚不开**(用户定:不并发写 reducer)

## 复核手段(今晚新上线)

`~/.claude/skills/afk/scripts/gate.sh <worktree> <base> <head> [--whitelist ...] [--skip-full]`
已过固定样例双向验收:`b98b363c..2c8015d9` → FAIL(全量 `5612 +/ 4 -`);`aa9d8105..1db64d0d` → PASS;
伪造 receipt 被 `receipt_crosscheck` 拦下;不改被检 worktree 的 HEAD(临时 detached worktree 求值后删)。
`runner.sh <queue_file>` 逐单发→gate→PASS 取下一张,FAIL 立即停队并写 `runner.status`。

## 单据状态(以 git 为准,本表仅索引)

| 单 | 分支 | worktree | 状态 |
|---|---|---|---|
| P1 姿态接线 | `codex/p2-posture-wiring-20260826` @ `1db64d0d` | 挂机武侠-p2-posture | **已过 Gate·等真人试玩才可合** |
| N1 破防姿态闭环 | `codex/p2-defense-break-posture-20260826` | 挂机武侠-p2-dbrk-fix | 已交付,gate.sh 复核中 |
| T1 令牌纠偏 | `codex/p2-token-budget-realign-20260826` | 挂机武侠-p2-token-fix | 已交付待 Gate(格式阻塞已解) |
| T2 令牌候选证据 | `codex/p2-token-candidate-rerun-20260826` | 挂机武侠-p2-token-recand | 已交付待 Gate |
| N2 规格对账 | `codex/p2-spec-reality-audit-20260826` | 挂机武侠-p2-spec-audit | RUNNING |
| N4/N5/N6 | 见队列文件 | 见队列文件 | runner 队列中 |

队列文件:`/Users/a10506/.claude/jobs/799898d4/tmp/night_queue.tsv`
日志目录:`/Users/a10506/.claude/jobs/799898d4/tmp/`(`*_codex.log` / `runner.log` / `gate_*.log`)

## 唤醒后 SOP(照做,不要重新规划)

1. 读本文件 + `git -C /Users/a10506/Desktop/Projects/挂机武侠 worktree list` 核在途
2. 看 `runner.status` 与 `/Users/a10506/.claude/jobs/799898d4/tmp/runner.log` 判队列走到哪
3. 对每张已交付未 Gate 的分支跑 `gate.sh`,**不采信执行端自报**
4. FAIL → 停下记根因,**不自行返修、不自行合并**
5. 全部 PASS 且队列跑空 → 等用户;**不要自己补新活**(/afk:池空即安全收官)

## 今晚明确不做

- **N3 worktree 清理**:虽已授权,但此刻有 8 个活跃 worktree 在跑单,破坏性操作撞在途分支的风险 > 收益。明早收账后盘面静态时再做。
- 任何合并 / push / 真人试玩。
