# Phase 2 M7 第六章内容迁移审计（2026-09-03）

## 结论

第六章 `stage_06_01..05` 已在候选分支接入真实 typed production catalog、encounter factory、runtime binding、enemy AI/director、objective 与 reducer 终局链。候选水位由全主线 `28/105` 提升至 `33/105`；第六章五关为工程候选 `5/5`，正式 M7 仍开放，未进入 `main`/`origin/main`，未声称真人、视觉、音频、手感或 Windows 验收。

## 生产接线核对

| stage | encounter | StageDef 基敌 | authored objective | 阵容/上限 |
| --- | --- | --- | --- | --- |
| `stage_06_01` | `ch6_encounter_01_lunjian_departure` | `enemy_zongShi_lunjian_sanchang_xunluo` | `all` | 3 / 3 |
| `stage_06_02` | `ch6_encounter_02_songshan_return` | `enemy_zongShi_songshan_shouguan` | `all` | 3 / 3 |
| `stage_06_03` | `ch6_encounter_03_yellow_river_source` | `enemy_zongShi_huanghe_yuantou_yufu` | `all` | 3 / 3 |
| `stage_06_04` | `ch6_encounter_04_kunlun_outer_gate` | `enemy_zongShi_kunlun_waimen_shouguan` | commander + guards | 3 / 3 |
| `stage_06_05` | `ch6_encounter_05_kunlun_summit` | `enemy_wuSheng_xiliang_bazhu` | commander + companions | 3 / 3 |

五个 assignment、encounter 和 runtime binding 均唯一存在；runtime 的 `base_enemy_id` 与 `data/stages.yaml` 对应 `StageDef.enemyTeam.single` 严格一致。所有 entrances、positions、behaviors、AI profiles、attack sets、visual variants 和 verified-only references 均复用既有 `ch2_sects` / `ch4_xiliang` 生态，没有新增玩法 ID 或数值。

真实生产路径由 repository → catalog/factory → runtime adapter → enemy generation/AI/director → objective/终局 reducer 消费；第六章五条 factory route 与五条动态 headless victory 均通过，未落回 legacy mapper。

## 证据与破坏证红

- 初始有效 RED 为 `0/6`：assignment、encounter/runtime、factory、objective、runtime base enemy 与 dynamic host 缺失各有守卫；首次环境依赖/生成文件失败不计产品 RED。
- 删除 `stage_06_03` assignment 后，setUpAll 以 `encounter ... is not assigned to any stage` fail-closed。
- 将 `stage_06_05.base_enemy_id` 改成 `stage_06_01` 基敌后，setUpAll 以 exact single `StageDef.enemyTeam` mismatch fail-closed。
- 反向补丁后恢复 SHA-256：`stage_assignments.yaml` = `0150329fd6cfaae7ebd76a84efa0ce07890b7ba4633cb282037f5a3ab61d4aa3`；`runtime_bindings.yaml` = `681aee7c9bac89025e36d72c0c45f1548d08936466e6c45c927526b440c02e80`。

## 验证结果

| 门 | 结果 |
| --- | --- |
| 第六章 targeted | `6/6` |
| Phase 2 data adjacent | `96/96` |
| mainline application adjacent | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1720 files (0 changed)` |
| 持锁整仓 `flutter test --no-pub -r compact` | `5905/5905`, `[E]` `0`, `All tests passed!` |
| full-test lock | 已自动释放 |
| 测试契约迁移门 | `[migration] expect 删 1 / 增 36; 用例删 0 / 增 6; 登记 1`；`PASS` |

## Gate 与状态边界

本批实现 commit 为 `b7a2fdf5ca2ad35107193d5a62a0f8b2e99df0a`，基线为 `c75a57c76fde3752f9030b4fd8b44af49ba0ffc5`。标准 `gate.sh` 已在精确区间独立复跑：`forbidden_files`、full test（`5905/5905`、`[E]` `0`）、analyze 和 format 全部 PASS；`receipt_crosscheck` 按零 `lib/` 改动规则 SKIP。实现 tip 当时尚未 `[READY]` 且治理尾尚未提交，原始 Gate 因 `test_deletions=1`、`commit_msg` 和 `worktree_clean` 暂红；其中测试删除由契约迁移门逐条覆盖，其余两项随本治理尾 `[READY]` clean 收口。

本审计不把工程候选、自动化测试、READY 或 c75 的历史 CI 当成正式 M7 或人类验收。正式 Phase 2 仍为 `1/10`；塔为 `0/49`，legacy runtime consumer 退役仍开放。未经用户授权不 merge、不 push；真人桌面、视觉/音频/手感和 Windows 继续 `DEFERRED`。
