# Phase 2 M7 第七章内容迁移审计（2026-09-03）

## 结论

第七章原有 `stage_07_01/04` 两条 typed production route；本批将实际缺口 `stage_07_02/03/05` 接入 production catalog、encounter factory、runtime binding、enemy AI/director、objective 与 reducer 终局链，使本章候选水位由 `2/5 → 5/5`，全主线候选由 `33/105 → 36/105`。

这是叠加在第六章之上的本地工程候选；`main == origin/main == c75a57c7` 的已集成口径仍为 `28/105`。正式 M7 仍开放，Phase 2 仍为 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线

| stage | encounter | StageDef 基敌 | 目标 | 阵容 / 同时上限 |
| --- | --- | --- | --- | --- |
| `stage_07_01` | `ch7_encounter_01_northern_outpost` | `enemy_erLiu_beidi_shuzu` | defeat all | 25 / 10 |
| `stage_07_02` | `ch7_encounter_02_snow_riders` | `enemy_erLiu_fengxue_shaoqi` | defeat all | 3 / 3 |
| `stage_07_03` | `ch7_encounter_03_mountain_scouts` | `enemy_erLiu_beipai_youshao` | defeat all | 3 / 3 |
| `stage_07_04` | `ch7_encounter_04_grey_cloak_pursuit` | `enemy_erLiu_huiyi_beijing` | pursue target | 5 / 3 |
| `stage_07_05` | `ch7_encounter_05_heavy_master` | `enemy_erLiu_beipai_zongjiang` | commander + guards | 3 / 1 |

三个新 assignment、encounter 和 runtime binding 均唯一；`base_enemy_id` 与各自 `StageDef.enemyTeam.single` 精确一致。入口、位置、行为、AI、攻击集、视觉变体与 verified-only 引用全部复用已有 `ch7_army` 生态，未新增玩法 ID。

`stage_07_05` 的三个 actor 会从章末 Boss StageDef 生成基础战斗属性；首轮三人并发编排使红线上限角色也在动态测试中战败。修正为 `active_limit: 1` 依次入场后取得真实 victory；保留三名敌人、Boss 身份/技能/阶段与全部目标，不修改 `stages.yaml`、`numbers.yaml`、奖励或规则。

## RED 与变异证明

- 初始产品 RED 为 `0/6`：缺 assignment/runtime/factory/objective/Boss 身份与动态闭环均被真实 loader 或断言拒绝。
- 首次实现为 `5/6`，唯一失败是 `stage_07_05` 实战判负；串行章末编排后为 `6/6`。
- 删除 `stage_07_03` assignment，loader 以 `encounter ... is not assigned to any stage` fail-closed。
- 将 `stage_07_05.base_enemy_id` 改绑为 `stage_07_02` 基敌，loader 以 exact single `StageDef.enemyTeam` mismatch fail-closed。
- 反向补丁后 SHA-256 恢复：`stage_assignments.yaml` = `ccc79d0c3dfbb94fd39adfc984524d6ef797a92099e158e8499030ae73123d4d`；`runtime_bindings.yaml` = `3b394ce500876d9f8c155826160f91564633ed30e797477014118c6cd78ffdc0`。

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
