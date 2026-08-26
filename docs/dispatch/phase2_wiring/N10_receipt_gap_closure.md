# N10 · receipt.yaml 交叉核对缺口补齐(基建)

> **本单工作目录是 `~/.claude`(不是挂机武侠仓库)。** 它是一个独立 git 仓。

## 背景(协调者 2026-08-26 实测)

今晚跑了两次 `gate.sh`,两次都打:

```
[SKIP] receipt_crosscheck: receipt.yaml not found
```

也就是说 `gate.sh` 里**最重要的那道防线——执行端自报数字 vs Gate 复跑数字的对撞——从来没有真正生效过**。
根因有两条,都已证实:

1. **派单包模板从没要求执行端产 `receipt.yaml`**。`~/.claude/skills/afk/SKILL.md` 的「派单包必含清单」①–⑦ 里没有这一项。
2. **`receipt.schema.md` 假设每个单都改生产代码**:它规定 `break_red` **恰好两项**、方向固定为 `remove_implementation` 与 `force_degenerate_value`。
   但纯审计单(如今晚的 N2 / N4 / N5 / N6)零 `lib/` 改动、**根本没有可破坏的实现**,产不出合法 receipt。
   现状下强行要求审计单交 receipt,只会逼执行端编造 break_red —— 比没有 receipt 更糟。

## 目标

补齐两处,让 receipt 交叉核对对**两类单**都真正可用:

1. **`receipt.schema.md`**:引入单类型区分。代码单沿用现规范;**审计单(零 `lib/` 改动)** 允许 `break_red` 为空列表,
   但必须新增一个可被 Gate 机器校验的替代字段(你来设计,要求:能证明执行端确实跑过验证、且 Gate 能独立复算对撞)。
2. **`skills/afk/SKILL.md` 的「派单包必含清单」**:新增一项,写明派单包必须要求执行端产 `receipt.yaml`,并指向 schema。

同时改 `gate.sh`,让它在 receipt 缺失时的行为分级:代码单缺 receipt → **FAIL**;审计单缺 receipt → 保持 `[SKIP]` 但打印明确原因。

## 范围围栏(机器可判)

- 只许改 `~/.claude` 下这三个文件:`skills/afk/scripts/receipt.schema.md` / `skills/afk/scripts/gate.sh` / `skills/afk/SKILL.md`
- **挂机武侠仓库一行都不许碰**
- `SKILL.md` 净增长 ≤15 行(它已 178 行,继续膨胀会没人读)

## 禁止的修法

- ❌ 禁止放宽现有代码单的 `break_red` 双向要求 —— 那是今晚唯一真正拦住假绿的机制。
- ❌ 禁止用「执行端自己声明这是审计单」来判定单类型 —— 那等于把判据交给被检方。
  单类型必须由 **Gate 独立从 `git diff` 算出来**(例如 `lib/` 改动数是否为 0)。
- ❌ 禁止改 `gate.sh` 里已通过固定样例的判定项(`full_test` / `analyze` / `format` / `test_deletions` / `forbidden_files` / `commit_msg` / `worktree_clean`)。

## 验收方式(必须自跑并把输出贴进交付说明)

改完后用**今晚两个已知样例**双向验收,两个都必须复现既有结论:

1. 已知红:`b98b363c..2c8015d9`(worktree `挂机武侠-p2-posture`)→ 必须仍 **FAIL**
2. 已知绿:`aa9d8105..1db64d0d`(同 worktree)→ 必须仍 **PASS**
3. 新增:构造一个零 `lib/` 改动的样例(可直接用 `挂机武侠-p2-spec-audit` 的 `0378df73..0ec0280a`),
   验证审计单路径按新规则走,且 **不因缺 break_red 而误 FAIL**
4. 构造一个「代码单但缺 receipt」的样例,验证它现在 **FAIL**(这是本单的核心新行为,必须证红)

## [BLOCKED] 出口条件

- 你设计的审计单替代字段无法被 Gate 独立复算(即只能采信执行端自报)→ 停 `[BLOCKED]`,把设计困难写清楚。
  **宁可停,也不要引入一个只能采信自报的字段** —— 那会让 Gate 看起来更严实际更松。

## 硬约束(全部照抄自协调者契约,违反即作废)

**执行端禁区文件**(一行都不许改):`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`

- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- commit message 用**中文动宾**,tip 打 `[READY]`(写完待评)或 `[BLOCKED]`(需拍板)
- 收工时工作树必须干净(`git status -sb` 无未提交实质改动、无未跟踪文件)
- 🔴 红级(玩家可见 UI / 数值与成长规则 / schema 迁移 / 删配置字段或功能 / GDD 解释)→ **停 `[BLOCKED]`,禁代拍**
- **数字必须实测**,禁转抄历史、禁凭记忆写 `file:line`;每条引用现 grep 定位
- 搜不到 ≠ 不存在:`git grep -E` 是 POSIX ERE **不认 `\s`**(静默永不匹配);先搜中文/领域词找代码真实命名
