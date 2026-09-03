# Phase 2 M7 第十章内容迁移审计（2026-09-03）

## 结论

第十章 `stage_10_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批将该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链。候选合入后，全主线 typed catalog 工程集成水位将由 `46/105 → 51/105`。

本文档在候选冻结前登记：当前 `main/origin/main` 仍是基线 `7c5517e8863a19f10adfd53735e710a61759675b`，不把分支候选写成已集成。标准 Gate、受控合入与 exact-SHA CI 将在后续治理尾回填。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线与语义边界

| stage | encounter | StageDef 基敌 | 角色 / 行为 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_10_01` | `ch10_encounter_01_hetao_swordsman` | `enemy_yiLiu_zhongzhou_hetao_jianke` | `sect_outer` / 近战直进 | defeat target |
| `stage_10_02` | `ch10_encounter_02_yanmen_wanderer` | `enemy_yiLiu_zhongzhou_yanmen_youxia` | `sect_hidden_weapon` / 距离压制 | defeat target |
| `stage_10_03` | `ch10_encounter_03_luoshui_reflection` | `enemy_yiLiu_zhongzhou_luoshui_zhaoying` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_10_04` | `ch10_encounter_04_songyang_gatekeeper` | `enemy_yiLiu_zhongzhou_songyang_guanzhu` | `army_shield` / 守位近战 | defeat commander |
| `stage_10_05` | `ch10_encounter_05_stillwater_master` | `enemy_yiLiu_zhongzhou_shouzhuo_weng` | `army_shield` / 守位近战 | defeat commander |

五关正文均明确为单敌，因此冻结为 `1 / 1 / 1 / 1 / 1`，没有为制造难度凭空扩编。五组 `base_enemy_id` 精确等于各自 `StageDef.enemyTeam.single`。复用层只提供 AI、姿态与表现资源；10-04/05 的名称、原图、全技能、蓄力技、Boss 阶段与 `createActor` 身份仍保持 StageDef 原值。

合入前复核发现 1 个 P1：10-05 正文的“守到极处、滴水不漏”与候选初版的轻功侧翼突进冲突。已改为现有军阵盾卫的守位近战行为，并将五关 role ID 写入精确测试合同。修复后无剩余 P0/P1。本批未改 `stages.yaml`、`numbers.yaml`、敌我基础数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。

## RED 与变异证明

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均未闭环。
- 删除 `stage_10_01` assignment，loader 精确拒绝未被 stage 引用的 encounter。
- 将 `stage_10_05.base_enemy_id` 错绑为 10-04 基敌，loader 精确拒绝与唯一 `StageDef.enemyTeam` 不一致。
- 将 10-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构仍闭包，但 exact actor-set 语义断言精确转红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `13d1f37a9e0108af0d9515a122c31339c7bf9f43ec51b8eccfd6ba6fc61eb91f`、assignments `2a23b62dd24eddf5ccc09736a299f7e2a853d855513d192403a05236416f2f19`、encounter `fc05a867f5111ca00171b1c26cc5db735e961efaf4ff7443b80eaf00f889bad5`、runtime `808c2273b38ada57066e5b3b9fbb6a038bf7799ffaeff7398635828854864ed6`、test `adf030b436b02f6737e64039dfee3c8364a4844b2d08cb6636608a5d1044584d`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第十章 targeted | P1 修复后 `6/6` |
| 第九、十章 adjacent | 各 `6/6`，合计 `12/12` |
| Phase 2 data adjacent | `120/120` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1724 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub` | P1 修复后 `5929/5929`，异常块 `0`，`All tests passed!` |
| full-test lock | 独占执行后已释放 |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`；`PASS` |

第九章旧测试的全局精确水位 `46` 改为已集成下限 `>=46`，第十章新测试以精确 `51` 守住本批增量。删除已登记在 `p2-m7-ch10-content-migration-20260903.yaml`，专用机器门核对通过。

## Gate 与挂账

实现提交为 `d74d600e`，测试契约与加固提交为 `6135123a` / `8117398f` / `64ba35cd`，P1 语义修正提交为 `950e83a5`。`[READY]` tip、标准 Gate 原始结果、主线集成提交与 exact-SHA CI 尚待后续治理尾实时回填，不预写 PASS。

本轮复核是主代理的受控合入复核，不冒充独立 agent 或真人验收。工程候选不等于正式 M7；桌面实战、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
