# N10-R · receipt 缺口补齐(验收标准改判后重派)

> **前置**:你已交付 `f492c05 补齐收据交叉核对 [BLOCKED]`(`~/.claude`,3 文件 806 行)。
> **协调者复核结论:你是对的,`[BLOCKED]` 判断正确,代码不必推翻重来。**
> 原派单包 N10 的验收标准第 2 条与第 4 条**自相矛盾**,是派单方的错:
> 固定绿样例 `aa9d8105..1db64d0d` 本身就是「有 1 个 `lib/` 改动、且无 receipt」的代码单,
> 它不可能既满足「仍 PASS」又满足「代码单缺 receipt 必 FAIL」。
> 你拒绝加 SHA 特判、拒绝伪造 receipt 而选择停下,是正确处置,记功不记过。

## 本单只做三件事

### 1. 验收标准改判(替换原 N10 验收方式全部四条)

固定绿样例的语义**从「必须 PASS」改判为「缺 receipt 故必须 FAIL,补上如实 receipt 后必须 PASS」**。
新门是对**未来**单生效的规则,旧 fixture 早于规则存在,不享有豁免、也不构成反例。

逐条跑并把**原始输出**贴进交付说明:

| # | 样例 | 期望 | 说明 |
|---|---|---|---|
| 1 | `b98b363c..2c8015d9`(worktree `挂机武侠-p2-posture`) | **FAIL** | 旧红仍红;失败项须含 `full_test` |
| 2 | `0378df73..0ec0280a`(worktree `挂机武侠-p2-spec-audit`)加 `--skip-full` | **PASS** | 审计单不因缺 `break_red` 误杀。**协调者已自行复跑确认当前实现此条已通过**,你只需复现并贴输出 |
| 3 | `aa9d8155..1db64d0d` 所在 range `aa9d8105..1db64d0d`,**不提供 receipt** | **FAIL**,且失败项**恰为** `receipt_crosscheck` | 这就是「代码单缺 receipt 必红」的证红样例 |
| 4 | 同一 range,**配一份如实 receipt** | **PASS** | 证明新门不是一刀切拒绝代码单 |

第 4 条的 receipt 必须**如实测**,不得编造:
- `full_test_last_line` / `error_block_count` / `analyze_last_line` / `format_last_line` 从该 tip 上实跑取原文
  (你上一轮已跑到 `09:28 +5617: All tests passed!`,若原始输出仍在可直接复用,否则重跑)
- `break_red` 两向都必须**真做**:
  - `remove_implementation`:删掉 `phase0a_battle_screen.dart` 里姿态标签的渲染门条件,复跑该文件测试
  - `force_degenerate_value`:把同一条件强制为 `false`,复跑同一测试
  - 两向各记实测 `failed_count`,做完**完整还原**并确认 worktree clean
- **禁止为了让第 4 条过而放宽 schema 或跳过 break_red**。做不出就停 `[BLOCKED]`,不要凑。

### 2. 分支约束更正(派单方错误,已修正)

原包照抄了挂机武侠仓的「禁碰 main」围栏,但 **`~/.claude` 是另一个仓、只有 `main` 一个分支**,
它的历史提交(`f231137` / `f3baf01`)也都在 main 上。**在 `~/.claude` 的 main 上提交是允许的**,
你上一轮的 `f492c05` 无需回退或搬到新分支。「禁碰 main」只约束 `/Users/a10506/Desktop/Projects/挂机武侠`。

### 3. 两处既有污点不归你管

`~/.claude` 开工前就有:
- `M automation-playbook/executors.json`(JSON 数组展开成多行的格式化,先前会话遗留)
- `?? skills/afk/scripts/runner.sh`(N0 单的产物,当时没提交)

**这两处你一行都不要碰,也不要提交**。协调者自己收口。
因此「工作树 clean」对本单**不适用**,交付说明里如实写「剩余污点为范围外既有项,未处理」即可,不算未完成。

## 范围围栏(机器可判)

- 只许改 `~/.claude` 下:`skills/afk/scripts/receipt.schema.md` / `skills/afk/scripts/gate.sh` / `skills/afk/SKILL.md`
- **挂机武侠仓库一行都不许写**(四个样例只读消费,`gate.sh` 自己会开临时 detached worktree 求值,不得改被检 worktree 的 HEAD)
- `SKILL.md` 相对 `f231137` 的净增长 ≤25 行

## 禁止的修法

- ❌ 禁止对任何具体 SHA 做特判。
- ❌ 禁止伪造或半伪造 receipt(含把 `break_red` 写成没真跑的值)。
- ❌ 禁止放宽代码单的 `break_red` 双向要求。
- ❌ 禁止改动 `executors.json` 与 `runner.sh`。
- ❌ 禁止在挂机武侠仓的任何 worktree 里写入。

## [BLOCKED] 出口条件

- 四条样例中任一条**在实现正确的前提下仍无法达到期望**,停 `[BLOCKED]` 并贴原始输出说明冲突在哪。
  **再次强调:发现派单标准本身有矛盾时停下来是正确行为,不是失败。**

## 交付说明必带

- 四条样例各自的**完整 gate 输出尾段**(含 `[INFO] task kind:` 行)
- 第 4 条 receipt 的全文
- `break_red` 两向的实测 `failed_count` 与还原后 `git status -sb` 原文
- commit message 中文动宾,tip 打 `[READY]` 或 `[BLOCKED]`
