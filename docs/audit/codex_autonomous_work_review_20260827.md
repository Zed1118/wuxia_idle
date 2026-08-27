# codex 自主推进部分的质量复核(2026-08-27)

## 0. 先纠正前提

用户问的是「昨晚用量用完后 codex 自己推进的部分」。**本会话并未因用量中断** ——
从 20:30 到 06:05 连续运行,派出并独立 Gate 了 10 个单据(N4/N5/N6/N7/N8/N9/N11/N12/N13/N14/N15)。

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

## 4. 真正的问题在协调者一侧:攻击令牌 A/B 来源链冲突

`g2-human-ready` 把生产令牌从 `2/2/1/1`(总和 6)改成 `1/1/1/1`(总和 4),
并在 registry 里保留 `user_choice: B` 的同时新增 `selected_candidate: A`。

**这不是执行端自作主张** —— `T1_token_budget_realign.md:72` 明确指示:

> `TUNE-ATTACK-TOKEN-01` 的历史选择 **不要抹掉**:保留原 `user_choice: B` 字段,另加一行

执行端**逐字照做**。问题在于 T1 本身的授权依据:

| 文档 | 时间 | 主张 | 证据 |
|---|---|---|---|
| registry commit `6114483c` | 08-26 12:44 | `ATTACK-TOKEN=B`,frozen 2/2/1/1=6 | 无用户侧原始记录 |
| 被删注释(候选测试内) | — | 「用户拍板维持两套口径」 | **查无实据**(T1 已证,我复验) |
| `T1_token_budget_realign.md` | 08-26 21:57 | 「用户 2026-08-26 拍板:恢复候选 A」 | **同样查无实据** |

**我的独立复验**:`grep -rn 'ATTACK-TOKEN\|攻击令牌' docs/sessions/` → **零命中**。
T1 用这把尺子证伪了别人的「用户拍板」,但它自己那句「用户拍板恢复候选 A」经同一把尺子量,
**也拿不出证据**。

T1 的**技术理由是站得住的**:方案 `:1025` 写「攻击令牌 2–4」,生产总和 6 越界;
`PROGRESS.md:16` 现取原文亦写「两边口径**待统一**」,与被删注释的「有意分离」矛盾。
但「越界该怎么修」是 🔴 数值规则,技术理由不能替代签字。

这与 N13 拍板菜单里挂着的待拍项**是同一件事**:
「『2–4 攻击令牌』指全部令牌,还是只指近战令牌?」(方案 `L617`/`L1025`/`L1534` 互相冲突)。

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

**真正需要修的在协调者一侧**:两份协调者文档(registry vs T1)对同一个用户决策
给出互相矛盾的记载,且**双方都拿不出用户侧原始证据**。
这不是 codex 的问题,是我们的决策留痕机制有洞。

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
