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
2. 看 `$CLAUDE_JOB_DIR/runner.status`(**注意:不在 scripts/ 下**)与 `/Users/a10506/.claude/jobs/799898d4/tmp/runner.log` 判队列走到哪
3. 对每张已交付未 Gate 的分支跑 `gate.sh`,**不采信执行端自报**
4. FAIL → 停下记根因,**不自行返修、不自行合并**
5. 全部 PASS 且队列跑空 → 等用户;**不要自己补新活**(/afk:池空即安全收官)

## 补单(2026-08-26 23:xx 用户追问「2:00 跑空怎么办」后追加)

池空是实测事实:`BACKLOG.md` 的「二·已解锁可派」与「四·方向级候选」**两栏都是空的**。
补单判据不是「有没有活」,是「明早要协调者花多少额度 Gate」——故**全部零 `lib/` 写入**。

| 单 | 内容 | 载体 |
|---|---|---|
| N12 | 把 N2 的 236 组非一致断言转成可派任务池条目 | 队列(基线=N2 tip `0ec0280a`) |
| N7 | M0–M9 权威门事实底座(判据/已接线/缺口,**不定权重**) | 队列 |
| N9 | BACKLOG 补给扫描(PROGRESS/audit/spec/TODO 四源) | 队列 |
| N8 | CLAUDE.md 自称 vs 代码实况 drift 审计 | 队列 |
| N11 | 变异测试探针建设 + 对战斗核心首轮跑批(🟡 不合并) | 并行,worktree `挂机武侠-p2-mutation` |
| N10 | receipt.yaml 交叉核对缺口补齐(工作目录 `~/.claude`) | 并行 |

**并发数 3**(runner + N11 + N10),超 /afk 的 `RUNNING ≤ 2`。理由:N10 域在 `~/.claude` 与仓库不相交,
且两者 Gate 成本 ≈ 读一个小 diff。**这是协调者的判断,用户可否决。**

派单已显式钉 `-m gpt-5.6-sol -c model_reasoning_effort=xhigh`,不再继承 `~/.codex/config.toml`。

## 今晚明确不做

- **N3 worktree 清理**:虽已授权,但此刻有 8 个活跃 worktree 在跑单,破坏性操作撞在途分支的风险 > 收益。明早收账后盘面静态时再做。
- 任何合并 / push / 真人试玩。

---

## 夜间事件记录(02:44–03:00 巡检追加)

**① 执行端被挂起 3.5 小时,已恢复。** runner + N10 + N11 全部 `T`(stopped)态,日志停在 23:18/23:47/23:48。
根因:另一 agent/会话在 01:58 建 `codex/p2-g2-human-ready-20260827`,其 plan 明写「原 N6/N10/N11 与挂机 runner 进程保持 `SIGSTOP`」。
已 `SIGCONT` 恢复,进程回 `SN`、日志 02:47 重新推进。

**② 待用户拍(🔴,未动)** — `codex/p2-g2-human-ready-20260827` @ `6e74ed2f [BLOCKED]`,90 文件:
- 改了 `data/numbers.yaml`(执行端禁区),新增 `combat.posture` 块,`defense_break` 降级为兼容段
- 其 plan 声称「用户已选择姿态 B / 破防 A / 攻击令牌 A(1/1/1/1)」;**攻击令牌 A 的签字出处协调者查过为「查无实据」**,不能替用户认
- tip 是 `[BLOCKED]`,按 §8.3 本就是等拍板,未合未 push

**③ N10 交付 `f492c05 [BLOCKED]`,判定:执行端正确,派单方错。**
原 N10 验收标准第 2/4 条自相矛盾——固定绿 `aa9d8105..1db64d0d` 本身是「1 个 `lib/` 改动且无 receipt」的代码单,
不可能既「仍 PASS」又满足「代码单缺 receipt 必 FAIL」。执行端拒绝加 SHA 特判/伪造 receipt 而停下,处置正确。
已写 `N10R_receipt_gap_acceptance_fix.md` 改判并重派(固定绿语义改为「缺 receipt 必红,补如实 receipt 后必绿」)。

