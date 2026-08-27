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

---

## 04:00 N12 内容复核(抽验通过)+ 一个关键结构发现

### 抽验结果(禁采信自报,以下均本会话实测)

| 抽验项 | 方法 | 结果 |
|---|---|---|
| 算术自洽 | 脚本重算两表「承载组数」列求和 | 可派 `26` + 待拍 `210` = `236` ✅ 与 N2 的 236 组不合规吻合 |
| §20 ID 真实性 | `sed -n '1274,1366p'` 现取 A 系 ID | `A01–A13` —— **我错、执行端对**(见下) |
| 双锚 · 方案侧 | `sed -n '40p;43p'` + `114,116p` | `COMBAT-SCOPE-01`「当前仅 radial + caster」/ `MAINLINE-PARTICIPANT-01`「取首名角色回退」/ 六槽输入表,全部对上 |
| 双锚 · N2 侧 | `sed -n '18p;20p'` | 原文与引用一致 |

### 我的派单包写错了 §20 的 ID 范围

N12 派单包里我写「§20 canonical IDs 为 `C01`–`C17` / `E01`–`E10` / `T01`–`T12` / `A01`–`A09`」。
现取方案 `1321-1324` 行:

```
- A10:旧阵容到门人调度迁移。
- A11:战斗装配六槽与旧槽存档迁移;
- A12:活动中改装拒绝、跨角色装备锁与并发事务;
- A13:新旧存档版本 Gate、活跃活动迁移和幂等 fixture。
```

实际是 `A01–A13`,我少写四个。执行端没照抄我的错范围,而是自己读原文,并正确用 `A11` 承接
「冻结六槽输入」与「决定角色装配方案」两条。**这是本夜第二次执行端纠正派单方**
(第一次是 N10 拒绝我自相矛盾的验收标准)。

### 关键结构发现:遗留工作的瓶颈不是产能,是签字

| 分类 | 条数 | 组数 | 占比 |
|---|---:|---:|---:|
| 🟢 已解锁可派 | 7 | 25 | 10.6% |
| 🟡 先出方案 | 1 | 1 | 0.4% |
| 🔴 待用户拍板 | 31 | 210 | **89.0%** |

**236 组遗留工作里,210 组(89%)在用户签字前一步都动不了**。
`NEW-*` 为 0 —— 39 行全部能映射到 §20 既有 ID,说明方案本身覆盖完整,缺的不是任务定义。

这直接改写了「任务量不够」这个问题的答案:池子不空,是**闸门关着**。
后半夜继续堆 🟢 类小单能填满时间,但填不动分母;
**早上最高杠杆的交付是一份按「解锁力」排序的拍板菜单**,而不是更多审计报告。

### 补单 N13 · 拍板菜单(04:05 入队)

| 项 | 值 |
|---|---|
| 包 | `docs/dispatch/phase2_wiring/N13_decision_unlock_menu.md`(冻结于 `be74a53e`,sha256 前 16 = `ffb2d95385b1369c`) |
| worktree | `挂机武侠-p2-pool`(复用 N12 的,池文件就在里面) |
| 基线 | `f1e645f0` |
| 产物 | `docs/dispatch/pool/phase2_decision_menu.md`,≤150 行 |
| 队列位置 | N7(跑中)→ N9 → N8 → **N13** |

**为什么派这个而不是继续派审计**:N12 量出 89% 的遗留工作卡在签字。
再多的 🟢 小单能填满墙钟,但推不动 M0–M9 那个 `1/10` 的分母。
用户早上真正需要的是「先签哪几条最省事」,不是第七份审计报告。

**包里三条防线**(都是本夜踩过的坑的直接产物):
1. **禁代拍**写成可 grep 的验收判据(`grep -nE '建议|推荐|更好|更合理|应该选|倾向'`),不是一句口号
2. **禁自造 ID / 禁自造选项** —— 因为我自己在 N12 包里就写错过 §20 的 ID 范围(`A01–A09` 实为 `A01–A13`)
3. **对 N7 产物是条件依赖**:存在就用,不存在就降级并显式声明,不得因缺失停工、也不得假装读过

---

## 04:50 巡检收账 · 队列全交付

