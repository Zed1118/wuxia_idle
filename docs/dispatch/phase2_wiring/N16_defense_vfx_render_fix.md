# N16 修复防御特效零像素渲染

**基线**:`main` @ `e11059c07a2777778dadaf975ef6ef821a973035`
**分支**:`codex/p2-defense-vfx-fix-20260827`
**来源**:2026-08-27 用户真人试玩实测「护盾和技能没有表现形式,察觉不了,但 CD 有显示」,协调者定位根因后用户拍板「A 直接派给 codex 修」。

## 一、任务

护盾 / 招架 / 闪避的战斗特效**当前一个像素都画不出来**。逻辑层正常(CD、减伤都生效),渲染层被短路。修复它,让这三个防御动作有可见反馈。

## 二、根因已定位,不要重新查

| 环节 | 位置 | 事实 |
|---|---|---|
| 事件产出 | `lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart:315` `:326` | 正常推出 `defenseStarted` / `defenseResolved` 条目 |
| **病根** | 同文件 | 两处**都没设 `vfxTarget`**。全文件只有 `:220 :297 :309 :399` 四处设了 |
| 渲染短路 | `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1610` | `if (source == null \|\| target == null) return const SizedBox.shrink();` |
| 结果 | — | 防御特效恒返回空 widget |

**影响面精确为 2 个 kind**(已实测):走 `_guardianMechanicVfx` 的共 4 个 kind,
`guardIntercepted`(`:291` 设了 vfxTarget)与 `guardianCoop`(`:303` 设了)渲染正常,
`defenseStarted`(`:315`)与 `defenseResolved`(`:326`)未设,**只有这两个坏**。

**根因性质**:`_guardianMechanicVfx`(`battle_screen.dart:1601`)是为「双人协战」写的,
需要 source→target 两点连线;防御是单点事件,套上去必然缺一个端点。**是渲染器套错,不是漏传参数**。

## 三、范围

**只修这一条。** 明确不做:

- ❌ 技能 1-6 的施法特效(`Phase0aVfxKind` 里根本没有技能类特效,`vfx_controller:350` 直接 break)——这是**缺失不是 bug**,属 🔴 待用户定方向,不在本单
- ❌ 破势(posture)的表现层——同上,🔴 待拍板
- ❌ 任何数值、时长、文案的调整

## 四、必须遵守的做法边界

**可以**:复用已有的渲染器与既有 token。现成可选项:
- `_bossMechanicBanner`(`battle_screen.dart:1553` 附近)——屏幕横幅,不需要 source/target,`bossChargeInterrupted` 就用它
- 或为防御写一个**单点**渲染器,锚在 `entry.anchor`(防御事件已带 `anchor: event.toPosition`)

**不可以**:
- ❌ **发明新的视觉语言**(新配色、新形状、新动画曲线、新美术资产)。玩家可见 UI 的视觉方向是 🔴,必须用户拍板。本单只负责**让已有意图能显示出来**
- ❌ 改动 `guardIntercepted` / `guardianCoop` 的现有渲染行为
- ❌ 给防御硬塞一个退化的 `vfxTarget`(比如让它等于自身位置)去骗过 `:1610` 那行判断——那会画出一条零长度连线,是绕过不是修复

**已有意图是现成的,直接用**:label `UiStrings.phase0aDefenseStarted` = 「守势」/ `phase0aDefenseResolved` = 「化解」;accent `WuxiaUi.qingOnDark` / `WuxiaUi.gold`;时长 `defenseFeedbackSeconds = 0.72`。

## 五、测试要求(本单的核心,不达标视为未交付)

**现有测试为什么没拦住**:`test/features/battle/presentation/phase0a/phase0a_defense_presentation_test.dart:34-51`
只断言**控制器产出了条目**和音效映射,**从不渲染任何 widget**。功能 100% 坏了它照样绿。

所以本单必须补一条**渲染层**测试:

1. 真正 pump 出 widget 树(`testWidgets`),不是只调 `Phase0aVfxController().consume()`
2. 断言防御特效**渲染出了非空内容**——不能只断言「有个 widget 存在」,要断言它不是 `SizedBox.shrink()` / 零尺寸
3. `defenseStarted` 与 `defenseResolved` **各测一条**
4. **破坏证红(必须在 commit 之后做)**:改回 `vfxTarget` 缺失的状态(或把渲染改回短路),证明新测试变红,再还原并**重跑绿**。把红/绿两次的输出贴进交付说明。
   - 破坏/还原写进一个带 `trap restore EXIT INT TERM` 的脚本,防止超时把 mutant 留在工作树里

**坑提醒**:`testWidgets` 体内不要 await 真 IO(dart:io / Isar 会挂 10 分钟),初始化收进 `setUp` 或 `tester.runAsync`。

## 六、附带核查(只报告,不擅自修)

`battle_screen.dart:1738` 还有一处同类短路 `if (source == null || target == null || targetId == null)`。
**核一遍**有没有哪个 kind 也恒不满足条件、因而恒不渲染。发现同类问题**写进交付说明**,
**不要在本单里顺手修**——由协调者在 Gate 时决定是否另立单。

## 七、执行端禁区文件(一个字都不许动)

- `data/numbers.yaml`
- `GDD.md`
- `PROGRESS.md`
- `lib/shared/strings.dart`(「守势」「化解」两条文案已存在,直接引用即可,不要改不要加)
- `pubspec.yaml`

## 八、纪律

- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- 只写自己的 worktree
- commit message **中文动宾**(英文 conventional 前缀属违规)
- 写完 dart 必跑 `dart format`(CI 门禁)
- tip commit 消息前缀打 `[READY]`(写完待评)或 `[BLOCKED]`(需用户拍板)

## 九、`[BLOCKED]` 出口条件

出现下列任一情况,**停下打 `[BLOCKED]`,不要硬做**:

- 复用任何一个现成渲染器都无法在不发明新视觉语言的前提下显示出来(即修复必然要求视觉设计决策)
- 修复会改变 `guardIntercepted` / `guardianCoop` 的现有表现
- 破坏证红做不出来(即新测试在功能坏掉时也不红)——**这说明测试没测到真东西,不许交**

## 十、验收方式(协调者会这么查)

1. `gate.sh` 全量:`full_test` / `analyze` 0 issue / `format` 0 changed / `worktree_clean`
2. 逐文件确认「All tests passed」出现次数,不看批跑总数
3. **协调者独立复跑破坏证红**:自己把修复破坏掉,确认新测试变红。你自报的红绿不作数
4. 核对没有新增美术资产、没有改配色常量、没有动 `strings.dart`
5. `git diff --stat` 核对改动范围与本单声明一致