**④ 新 gate.sh 已由协调者独立验证。** N10 重写的 688 行 gate.sh 已 commit 且队列正在用它。
协调者用审计单样例 `0378df73..0ec0280a --skip-full` 复跑:正确判 `task kind: audit (lib/ changes: 0)` → **PASS**。
队列剩余 N12/N7/N9/N8 皆审计单,尺子安全。

**⑤ `~/.claude` 两处范围外污点**(`M automation-playbook/executors.json` 格式化 + `?? skills/afk/scripts/runner.sh`)
为先前会话遗留,已在 N10-R 里明令执行端不碰,由协调者收口。

---

## ⚠️ 03:20 重大发现:Gate 机制自身产生假绿(已止血)

**这是今晚最重要的一条,明早优先读。**

### 现象

`gate.sh` 在 `full_test` 之后崩溃,`analyze` / `format` / `receipt_crosscheck` 三项**从未执行**,
但 runner 把这些单记成了 `PASS`。

- N5:崩在 `line 343: syntax error near unexpected token 'else'`(23:1x,**早于 N10 改写**)
- N6 / N11:崩在 `line 480: syntax error near unexpected token '('`(python 代码漏进 bash 上下文)
- 两次崩溃 `gate.sh` **都正确返回了 `gate_exit=2`**

### 根因(两层,缺一不成灾)

1. **`gate.sh` 本身有语法错**,且**从未被提交过**——`git -C ~/.claude log -- skills/afk/scripts/gate.sh`
   只有 N10 的 `f492c05` 一个 commit,N0 产出时是 untracked。**没有旧版可回退。**
2. **`runner.sh` 的 PASS 判定把非零退出吞掉了**(真正的放大器):

```bash
GATE_LINE="$(tail -1 "$GATE_STDOUT")"      # 崩溃时 stdout 末行为空
if [[ "$GATE_RC" -ne 0 ]]; then
  GATE_ITEMS="${GATE_LINE#FAIL: }"          # → 空字符串
  FAILURE_ITEMS="$GATE_ITEMS"               # → 空字符串
fi
if [[ -n "$FAILURE_ITEMS" ]]; then          # → 假,不触发 stop_runner
  stop_runner ...
fi
write_status "PASS: $PACKAGE_BASENAME"      # → 记 PASS
```

**它检查了退出码,却用 stdout 末行推导失败项;崩溃时末行为空,于是失败被静默吞掉。**

### 影响面(逐单实测,非推断)

| 单 | 原 runner 判定 | 实况 | 补验后 |
|---|---|---|---|
| N4 | PASS | gate 完整跑完 | ✅ 有效,无需补 |
| N2 | PASS | `--skip-full` 完整跑完 | ✅ 有效 |
| N5 | PASS | **崩溃,gate_exit=2** | ✅ 已补验 PASS |
| N6 | PASS | **崩溃,gate_exit=2** | ✅ 已补验 PASS |
| N11 | — | **崩溃,gate_exit=2** | ✅ 已补验 PASS |
| N12 | 待定 | 预期同样崩 | ⏳ 需补验 |
| N7 / N9 / N8 | 待定 | 预期同样崩 | ⏳ 需补验 |

**补验方法**:`gate.sh --skip-full`(该路径未受影响,N2 已验证走得通)覆盖
scope / commit_msg / worktree_clean / analyze / format / receipt;
全量证据复用崩溃前已打出的 `[PASS] full_test: error_block_count=0 last=... All tests passed!`(那是真实测量)。
N5 `05:05`、N6 `08:19`、N11 `07:45`,三者 `error_block_count` 均为 0。

### 仍未修复(明早处置)

