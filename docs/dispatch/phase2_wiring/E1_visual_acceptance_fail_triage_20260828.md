# 派单包 · E1 视觉验收 54 项 FAIL 逐条 triage(2026-08-28)

## §0 身份与总纪律

本单是**判定 triage 单**,不是 UI 修复单。产出是「哪些 FAIL 是真缺陷、哪些是判据误用」的分类结论。

- **唯一基线**:`1ba913a633beb0fd8f9b47764161f47c54260707`
- 分支 `codex/p2-e1-visual-fail-triage-20260828`,worktree `/Users/a10506/Desktop/Projects/挂机武侠-e1-visual-triage`
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **不得修改 `~/.claude/skills/` 下任何文件**
- commit message **中文动宾**;tip 前缀 `[READY]` 或真实 `[BLOCKED]`
- **本单零 `lib/` 改动**。需要改生产 UI 才能推进 → 停下报告,不要自己动。

## §1 事实底座(2026-08-28 协调者实测,你要自己复算一遍)

事实源:`docs/audit/phase2_visual_acceptance_a2_20260826.md`(95 行)

| 列 | PASS | FAIL | SKIP |
|---|---|---|---|
| 溢出 | 46 | 0 | 2 |
| 返回 | 34 | **12** | 2 |
| 键盘 | 24 | **22** | 2 |
| semantics | 26 | **20** | 2 |
| 鼠标 | 0 | 0(全 N/A) | 2 |

48 行(46 可达 + 2 SKIP),**FAIL 合计 54**。
开工第一步自己复算这张表,与上表不符**先报告偏差再动**,不要顺着我的数往下做。

**已知分布**:`phase0a_battle_screen` / `phase0a_mainline_battle_host` / `stage_entry_flow` /
`tower_entry_flow` / `phase0a_visual_roster` 的键盘列是 **PASS**,FAIL 在「返回」列;
键盘 FAIL 集中在 `stage_list_screen` / `inner_demon_screen` / `tower_floor_list_screen` /
`mass_battle_screen` / `light_foot_screen` / `main_menu_status_summary` /
`mainline_location_archive_screen` 等菜单类屏。

## §2 三个已知假阳陷阱(不照做必出错判)

1. **只扫 `GestureDetector` 会漏判**。判一个屏「键盘不可达」之前,必须查同屏是否存在
   其他可键盘激活的控件(`InkWell`/`TextButton`/`FocusableActionDetector` 等)。
   同屏另有可达入口 = 该行不是真缺陷。
2. **`FocusHighlightMode.automatic` 下 `autofocus` 不画焦点环**。截图里看不到焦点环
   **不等于**焦点不可达。要用真实焦点遍历取证,不要靠肉眼看图。
3. **「返回」FAIL 要区分两种**:真的没有返回路径 vs 有返回但判据只认某种特定控件。
   后者是判据误用,不是产品缺陷。

## §3 任务

逐条处理 54 个 FAIL,每条给出且只给出以下三种分类之一:

| 分类 | 含义 | 证据要求 |
|---|---|---|
| `真缺陷` | 生产 UI 确实不可达 | 必须给出该屏所有候选控件的 `file:line` 与逐个排除理由 |
| `判据误用` | 行为正常,判据口径不对 | 给出实际可达路径的 `file:line` |
| `无法判定` | 现有手段拿不到证据 | 说明缺什么,不许猜 |

**不许出现「疑似」「可能」而无实测支撑的条目。**
**不许因为「在清单里」就把一条判成真缺陷**——判据误用同样是合法结论,而且很可能是多数。

## §4 产出

`docs/audit/visual_acceptance_fail_triage_20260828.md`,**≤120 行**:

1. 复算后的三列 FAIL 计数(与 §1 对撞,不符要说明)
2. 54 条逐条分类表(目标 / 视口 / 列 / 分类 / 证据 `file:line`)
3. 按分类汇总:真缺陷 N 条、判据误用 M 条、无法判定 K 条
4. 若判出真缺陷:按屏聚合出**修复建议清单**,写清每条要动哪个文件——**只写建议,不实装**

允许新增 `test/` 下的**只读探针测试**来取证(例如遍历某屏的 focus traversal 顺序并打印),
但探针测试要么写成正式可留存的守卫测试(需通过破坏证红),要么取证后删除,
**不得留下不断言任何东西的空壳测试**。

## §5 `[BLOCKED]` 出口

- 需要改生产 UI 才能推进
- 需要动任何禁区文件
- 需要真人主观判断可达性
- 复算计数与 §1 差距大到说明事实源本身有问题

## §6 收工流程

1. commit(中文动宾)
2. 若新增了 `test/`:跑该文件 targeted,并做**双向破坏证红**(删断言支点 / 强制退化值),
   两向实测变红并记失败数,随后精确反向补丁还原;禁 `git reset --hard` / `checkout --` / `revert`
3. `flutter analyze --no-pub lib test tool`
4. `dart format --output=none --set-exit-if-changed .`(整仓 `.`)
5. 全量 `flutter test --no-pub`。**跑前建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;
   发现锁存在就等**——本批有另一道单在并行,两道不得同时跑全量
6. `git diff --check <base>..<head>`
7. 写 `receipt.yaml` 并 commit,tip 打标记,worktree clean

**退出码 0 不算成功**:逐条读 reporter 最后一行原文与 `[E]` 块计数。

**receipt 类型**:`git diff --name-only base..head` 含 `lib/` 路径 → 代码单;
零 `lib/` → **审计单**(`break_red` 留空 + 恰好一个 `audit_verification` 块)。本单预期是审计单。

## §7 环境

```bash
export LC_ALL=en_US.UTF-8      # 设成 C 会让 CocoaPods 在中文路径崩
# 不要设 DEVELOPER_DIR
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/
cd <worktree> && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

## §8 我会怎么验收

抽查至少 8 条分类结论,自己走一遍它的 `file:line` 看证据是否真的支撑该分类。
把「判据误用」写成「真缺陷」(或反过来)按错判打回。
只有分类没有证据的条目一律打回。