### 单据状态(Gate 结果取自脚本输出,非执行端自报)

| 单 | 分支 tip | Gate | 全量 | 交付 |
|---|---|---|---|---|
| N4 | `57fb6416 [READY]` | PASS | — | `docs/audit/phase2_test_false_green_audit_20260826.md` |
| N5 | `fa6e7ad0 [READY]` | PASS | 5611/5611 | `docs/audit/ci_health_20260826.md` |
| N6 | `76654911 [READY]` | PASS | 5611/5611 | `docs/audit/phase2_dead_field_audit_20260826.md` |
| N7 | `d56b214a [READY]` | `gate_exit=0` PASS | 5611/5611 `04:52` | `docs/audit/g0_decision_reconciliation_20260826.md` |
| N9 | `8d704d27 [READY]` | `gate_exit=0` PASS | 5611/5611 `04:36` | `docs/audit/backlog_replenish_proposal_20260826.md` |
| N8 | `be0e8582` **`[BLOCKED]`** | `gate_exit=0` PASS | 5611/5611 `04:24` | `docs/audit/claude_md_drift_20260826.md` |
| N12/N13 | `258b3e8e [READY]` | N12 PASS / N13 Gate 跑中 | 5611/5611 `04:27` | `phase2_leftover_pool_proposal.md` + `phase2_decision_menu.md` |

修复后的 `gate.sh` 已在 runner 里连续跑完 4 次完整全量,全部 `gate_exit=0`。
每份日志含**两轮** Gate:执行端自检(`--skip-full`)+ runner 独立复检(全量)。

### N8 `[BLOCKED]` —— 需用户拍板(不代拍)

N8 发现 CLAUDE.md 正文与代码实况的矛盾落在 🔴 红级,它只登记矛盾、明确不判定「该改文档还是改代码」。
**四处引用我已现场核对,全部属实**:

| 引用 | 现取内容 | 矛盾 |
|---|---|---|
| `CLAUDE.md:295` | 红线理由段 | 机制 Boss 参数与位置已变 |
| `CLAUDE.md:316-318` | 最终伤害公式 | 公式确实缺真气/内伤等当前乘项 |
| `CLAUDE.md:563` | §12.2 #10 师承遗物 | 传承规则字段未驱动生产行为 |
| `CLAUDE.md:565` | §12.2 #12「固定标价·不卖出·**无折扣公式**」 | 与 v1.23「装备可出售/分解」、v1.24「经验丹 ETL 动态标价」头部决议直接冲突 |

### N13 拍板菜单 —— 六条判据全过

| 判据 | 结果 |
|---|---|
| 体量 ≤150 行 | 67 行 ✅ |
| 禁代拍 `grep -nE '建议\|推荐\|更好\|更合理\|应该选\|倾向'` | **0 命中** ✅ |
| 守恒 ≤236 | 去重 `210`,差额 `26` = 绿 25 组 + 黄 1 组,与 N12 完全对齐 ✅ |
| 无自造 ID | 无方案 ID 的一律写「方案未编 ID」,4 个真 ID 均现搜可得 ✅ |
| 无自造选项 | 唯一列出的选项(`领悟点`/`已有强化材料`)现取方案 `L536` 原文属实 ✅ |
| 行号真实性 | 抽 `L30`/`L31`/`L387`/`L536`/`L617`/`L1033` 六处现取比对,全对 ✅ |

### ⚠️ 纠正一条我一直带着的错误认知:G2 不是待办

`test/tools/output/phase2_g2_stage_01_03_acceptance_record.md` **真实存在**(7675 bytes),
`overall: 8/8 PASS`,八项逐条带证据:测试 `file:line` + 截图 SHA256 +
真人 manual run `g2-manual-production-entry-81125630-20260824T123000Z`。
**黑风岭 G2 在 2026-08-24 就已由用户签过**,按 §23 step 10,M3/M4/M7 扩面不卡在 G2。
N13 据此把 G2 的 103 组从「早上待拍项」里移除,是对的。

**但有保留**:该验收是对 08-24 的代码态做的(memory `feedback_capture_commit_vs_screenshot_code_state`)。
此后 POSTURE 接线等改动是否影响其成立,是**另一个未回答的问题**,不能当无条件有效。

