# 派单包 · 试玩阻塞输入诊断单(2026-08-28)

## §0 身份与总纪律

你是本单唯一执行端。这是**诊断优先单**:先拿到可证伪的根因,再谈修不修。

- **唯一基线**:`1ba913a633beb0fd8f9b47764161f47c54260707`(分支 `codex/p2-b3-presentation-test-audit-20260827` 的 tip)
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **不得修改 `~/.claude/skills/` 下任何文件**(含 `gate.sh`)
- commit message **中文动宾**;收工 tip 前缀 `[READY]` 或真实 `[BLOCKED]`
- 探针 `print` / 临时脚本**不得进 commit**

## §1 现象(2026-08-28 真人实测,用户原话)

在链 tip 编译出的 macOS app 里进战斗:**能普攻,不能移动,不能放技能**。
用户存档在**第 8 章**(`wuxia_save_slot1`),不是第一章。

## §2 我(协调者)已在代码层排除的五条 —— 不要重做

| 怀疑 | 结论与依据 |
|---|---|
| 键盘层没收到 | 排除。移动与 `J` 同在 `phase0a_battle_screen.dart` 的 `_handleKey`,`J` 通即该函数在跑 |
| controller 合并吞命令 | 排除。`phase0a_battle_controller.dart:95-117` 的 `_merge` 对 `left/right/up/down` 用 `\|\|` |
| adapter 没透传 | 排除。`phase0a_player_input_adapter.dart:118-125` 构造 `Phase0aMoveIntent` |
| `moveSpeed` 为 0 | 排除。玩家取 `arena.playerMoveSpeed`,`data/numbers.yaml:533` = `210.0`(`:148` 那处 `snapshot.speed` 是**敌方** actor) |
| 镜头跟随致"看着没动" | 排除。`Phase0aStage` 只有固定 viewport 映射,无 camera offset |

**尚未排除、值得先查**:`phase0a_combat_reducer.dart:556-562` 的 `defenseConsumed` 分支、
`:563` 的 `suppressedActorIds`(蓄力/踉跄压制)、以及 `_heldMovementKeys` 是否真的收到了 `KeyDownEvent`。

技能侧我的**待证伪假设**:`phase0a_stage_content_mapper.dart:1096` 显式排除 `SkillType.normalAttack`,
角色数字槽若只有普攻则 `bindingFor()` 全 null → 按 1-6 静默无反应。
对应 UI 证据:`phase0a_battle_screen.dart:735` 是 `if (numericSkillBindings.equipped.isNotEmpty)` 才渲染技能封印。
**这只是假设,第 8 章角色理应已配招,必须实测证伪或证实,不得直接采信。**

## §3 环境(三个今天实测的坑,不照做必挂)

1. **locale 必须 UTF-8**:`export LC_ALL=en_US.UTF-8`。
   设成 `LC_ALL=C` 会让 CocoaPods 对中文路径「挂机武侠」做 unicode 归一化时抛
   `Encoding::CompatibilityError`,`flutter build macos` 直接失败。今天实测。
2. **不要设 `DEVELOPER_DIR`**,设了 `flutter build macos` 报 xcodebuild 找不到。
3. fresh worktree 预热三件套,不做必撞 `.g.dart` 缺失:
   ```bash
   cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/
   cd <worktree> && flutter pub get && dart run build_runner build --delete-conflicting-outputs
   ```

## §4 存档保护(第一步,不做完不许进 §5)

app 是**沙盒**应用(`com.pen.wuxia.wuxiaIdle`),**所有 build 共享同一个存档容器**:
`~/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents/wuxia_save_slot{1,2,3}.isar`

`slot1` 是用户第 8 章的真实存档(5.0M)。你驱动游戏会直接写它。

1. 先杀掉所有在跑实例:`pkill -f "wuxia_idle.app/Contents/MacOS/wuxia_idle"`
2. 进程退干净后做**冷备**并记 sha256(协调者已有一份热备在
   `~/Desktop/wuxia_save_backup_20260828/`,那份是游戏运行中拷的,不作权威)
