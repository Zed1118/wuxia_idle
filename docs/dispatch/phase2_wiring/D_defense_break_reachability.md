# D 单:破防技进 Phase 0A 数字技槽的可达性诊断(2026-08-26)

基线 `e4f0f171`。分支 `codex/p2-defense-break-reachability-20260826`,worktree
`/Users/a10506/Desktop/Projects/挂机武侠-p2-dbrk-diag`(已预热)。

## 待证伪的假设(不是结论)

协调者 grep 出一条**看起来能崩**的链,但**没有复现过**。你的任务是把它证实或证伪,不是修它。

1. `data/skills.yaml` 有三招 `type: powerSkill` 带 `defenseBreakPct: 0.30`
   (`skill_gangmeng_changlian_power` 一类,行 257/307/357 附近,现查行号别抄)。
2. `lib/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart:37-41`
   在 `skill.defenseBreakPct != 0` 时 **`throw StateError`**(「尚无 reducer 状态消费方」)。
3. `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:1060-1080`
   把 `CombatantSkillLoadout.numericSlots` 的技能逐个塞进 `Phase0aNumericSkillBinding`。
4. `lib/features/cultivation/domain/skill_loadout.dart:104-115` 在
   `lineageRole == LineageRole.senior && !isFounder` 时**主动**把一个
   `defenseBreakPct > 0` 的技能填进主修槽。

若 4 填入的槽 ∈ 3 读取的 `numericSlots`,则大弟子入 Phase 0A 战斗 = `StateError` 崩溃。
现有 5,611 条全绿没抓到,一个可能原因是战斗测试画像基本都是祖师(founder),
而 4 的偏好恰好被 `!isFounder` 门到只有大弟子才触发。

## 你要交付什么

1. **一条决定性的测试**,放 `test/features/battle/application/phase0a/`。
   - 若可达:测试必须**真的复现** `StateError`,并保持在**能复现的状态**(不要修生产代码让它变绿)。
     用 `expect(() => ..., throwsStateError)` 之类如实钉住当前行为,注释写明这是**已知缺陷**、
     等用户拍板处置方式后再改。
   - 若不可达:测试必须证明**为什么**不可达(哪一步把 `defenseBreakPct > 0` 挡在
     `numericSlots` 之外),并断言那道闸门本身,而不是断言「没崩」。
   - 自检:**破坏那道闸门那一行,这条断言必然红吗**?不必然红 = 没交付。
2. **`docs/audit/phase2_defense_break_reachability_20260826.md`,≤50 行**,写清:
   可达/不可达的结论、决定性的那一步在哪个 `file:line`、你实际跑的命令与通过数、
   以及若可达时的三条候选处置(实装破防开窗 / 砍掉 `defenseBreakPct` 字段 /
   在 autoFill 或 binding 层过滤),**只列不选**。

## 硬约束

- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、
  `lib/shared/strings.dart`、`pubspec.yaml`。
- **本单是诊断单,禁改任何 `lib/` 生产代码**。你只写 test 和那份 audit。
- **禁 push、禁 merge、禁碰 main、禁 revert**。只在自己的 worktree 提交。
- commit message 走中文动宾;分支 tip commit 消息前缀打 `[READY]`(写完待评)
  或 `[BLOCKED]`(需用户拍板)。工作区必须干净。
- 所有行号**现 grep**,不抄本文档里的数字——本文档的行号可能已经漂了。
- 数字(通过数、文件数、命中数)一律实测,不估算。

## [BLOCKED] 出口条件

- 证实可达,但你认为不改生产代码就写不出复现测试 → `[BLOCKED]`,写清卡在哪。
- 发现这条链牵出的处置方式必然改变玩家可见战斗规则 → `[BLOCKED]`,不要自己选。

## 我会怎么验收

我会逐条打开你给的 `file:line`,对不上即打回。你说的通过数我自己复跑,**不采信自报**。
`git diff --name-only main..<branch>` 里出现任何 `lib/` 文件 = 直接打回。
「测试没崩所以不可达」而没有指出那道闸门 = 视为未交付。
