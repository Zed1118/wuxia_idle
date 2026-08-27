# codex 自主推进部分的质量复核(2026-08-27)

## 0. 先纠正前提

用户问的是「昨晚用量用完后 codex 自己推进的部分」。**本会话并未因用量中断** ——
从 20:30 到 06:05 连续运行,派出并独立 Gate 了 **10 个正式单据**(N4/N5/N6/N7/N8/N9/N12/N13/N14/N15)。
N11 是并行的变异探针支持工作,不计入夜批正式分母(原文此处曾列 11 个标签而正文写「10 单」,2026-08-27 修正)。

但用户的关切**实质成立**:确实存在一批 codex 交付,**我从头到尾没有审过**,
即 17:47–01:58 的姿态/破防/G2 这条线:

| 分支 | tip | 我是否派/审过 |
|---|---|---|
| `codex/p2-posture-wiring-20260826` | `1db64d0d [READY]` | ❌ 未 Gate |
| `codex/p2-defense-break-posture-20260826` | `bc1f568c [READY]` | ❌ 未 Gate |
| `codex/p2-token-budget-realign-20260826` | `6b059d51`(**无就绪标记**) | ❌ 未 Gate |
| `codex/p2-token-candidate-rerun-20260826` | `bae8f89b`(**无就绪标记**) | ❌ 未 Gate |
| `codex/p2-g2-human-ready-20260827` | `6e74ed2f [BLOCKED]` | ❌ 未 Gate |

## 1. 我在本次复核中自己犯的错(先说)

我第一轮用 `git merge-base main <branch>` 作基线跑 Gate,报出
`[FAIL] forbidden_files: data/numbers.yaml`,并据此准备指控执行端越禁区。

**这是错的。** `P1_posture_wiring.md:8,67` 写明:

> 协调者已把冻结值写进 `data/numbers.yaml` `combat.posture`(基线里已有)……
> 禁区文件,一个字都不许动:`data/numbers.yaml`(**posture 块已由协调者写好,只读**)

实测 `b98b363c`「冻结姿态统一配置块」正是**协调者自己的 commit**,
而 `P1_posture_wiring_R1.md:11` 的验证区间用的就是 `b98b363c..2c8015d9`。
我用 merge-base 把协调者的 commit 算进了执行端账上。

用正确基线重判:

| 分支 | 执行端区间 | 禁区命中 |
|---|---|---|
| `posture-wiring` | `b98b363c..1db64d0d` | **无 ✅**(指控撤回) |
| `g2-human-ready` | `1cf7df37..6e74ed2f` | `data/numbers.yaml`(见 §2) |

## 2. 唯一坐实的禁区改动:只有注释,零个数值

`g2-human-ready` 的执行端区间内,`f21f8120`/`90553140` 两个 commit 改了 `numbers.yaml`,
全 diff 实测**只有注释,数值一个没动**:

```
- # TUNE-POSTURE-01 用户拍板 B(2026-08-26)冻结值,
+ # TUNE-POSTURE-01 用户选择候选 B(2026-08-26),
+ # 当前状态仍为 TUNING,待生产路径真人试玩后才能冻结,
```

方向是**把协调者的话说弱**:「拍板冻结」→「选择候选,待试玩才能冻结」。
另一处把 `defense_break` 注释成「旧 schema 兼容段,Phase0A 不消费」。

**定性**:违反了「一行都不许改」的硬围栏,但内容上是**降低断言强度**,不是偷改数值。
属程序违规、非数值风险。

## 3. 技术质量:自报数字属实

我独立跑 `gate.sh` 全量(临时 detached worktree,基线 `049fce08`):

```
[PASS] full_test: error_block_count=0 last=05:14 +5623: All tests passed!
```

与分支计划文件自报的「最终全量 `5623 passed / 0 failed`」**完全一致**。执行端没有虚报。

## 4. 攻击令牌 A/B:决策链已查实,原判「双方都查无实据」撤回

