# 派单包 · 二阶段 F1 战斗操作手感批(2026-08-28)

## §0 身份与总纪律

- **唯一基线**:`1ba913a633beb0fd8f9b47764161f47c54260707`(候选链 tip)
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **不得修改 `~/.claude/skills/` 下任何文件**(含 `gate.sh`)。执行端不修改自己的判据。
- commit message **中文动宾**;收工 tip 前缀 `[READY]` 或真实 `[BLOCKED]`,worktree clean。
- 本单**有 `lib/` 改动**,是**代码单**,不是审计单。receipt 形态见 §5,写错即 schema FAIL。

## §1 本单存在的理由(用户 2026-08-28 真人试玩拍板)

用户实际试玩后的原话与拍板结论,**不要重新论证要不要做**:

| 用户反馈(原话) | 拍板 |
|---|---|
| 「j键普攻没什么意义,没有鼠标直接点击普攻顺畅,因为按 j 没有办法选中敌人」 | **A:J 键加自动瞄准(锁最近敌人)** |
| 「我更喜欢空格键闪避」 | **加空格键,保留 Z 不删** |
| 「闪避的 cd 展示不明显,导致我不知道什么时候可以闪避」 | **防御动作 CD 可视化** |
| 「ef 说实话我感觉很鸡肋,现阶段先这样吧」 | **不动 E/F 的机制语义**,只补它们的 CD 展示 |
| 「先把基础攻击和技能做好体验,后续再详细做破势等机制类的」 | **本单不碰姿态/破势/POSTURE** |

## §2 三个可验收结果

1. J 键普攻具备目标指向能力,不再必须靠 WASD 转身才能打中。
2. 空格键可触发闪避,Z 键行为不变。
3. 守势/化解/闪避三个防御动作在 HUD 上能看出「现在能不能用」。

不为消耗额度扩范围;三项之外的任何"顺手优化"一律不做。

## §3 环境预热(新 worktree 必做,不做必挂)

```bash
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/
cd <worktree>
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**不要设置 `DEVELOPER_DIR`**(设了会让 flutter 构建报 xcodebuild 找不到)。需要跑 CocoaPods / `flutter build macos` 时用 `LC_ALL=en_US.UTF-8`,**不要用 `LC_ALL=C`**——本仓路径含中文,`C` 会让 CocoaPods 抛 `Encoding::CompatibilityError`。`.g.dart` 被 gitignore,不预热会一片 `Target of URI hasn't been generated`,那是环境前置未满足,不是代码回归。

## §4 已实测锚点(行号会漂,必须用符号重新定位)

全部在基线 `1ba913a6` 上实测:

- `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`
  - `_heldCommand()` `:304-311` —— 唯一命令构造点。现状:
    `attack: _primaryAttackKeyHeld || _primaryAttackHeld`,`attackAimDirection: _pointerAimDirection`。
  - `_onStagePointerDown` / `_onStagePointerMove` / `_stopPointerAttack` `:178-200` ——
    鼠标路径会设 `_pointerAimDirection = _pointerAim(event.localPosition, stage)`;**J 键路径不设,恒为 null**。这就是两者手感差异的根因。
  - 键位 switch `:635-657`;闪避 `:641` = `LogicalKeyboardKey.keyZ`;
    `keyJ` 在 `:594`(KeyUp)与 `:627`(KeyDown)。
  - 封印区(数字技能栏)渲染 `:735-753` —— 已有「可用 / 冷却 x.x 秒 / 未装备」三态体例,**CD 展示复用此体例**。
- `lib/features/battle/domain/phase0a/phase0a_combat_model.dart:259-263`
  —— `parryTicksRemaining` / `dodgeTicksRemaining` / `parryCounterBudgetRemaining` **数据已存在**。
  CD 展示是 UI 层消费缺口,**不要为此新增 domain 字段或改防御机制语义**。

## §5 三项固定范围

### F1-1 J 键自动瞄准

- 只改输入层:让 J 键路径也能产出 `attackAimDirection`。
- 目标选择语义:**当前存活敌人中距玩家最近的一个**;无存活敌人时回退当前朝向(即维持现状,不得崩)。
- 鼠标路径**行为不变**——鼠标仍是自由瞄准,不得被"最近敌人"覆盖。
- 判据:同一局内不移动、只按 J,能打中侧后方的最近敌人。

### F1-2 空格闪避

- 在 `:641` 的 keyZ 之外**追加** `LogicalKeyboardKey.space`,产出同一个闪避命令。
- **Z 不删**。两键行为完全一致。
- 注意空格在 Flutter 里常被按钮/焦点系统吃掉:必须验证战斗屏聚焦状态下空格进入 `_handleKey` 而不是触发某个控件。做不到就 `[BLOCKED]` 报告,不要硬塞。

