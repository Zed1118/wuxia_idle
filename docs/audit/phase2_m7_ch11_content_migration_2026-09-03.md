# Phase 2 M7 第十一章内容迁移审计（2026-09-03）

## 当前结论

第十一章 `stage_11_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批把该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链；全主线 typed catalog 工程集成水位由 `51/105 → 56/105`。

候选 `584600c55f431adaa667ba2bdeb4e98658d80dcc` 已经 no-ff merge `37688ea908ca6dad17ac12c738b06577f0ec0f76` 进入 `main` 与 `origin/main`，merge exact-SHA CI run `33772898042` 为 `completed/success`。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

第十一章并非按顺序默认选择。只读审计比较剩余章节后确认：本章五关正文均明确为单一对手，StageDef 与 Boss 身份已冻结，又没有既有 typed route 重叠，可一次关闭 5 门。第十三章虽只缺 4 门，但既有 `stage_13_02` 25 actor 生态与“一名知客僧”正文存在冲突并受 M4 合同约束，未混入本批。

| stage | encounter | StageDef 基敌 | 角色 / 行为 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_11_01` | `ch11_encounter_01_xudu_swordsman` | `enemy_yiLiu_zhongzhou_xudu_mingjia` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_11_02` | `ch11_encounter_02_jinding_disciple` | `enemy_yiLiu_zhongzhou_jinding_menren` | `sect_outer` / 近战直进 | defeat target |
| `stage_11_03` | `ch11_encounter_03_luoyang_merchant` | `enemy_yiLiu_zhongzhou_luoyang_haoke` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_11_04` | `ch11_encounter_04_yujing_swordmaster` | `enemy_yiLiu_zhongzhou_yujing_jianzhu` | `sect_outer` / 近战直进 | defeat commander |
| `stage_11_05` | `ch11_encounter_05_liujin_master` | `enemy_yiLiu_zhongzhou_liujin_gong` | `sect_outer` / 近战直进 | defeat commander |

五关均冻结为单敌 `1 / 1 / 1 / 1 / 1`。复用层只提供 AI、姿态与表现资源；各 StageDef 的姓名、原图、流派与全技能均保持原值，11-04/05 的 Boss 身份、蓄力技与阶段也由精确合同守住。本批未改 `stages.yaml`、`numbers.yaml`、技能、掉落、奖励、经济、正文、解锁、周目或结算 owner。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均真实缺失。
- 删除 `stage_11_01` assignment，loader 精确拒绝无 stage 引用的 encounter。
- 将 `stage_11_05.base_enemy_id` 错绑为 11-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致。
- 将 11-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同转红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `ff9770c0ff8fffcdd036a0aebd70e7276961863c41c14ad79436904145869b71`、assignments `748a9834554ca654e8cb51a6a52e006b5f6fe258f3cbed5a7263e3610b9fd7f2`、encounter `f679c8b5e87b3280926c432f3f37dc1d52ece210df7fe85ae0b0875bdd8f98be`、runtime `73b27a772515d90eea40afe743079379fe222645089a2a092c72e5527247f823`、test `801a9e4f783c1b6cac476058126ed4982a7910f526e0283c322d74fddbcbba1c`。

## 已完成验证

| 门 | 结果 |
| --- | --- |
| 第十一章 targeted | `6/6` |
| 第十、十一章 adjacent | `12/12` |
| Phase 2 data | `126/126` |
| mainline application | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1725 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub` | `5935/5935`，异常块 `0`，`All tests passed!`，锁已释放 |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`，`PASS` |
| exact-tip 标准 Gate | 原生终判仅 `FAIL: test_deletions`；full `5935/5935`、analyze、format、禁改文件、中文提交、clean 与 receipt 均 `PASS` |
| main 合入后 analyze / format | `No issues found`；`1726 files (0 changed)` |
| main 合入后持锁整仓 | `5935/5935`，`All tests passed!`，锁已释放 |
| merge exact-SHA CI | run `33772898042`，head `37688ea908ca6dad17ac12c738b06577f0ec0f76`，`completed/success` |

第十章旧测试的全局精确水位 `51` 改为已集成下限 `>=51`，第十一章新测试精确守住 `56`。该 1 行 expect 删除已登记在 `p2-m7-ch11-content-migration-20260903.yaml`，专用迁移门通过；标准 Gate 的原始 `test_deletions` 结论不被改写，其余门全部通过后才执行受控集成。

## 提交与验收边界

内容实现为 `f5359335c5b92a4f03d47cc2347d25f84cefef2b`，旧合同迁移为 `e14c57d120fde1f3ae81f2e8db548446ee50937e`，登记表为 `b2d8c5b89329b09e99f53b7812ad70e634d56112`，冻结候选为 `584600c55f431adaa667ba2bdeb4e98658d80dcc`。主代理已复核实际 diff、五组 production consumer、StageDef 基敌与正文单敌边界，当前无已知 P0/P1；这不冒充独立 agent 或真人验收。
