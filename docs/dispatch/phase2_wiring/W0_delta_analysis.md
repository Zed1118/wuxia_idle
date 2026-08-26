# W0 派单包:三条 PARKED 战斗合同的生产接线差异分析(只读)

## 你是谁 / 这单要什么

你是执行端。这是一张**纯只读分析单**,产出一份差异规格文档,**不改任何生产代码、不改任何 yaml、不接线**。
派单方(协调者)会用你的产出来决定三条接线的批次顺序与每批的 RED 断言,所以事实必须可核、行号必须现查。

## 背景(已成事实,不要重新论证)

用户已于 2026-08-26 冻结四条战斗核心调优决策:

| 决策 | 选择 | 冻结值 |
|---|---|---|
| TUNE-POSTURE-01 | B | capacity 14 / vulnerabilityTicks 4 / recoveryPolicy recover / postVulnerabilityAccumulated 4 / Boss conversionFactor 3 |
| TUNE-WEAPON-TIMELINE-01 | B | sword `1/2/3/1/1/4/3/2/4`、heavy `2/3/3/2/2/5/4/3/5`、flexible `1/4/2/1/1/4/3/2/4`、dual `0/4/2/0/0/4/2/1/3`、hidden `0/2/3/0/0/3/2/1/3`(顺序=windup/active/recovery/firstEffect/cancelStart/cancelEnd/interruptedCd/cancelledCd/failedCd) |
| TUNE-ATTACK-TOKEN-01 | B | **已接线完毕,本单不涉及** |
| TUNE-WEAPON-QI-01 | C | recoveryPolicy `basicAndCappedKill`、killGain 5、killWindowCap 15;五武器 capacity/opening/basicGain/powerCost/ultimateCost 见候选 spec |

候选证据:`docs/spec/phase2_combat_core_tuning_candidates_20260826.md`
决议登记:`docs/dispatch/phase0a_overhaul/decision_registry.yaml`(四条均 `status: frozen`,`batch_action: awaiting_production_wiring`)

协调者已实测的前提(你要复核,不要盲信):
- `PostureConfig` / `ActionTimelineConfig` / `QiResourceLedger` 在 `lib/` 内**除自身定义文件外零消费者**。
- 生产 Phase 0A reducer 有自己的平行实现:破招踉跄走 `staggerTicksRemaining` / `defenderStaggered`,脆弱窗口走 `DefaultGroundStrategy.vulnerabilityMultOf`,真气走 `Phase0aSkillAvailability.qi` + combat model 的耗气快照。
- 因此「接线」不是把数值写进 yaml,而是**用 parked 合同替换/合并生产已有的战斗子系统**。

## 你要产出什么

一份文档:`docs/spec/phase2_parked_contract_wiring_delta_20260826.md`,**≤150 行**。

对 POSTURE / TIMELINE / QI **三块各写一节**,每节必须包含:

1. **生产现状**:这块机制今天在生产里由哪些符号实现,逐个给 `file:line`。说清状态存在哪(model 字段名)、谁写它、谁读它、玩家能感知到什么。
2. **合同语义**:parked 合同提供什么(类/枚举/方法),与生产现状**语义上哪些重合、哪些是生产没有的新行为、哪些是生产有而合同没有的**。三类分开列。
3. **接线的最小定义**:要让冻结值真正影响玩家,**最少**要改哪些文件、加哪些消费点。列出文件清单与每个文件要做什么(一句话)。
4. **配置落点**:冻结值该放哪个 yaml、用什么 key 结构。注意 §5.6 不硬编码数值,值必须走 yaml。**只提方案,不要动 yaml**。
5. **行为变化面**:这块改了会影响哪些玩家可见内容(主线/塔/轻功/守城/断魂庄/远征/扫荡/离线),逐项说会怎么变。
6. **现有测试的冲击面**:哪些测试会因这块改动而红,给文件路径与大致条数(实跑 grep 计数,不要估)。
7. **风险与不确定点**:你拿不准的、需要用户拍板的,单列。

最后加一节 **「批次顺序建议」**:三块的推荐先后 + 每条一句话理由,理由必须引用你上面量到的事实(不是"感觉简单")。

## 硬约束

- **禁改任何文件,除了你新建的那份 spec**。不改 `lib/`、不改 `data/`、不改 `test/`。
- 执行端禁区(即使本单本来就不该碰):`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`。
- **禁 push、禁 merge、禁碰 main、禁 revert**。
- commit message 用**中文动宾**结构。
- 分支 tip commit 消息前缀打 `[READY]`(写完待评)或 `[BLOCKED]`(需用户拍板)。工作区必须干净。
- 所有行号**现查**,禁凭记忆或从旧文档转抄。`grep` 搜不到不等于不存在——同一概念可能有多种写法(实录:`tokenBudgets` vs `attackTokenBudgets` 属性名不同,单一 grep 会漏),每个结论至少用两种命名口径交叉验。
- 数字(测试条数、文件数、行数)必须实跑得到,禁估算。

## [BLOCKED] 出口条件

出现下列任一情况,**停下来打 `[BLOCKED]` 并写清原因**,不要硬做:
- 你发现某块合同与生产现状语义冲突到无法在不改玩法规则的前提下接线;
- 你发现接线必然要改 `data/numbers.yaml` 之外无处安放的数值,且结构需要用户拍板;
- 你发现某块会触及 §5.4 数值红线、§5.3 三系锁死、§5.5 在线=离线中的任一条。

## 派单方会怎么验收

- 逐条打开你给的 `file:line`,对不上即打回。
- 你说的「零消费者 / N 个文件 / M 条测试」我会自己重跑 grep 与 test 复核,**不采信自报**。
- 我会检查你有没有偷偷改文件:`git diff --name-only main..<branch>` 必须只有那一份 spec。
- 我会检查三块的「新行为 / 重合 / 缺失」三类是否真的分开列了,混在一起写视为未交付。