### F1-3 防御 CD 可视化

- 消费 `:259-263` 已有字段,让守势/化解/闪避各自显示「可用 / 冷却中」。
- **复用封印区 `:735-753` 的现有文案与视觉体例**,不新增 `strings.dart` 条目。
  确实需要新文案才能表达 → **停下报告**,不要自己往禁区文件里加。
- 不改 E/F/Z 任何一个的机制、数值、时长、生效条件。本单只让玩家看见它们的状态。

## §6 固定收工流程

1. 实现并 commit(中文动宾)。
2. **commit 之后**做双向破坏证红(顺序固定):
   - `remove_implementation`:删掉新增实现的支点,复跑该任务 targeted 测试。
   - `force_degenerate_value`:把关键条件强制成退化值,复跑同一组。
   - 两向都必须变红并记录**实测失败数**;随后**精确反向补丁还原**。
     禁 `git reset --hard` / `git checkout --` / `git revert`;还原后必须 `git diff --quiet` 为 0 且 `git status --short` 为空。
3. targeted 测试(本单直接相关文件)。
4. `flutter analyze --no-pub lib test`。
5. `dart format --output=none --set-exit-if-changed .`(**整仓 `.`**)。
6. 一次全量 `flutter test --no-pub`。**先建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;锁存在就等。**
7. `git diff --check <base>..<head>`。
8. 写 `receipt.yaml` 并 commit,tip 打 `[READY]` / `[BLOCKED]`,worktree clean。

**退出码 0 不算成功**:逐条读 reporter 最后一行原文与 `[E]` 块计数;多路径批跑会静默漏跑文件,逐文件确认「All tests passed」出现次数。

## §7 receipt.yaml —— 本单是**代码单**

Gate 按 `git diff --name-only base..head` 有没有 `lib/` 路径自判单类型。本单必有 `lib/` → **代码单**:

- `break_red` **必须是两向数组** `["remove_implementation", "force_degenerate_value"]`,**不得留空**。
- **不要**写 `audit_verification` 块(那是审计单的形态,写了即 FAIL)。

```yaml
schema_version: 1
base_sha: "1ba913a633beb0fd8f9b47764161f47c54260707"
head_sha: "<收工 tip 全 40 位小写 sha>"
changed_files:
  - "lib/....dart"
  - "test/....dart"
full_test_last_line: "12:32 +5643: All tests passed!"
error_block_count: 0
analyze_last_line: "No issues found! (ran in 18.9s)"
format_last_line: "Formatted 1626 files (0 changed) in 3.13 seconds."
break_red:
  - "remove_implementation"
  - "force_degenerate_value"
```

字段全部 JSON 双引号;`changed_files` 按字节序升序去重;三行 last_line 抄**原文**。

## §8 `[BLOCKED]` 出口条件(命中任一立刻停,不硬做)

- 空格键被 Flutter 焦点/按钮系统吞掉,不改生产控件结构就拿不到。
- CD 展示必须新增 `strings.dart` 文案才能表达。
- 需要新增 domain 字段或改防御机制语义才能做出 CD 展示。
- 自动瞄准做不到"不影响鼠标自由瞄准"。
- 触及数值、schema、存档语义,或任何禁区文件。
- 破坏证红两向中任一向**没变红**(说明新增断言本身是假绿,必须报告不得掩盖)。

## §9 我(Claude)会怎么验收

不采信执行端自报数字。`[READY]` 后我会:

1. 独立复跑 targeted + analyze + format + `git diff --check`,逐条读 reporter 尾行与 `[E]` 块。
2. **自己再做一次破坏证红**,不看你的记录。
3. 核 worktree clean、tip 前缀、commit 中文动宾、禁区零 diff。
4. 核 receipt 与实测对撞(含 patch sha256)。
5. **亲自启动 macOS app 手动验三项手感**:按 J 能否打中侧后方最近敌人、空格能否闪避、三个防御动作 CD 是否看得出来。手感不过一律打回,自报"已实现"不作数。

不合格直接打回,不替你修。

## §10 明确不做

- 不碰姿态 / 破势 / POSTURE 任何机制(用户明确押后)。
- 不碰波次密度与 M2 四模板(另单)。
- 不改 E/F/Z 的机制语义、数值或生效条件。
- 不做战斗退出按钮(E1 已归档 10 条,另单)。
- 不补 HUD 移动键位说明(🔴 待用户拍板文案,不代拍)。
