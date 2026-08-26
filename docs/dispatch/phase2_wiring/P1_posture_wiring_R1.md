# 批 1-R1:POSTURE 姿态统一接线**返修**(2026-08-26)

分支 `codex/p2-posture-wiring-20260826` @ `2c8015d9`——**在原分支上续做,不要新开分支、不要 rebase、不要 revert 已有 commit**。
worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-posture`(已预热,`git status` 干净)。
原始单见同目录 `P1_posture_wiring.md`,其【硬约束】【禁区】【[BLOCKED] 出口条件】**全部继续生效**,本单只增不减。

## 一、你上一轮做对了什么(先说清楚,免得你返工过头)

协调者本会话实测,**语义层已过**,不要重做:

- 禁区文件 0 命中:`git diff --name-only b98b363c..2c8015d9` 无 `numbers.yaml`/`GDD.md`/`PROGRESS.md`/`strings.dart`/`pubspec.yaml`
- `defenseBreak` 相关改动 0 行(与并行诊断单无撞车)
- `flutter analyze --no-pub lib test` **0 issue**
- `dart format` 1523 文件 **0 changed**

**唯一不过的是全量回归**:`flutter test --no-pub` 实测 **`5612 +/ 4 -`,耗时 5m41s,退出码 0**。

> 退出码 0 是骗人的。你上一轮自报「独立 RED 5/5 + 逐文件 39/39 全绿」协调者复核**句句为真**——
> 但**逐文件绿 ≠ 全量绿**:下面 4 条里,1 条是扫全目录的源码契约测,3 条是跨 fixture 的 UI 去噪测,
> 只有在全量批跑里才被触发。所以本轮**验收只认全量**,逐文件绿不算数。

## 二、必须修的 4 条(根因协调者已定位到 file:line,行号本会话现 grep,**不需要你重新诊断**)

### R1-A · 源码契约违规(1 条,独立根因)

**红测**:`test/features/battle/domain/phase0a/phase0a_source_contract_test.dart:80` 「不得出现数值参数默认值」
(正则见 `:84-86`,reason 原文「数值必须由调用方显式传入」)

**违规点**:`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:325`

```dart
    int breakPower = 0,          // ← settleInbound 的可选参数,带数值字面量默认值