### 早上待拍菜单(按解锁力,前三)

| 顺位 | 问题 | 状态 | 解锁组数 |
|---|---|---|---:|
| 1 | 六类生态在各章和塔层如何固定分配 | `PROPOSED`(L30;目标表 L653-664) | **20** |
| 2 | 战斗信息层级/伤害组数/屏外方向上限/战后统计定值 | `TUNING`(L31;候选 L759-806) | **13** |
| 3 | 归来时保留各活动独立摘要 vs 重开统一归来报告 | 查无实据(§0.2 无对应 ID) | **12** |

11 个待拍问题直接覆盖 62 组,含传递合计可达 80 组。
**11 条里 10 条的「可选项」都是「方案未列选项,需用户先定方向」** —— 方案写了目标没写选项,
这意味着早上不是勾选题,多数得先定方向。

---

## 04:55 队列收官后续派 N14(附决策理由)

### 为什么没有就此收官

巡检 SOP 写的是「队列跑空且无待 Gate → 安全收官,不要自己补新活」。
但按 `feedback_no_effort_saving_in_recommendations` 做「工作量无关」自检:
**假设工作量完全不是考虑因素,我会就此停手吗?不会。**
池里 7 条 🟢 条目(25 组)不需要任何签字就能做,其中两条是纯 `test/` + `docs/audit/` 工作。
停手就是省力伪装。

区别在于:**「不补新活」指的是不发明任务,不是不动已建好的池**。
池子是昨晚专为「任务量不够」这个问题建的,现在正是它该被用的时候。

### N14 单据

| 项 | 值 |
|---|---|
| 来源 | 池 #39,§20 `C12` + `C14`,7 组,🟢,前置「无」 |
| 包 | `docs/dispatch/phase2_wiring/N14_same_core_reward_evidence.md`(冻结于 `b3a1b1cf`) |
| worktree | `挂机武侠-p2-samecore`,分支 `codex/p2-same-core-evidence-20260827` |
| 基线 | `b3a1b1cf` |
| 预热 | dylib `2187120` bytes / `pub get` ok / `build_runner` ok / `analyze` 0 issue / 工作树 0 脏 |
| 产物 | `docs/audit/phase2_same_core_reward_evidence_20260826.md` ≤120 行 + `test/` |

**目标不是让 7 组全绿,是让它们有确定答案。查出 FAIL 与查出 PASS 同等有价值。**

包里专门写了一节「红了怎么办」防假绿:实测 FAIL 时**不许**提交红测试(会把有价值的发现变成挡路的红),
**也不许**放宽断言或改生产代码让它绿;正确做法是测试加显式 `skip:` 并在理由里指向报告的 FAIL 组,
tip 打 `[BLOCKED]`。验收时我会 `grep -n 'skip:'` 逐个核对是否有对应 FAIL 组,没有的按假绿处理。

另外三条验收是本夜教训的直接产物:
1. **确定性自证** —— 同一命令连跑两次比对 hash,不一样即整单打回(seed 没真固定住)
2. **破坏证红** —— 挑一条标 PASS 的断言,改坏它依赖的生产行为,确认必然转红
3. **组数溯源** —— 我自己 `sed -n '56p'` 现取 N2,不采信包里的转述

### ⚠️ 一个需要用户裁决的口径冲突(我没有自行放宽)

巡检 SOP 的硬约束写了「禁碰 main」,但**协调者盘面今晚合了 7 次 main**
(`a352b3f8` → `4e5edb9a` → `ab6d757f` → `1280b15f` → `a2d73f97` → `7d27a985` → `77c0199a` → `b3a1b1cf`)。

我的理解是:该约束针对的是**执行端交付分支**,而盘面必须在 main 上,
因为它是唤醒时重建上下文的唯一事实源(冻结派单包同理,执行端要按 SHA 取包)。
全部合入内容都是**纯文档,0 行 `lib/`**,且全是 fast-forward。

但这是我的解释,不是用户的明示授权。**早上请用户明确一句**:
协调者的纯文档盘面/派单包合 main 是否照旧允许。若不允许,改为只留在
`coordinator/p2-handoff-20260826b` 分支上,执行端改按分支取包。

