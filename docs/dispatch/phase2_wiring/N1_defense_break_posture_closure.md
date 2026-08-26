# 批 N1:破防技并入统一姿态事实源(M1-B 闭环)(2026-08-26)

分支 `codex/p2-defense-break-posture-20260826`,**基线 `1db64d0d`**(姿态接线分支 tip,已过协调者独立 Gate:
全量 `05:52 +5617: All tests passed!`、`[E]`=0、analyze 0、format 0 changed)。
worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-dbrk-fix`(已预热)。

> **注意基线不是 main。** 统一姿态事实源只存在于这条分支上,本单必须叠在它上面做。
> **不要 rebase、不要 merge main、不要碰 `1db64d0d` 及其之前的任何 commit。**

## 用户已拍板(不要再选,也不要"两种都留")

破防处置拍 **A**:**纳入 M1-B 姿态/破招统一生产闭环**。
- 允许独立 commit,但**最终只能进入统一姿态事实源**;
- **不得恢复第二套破绽窗口**(方案 §5.3「不得维护第二份数值」);
- 候选处置里的「砍掉 `defenseBreakPct` 字段」**已由用户撤销**,不在选项内;
- **若映射需要你发明新的换算数字,立即 `[BLOCKED]`,不得代拍。**

## 问题已被前一张诊断单钉死,不要重新诊断

诊断全文见 `docs/audit/phase2_defense_break_reachability_20260826.md`(在分支
`codex/p2-defense-break-reachability-20260826` @ `39ae8f83` 上,用 `git show <sha>:<path>` 读)。结论摘要:

- `data/skills.yaml:243-257` 的 `skill_gangmeng_changlian_skill` 是 `powerSkill` 且 `defenseBreakPct: 0.30`;同值命中共 3 处(`:257,307,357`)。
- 可达链:`lib/shared/battle_shared/combatant_skill_loadout.dart:37-44` 把 `main1/main2` 列入 `numericSlots`
  → `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:1065-1080` 构造 `Phase0aNumericSkillBinding`
  → `lib/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart:37-41` **因 `defenseBreakPct != 0` 抛 `StateError`**。
- 复现测已存在:`test/features/battle/application/phase0a/phase0a_defense_break_reachability_test.dart:41-122`
  (真 Isar 大弟子 + 真 YAML + 生产 snapshot assembler + 真 mapper),协调者复跑 `1/1` 通过。

**行号一律现 grep 复核**——上述来自 `39ae8f83` 基线,你的基线是 `1db64d0d`,姿态批动过 binding 附近的文件。

## 要做的事

把 `defenseBreakPct` 从「抛异常的未支持字段」变成「**统一姿态事实源里的额外姿态伤害/打断效力**」。

**首选映射(不引入新常量)**:`defenseBreakPct` 是一个比例,把它作用在**该技能自己已有的姿态伤害**上,
得到额外姿态伤害。姿态伤害的权威来源在 P1 单里已定:普攻=1、技能=`powerMultiplier / basicPower`
(现 grep `test/tuning/phase2_combat_core_tuning_candidates_test.dart` 核实口径)。
这样只用到既有数据字段与既有姿态伤害,**不发明新数字**。

已有的可复用件(现 grep 确认仍在):
- `lib/features/battle/domain/phase0a/posture.dart` 的 `PostureState` / `PostureConfig`
  (含 `bossControlConversionFactor`,P1 单已定它**只作用于 Boss 的强控制/破招折算**);
- `lib/features/battle/application/phase0a/phase0a_tactical_skill_binding.dart:66-67` 的
  `breakPower` ← `Phase0aSkillEffectType.breakPower`.points;
- `settleInbound` 的 `breakPower` 形参(R1 已改为 `required`)。

**如果你发现首选映射在生产数据上不成立**(例如某技能有 `defenseBreakPct` 却没有可推导的姿态伤害),
**`[BLOCKED]` 报上来**,写清是哪个 `skillId` / 哪一行,**不要自己补一个默认值**。

## 范围围栏(机器可判)

- 生产改动**只允许**落在 `lib/features/battle/**`。出现 `lib/shared/**`、`data/**` 改动 → 打回。
- **禁止**新增任何「破绽窗口」状态字段/枚举/计时器。判据:`git diff` 里出现 `vulnerabilit`/`breakWindow`
  的**新增状态字段**即打回(读取既有字段不算)。
- **禁止**删除或修改 `data/skills.yaml` 里的 `defenseBreakPct`(那是被撤销的选项 2)。
- `test/` 只允许**新增**;禁止修改/删除既有断言。验收跑 `git diff 1db64d0d..HEAD -- test/`,出现 `^-[^-]` 即打回。

## 禁区(一个字都不许动)

`data/numbers.yaml` / `data/skills.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`。
禁 push / 禁 merge / 禁碰 main / 禁 revert。commit message 中文动宾,tip `[READY]`/`[BLOCKED]`,工作区干净。

## 必须跑的验证

1. **RED 先行**:那条复现测目前是「断言会抛 StateError」还是「断言不抛」?现读它再动
   ——若它锁的是旧行为,**新增**一条锁新行为的测试,**不要改它**;两条并存时在报告里说明为什么不冲突。
2. **破坏证红双向**(缺一不可):① 把你的映射代码删掉 → 新测必红;
   ② 把映射写死成退化值(如额外姿态伤害恒 0)→ **另一条**断言必红。两向都跑,贴输出。
3. **全量**:`flutter test --no-pub 2>&1 | tee /tmp/n1_full.log`,贴 reporter 末行原文 +
   `grep -c '^\[E\]' /tmp/n1_full.log`(期望 0)。**基线是 5617**,你的数应 ≥5617。退出码 0 不作数。
4. `flutter analyze --no-pub lib test` → 0 issue。**必须带 `lib test` 参数**——裸 `flutter analyze`
   会误扫独立子工程 `tools/phase0minus_probe`,实测 1943 个既存 issue,那不是你的问题。
5. `dart format .` → 0 changed(基线已清干净,再报 changed 就是你引入的)。

## [BLOCKED] 出口条件

- 映射需要发明新换算数字;
- 生产数据里存在有 `defenseBreakPct` 但无法推导姿态伤害的技能;
- 不新增破绽窗口就无法表达「对蓄力窗口的额外打断效力」;
- 出现无法归因到本单改动的新红测。

## 协调者怎么验收

逐条打开 `file:line` 对不上即打回。通过数我自己复跑全量,不采信自报。
出现新增破绽窗口状态 / `data/**` 改动 / `test/` 删既有断言 / 禁区文件 = 直接打回。
「破招与姿态窗并存」= 违反方案 §5.3 = 直接打回。