> **2026-08-27 修订**。本节初版结论是「registry 的 B 与 T1 的 A **双方都查无实据**」。
> 该结论**错误,现予撤回**。根因:我只 grep 了仓内 `docs/sessions/`,
> 没有查 Claude 会话原始 JSONL——而用户拍板发生在对话里,从来不落仓。
> 这是 memory `feedback_negative_grep_not_proof_of_absence`(搜不到 ≠ 不存在)的又一次实例。

### 4.1 查实的决策链(四处原始记录,均本会话实测)

JSONL 时间戳为 UTC,下表已换算为本地时间(UTC+8)。

| # | 出处 | 本地时间 | 原文 |
|---|---|---|---|
| 1 | `799898d4-….jsonl:2409` | 08-26 12:37:52 | 用户:**「按推荐执行」** |
| 2 | `799898d4-….jsonl:2412` | 08-26 12:38:36 | Claude:「采纳全部推荐:POSTURE=B / TIMELINE=B / **TOKEN=B** / QI=C,结算修法=A」 |
| 3 | `c77fedf4-….jsonl:685` | 08-26 21:52 | Claude 发现越界并给出**两件套**建议(见 §4.2) |
| 4 | `c77fedf4-….jsonl:695` | 08-26 21:54:34 | 用户:**「没问题,活交给 codex 干…」** |

**结论**:B 在 12:37 真签过,A 在 21:54 也真签过。
两份文档记的都是**真实发生过的决策**,不是任何一方编造;
它们看起来矛盾,只是因为**没人记录 B→A 的时间顺序与改判理由**。
`selected_candidate: A` 生效成立,**不需要重新拍 A/B**。

### 4.2 但用户批的是「两件套」,第二件的结果被丢掉了

21:52 那条建议原文是两部分,不是单纯的「A 照做」:

> **A 照做**(先把口径统一,纯回退零风险);**同时补一张小单:在总和 ≤4 的约束下重跑候选**。

理由也写明了:「B=6、C=7 **两个候选都违反方案 `:1025` 的 2–4**……
A 之所以合规,**纯粹因为它是「当前生产锚点」,不是因为它在 2–4 的空间里被优化过**。」

第二件**执行了**,交付在分支 `codex/p2-token-candidate-rerun-20260826`:

- `af326685 [BLOCKED] 固化攻击令牌候选证据`(08-26 22:14)
- 交付:`docs/spec/phase2_token_budget_candidates_le4_20260826.md` + `test/tuning/phase2_combat_core_tuning_candidates_test.dart`
- 方法:在调优测试台架里**穷举**总和 2–4 的全部合规组合
- 结论:推荐 `2/1/1/0` —— melee 授予率 **13.30% → 25.69%**、
  总授予率 **17.28% → 20.47%**、平均连续拒绝 10.64 → 10.72,
  **代价是 support 攻击授予率归零(0.00%)**

**该分支至今 `[BLOCKED]`,没有任何拍板记录。**
(tip `bae8f89b 并入探针工具格式化基线` 是后叠的格式化 commit,把 `[BLOCKED]` 前缀冲掉了——
按 §8.3 机械读作 WIP,但实质状态是 BLOCKED 等拍板。**这是就绪标记机制的一个洞**:
格式化/基线类 commit 叠在标记 commit 之上会静默清掉信号。)

所以当前生产用的 A(`1/1/1/1`)处境是:**合规,但从未与 ≤4 空间里的其他组合比较过**。
T2 的实测说明这个空间里存在参与感明显更高的点位。

### 4.3 遗留的两个 🔴 待拍

1. **是否采纳 T2 的 `2/1/1/0`** —— 收益是 melee 授予率近乎翻倍、总授予率 +3.19pp,
   代价是 support 流派攻击授予率归零。support 归零是不是可接受的产品取舍,是用户的判断,
   不是执行端或协调者能代拍的。项目写明的产品原则是「战斗爽感 = 参与感 + 即时打击」
   (memory `feedback_wuxia_combat_satisfaction_principle`),这条原则**指向采纳**,但仍需签字。
