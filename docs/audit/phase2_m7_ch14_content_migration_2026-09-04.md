# Phase 2 M7 第十四章内容迁移审计（2026-09-04）

## 当前结论

第十四章 `stage_14_01..05` 的 StageDef、13 份正文（1 个 chapter 文件、12 个 stage 文件）与 5 个敌人图标原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批把该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链；全主线 typed catalog 集成水位由 `61/105 → 66/105`。

内容候选 `3f8538949968c93cecaf47c84cf3ce9957b3dbb6` 已经 no-ff merge `4b976cdd9a4ea11bd197b305df17eefc7c8830aa` 进入 `main` 与 `origin/main`，exact-SHA CI run `33791901269` 为 `completed/success`，全部 jobs 与 steps 成功。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

第十四章并非按顺序默认选择。实时审计确认五关均为冻结的单一对手，StageDef、Boss、技能、正文与图标完整，且无既有 typed route 或任务登记重叠。第十三章既有 `stage_13_02` 25 actor 生态与“一名知客僧”正文冲突并受 M4 合同约束，未混入本批。

| stage | encounter | StageDef 基敌 | 角色 / 行为 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_14_01` | `ch14_encounter_01_mountain_messenger` | `enemy_jueDing_shanwailaike_kaidao_xinshi` | `sect_outer` / 近战直进 | defeat target |
| `stage_14_02` | `ch14_encounter_02_inn_vanguard` | `enemy_jueDing_shanwailaike_xiliang_xianfeng` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_14_03` | `ch14_encounter_03_forest_swordsman` | `enemy_jueDing_shanwailaike_xiyu_jianke` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_14_04` | `ch14_encounter_04_drill_deputy` | `enemy_jueDing_shanwailaike_xiliang_fujiang` | `sect_outer` / 近战直进 | defeat commander |
| `stage_14_05` | `ch14_encounter_05_peak_mounted_master` | `enemy_jueDing_shanwailaike_mazhan_zongshi` | `sect_outer` / 近战直进 | defeat commander |

五关冻结为单敌 `1 / 1 / 1 / 1 / 1`。复用层只提供 AI、姿态与表现资源；StageDef 的姓名、原图、流派与全技能保持原值，14-04/05 的 Boss 身份、蓄力技与阶段由精确合同守住。本批未改 `stages.yaml`、`numbers.yaml`、技能、掉落、奖励、经济、正文、解锁、周目或结算 owner。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均真实缺失。
- 删除 `stage_14_01` assignment，loader 精确拒绝无 stage 引用的 encounter（1 条红）。
- 将 `stage_14_05.base_enemy_id` 错绑为 14-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致（1 条红）。
- 将 14-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同精确 2 条红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `8af30037b1b484d4a5f3fcfdbe2419a718b66b08a1f10ed89f8698fbacc0c789`、assignments `55e65d9ba946569475a16d631c02e918045d56a348e42ee7f74fabd0f332c1cd`、encounter `c1f383937bf2b04fe60894308cbd2ddce15b1be7c36ae28be4156f5ad2b9c1ea`、runtime `7d736a6bd70b5465a95543ac4b63755550cfc2a026f22a80ab5d8dfcab4f5b7d`、test `fa09f91cfc4096c2a28411a3257a6b3c2f82d72f1a218b4952c12d973541a02b`。

## 当前验证

| 门 | 结果 |
| --- | --- |
| 第十四章 targeted | `6/6` |
| 第十二、十四章 adjacent | `12/12` |
| Phase 2 data | `138/138`，异常块 `0` |
| mainline application | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1727 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub` | `5947/5947`，异常块 `0`，`All tests passed!`，锁已释放 |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`，`PASS` |
| exact-tip 标准 Gate | full/analyze/format/commit/clean/receipt 均 PASS；原始终行严格为 `FAIL: test_deletions` |
| main 合入后 | 第十四章 `6/6`、analyze 0 issue、format `1728/0`、持锁全量 `5947/5947` |
| merge exact-SHA CI | run `33791901269`，head `4b976cdd9a4ea11bd197b305df17eefc7c8830aa`，全部 jobs/steps 成功 |

第十二章旧测试的全局精确水位 `61` 改为已集成下限 `>=61`，第十四章新测试精确守住集成水位 `66`。删除已登记在 `p2-m7-ch14-content-migration-20260904.yaml`。标准 Gate 的原始 `test_deletions` 失败没有隐藏，由专用测试契约迁移 Gate 的 PASS 形成放行证据。

## 提交与验收边界

内容实现为 `248473c4`，旧合同迁移为 `b96592c1`，测试契约登记为 `e7115b9b`，候选冻结为 `3f853894`，内容合并为 `4b976cdd`。主代理已复核实际 diff、五组 production consumer、StageDef 基敌与冻结 spec 单敌边界，当前无已知 P0/P1；这不冒充正式 M7 或真人验收。