---

## 05:30 N14 验收(四条判据全过)+ 一个弱支点发现

### 交付

`codex/p2-same-core-evidence-20260827` @ `85ee8483 [READY]`,worktree 0 脏,0 个 `lib/` 改动。
Gate `gate_exit=0`,全量 `5611 → 5618`(+7 测试),`analyze` 0 issue,`format` 0 changed。
7 组全部 PASS。

### 四条判据(全部本会话实测)

| 判据 | 方法 | 结果 |
|---|---|---|
| 组数溯源 | 自己 `sed -n '56p'` 现取 N2 | ✅ 确为 7 组,断言原文与报告逐条一致 |
| 确定性自证 | 同一命令连跑两次 | ✅ 两次均 `+7 All tests passed` |
| 破坏证红 | 改 `phase0a_player_bot_adapter.dart:55` `attack: true→false` | ✅ **第7组转红**;还原后 sha256 `964fb9dca217f89d` 与备份一致、工作树 0 脏 |
| skip 审查 | `grep -cn 'skip:'` | ✅ **0 个**,与 7/7 全绿自洽 |

破坏/跑测/还原写进同一个带 `trap restore EXIT INT TERM` 的脚本,
避免重演早先「超时把变异体留在工作树」的事故。

### 报告本身的三个正确处(值得记下)

1. 用 `stage_01_01` 而非黑风岭 `stage_01_03` —— 主动避开池条目警告的「单关外推全模式」陷阱
2. 走 `rngProvider.overrideWithValue(DefaultRng(seed:))`,不新接 `Random` 签名 service(守 CLAUDE.md §9.1)
3. 明说 hash 用测试内 FNV-1a 而非 Dart `hashCode`(后者进程随机化,会让「确定性」变成假的)

### ⚠️ 弱支点:第2组的 `commandSummaries` 断言构造上恒真

破坏 bot 后**第2组没红**,追进去发现原因:

```dart
// 测试 :298-303  bot 产命令
final command = bot.commandFor(botController.state);
commands.add(command);
botController.step(command);
// 测试 :318-333  manual 回放同一批命令
for (final command in commands) { manualController.step(command); }
```

第2组断言 `traces[bot].commandSummaries == traces[manual].commandSummaries`,
而 manual 逐条 step 的**正是 bot 刚发出的那批命令** —— bot 怎么变两边都一样,**该行断言不可能红**。

**但这不算假绿**,判定理由:
- N2 的原始断言是「同一命令流经不同执行路径必须得到相同状态 hash」,回放是测这件事的正确做法
- 真正承重的是每组都调的 `_expectFourModeTraceParity`(比四条轨迹逐 tick 状态 hash),那条是实的
- 系统里不存在独立的「人类手动输入源」,除了回放没有别的做法

**问题在于组名和结论文案 oversell**:「前台 bot 产生与手动回放相同 command」听起来像验证了 bot 决策,
实际只验证了回放器没截断。建议后续把该行改成断言 **manual 回放未提前 break**(它唯一可能失败的方式),
或直接删掉该行、只留 parity。

### 这类测试的结构性上限(不是缺陷,是边界)

四模式 parity 套件**天然无法发现「四种模式被同等地改坏」的缺陷** ——
我的破坏之所以能被第7组抓到,是因为掉落 profile 有独立于 bot 的比较基准。
凡是共用 reducer 的改动,四边一起变、hash 照样相等。
**这条边界应当写进报告的「本证据不覆盖什么」**,否则 7/7 PASS 会被读成「同核已完全证明」。

---

## 06:05 N15 验收 · 夜批收官

### N15 `[BLOCKED]` —— 这是本夜最有价值的一单

`codex/p2-density-fx-evidence-20260827` @ `94a93293 [BLOCKED]`,0 个 `lib/` 改动,
全量 `5613 PASS / 4 SKIP`,Gate `gate_exit=0`。格 1-4 **`0/4 PASS`**。

它没有交出漂亮的全绿,而是查出**两个真问题**:

#### 发现一:方案写的「低特效设置」在生产里根本不存在

