# 批 1:POSTURE 姿态统一生产接线(2026-08-26)

分支 `codex/p2-posture-wiring-20260826`,基线 `b98b363c`(已预热),worktree
`/Users/a10506/Desktop/Projects/挂机武侠-p2-posture`。

## 用户已拍板的模型(不要再选,也不要"两种都留")

**统一累计模型**。协调者已把冻结值写进 `data/numbers.yaml` `combat.posture`(基线里已有,
**你只读不改**)。这是《二阶段优化方案》§5.3「姿态统一」的落地,原文要求逐条照做:

- 把旧硬直、踉跄、破招、打断施法、霸体等零散概念**统一为姿态体系**;
- 领域值统一为「已累计姿态伤害」从 0 向破势阈值增加;UI 可反向显示「剩余架势」,
  但**不得维护第二份数值**;
- `postureDamageAccumulated >= postureCapacity` 时进入短暂破绽,按配置在破绽结束后重置/恢复;
- 霸体表示某阶段不被轻击打断,但**仍可累计姿态伤害**;
- Boss 所有强控制效果转为姿态伤害或阶段性交互,不允许永久免疫;
- **破招技能对蓄力窗口有额外姿态/打断效力**——破招不消失,它变成对蓄力目标的额外姿态伤害。

§5.4 补充:`postureReaction`(踉跄、破势、倒地)由姿态累计触发;旧「刚猛震慑」不做独立眩晕,
改为姿态伤害。

**因此现有 `_maybeApplyChargeBreak` 的「命中蓄力目标 → 立刻清蓄力 + 上 CD + 进踉跄」
必须改成走姿态槽**,而不是与新姿态窗并存。并存 = 第二份数值 = 违反方案,直接打回。

## 接线最小定义(照 `docs/spec/phase2_parked_contract_wiring_delta_20260826.md` §POSTURE.3)

`lib/data/numbers_config.dart`(严格解析 posture,禁默认值兜混过去)→
`lib/features/battle/domain/phase0a/phase0a_combat_model.dart`(姿态运行态纳入不可变 actor)→
`lib/features/battle/domain/phase0a/phase0a_combat_intent.dart`(每次命中显式携带 posture damage / hit kind)→
`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`(初始化 `PostureState` 并注入配置)→
`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart`(每拍 `advance(1)`,命中 `apply`,开/关窗并入现有 charge/stagger 状态机)→
`lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart`(读统一窗口事实)→
`phase0a_combat_events.dart` / `phase0a_vfx_controller.dart` / `phase0a_battle_screen.dart`
(投影姿态变化,**复用现有文字标签**,不新增被否过的预兆图标/百科入口)。

复用 `lib/features/battle/domain/phase0a/posture.dart` 已有合同,不要另写一套。

## 姿态伤害的来源必须在 RED 里先钉死

候选模拟用的口径是:普攻 = 1、技能 = `powerMultiplier / basicPower`、破招再加转换值
(`test/tuning/phase2_combat_core_tuning_candidates_test.dart:451-475`,现查行号)。
冻结登记只冻了那五个参数,**没冻姿态伤害的权威来源**。

要求:每一项姿态伤害都必须能指回一个**已有的生产数据字段**(`skills.yaml` 的
`powerMultiplier` / `phase0aBehavior` 的 `break.points` 之类),并在 RED 里断言这个映射。
**凡是需要你发明一个新数字才能成立的,立刻 `[BLOCKED]`,不要自己拍。**

适用范围按 §5.3 的「统一」= 全体敌人都有姿态槽,`boss_conversion_factor: 3` 只作用于
Boss 的强控制/破招折算。若你发现全体适用会打爆某条既有断言,`[BLOCKED]` 报上来,别偷偷缩范围。

## 必须跑的三项验证

1. **独立 RED**:先写会红的测试再写实现;实现完成后**逐条自检**「把这行生产代码破坏掉,
   这条断言必然红吗」。不必然红的断言等于没写。
2. **模拟回归**:`flutter test --no-pub test/tuning/phase2_combat_core_tuning_candidates_test.dart`
   与 Ch1 全内容平衡诊断 `test/tools/phase0a_full_content_balance_diagnostic_test.dart` 必须仍绿;
   后者硬断言伤害不进百万(§5.4 红线),姿态窗会改变有效伤害,**这是必查项**。
3. **可构建**:`flutter build macos` 通过(**禁止设置 `DEVELOPER_DIR`**,设了会报 xcodebuild 找不到)。
   真机手感验证由协调者另行安排,你不做。

另跑:`flutter analyze lib test` 0 issue、`dart format` 无改动、
POSTURE 域 39 个耦合测试文件(正则见 spec §POSTURE.6)全绿。**逐文件确认「All tests passed」
出现次数**,`flutter test` 传多路径会静默漏跑。

## 硬约束

- **禁区文件,一个字都不许动**:`data/numbers.yaml`(posture 块已由协调者写好,只读)、
  `GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。
- **不要碰 `defenseBreakPct` / `defense_break` 任何东西**——另有一个诊断单在跑,撞车即打回。
- **禁 push、禁 merge、禁碰 main、禁 revert**。
- commit message 中文动宾;tip 前缀 `[READY]` 或 `[BLOCKED]`;工作区干净。
- Dart 里不写数值常量、不写中文文案(§5.6);行号一律现 grep;数字一律实测不估算。

## [BLOCKED] 出口条件

- 姿态伤害来源必须发明新数字才能成立;
- 统一模型会改变某条既有玩家可见规则,而该规则不在上面 §5.3/§5.4 的授权范围内;
- Ch1 平衡诊断因姿态窗而红,且修复方式需要动数值。

## 我会怎么验收

逐条打开你给的 `file:line`,对不上即打回。通过数我自己复跑,**不采信自报**。
`git diff --name-only main..<branch>` 出现禁区文件或 `defenseBreak` 相关改动 = 直接打回。
「破招与姿态窗并存」= 违反 §5.3 不得维护第二份数值 = 直接打回。
