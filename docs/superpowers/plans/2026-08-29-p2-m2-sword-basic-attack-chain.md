# M2 剑形态完整普攻链计划

## 目标

把方案已冻结的剑形态三段“直刺 → 横扫 → 进步斩”接入真实
`Phase0aPlayerInputAdapter → Phase0aCombatSession → reducer → event → VFX`
生产链，并保证手动、前台 bot 与 headless 复用同一连段运行态。

## 基线与分支

- 基线：`03b2f0e8b14f89f9abaffc475fbfaf6aecfd0295`
- 分支：`codex/p2-m2-sword-chain-20260829`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-m2-sword-chain-20260829`
- 预热：已完成 `libisar.dylib` 复制、`flutter pub get`、`build_runner`

## 授权与实况

- 权威方案 `/Users/a10506/Desktop/二阶段优化方案.md:172`
  冻结剑链顺序为直刺、横扫、进步斩。
- 实况是 `basic_attack_chain.dart` 只有 candidate schema，生产 input
  adapter 每次只发同一个 `moveKind: light`，事件与 VFX 也不知道段身份。
- 用户冻结的 weapon timeline B 属于更广的动作 phase 合同；本单
  不改禁区 `data/numbers.yaml`，不把尚未生产接线的五武器 timeline
  平行硬编码进普攻链。三段继续使用现有生产冷却节奏。

## 依 §11 预授权执行的推荐方案

1. **实现路线 A（§11.2）**：连段游标存在不可变 actor/reducer
   状态，只在普攻通过冷却与合法性闸后推进。理由是所有操作
   路径都汇入同一 reducer，可回放、可测且不会因 adapter 实例生命
   周期漂移。备选 B 是在 input adapter 内保存可变游标，会让冷却
   拒绝、fork 与 headless 重建各自制造段次漂移，不选。
2. **表现方案（§11.1）**：直刺用前向细长墨锋，横扫用宽弧，
   进步斩用前倾双折墨痕；全部复用现有 `WuxiaUi` 与
   `Phase0aPresentationTokens`，不新增文案、数值 token 或美术资产。
3. **力学边界**：本单不改每段伤害、射程、扇区、姿态伤害或
   命中上限，它们继续由既有生产 binding/resolver 单源结算。
   这不是删减“三段链”，而是避免把尚未冻结的目标上限与位移
   距离夹带进 M2 连段身份任务。这些数值的最终手感仍归 G2 真人试玩。

## 验收标准

- 正式 player mapping 显式装配 sword chain；debug visual route 也走
  同一链，禁止另造演示专用假链。
- reducer 对通过冷却闸的普攻严格发射
  `thrust → sweep → advancing_slash → thrust`；冷却拒绝不推进。
- `AttackStarted` 与 `HitLanded` 携带同一 typed segment，VFX 不从
  actor id、文案或序号反猜。
- 真实 `Phase0aBattleScreen` 能遍历观测三种段墨痕，每种都进入
  生产 `CustomPaint` 且画出非透明像素。
- 实现 commit 后完成两向破坏证红：移除 production mapper 装配；
  把 reducer 选段强制退化为首段。随后走完定向、analyze、整仓
  format、持锁全量、receipt、gate、合并、push 与 CI 核验。

## 恢复点

- 当前：实现、双向破坏证红与最终全量已完成，待
  READY/receipt/gate 收口。
- 初始 RED：生产 mapper 与整屏两文件先跑，因缺少
  `swordBasicAttackChain`、adapter 链字段、actor 游标与 event segment
  编译失败，结论为真 RED，不是先写实现后补测。
- 实现：正式 player mapper 和 debug visual fixture 显式装配同一
  `swordBasicAttackChain`；reducer 保存“下一个已接受段”游标；
  `AttackStarted/HitLanded` 透传 segment；VFX 以直刺细长墨锋、
  横扫宽弧、进步斩前倾双折墨痕绘制。
- 定向验证：生产 mapper + 真实 `BattleScreen` 并跑
  `+54: All tests passed!`；仓内现存 4 个相关文件逐文件全绿：
  链定义 `+6`、mapper `+25`、整屏 `+29`、主线生产接线
  `+18`。原记录的其他 4 个测试路径并不存在，已经
  `rg --files test` 复核并修正，不把 `Does not exist` 冒充为测试失败。
  `flutter analyze --no-pub lib test` 为 `No issues found! (ran in 4.4s)`。
- 提交后双向破坏证红（基于实现提交 `a68a8dec`）：
  1. `remove_implementation`：同时移除正式 player mapper 与 debug
     visual fixture 的 `basicAttackChain` 装配，同一两文件组实测
     `+52 -2: Some tests failed.`；生产 mapper 得到 `null`，整屏三段
     观测得到空集。结论 `RED_CONFIRMED`，`failed_count: 2`。
  2. `force_degenerate_value`：把 reducer 选段强制为
     `basicAttackChain?.segmentAt(0)`，同一组实测
     `+51 -3: Some tests failed.`；生产序列退化为四次直刺，整屏只看到
     直刺，并连带原有近/远 VFX 互斥守卫变红。结论
     `RED_CONFIRMED`，`failed_count: 3`。
  3. 两次均以精确反向补丁还原，每次 `git diff --quiet`
     均为 `rc=0`且 `git status --short` 为空；还原后同组重跑
     `+54: All tests passed!`。
- 全量回归：首轮在新增 actor 游标的数字默认值上触发
  `phase0a_source_contract_test.dart`，最终为
  `+5686 -1: Some tests failed.`。不放宽契约，而是把初值
  移为命名常量；源码契约复验 `+20`，最终持锁全量为
  `05:43 +5687: All tests passed!`，`[E]` 为 0。
- 禁区文件：未触碰。
- 数值红线：不修改生产 HP/伤害/CD/范围/目标上限。
- G2 边界：自动验证只证明连段接线与可观测表现，不代替用户
  对手感、可打过性与双视口水墨质量的签字。