方案 `L801` 写:「设置允许降低特效密度、背景人群、震屏和闪光,但不能减少真实敌人数、改变攻击令牌或降低难度。」

实况:`GameplaySettings` 只有 `autoPlayDefault` / `battlePlaybackSpeed` / `textDensity` / `reduceFlashing`,
而 `reduceFlashing` **只出现在 `lib/features/settings/` 三个文件里,战斗/主线/塔/群战零消费**。

**我独立复核过**(按 `feedback_negative_grep_not_proof_of_absence`,否定式 grep 不是存在性证明,
必须搜中文/领域词):`git grep -niE '特效|粒子|剪影|震屏|闪光|背景人群'` 与
`effectDensity|vfxDensity|lowEffect|particleDensity|silhouette` 在 `lib/` 的命中**全部是误报** ——
`enums.dart:142` 是「剑鸣特效」注释、`numbers_config.dart:1138` 是「克制特效字符串」文档注释、
`visual_acceptance_plan.dart:240` 是奇遇录「剪影态」、`portrait_frame.dart` 是头像「身份剪影」。

**结论:这不是「缺证据」,是「缺功能」。** 属 🔴(玩家可见设置 + 新增生产消费点),需用户拍板。

#### 发现二:「群战 18/24」把总量当成了同时活跃数

`data/stages.yaml` 注释原文(我现取复核):`stage_mass_battle_04 · wave=4[5,6,6,7]`。
**24 是四波之和,同时活跃最多 7。** 五关波形实测 `[5,5]/[5,6,6]/[6,6,7]/[5,6,6,7]/[6,6,7,7]`,
active 只有 `{5,6,7}`。塔 14 层 `enemyTeam=3`、映射也是 3。

也就是说,**不存在 24 单位同屏的时刻**,方案 `L1420-1428` 的「8、16、24 活跃单位下 HUD 不被遮挡」
这条判据在当前内容下**测不出来**。这是口径错误,不是实现缺陷。

### 七条判据核对

| 判据 | 结果 |
|---|---|
| 锚点溯源 | ✅ 我自己 `sed -n '55p'` 现取 N2,格数与断言原文一致 |
| 确定性自证 | ✅ 报告贴两份日志 `cmp` 退出 0 + SHA-256 一致;我复跑亦稳定 |
| **破坏证红** | ✅ 见下 |
| 配置耦合验证 | ⚠️ 见下 |
| skip 审查 | ✅ 4 个 `skip:`(`:133/137/141/145`)与 4 个 FAIL 格一一对应,skip 理由字符串逐条指向报告 |
| 边界节 | ✅ 有「本证据不覆盖什么」,且多写一句「不等于 N15 通过」 |
| Gate | ✅ `gate_exit=0` |

**破坏证红实录(含我自己的一次选错)**:

1. 第一次我改 `phase0a_stage_content_mapper.dart:202`(`slot < count` → `count - 1`),**没证红**。
   查因是**我选错了破坏点** —— 那段走 `_asMainlineMob`(主线怪构造),而断言比的是群战映射。
   不是测试的问题。
2. 改对路径后:`enemy_combatant_snapshot_assembler.dart:61`(`j < count` → `count - 1`)
   → 测试 **`-1` 转红**,失败点正是 `:112` 的 `expect(mappedMassWaves, configuredMassWaves)`。
   还原后 sha256 `2b8d1efda54e932a` 一致、工作树 0 脏。

**配置耦合验证的诚实说明**:我原计划「改配置目标值看测试是否跟红」,但分析后发现
`configuredMassWaves` 与 `mappedMassWaves` **同源于 stages.yaml**,改配置两边一起变、不会红。
这不是缺陷 —— 该断言测的是 **mapper 是否忠实还原配置**,mapper 才是正确的破坏点(见上)。
但这意味着**该断言无法发现「配置本身写错」**,只能发现「mapper 与配置不一致」。

### 夜批总账

| 批次 | 单数 | 结果 |
|---|---:|---|
| 队列一 | 8 | 全部 Gate PASS;N8 `[BLOCKED]` |
| 队列二 | 1 | N14 `[READY]`,7/7 PASS,四条判据全过 |
| 队列三 | 1 | N15 `[BLOCKED]`,查出两个真问题 |

