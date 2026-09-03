# Phase 2 M7 第八章内容迁移审计（2026-09-03）

## 结论

第八章 `stage_08_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批将实际缺口由 `0/5 → 5/5`，接入真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链，全主线 typed catalog 形成 `36/105 → 41/105` 的独立工程候选。

独立复核未发现 P0/P1 阻断后，内容 tip `758a1cd6734399a33b9c611c893e3df289c9f4d1` 已 `--ff-only` 进入本地 main，使本地工程集成水位达到 `41/105`；最终治理 tip、远端与 exact-SHA CI 需实时核验。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。

## 生产接线与语义边界

| stage | encounter | StageDef 基敌 | 目标 | 正文阵容 / 同时上限 |
| --- | --- | --- | --- | --- |
| `stage_08_01` | `ch8_encounter_01_frontier_riders` | `enemy_erLiu_monan_mazei` | defeat all | 12 / 2 |
| `stage_08_02` | `ch8_encounter_02_desert_skirmishers` | `enemy_erLiu_hanhai_shadao` | defeat all | 3 / 2 |
| `stage_08_03` | `ch8_encounter_03_grey_cloak_night` | `enemy_erLiu_huiyi_saibei` | defeat commander | 1 / 1 |
| `stage_08_04` | `ch8_encounter_04_garrison_gate` | `enemy_erLiu_gucheng_shuwei` | defeat all | 5 / 1 |
| `stage_08_05` | `ch8_encounter_05_grey_cloak_final` | `enemy_erLiu_huiyi_final` | defeat commander | 1 / 1 |

五条 assignment、encounter 与 runtime binding 均唯一，`base_enemy_id` 精确等于各自 `StageDef.enemyTeam.single`。08-01 复用西凉骑战生态，08-02/03/05 复用门派生态，08-04 复用军阵生态；没有新增玩法原语，也没有修改 `stages.yaml`、`numbers.yaml`、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。

逐份正文锁定的 actor 集合为 `12 / 3 / 1 / 5 / 1`。动态探针显示 08-01、08-02 可在并发 2 下稳定胜利；08-04 并发 2 会真实战败，故只将该场降为串行 1，未抬高玩家或关卡数值。08-03 与 08-05 使用 `defeat_commander`，并逐项保留灰衣 Boss 的名称、原图、全技能、蓄力技、阶段和 `createActor` Boss 身份。

## RED 与变异证明

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均未闭环。
- 首轮接线被 loader 拒绝，原因是新增 objective target 未进入 manifest reference index；修复生产引用而未放宽 loader。
- 删除 `stage_08_02` assignment，loader 精确报 `encounter ... is not assigned to any stage`。
- 将 `stage_08_05.base_enemy_id` 错绑为章中灰衣基敌，loader 精确报 exact single `StageDef.enemyTeam` mismatch。
- 将正文角色 `ch8_s02_flank_02` 改名为虚构 extra，loader 仍可闭包，但 exact actor-set 断言精确转红。
- 三次均以反向补丁恢复；SHA-256：manifest `11bbad788062ff1aecaf27e6a58ccabadcdd48657b1132c7cf34b3d99cc1fbf5`、assignments `16c38d8bf0f0c5cd157b6bac85178a7196d718a021401c62867156e97559e8e0`、encounter `61e127adc03e39292fb2dbead0c223c374fbaf00976b68746e2c3d6cb318d4b1`、runtime `1e52ef9ffbf29ef7d327514a898c3fce540590b33d67d7e0cec0756e6323bb5f`、test `99459ee4f2a87754ba47c82b645987b906a7f7fba8117b78f5a43d54406cd6d5`；恢复后 targeted 再次 `6/6`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第八章 targeted | `6/6` |
| 第七、八章 adjacent | 各 `6/6`，合计 `12/12` |
| Phase 2 data adjacent | `108/108` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format --output=none --set-exit-if-changed .` | `1722 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub -r compact` | `5917/5917`，`[E] 0`，`All tests passed!` |
| full-test lock | 已自动释放 |
| 测试契约迁移门 | `expect 删 1 / 增 29；用例删 0 / 增 6；登记 1`；`PASS` |

第七章旧测试的全局精确水位 `36` 改为已集成下限 `>=36`，第八章新测试以精确 `41` 守住本批增量。该删除已登记在 `p2-m7-ch8-content-migration-20260903.yaml`，专用门机器核对通过。

## Gate 与挂账

评审时必须以 `git rev-parse HEAD` 实时解析 exact tip。标准 Gate 原生拒绝了必须更新的 `PROGRESS.md` 与已由专用契约门登记的旧精确计数断言删除，原始终行为 `FAIL: forbidden_files,test_deletions`，不得改写为标准 Gate PASS；同轮 full test `5917/5917`、analyze、format、commit message 与 clean 均通过，scope whitelist 与 audit receipt 按规则跳过。最终 exact tip 仍须现场复核同一组结果。

内容候选经独立复核后已进入本地 main 受控集成链，push 与 CI 结论以最终 exact tip 的实时结果为准。工程集成不等于正式 M7 或真人验收；桌面实战、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
