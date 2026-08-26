# 批 1-R2:POSTURE 姿态标签可见范围收窄(2026-08-26)

分支 `codex/p2-posture-wiring-20260826`,**基线 = R1 返修通过后的那个 commit**(协调者派单时会当面告诉你 sha;
`git log --oneline -1` 自己再核一遍)。worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-posture`。
原始单 `P1_posture_wiring.md` 与返修单 `P1_posture_wiring_R1.md` 的硬约束**全部继续生效**,本单只增不减。

**前置**:本单必须在 R1 全量绿之后才开工。若你拿到本单时 `flutter test` 仍有 `[E]`,立刻 `[BLOCKED]`。

## 一、这是用户拍板,不是你的设计空间

R1 单里冻结的那个观感问题,用户已拍 **A 案**:

> 姿态标签只在「已受姿态伤害或已破防」时出现,**普通满姿态敌人不挂标签**。

理由是首屏去噪:全体敌人有姿态槽(§5.3 统一)不等于全体敌人头上常驻一个数字。
**不要重新讨论 A/B/C,不要"两种都留",不要加开关。**

## 二、边界已经由协调者算过,照抄别自己推

**关键约束:Boss/精英的「严防」标签必须原样保留。**

`test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart:161-163`
在 **首帧、`accumulated == 0`** 时就断言 `phase0a_vulnerability_guarded_wave2_elite` `findsOneWidget`
(同文件 `:186`、`:202` 另有两处同 key 断言)。

所以 A 案**不能**写成 `accumulated > 0 || isVulnerable`——那会把这 3 条打红。
**只收窄第三分支(普通敌人的 `phase0a_posture_remaining_*`)**,前两个分支的可见性一个字不动。

## 三、指定修法

**文件**:`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`

**锚点按内容找,不要信行号**——R1 删过一行,行号已漂移。现 grep `if (enemy && actor.posture != null)`
(R1 前位于 `:1097`,是 `_BossStatusTag` 那个 `Positioned` 的渲染门)。

改成:

```dart
        if (enemy &&
            actor.posture != null &&
            (actor.vulnerabilityMult != null ||
                actor.posture!.isVulnerable ||
                actor.posture!.accumulated > 0))
```

`PostureState.accumulated`(`lib/features/battle/domain/phase0a/posture.dart:139`)与
`isVulnerable`(同文件 `:142`,`=> vulnerabilityTicksRemaining > 0`)均为现成公开面,**不要新增字段、不要改 posture.dart**。

标签体内部的三分支 label / key / accent 逻辑**完全不动**。本单只动这一个可见性条件。

## 四、RED 必须证明两个方向(只证一半 = 假绿)

写在 `test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart`,
挂进既有 group「首屏威胁去噪 HUD(双视口)」(现 grep 定位,R1 前在 `:161`),复用该 group 已有的
`pumpScreen` / `fixture` / `controller` 装置,**不要另起一套 fixture**。

1. **隐藏方向**:首帧,对每个普通(非精英)满姿态敌人断言
   `find.byKey(ValueKey('phase0a_posture_remaining_${enemy.id}'))` `findsNothing`。
2. **出现方向**:让同一个敌人**真的吃到姿态伤害**(走生产路径 —— 用该文件既有的
   `stepAndPump` + `attackTowardNearest` 推进,**禁止手工构造 `PostureState` 或直接改 controller 内部状态**),
   断言 `accumulated > 0` 之后该 key `findsOneWidget`。

> 只写第 1 条的话,把渲染门写成恒 `false` 也能绿——那是假绿的标准入口。
> 自检句:「把我加的这个条件删掉,第 1 条必然红吗?把条件写死成 false,第 2 条必然红吗?」两问都必须是「是」。

**Boss 侧不需要你新写测试**,`phase0a_mechanics_presentation_test.dart` 那 3 条既有断言就是 Boss 分支的回归网,
它们必须继续绿。

## 五、范围围栏

- 生产代码改动预期只落 **1 个文件、1 个条件**。多出来的逐个说明理由。
- `test/` 只允许**新增**上述断言;**禁止修改或删除任何既有断言**。
  验收跑 `git diff -- test/`,出现 `-` 号开头的既有断言行(纯格式/位移除外)即打回。
- 禁区、禁 push / 禁 merge / 禁碰 main / 禁 revert、commit message 中文动宾、tip 前缀——沿用。

## 六、必须跑的验证

1. 上面【四】的两句破坏证红自检,逐句写结论。
2. **全量**:`flutter test --no-pub 2>&1 | tee /tmp/p1_r2_full.log`,贴 reporter 末行原文 +
   `grep -c '^\[E\]' /tmp/p1_r2_full.log` 计数(期望 0)。**退出码 0 不作数**,有 `[E]` 就贴块原文,不要 `| tail`。
3. `flutter analyze --no-pub lib test` → 0 issue;`dart format .` → 0 changed。均贴原文末行。
4. 数字实测禁估算;引用代码现 grep 带 `file:line`。

`flutter build macos` 不用跑(纯 UI 条件改动,无新增依赖/入口)。**禁止设置 `DEVELOPER_DIR`**。

## 七、[BLOCKED] 出口条件

- 收窄后 `phase0a_mechanics_presentation_test.dart` 的 Boss guarded 3 条中任意一条红;
- 「出现方向」的测试无法在不手工构造 `PostureState` 的前提下写出来(说明生产路径打不通,这是真问题,报上来);
- 出现 4 条之外的新红测。

## 八、协调者怎么验收

逐条打开 `file:line` 对不上即打回。通过数我自己复跑**全量**,不采信自报。
既有断言被改 / 被删 = 直接打回。标签的 label / key / accent 三分支被改 = 直接打回(越权,本单只授权可见性条件)。
