# 派单包 · 二阶段 M2-A0 范围现状盘点(2026-08-28)

## §0 身份与总纪律

- **唯一基线**:`1ba913a633beb0fd8f9b47764161f47c54260707`(候选链 tip)
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **不得修改 `~/.claude/skills/` 下任何文件**(含 `gate.sh`)。
- commit message **中文动宾**;收工 tip 前缀 `[READY]` 或真实 `[BLOCKED]`,worktree clean。
- 本单**零 `lib/` 改动**,是**审计单**。唯一产出是一份 md。receipt 形态见 §5。
- **本单不实装任何东西。**发现缺口就如实记录,不要"顺手补上"。

## §1 本单存在的理由

用户 2026-08-28 真人试玩后拍板「按方案做 M2 四模板」。但方案 §18 的 M2 范围里,有多项在 `CLAUDE.md` 版本摘要中已自称实装(v1.53 关间叙事去阻塞、v1.75/v1.89 当前掌门与五模式一致性等)。

**长寿文档的「已实装 ✅」是 drift 高发区,不得作为事实源。**本单的唯一任务:把 M2 范围逐条落到代码实况上,产出可直接驱动实装 spec 的基线。

盘点错了,后面整个 M2 批次都建在错误基线上。

## §2 唯一可验收结果

一份 `docs/audit/m2_scope_inventory_20260828.md`,把 §3 九条逐条判定为 **已实装 / 部分实装 / 未实装**,每条都带 `file:line` 或 `yaml:line` 实证。

**上限 150 行。**不写方案复述,不写建议方案,不写工作量估算——那些是我的活。

## §3 九条盘点项(方案 §18 M2 范围原文逐条)

对每一条,给出:判定 + 证据 `file:line` + 一句话现状描述。

| # | 方案原文范围 | 必须回答 |
|---|---|---|
| 1 | 山匪四角色生态 | 存不存在"生态/敌人族群"这一层抽象?四个山匪角色在哪定义?还是只有零散 enemy 快照? |
| 2 | `stage_01_03` 黑风岭 35–45 总敌量、8–16 活跃、攻击令牌 2–4 | 当前实配是多少?"活跃数"和"攻击令牌"有没有生产实现?(注:`attack_token_observe_only_observer.dart` 名字含 observe_only,核它到底是观察还是已 enforcing) |
| 3 | 第 1 章五关依次为破路/据点/伏击/斩将/斩将 | 代码或 yaml 里**有没有"模板"这个概念**?五关现在靠什么区分?还是全走 `mainline_wave` 同一份配置? |
| 4 | 剑形态完整普攻链 | "武器形态"存不存在?普攻是单段还是有连段链? |
| 5 | 至少一项护盾、一项化解/反击、一项聚怪、一项绝技 | 四类各自有没有生产实现?分别是哪个符号? |
| 6 | 新 HUD、聚合伤害、杂兵散墨、屏外提示、结果"下一关" | 五项逐个判定。屏外提示(off-screen indicator)特别核——高密度下没有它就没法玩。 |
| 7 | 关间剧情移除并进入章节卷轴/待处理江湖事 | CLAUDE.md v1.53 自称已完成。**核代码,不信文档。** |
| 8 | 首次推进使用"当前掌门"身份解析 | CLAUDE.md v1.75/v1.89 自称已完成。**核代码,不信文档。** |
| 9 | 手动首推必须全通 | 第 1 章五关手动首推路径当前是否连通?有没有测试覆盖? |

## §4 盘点纪律(这几条决定盘点质量)

- **搜不到 ≠ 不存在**。先搜中文/领域词找到代码里的真实命名,再下判定。
  `git grep -E` 是 POSIX ERE,**不认 `\s`**(静默永不匹配),别用。
- **"采集却不用的字段"是漏实现的强信号**——yaml 里配了、loader 读了、但生产路径零消费,判「部分实装」并写明消费方缺在哪。
- **别按文件名判断**。`*_observe_only_*` / `*_batch_gate_*` 这类名字要读实现才知道是不是已接线。
- 判「已实装」必须能指出**生产消费点**,不是只有定义或只有测试。
- 判「未实装」前先做一次反向搜索(换 2 个以上关键词),把否定式结论的证据写进文档。

## §5 receipt.yaml —— 本单是**审计单**

Gate 按 `git diff --name-only base..head` 有没有 `lib/` 路径自判单类型。本单零 `lib/` → **审计单**:

- `break_red` **必须留空**(写成代码单的两向数组会 schema FAIL)。
- 必须且只能有一个 `audit_verification` 块。

```yaml
schema_version: 1
base_sha: "1ba913a633beb0fd8f9b47764161f47c54260707"
head_sha: "<收工 tip 全 40 位小写 sha>"
changed_files:
  - "docs/audit/m2_scope_inventory_20260828.md"
full_test_last_line: "<原文>"
error_block_count: 0
analyze_last_line: "<原文>"
format_last_line: "<原文>"
break_red:
audit_verification:
  kind: "git_diff_check_and_patch_sha256"
  diff_check_exit: 0
  patch_sha256: "<下面命令输出的 64 位小写 sha256>"
```

```bash
LC_ALL=C git -c core.quotePath=false --no-pager diff --no-ext-diff --no-textconv \
  --no-renames --binary --full-index --no-color <base_sha>..<head_sha> | shasum -a 256
```

纯文档单仍需跑 analyze / format / 全量各一次并抄原文尾行(全量前先建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;锁存在就等)。

## §6 `[BLOCKED]` 出口条件

- 某条盘点项的判定需要改代码才能确认(不许为了盘点去改生产代码)。
- 发现方案范围与现有架构存在**不可调和的冲突**(例如"模板"概念与现有 stage schema 互斥)——这属于要用户拍板的设计冲突,停下报告,不要自己选一条路。

## §7 我(Claude)会怎么验收

1. 抽检至少 5 条判定,自己按给出的 `file:line` 复核。
2. 重点复核判「已实装」的项——**这类判错代价最大**(会让后续 spec 漏掉真正要做的活)。
3. 核 receipt 与实测对撞(含 patch sha256)、worktree clean、tip 前缀、禁区零 diff。
4. 任何一条"已实装"经我复核发现只有定义没有生产消费点,整单打回。

## §8 明确不做

- 不实装任何 M2 内容。
- 不写实装方案、不排期、不估工作量。
- 不碰 F1 手感单的域(`phase0a_battle_screen.dart` 的输入与 HUD 改动)——那是另一个在跑的单,只读不写。