1. **`gate.sh` 全量模式仍坏**。N10-R 已在改 gate.sh,但它的验收标准没覆盖「全量模式不崩」,**需补一条**。
2. **`runner.sh` 的吞错逻辑没改**。**不要在 runner 运行期间编辑它**——bash 是增量读脚本的,改运行中的脚本会导致未定义行为。
   等队列跑完再改,或另起新版。
3. **`gate.sh` / `runner.sh` 长期 untracked** 是这次没有回退路径的根因;应纳入版本管理并加 `bash -n` 语法自检。

### 判据沉淀

**工具自己的退出码必须是唯一判据,不得用输出内容反推失败项。**
「退出码非零但输出为空」正是崩溃的典型形态,而这恰恰是最该拦下的情况。

---

## ✅ 03:50 Gate 假绿已闭环(实测)

### 1. `gate.sh` 全量模式修复已验证

N10-R `0566f29` 后,**首次跑通完整全量链路**并打出终审行。实测(对 N12 分支 `f1e645f0`):

```
[PASS] full_test: error_block_count=0 last=05:06 +5611: All tests passed!
[PASS] analyze:   No issues found! (ran in 14.9s)
[PASS] format:    Formatted 1619 files (0 changed)
[SKIP] receipt_crosscheck: audit task has 0 lib/ changes
PASS
gate_exit=0
```

此前两次崩溃(N5 `line 343`、N6/N11 `line 480` python 漏进 bash)都发生在 `[PASS] full_test` **之后**,
导致 `analyze` / `format` / `receipt_crosscheck` 从未执行、终审行从未打印。现在三项全部执行且终审行存在,
**`bash -n` 之外的运行期路径也已证明可用**。

### 2. N12 已真 Gate

runner 在 ~03:15 记的 N12 `PASS` 是那个坏 gate.sh 给的,已作废。
本次用修好的 gate.sh **全量模式**重跑 → `PASS` / `gate_exit=0`(证据同上)。
全量 5611/5611 与 main 基线一致,N12 未引入回归。

### 3. N5 / N6 / N11 复合 Gate 无缺口(量测结论)

崩溃点在 `receipt_crosscheck`,故这三单唯一没跑到的就是该项。实测三者的 `lib/` 改动数:

| 单 | worktree | head | `lib/` 改动 | 总文件 | 判定 |
|---|---|---|---|---|---|
| N5 | `挂机武侠-p2-n5-ci` | `fa6e7ad0` | **0** | 1 | audit → receipt_crosscheck 本就 SKIP |
| N6 | `挂机武侠-p2-n6-deadfield` | `76654911` | **0** | 1 | 同上 |
| N11 | `挂机武侠-p2-mutation` | `e9a3aa8a` | **0** | 4(`docs/` + `tools/mutation/`) | 同上 |

三者均为纯审计型交付,`receipt_crosscheck` 对其不适用,**不需要重跑全量 Gate**。
它们已有的证据链完整:`--skip-full` 复检(forbidden_files / test_deletions / commit_msg /
worktree_clean / analyze 0 issue / format 0 changed)+ 崩溃前抢救的 `[PASS] full_test`
(N5 `05:05`、N6 `08:19`、N11 `07:45`,均 `error_block_count=0` + `All tests passed!`)。

### 4. 仍未修(留到队列排空后)

- **`runner.sh` 吞退出码**(`:165` `GATE_LINE="$(tail -1 ...)"` 在 gate 崩溃时取到空串 → `:175`
  `FAILURE_ITEMS=""` → `:182` 不触发 `stop_runner` → `:186` 照记 `PASS`)。
  gate.sh 不崩之后此 bug 不会再被触发,但**放大器还在**,必须修。
  **禁止现在改**:bash 逐段读取正在运行的脚本,改动是未定义行为。
- **`gate.sh` / `runner.sh` 未纳入 git 跟踪**——这是「崩了没有回滚版本」的根因。
  应纳管并加 `bash -n` 自检。
- **`gate.sh` 缺方案 §21.6 的两项**:常规视口 visual smoke、生产路线 smoke。