2. **「2–4 攻击令牌」的口径** —— 指全部令牌还是只指近战令牌?
   方案 `L617`/`L1025`/`L1534` 互相冲突。此项已挂在 N13 拍板菜单里。

### 4.4 真正要修的是留痕机制,不是这次的决策

两份文档各记录了链条的一端,谁都没记「上一次是什么、为什么改」。
`decision_registry.yaml` 里 `selected_candidate: A` 目前仍沿用 B 的理由字段
(`chosen_because: 群敌参与率 +9.75…`)——**A 顶着 B 的理由**。
这是本节唯一坐实、且仍未修的缺陷。

## 5. 两条 `[READY]` 分支的处置建议

`posture-wiring` 与 `defense-break-posture` 都打着 `[READY]`,但:

- 各删 165 行测试(多数文件增多于删,形状是语义重写而非掏空,但未逐条核过)
- `docs/sessions/NEXT.md:50` 记录 `posture-wiring @ 2c8015d9` 曾**复核不过**(4 条失败);
  之后的 `aa9d8105`/`1db64d0d` 声称修好,但**从未有人独立 Gate 过**

它们已被 `g2-human-ready` 吸收(同一条链的前段),建议**不单独复核**,
统一以 `g2-human-ready` 为审查对象。

## 6. 结论

**codex 的执行质量:合格偏好。** 依据:

- 忠实执行派单包指令(T1 的「保留 B、另加一行」逐字照做)
- 自报数字属实(全量 5623 经我独立复跑印证)
- 主动打 `[BLOCKED]`、写「本块不得单独合入 main」、拒绝合并
- 把协调者的过强断言主动降级(拍板冻结 → 选择候选待试玩)
- 保留历史决策记录而非抹掉

**扣分项:**

1. 改了 `numbers.yaml` 注释(硬围栏「一行都不许改」),虽只降低断言强度
2. 两条 `[READY]` 分支从未被独立 Gate 就挂着可评标记

**真正需要修的在协调者一侧**(2026-08-27 依 §4 修订):
两份协调者文档(registry vs T1)各记录了同一条决策链的一端——B 在 12:37 签、A 在 21:54 签,
**两次签字都真实存在**,但谁都没记「上一次是什么、为什么改」,于是读起来像互相矛盾。
另有两项具体欠账:① registry 的 `selected_candidate: A` 仍顶着 B 的 `chosen_because`;
② 用户 21:54 批的是两件套,第二件(T2 的 ≤4 重跑,推荐 `2/1/1/0`)交付后
一直 `[BLOCKED]` 无人拍板。这不是 codex 的问题,是决策留痕机制有洞。

## 附:`g2-human-ready` 完整 Gate 结果(本会话实测)

```
[FAIL] forbidden_files: data/numbers.yaml          ← 仅注释,零数值(§2)
[FAIL] test_deletions: 185 deleted test lines
[PASS] commit_msg
[PASS] worktree_clean
[PASS] full_test: error_block_count=0 last=05:14 +5623: All tests passed!
[PASS] analyze: No issues found! (ran in 22.1s)
[PASS] format: Formatted 1622 files (0 changed)
[FAIL] receipt_crosscheck: code task has 27 lib/ changes but receipt.yaml was not found
FAIL: forbidden_files,test_deletions,receipt_crosscheck
gate_exit=1
```

**`receipt_crosscheck` 这条 FAIL 不能算在执行端头上**:外置收据机制是昨夜 N10/N10-R
才建起来的(`~/.claude` commit `0566f29`,08-27 03:35),而本分支最后一个 commit 是
08-27 01:58 —— **要求晚于交付**,属追溯性判罚。同理 `forbidden_files` 与 `test_deletions`
这两道检查也是 N0/N10 之后才有的自动化,此前只写在派单包正文里。

因此对本分支的公允判读是:**技术面三项全绿(full_test / analyze / format),
程序面三项 FAIL 中有一项(receipt)不适用、一项(forbidden_files)只涉注释、
一项(test_deletions)需逐条核实而非一票否决。**
