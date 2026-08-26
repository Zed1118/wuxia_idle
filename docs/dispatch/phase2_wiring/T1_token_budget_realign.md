# 批 T1:攻击令牌口径纠偏(2026-08-26)

分支 `codex/p2-token-budget-realign-20260826`,基线 `03275d2c`(= main),worktree
`/Users/a10506/Desktop/Projects/挂机武侠-p2-token-fix`(已预热:libisar.dylib / pub get / build_runner)。

## 背景:这是纠正一次已进 main 的口径偏差,不是调数值

二阶段方案 `/Users/a10506/Desktop/二阶段优化方案.md:1025` 原文:

> `stage_01_03` 黑风岭单关 35–45 总敌量、8–16 活跃、**攻击令牌 2–4**

而生产配置 `data/combat/encounters/black_wind_ridge.yaml:13-17` 现为
`melee 2 / ranged 2 / charge 1 / support 1` = **总和 6**,越界。

用户 2026-08-26 拍板:**恢复候选 A**。候选 A 的原值见
`docs/spec/phase2_combat_core_tuning_candidates_20260826.md:64-68`,为
**`melee 1 / ranged 1 / charge 1 / support 1`,总和 4**;该文档同时写明「**A 锚定当前生产 `EC`**」,
即这是改动前的生产值。**照抄这四个数,不要自己发明另一组 ≤4 的组合。**

## 必须做的四件事

### T1-1 生产配置回到候选 A
`data/combat/encounters/black_wind_ridge.yaml` 的 `token_budgets` 四项全部改为 `1`。
**只改这四行**,`active_limit: 12`、`reinforcement_threshold` 等一律不动。

### T1-2 同步被钉死的生产断言
`test/data/phase2/ch1_production_catalog_test.dart:187-190`(现 grep 核行号)当前把
`2/2/1/1` 钉成断言,不改它就会红。改成 `1/1/1/1`。

### T1-3 删掉误导性注释
`test/data/phase2/ch1_candidate_combat_catalog_test.dart` 里 `_totalTokenBudget` 上方那段 `///` 注释
(现 grep `两套口径`定位,约 `:216-227`)声称:

> 「两套口径**有意分离、不需要统一**(2026-08-26 用户拍板维持两套口径)」

**该「用户拍板」查无实据**(协调者已实测:`docs/sessions/` 全目录 grep `TUNE-ATTACK-TOKEN-01` 零命中),
且与 `PROGRESS.md:16` 登记的「两边口径**待统一**」直接矛盾。**整段删除**,replace 成一句事实陈述即可,例如:

```dart
/// 令牌总预算区间 [2,4] 来自二阶段方案 §「第 1 章范围」(方案 :1025)。
/// 候选源与生产源共用同一区间;生产侧的专项守卫见
/// `test/data/phase2/ch1_production_catalog_test.dart`。
```

**不要在注释里写任何「用户拍板/用户批准」字样**——除非你能给出可 grep 的出处文件与行号。

### T1-4 补生产侧专项约束测(本单的真正防回归网)
现状:`_enforceStage0103CandidateBounds`(`test/data/phase2/ch1_candidate_combat_catalog_test.dart:202`)
只是**测试内私有 helper**,且体内只校验 `totalEnemies ∈[35,45]` 与 `activeLimit ∈[8,16]`,
**根本没有令牌判据**;`lib/` 侧 grep 不到任何令牌总和边界。所以方案 :1025 的 2–4 在整个测试网里**无人看守**。

在 `test/data/phase2/ch1_production_catalog_test.dart` 新增一条测试:
读**生产** encounter `stage_01_03`,断言 `melee+ranged+charge+support` 落在 `[2,4]`,
reason 里写明出处「二阶段优化方案 :1025」。

**范围限制(硬要求)**:只钉 `stage_01_03` 这一关。
**禁止**把 [2,4] 做成 `combat_encounter_catalog_loader.dart` 的全局 loader 红线或对所有关卡生效的断言——
方案 :1025 只约束这一关,其余关卡「按各自破路/据点/斩将目标配置」。擅自全局化 = 直接打回。

### T1-5 决策登记表回写(值由用户给定,你只做录入,不得改动)
`docs/dispatch/phase0a_overhaul/decision_registry.yaml`,四条 TUNE-* 从 `status: frozen`
**降回 `status: tuning`**(这是该文件既有枚举,`TUNE-STAGE-COUNT-01`/`TUNE-INJURY-01` 在用;
**不要新造状态词**)。各自补三段 Gate 状态:

| id | selected_candidate | production_wiring | playtest |
|---|---|---|---|
| TUNE-ATTACK-TOKEN-01 | A | complete | pending |
| TUNE-POSTURE-01 | B | ready_unmerged | pending |
| TUNE-WEAPON-TIMELINE-01 | B | pending | pending |
| TUNE-WEAPON-QI-01 | C | pending | pending |

`TUNE-ATTACK-TOKEN-01` 的历史选择 **不要抹掉**:保留原 `user_choice: B` 字段,另加一行
`superseded_by: 2026-08-26 方案一致性复核(与方案 :1025 的攻击令牌 2–4 冲突)`。
`frozen_values` 字段随之改名/更新为选中的 A 值,或保留并加注 —— 你自己选一种,但**必须让文件读起来
只有一个当前生效值**,不得出现两个都像生效的值。

**禁止**在 registry 里写任何本单没给你的经过叙述。

## 硬约束

- 禁区一个字不许动:`GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml` /
  `data/numbers.yaml`。(注意:`black_wind_ridge.yaml` **不是**禁区,本单明确授权改它那四行。)
- 禁 push / 禁 merge / 禁碰 main / 禁 revert。commit message 中文动宾,tip 前缀 `[READY]`/`[BLOCKED]`,工作区干净。
- 不碰姿态相关任何文件(另一分支在途)。不碰 `defenseBreak`。
- 数字实测禁估算;引用代码现 grep 带 `file:line`。

## 必须跑的验证

1. **破坏证红**:把 T1-4 新增的那条测试所依赖的生产值改回 `2/2/1/1`,该测试必然红——跑一次贴输出,再改回。
2. **全量**:`flutter test --no-pub 2>&1 | tee /tmp/t1_full.log`,贴 reporter 末行原文 +
   `grep -c '^\[E\]' /tmp/t1_full.log`(期望 0)。**退出码 0 不作数**;有 `[E]` 贴块原文,不要 `| tail`。
3. `flutter analyze --no-pub lib test` → 0 issue;`dart format .` → 0 changed。贴原文末行。

## [BLOCKED] 出口条件

- 改回 `1/1/1/1` 后出现**平衡类**红测(不是断言同步类),说明有别处依赖 6 这个总量 —— 停下报告,不要改平衡数值;
- registry 回写时发现本单给的表与文件现状对不上(比如某条 id 不存在);
- 需要你发明任何本单没给出的数字。

## 协调者怎么验收

逐条打开 `file:line` 对不上即打回。通过数我自己复跑全量,不采信自报。
出现全局 loader 红线 / 禁区文件 / 姿态或 defenseBreak 改动 = 直接打回。
注释或 registry 里出现无出处的「用户拍板」字样 = 直接打回。
