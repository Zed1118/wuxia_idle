# Phase 2 M7 第七章内容迁移审计（2026-09-03）

## 结论

第七章原有 `stage_07_01/04` 两条 typed production route；本批将实际缺口 `stage_07_02/03/05` 接入 production catalog、encounter factory、runtime binding、enemy AI/director、objective 与 reducer 终局链，使本章候选水位由 `2/5 → 5/5`，全主线候选由 `33/105 → 36/105`。

这是叠加在第六章之上的本地工程候选；`main == origin/main == c75a57c7` 的已集成口径仍为 `28/105`。正式 M7 仍开放，Phase 2 仍为 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线

| stage | encounter | StageDef 基敌 | 目标 | 阵容 / 同时上限 |
| --- | --- | --- | --- | --- |
| `stage_07_01` | `ch7_encounter_01_northern_outpost` | `enemy_erLiu_beidi_shuzu` | defeat all | 25 / 10 |
| `stage_07_02` | `ch7_encounter_02_snow_riders` | `enemy_erLiu_fengxue_shaoqi` | defeat rider | 1 / 1 |
| `stage_07_03` | `ch7_encounter_03_mountain_scouts` | `enemy_erLiu_beipai_youshao` | defeat all | 3 / 3 |
| `stage_07_04` | `ch7_encounter_04_grey_cloak_pursuit` | `enemy_erLiu_huiyi_beijing` | pursue target | 5 / 3 |
| `stage_07_05` | `ch7_encounter_05_heavy_master` | `enemy_erLiu_beipai_zongjiang` | defeat commander | 1 / 1 |

三个新 assignment、encounter 和 runtime binding 均唯一；`base_enemy_id` 与各自 `StageDef.enemyTeam.single` 精确一致。入口、位置、行为、AI、攻击集、视觉变体与 verified-only 引用全部复用已有 `ch7_army` 生态，未新增玩法 ID。

集成前逐段复核设计稿和正文后，否决了最初的“三人编排”：`stage_07_02` 正文只有当先一骑下场，`stage_07_05` spec/正文锁定单一北派重手宗匠。现分别收回 `1 / 1`，章末仅保留宗匠本人；Boss 名称、原图、技能、蓄力技、阶段与目标均沿 `StageDef` 保留。新增 exact actor-id 与 Boss 完整身份断言，不修改 `stages.yaml`、`numbers.yaml`、正文、奖励或规则。

## RED 与变异证明

- 初始产品 RED 为 `0/6`：缺 assignment/runtime/factory/objective/Boss 身份与动态闭环均被真实 loader 或断言拒绝。
- 首次实现为 `5/6`，唯一失败是 `stage_07_05` 三个 Boss 基模 actor 并发判负；当时用串行三人取得 `6/6`，但该方案在集成前语义复核中因偏离单 Boss canon 被否决并替换为单宗匠编排。
- 删除 `stage_07_03` assignment，loader 以 `encounter ... is not assigned to any stage` fail-closed。
- 将 `stage_07_05.base_enemy_id` 改绑为 `stage_07_02` 基敌，loader 以 exact single `StageDef.enemyTeam` mismatch fail-closed。
- 反向补丁后 SHA-256 恢复：`stage_assignments.yaml` = `ccc79d0c3dfbb94fd39adfc984524d6ef797a92099e158e8499030ae73123d4d`；`runtime_bindings.yaml` = `3b394ce500876d9f8c155826160f91564633ed30e797477014118c6cd78ffdc0`。
- 集成前语义变异把 `stage_07_05` 宗匠 ID 替换成 guard；loader 仍能闭包，但角色、目标与 Boss 身份断言精确转红，反向恢复后再次 `12/12`。修复态 SHA-256：manifest `8b764b8d275f564037f44c384b62b0113e72b891b23d5f742a96415c4e11b5f5`、encounter `4194d9f881e113217799c7d37afff11bf64dbb8a9979dc10fb14a2126bea1c40`、runtime `fe914b0c30d296f3d1774a3117d6ad321c4aa1b54f24063995b8b2e164ebf5cf`、test `e6ea815d22f8d16c261ec997431cd94fa1f44224bb959934d69a792623bd7df2`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第七章 targeted | `6/6` |
| 第六 + 第七章 adjacent | `12/12` |
| Phase 2 data adjacent | `102/102` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1721 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub -r compact` | `5911/5911`，`[E]` `0`，`All tests passed!` |
| full-test lock | 已自动释放 |
| 测试契约迁移门 | `expect 删 1 / 增 28；用例删 0 / 增 6；登记 1`；`PASS` |

## Gate 与边界

本批实现 commit 为 `1d5b9f8ab6997940e332d563e9fdb1bfcd0bdf42`，基线为第六章证据纠偏 commit `5aac9f5c5d2a6215e37f9030e87beb83d4bc5c96`。治理文档不写死会被下一次提交立即作废的“最终 tip”；评审时必须用 `git rev-parse HEAD` 实时解析，并查看该 exact tip 的标准 Gate 原始终行。项目 Gate 会原生拒绝必须更新的 `PROGRESS.md` 以及已被专用契约门登记的旧精确计数断言删除；若命中，必须按原始 `FAIL` 报告，不得改写为脚本 PASS。

本审计只支持工程候选结论。未 merge、未 push、无远端 exact-SHA CI；真人桌面实战、视觉、音频、手感和 Windows 均继续 `DEFERRED`。