3. 收工前后各核一次 sha256,若被改动,在 receipt 与报告里**显式声明改了哪个 slot**

## §5 三件任务

### D1 移动失效根因

用自动化驱动,不靠肉眼猜:

- 发键用 **CGEvent**(AX 的 click/keystroke 对 Flutter 窗口无效,已有实录)
- 窗口 bounds **实时读**(`CGWindowListCopyWindowInfo`),不要假设位置尺寸;retina 是 2x
- 允许在 `lib/` 临时加 `print` 探针取证(`_handleKey` 入口、`_heldMovementKeys` 内容、
  `intentsFor` 产出的 intent 列表、reducer 移动分支的 `player.position` 前后值),
  **取证完必须精确还原,探针不进 commit**
- 结论必须落到具体 `file:line` + 实测值,形如「按下 W 后 `_heldMovementKeys` 为空」
  或「intent 生成了但 `suppressedActorIds` 每 tick 都含 player」

### D2 技能 1-6 根因

证伪或证实 §2 的假设。至少给出:该存档角色数字槽 1-6 各绑了什么、
`numericSkillBindings.equipped` 实际长度、战斗界面是否渲染了技能封印。

### D3 诊断报告

写 `docs/audit/playtest_input_blocker_diagnosis_20260828.md`,**≤80 行**。
每条结论带 `file:line` 与实测值;写清哪些是实测、哪些仍是假设。

## §6 允许你修什么(边界很硬)

- **可以修**:纯输入层 / 状态机 / 渲染层的确定性 bug(恢复本应有的行为)。
  修了必须补红线测试,并做**双向破坏证红**(删实现支点 / 强制退化值),
  两向都要实测变红并记失败数,随后精确反向补丁还原,禁 `git reset --hard` / `checkout --` / `revert`。
- **不许修,直接 `[BLOCKED]` 报告**:
  - 根因是设计意图(如「攻击期间有意锁移动」「一次 R 只累计架势」)
  - 根因指向 `data/numbers.yaml` 的调优值
  - 「没配招导致按键零反馈」——补提示属**玩家可见 UI**,🔴 级,禁代拍
  - 需要动任何禁区文件
  - 需要真人手感判断才能定性

## §7 收工流程

1. 实现/诊断并 commit(中文动宾)
2. 若改了 `lib/`:按 §6 做双向破坏证红
3. targeted 测试 → `flutter analyze --no-pub lib test tool` → `dart format --output=none --set-exit-if-changed .`(整仓 `.`)
4. 全量 `flutter test --no-pub`。**跑前建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除**
5. `git diff --check <base>..<head>`
6. 写 `receipt.yaml` 并 commit,tip 打标记,worktree clean

**退出码 0 不算成功**:逐条读 reporter 最后一行原文与 `[E]` 块计数。

**receipt 类型按 Gate 自判规则**:`git diff --name-only base..head` 含 `lib/` 路径 → **代码单**
(`break_red` 必须是 `["remove_implementation","force_degenerate_value"]` 两向数组);
零 `lib/` 路径 → **审计单**(`break_red` 留空 + 恰好一个 `audit_verification` 块)。
**写错形状是 schema FAIL**。若最终只交诊断报告,那就是审计单。

## §8 `[BLOCKED]` 出口

命中 §6 任一条、或存档被破坏无法恢复、或驱动手段拿不到可证伪证据 → 立刻停,写清卡在哪,不硬做。

## §9 我会怎么验收

不采信自报数字。我会独立复跑 targeted + analyze + format + `diff --check`;
**自己再做一次破坏证红**;核 worktree clean、tip 前缀、中文动宾、禁区零 diff;
核 receipt 与实测对撞;核存档 sha256;核诊断报告每条结论的 `file:line` 是否真的支撑该结论。

结论若只是「疑似」「可能」而无实测值支撑,直接打回。
