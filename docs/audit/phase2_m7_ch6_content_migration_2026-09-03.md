# Phase 2 M7 第六章内容迁移审计（2026-09-03）

## 结论

第六章 `stage_06_01..05` 已在候选分支接入真实 typed production catalog、encounter factory、runtime binding、enemy AI/director、objective 与 reducer 终局链。候选水位由全主线 `28/105` 提升至 `33/105`；第六章五关为工程候选 `5/5`，正式 M7 仍开放，未进入 `main`/`origin/main`，未声称真人、视觉、音频、手感或 Windows 验收。

## 生产接线核对

| stage | encounter | StageDef 基敌 | authored objective | 阵容/上限 |
| --- | --- | --- | --- | --- |
| `stage_06_01` | `ch6_encounter_01_lunjian_departure` | `enemy_zongShi_lunjian_sanchang_xunluo` | `all` | 3 / 3 |
| `stage_06_02` | `ch6_encounter_02_songshan_return` | `enemy_zongShi_songshan_shouguan` | `all` | 2 / 2 |
| `stage_06_03` | `ch6_encounter_03_yellow_river_source` | `enemy_zongShi_huanghe_yuantou_yufu` | `all` | 3 / 3 |
| `stage_06_04` | `ch6_encounter_04_kunlun_outer_gate` | `enemy_zongShi_kunlun_waimen_shouguan` | commander + guards | 3 / 3 |
| `stage_06_05` | `ch6_encounter_05_kunlun_summit` | `enemy_wuSheng_xiliang_bazhu` | commander + companions | 3 / 3 |

五个 assignment、encounter 和 runtime binding 均唯一存在；runtime 的 `base_enemy_id` 与 `data/stages.yaml` 对应 `StageDef.enemyTeam.single` 严格一致。所有 entrances、positions、behaviors、AI profiles、attack sets、visual variants 和 verified-only references 均复用既有 `ch2_sects` / `ch4_xiliang` 生态，没有新增玩法 ID 或数值。

真实生产路径由 repository → catalog/factory → runtime adapter → enemy generation/AI/director → objective/终局 reducer 消费；第六章五条 factory route 与五条动态 headless victory 均通过，未落回 legacy mapper。

## 集成前语义复核与修复

独立于原实施清单重新阅读全文后，发现 `stage_06_02` opening/victory 明确只有“守关 + 巡山人”两名对手，候选却额外生成了第三名 instructor。集成前已删除该非叙事角色及其 encounter/runtime 引用，把阵容和同时上限收回 `2 / 2`；新增 exact actor-id 断言，锁住 `ch6_s02_guard_01 + ch6_s02_scout_01`。未改 `stages.yaml`、正文、敌人数值、掉落、奖励或规则。

## 证据与破坏证红

- 初始有效 RED 为 `0/6`：assignment、encounter/runtime、factory、objective、runtime base enemy 与 dynamic host 缺失各有守卫；首次环境依赖/生成文件失败不计产品 RED。
- 删除 `stage_06_03` assignment 后，setUpAll 以 `encounter ... is not assigned to any stage` fail-closed。
- 将 `stage_06_05.base_enemy_id` 改成 `stage_06_01` 基敌后，setUpAll 以 exact single `StageDef.enemyTeam` mismatch fail-closed。
- 反向补丁后恢复 SHA-256：`stage_assignments.yaml` = `0150329fd6cfaae7ebd76a84efa0ce07890b7ba4633cb282037f5a3ab61d4aa3`；`runtime_bindings.yaml` = `681aee7c9bac89025e36d72c0c45f1548d08936466e6c45c927526b440c02e80`。
- 集成前语义变异把 `stage_06_02` 的巡山人 ID 替换成未获正文支持的 warden；loader 正常闭包，但 exact narrative cast 断言按预期单点转红，反向恢复后再次 `12/12`。修复态 SHA-256：encounter `3760a91f0a0c976676de9e6273c89de3f8741f46dfcdd57d30037e8d4508892f`、runtime `fe914b0c30d296f3d1774a3117d6ad321c4aa1b54f24063995b8b2e164ebf5cf`、test `a9e687fe37d9075d8c5fd62abafe8d1ac4416fcab1e2ccc87028f1929a6f2113`。

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

本批实现 commit 为 `b7a2fdf5ca2ad35107193d5a62a0f8b2e99df0a`，基线为 `c75a57c76fde3752f9030b4fd8b44af49ba0ffc5`。标准 `gate.sh` 已在精确区间独立复跑：`forbidden_files`、full test（`5905/5905`、`[E]` `0`）、analyze 和 format 全部 PASS；`receipt_crosscheck` 按零 `lib/` 改动规则 SKIP。实现 tip 当时尚未 `[READY]` 且治理尾尚未提交，原始 Gate 因 `test_deletions=1`、`commit_msg` 和 `worktree_clean` 暂红；其中测试删除由契约迁移门逐条覆盖。

治理尾 `b63a8155` 的完整区间复跑确认 full/analyze/format/commit_msg/worktree_clean 通过，但原生 `forbidden_files` 如实命中项目要求更新的 `PROGRESS.md`，并仍有已登记的 `test_deletions=1`；所以该轮原始判决是 `FAIL: forbidden_files,test_deletions`，不得改写成脚本原生 PASS。后续 `e357c4c3` 仅补写收据说明，未取得 exact-tip Gate；当前 tip 必须在评审时用 `git rev-parse` 实时解析，本文不再写死会被下一次文档提交立即作废的“最终 tip”。

本审计不把工程候选、自动化测试、READY 或 c75 的历史 CI 当成正式 M7 或人类验收。正式 Phase 2 仍为 `1/10`；塔为 `0/49`，legacy runtime consumer 退役仍开放。未经用户授权不 merge、不 push；真人桌面、视觉/音频/手感和 Windows 继续 `DEFERRED`。