```

它属于 `settleInbound({...})`(定义在 `:315`)。main 版本的该文件 `= 0,` 命中数为 **0**,是本分支新引入的。

**指定修法**:改成 `required int breakPower,`,并在 4 个调用点显式传值——
`phase0a_combat_reducer.dart` 的 `:625` / `:721` / `:846` / `:1398`(四处均为 `settleInbound(` 起始行)。
调用点若语义上确实无破招效力,**允许**在该文件顶部按既有惯例声明 `const _noBreakPower = 0;` 再显式传入——
这个惯例在 main 上已存在(`lib/features/battle/domain/phase0a/phase0a_combat_intent.dart:9`,
被 `:165`/`:200` 使用),**不是你发明的新数字**,契约测也接受。

**禁止**:直接把 `= 0` 换成 `= _noBreakPower` 保持可选参数形态。那只是躲开正则,契约语义
(「由调用方显式传入」)没被满足,视同没修。

### R1-B · 首屏威胁去噪回归(3 条,**同一个根因**)

**红测**:`test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart`
- `:161` group「首屏威胁去噪 HUD(双视口)」→ 1280×720 与 1440×900 **两个视口都红**(= 2 条)
  失败断言:`:172` 普通满血敌人姓名 `findsNothing`(实测「山贼刀客」被渲染)、`:177` `hpKey(enemy.id)` `findsNothing`
- 同文件「键盘 J 普攻…目标血条强调保持后自动消退」→ 血条 key `phase0a_hp_wave1_archer` 未消退(= 1 条)

**违规点**:`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:941`

```dart
    final showThreatLabel =                     // :934
        enemy &&
        (visual.isElite ||
            isHealthEmphasized ||
            actor.vulnerabilityMult != null ||
            actor.chargingCast != null ||
            actor.staggerTicksRemaining > 0 ||
            actor.posture != null ||            // :941 ← 你本轮新增的这行
            guardianWardActive ||
            guardianLabelOffsetX != 0);
```

`showThreatLabel` 唯一消费点是 `:1041`,它包裹的正是**敌人姓名 `Text` + `HpBar`**(`:1066` / `:1084`)。
按 §5.3「统一」全体敌人都有姿态槽 ⇒ `actor.posture != null` 对普通敌人恒真 ⇒
姓名与血条对全体敌人**常驻**,同时压过 `isHealthEmphasized` 的消退逻辑。三条失败由此一次性解释完。

**指定修法**:**删掉 `:941` 这一行**,`showThreatLabel` 回到 main 口径。

**同时明确不许动**:`:1097` 的 `if (enemy && actor.posture != null)`(姿态标签 `_BossStatusTag` 的渲染门)
**保持现状,一个字都别改**。它是独立 child,不受 `showThreatLabel` 影响,删 `:941` 不会让姿态标签消失。
姿态标签该给全体敌人还是只给 Boss/精英,是**观感判断,已挂到用户待拍板队列**,本轮冻结现状,你不要代拍。

## 三、本轮的硬性范围围栏

- **`test/` 目录改动必须为 0**。4 条红测全部是既有测试,它们**就是本轮的 RED**,不需要你新写,更不许你改断言让它变绿。
  协调者验收会跑 `git diff --name-only 2c8015d9..<你的新 commit> -- test/`,**有输出即直接打回**。
  若你判定「不改测试就修不了」,立刻 `[BLOCKED]` 报上来,**不要自己改**。
- 生产代码改动预期只落在上面点名的 **2 个文件**。多出来的文件都要在收工报告里逐个说明理由。
- 原单禁区、禁 push / 禁 merge / 禁碰 main / 禁 revert、commit message 中文动宾、tip 前缀 `[READY]`/`[BLOCKED]`——全部沿用。

## 四、必须跑的验证(缺一项即打回)

1. **破坏证红逐条自检**:对 R1-A 与 R1-B 各问一次「把我这行改动**再改回去**,对应那条断言必然红吗」。
   不必然红 = 你没修到根因。
2. **全量**:`flutter test --no-pub 2>&1 | tee /tmp/p1_r1_full.log`
   - 报告里贴 **reporter 末行原文**(形如 `NNNN +/ M -` 或 `All tests passed!`)
   - **退出码 0 不作数**;必须 `grep -c '^\[E\]' /tmp/p1_r1_full.log` 并贴出计数(期望 **0**)
   - 若仍有 `[E]`,把每个 `[E]` 块原文贴上来,**不要 `| tail`**(会毁掉失败详情)
3. `flutter analyze --no-pub lib test` → 0 issue,贴原文末行
4. `dart format .` → 0 changed,贴原文末行
5. 数字一律实测,禁估算;引用代码一律现 grep 带 `file:line`。

`flutter build macos` 本轮**不用重跑**(上一轮已过,本轮无新增依赖/入口)。**禁止设置 `DEVELOPER_DIR`**。

## 五、[BLOCKED] 出口条件(本轮新增,原单的继续有效)

- 删掉 `:941` 后出现**新的**红测(即 4 条之外的);
- 修 R1-A 时发现某个调用点的 `breakPower` 真值需要你发明新数字;
- 你判定必须修改 `test/` 才能变绿。

## 六、协调者怎么验收

逐条打开你给的 `file:line` 对不上即打回;通过数我自己复跑**全量**,**不采信自报**。
`git diff --name-only 2c8015d9..<新 commit>` 出现 `test/` 或禁区文件 = 直接打回。
`:1097` 被改 = 直接打回(越过了用户的拍板点)。