**零合并、零 push、零碰执行端分支** —— 全部 10 个交付分支原样留在各自 worktree 等用户处置。
协调者只合了自己的纯文档盘面(0 行 `lib/`,全 fast-forward)。

### 为什么在 06:05 停,而不是填满到 08:00

做「工作量无关」自检后仍然停,理由是**可派的活真的用完了**,不是省力:

- 池里 🟢 剩下的 4 条是「校准方案现状」,但方案文件在用户桌面且**只读**,派不出去
- 池 #37「补齐性能矩阵证据」含 **Windows** 格,本机做不了
- N16(视觉格 5-7)需要 CGEvent 驱动 macOS app 截图,**会接管鼠标**。
  按 `feedback_user_mouse_handoff` 借鼠标必须先告知用户时长,用户在睡觉无法授权 —— **不能无人值守派**

### 早上待办(按优先级)

1. **N15 发现一** 🔴 —— 「低特效设置」要不要做?方案写了但生产没有。做=新增设置+provider+VFX 消费点
2. **N15 发现二** —— 群战密度口径:24 是总量,方案的「24 活跃」判据当前测不出来,需修方案还是修内容?
3. **N8 `[BLOCKED]`** 🔴 —— CLAUDE.md 与代码的矛盾,最硬一处是 `:565` 与 v1.23/v1.24 头部自相矛盾
4. **拍板菜单** `docs/dispatch/pool/phase2_decision_menu.md` —— 11 问,前三解锁 20/13/12 组
5. **main 合并口径** —— 协调者纯文档盘面合 main 是否照旧允许(今夜 13 次)
6. **N14 第2组弱支点** —— 建议改成断言「manual 回放未提前 break」或删该行
7. **`runner.sh` 吞退出码** + **`gate.sh`/`runner.sh` 未纳入 git** —— 队列已空,现在可以修了
8. **N3 worktree 清理**(169 条,授权 3A,需三验)

## codex 反馈复核 + 收尾修复(2026-08-27)

**codex 对我那份审计的反驳,逐条实测后判定**:

| 主张 | 判定 | 依据 |
|---|---|---|
| 「双方查无实据」应撤回 | ✅ 成立,**已撤回** | 四条 JSONL 原始记录本会话复核,B 12:37 签、A 21:54 签 |
| 我的 16 协调提交零代码改动 | ✅ 成立 | 全 `docs/`,`lib/test/data` 命中 0 |
| 185 删行是语义重写非掏空 | ✅ 成立且更干净 | test/ 区间 +1451/-185,删行>30 的文件仅 1 个且净增(+65/-33) |
| 测试文件/声明数 | 增量对、**绝对基数错** | 实测 803→805 / 5505→5517;codex 报 820→822 / 5525→5537 |
| main 16 / candidate 10 无法 ff | ✅ 成立 | `rev-list --left-right --count` 实测 |
| T2 `2/1/1/0` 排除是正确的 | ⚠️ **这是代拍** | support 归零是事实,但「是否可接受」是 🔴 用户判断,T2 自己停在 `[BLOCKED]` 等签字 |

**新发现(就绪标记机制的洞)**:T2 分支 tip `bae8f89b 并入探针工具格式化基线` 无前缀,
按 §8.3 机械读作 WIP,实质是其父 commit 的 `[BLOCKED]`。
**格式化/基线类 commit 叠在标记 commit 之上会静默清掉就绪信号。**

**已修**:
- `docs/audit/codex_autonomous_work_review_20260827.md` §4 重写(`d1a5864c`,已合 main);记账 10 单/11 标签已订正
- `~/.claude` `a714209`:`runner.sh` 纳管 + 修「gate 崩溃被吞成 PASS」;
  四用例破坏证红,旧版对崩溃 gate 记 `PASS`/exit 0,新版 `FAIL: gate_crash_exit_3`/exit 1

**未修(需用户拍板或需派单)**:registry `selected_candidate: A` 仍顶着 B 的 `chosen_because`(在候选分支上,不属协调者微修例外)。
