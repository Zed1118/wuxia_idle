# Phase 2 M7 第十五章内容迁移审计（2026-09-04）

## 当前结论

第十五章 `stage_15_01..05` 的 StageDef、13 份正文（1 个 chapter 文件、12 个 stage 文件）与 5 个敌人图标原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批把该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链；全主线 typed catalog 候选水位由 `66/105 → 71/105`。

当前仍是分支候选，不冒充 `main`/`origin/main` 集成。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

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
- 三次均以反向补丁恢复；最终 SHA-256：manifest `08a4ace91bae22997804047fb04156691e4e8e4ee70b839e42883e7fa2528853`、assignments `019403a558707523f3a86ff2b68c489ce2408d82a919936ed97b9bb2b180d2e5`、encounter `1471eea2f077242fa22405e9a918a2066e4f7b701022a74031020525758c1778`、runtime `8817141110cbbd1ca99c806b6d7edd126bf943d827401217d7efadd6e4778736`、test `35d3e152834a10203e3be9f4ca02de7855598457e1d07b291a4ec7d636194fde`。

## 当前验证

| 门 | 结果 |
| --- | --- |
| 第十五章 targeted | `6/6` |
| 第十四、十五章 adjacent | `12/12` |
| 三向 mutation | `1/1/2` 条精确转红，全部恢复 |
| Phase 2 data / mainline application / analyze / format / full / Gate | 待批末验证 |

第十四章旧测试的全局精确水位 `66` 改为已集成下限 `>=66`，第十五章新测试精确守住候选水位 `71`。删除登记在 `p2-m7-ch15-content-migration-20260904.yaml`；标准 Gate 将按原始结果如实记录。

## 提交与验收边界

内容实现为 `8bbad897`，旧合同迁移为 `e44b2f85`。主代理将继续复核实际 diff、五组 production consumer、StageDef 基敌与冻结 spec 单敌边界；分支内绿色测试或 `[READY]` 都不等于正式 M7、Phase 2 或真人验收。
