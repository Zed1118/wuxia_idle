# Phase 2 M7 第十五章内容迁移审计（2026-09-04）

## 当前结论

第十五章 `stage_15_01..05` 的 StageDef、13 份正文（1 个 chapter 文件、12 个 stage 文件）与 5 个敌人图标原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批把该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链；全主线 typed catalog 集成水位由 `66/105 → 71/105`。

内容候选 `f26ffc827f96906f59e151c1c5a2e56f7942f3a0` 已经 no-ff merge `8976362aa93a701abc3590e738a7b03227b2bc45` 进入 `main` 与 `origin/main`，exact-SHA CI run `33800564328` 为 `completed/success`，全部 jobs 与 steps 成功。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

第十五章并非按顺序默认选择。实时审计确认五关均为冻结的单一对手，StageDef、Boss、技能、正文与图标完整，且无既有 typed route 或任务登记重叠。第十三章既有 `stage_13_02` 25 actor 生态与“一名知客僧”正文冲突并受 M4 合同约束，未混入本批。

| stage | encounter | StageDef 基敌 | 角色 / 行为 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_15_01` | `ch15_encounter_01_mountain_companion` | `enemy_jueDing_guanshanyicheng_songxing_tongdao` | `sect_outer` / 近战直进 | defeat target |
| `stage_15_02` | `ch15_encounter_02_ferry_night_guest` | `enemy_jueDing_guanshanyicheng_dukou_yeke` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_15_03` | `ch15_encounter_03_grotto_monk` | `enemy_jueDing_guanshanyicheng_xingjiao_seng` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_15_04` | `ch15_encounter_04_desert_chieftain` | `enemy_jueDing_guanshanyicheng_shahai_zongpiao` | `sect_outer` / 近战直进 | defeat commander |
| `stage_15_05` | `ch15_encounter_05_pass_old_general` | `enemy_jueDing_guanshanyicheng_shouguan_laojiang` | `sect_lightfoot` / 侧翼突进 | defeat commander |

五关冻结为单敌 `1 / 1 / 1 / 1 / 1`。复用层只提供 AI、姿态与表现资源；StageDef 的姓名、原图、流派与全技能保持原值，15-04/05 的 Boss 身份、蓄力技与阶段由精确合同守住。本批未改 `stages.yaml`、`numbers.yaml`、技能、掉落、奖励、经济、正文、解锁、周目或结算 owner。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均真实缺失。
- 删除 `stage_15_01` assignment，loader 精确拒绝无 stage 引用的 encounter（1 条红）。
- 将 `stage_15_05.base_enemy_id` 错绑为 15-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致（1 条红）。
- 将 15-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同精确 2 条红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `08a4ace91bae22997804047fb04156691e4e8e4ee70b839e42883e7fa2528853`、assignments `019403a558707523f3a86ff2b68c489ce2408d82a919936ed97b9bb2b180d2e5`、encounter `1471eea2f077242fa22405e9a918a2066e4f7b701022a74031020525758c1778`、runtime `8817141110cbbd1ca99c806b6d7edd126bf943d827401217d7efadd6e4778736`、test `650337ccb1d81aca01e60dab4b43caebfe7b2d554c2089680a1f1d04ff03e9cd`。

## 当前验证

| 门 | 结果 |
| --- | --- |
| 第十五章 targeted | `6/6` |
| 第十四、十五章 adjacent | `12/12` |
| 三向 mutation | `1/1/2` 条精确转红，全部恢复 |
| Phase 2 data | `144/144`，异常块 `0` |
| mainline application | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1728 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub` | `5953/5953`，异常块 `0`，`All tests passed!`，锁已释放 |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`，`PASS` |
| exact-tip 标准 Gate | full/analyze/format/commit/clean/receipt 均 PASS；原始终行严格为 `FAIL: test_deletions` |
| main 合入后 | 第十五章 `6/6`、analyze 0 issue、format `1729/0`、持锁全量 `5953/5953` |
| merge exact-SHA CI | run `33800564328`，head `8976362aa93a701abc3590e738a7b03227b2bc45`，全部 jobs/steps 成功 |

第十四章旧测试的全局精确水位 `66` 改为已集成下限 `>=66`，第十五章新测试精确守住集成水位 `71`。删除已登记在 `p2-m7-ch15-content-migration-20260904.yaml`。标准 Gate 的原始 `test_deletions` 失败没有隐藏，由专用测试契约迁移 Gate 的 PASS 形成放行证据。

## 提交与验收边界

内容实现为 `8bbad897`，旧合同迁移为 `e44b2f85`，测试契约登记为 `d1fcfef7`，格式收口为 `3a239a69`，候选冻结为 `f26ffc82`，内容合并为 `8976362a`。主代理已复核实际 diff、五组 production consumer、StageDef 基敌与冻结 spec 单敌边界，当前无已知 P0/P1；这不冒充正式 M7 或真人验收。
