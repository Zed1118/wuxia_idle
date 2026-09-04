# Phase 2 M7 第十九章内容迁移审计（2026-09-04）

## 结论

第十九章 `stage_19_01..05` 已从既有 StageDef 接入 typed production catalog、runtime binding 与 production encounter factory。候选 `7072d7ca4428063f918cda56ad089263d3f936db` 经 no-ff merge `5ab2fe351e88c1cbb3a1f46c931f03ebd6714dd8` 进入 `main` 与 `origin/main`；该 merge exact-SHA CI run `33844770791` 已全部成功。

本批只把主线 typed catalog 工程水位从 `86/105` 推进到 `91/105`。塔保持 `0/49`，五处 legacy 生产接缝仍开放，正式 M7 未关闭，Phase 2 正式里程碑仍为 `1/10`。

## 生产接线

| 关卡 | 生产 encounter / actor | 冻结语义 |
| --- | --- | --- |
| `stage_19_01` | `ch19_encounter_01_turnback_traveler` / `ch19_s01_turnback_traveler` | 单敌、刚猛、defeat-target |
| `stage_19_02` | `ch19_encounter_02_sand_measurer` / `ch19_s02_sand_measurer` | 单敌、灵巧、defeat-target |
| `stage_19_03` | `ch19_encounter_03_wind_listener` / `ch19_s03_wind_listener` | 单敌、阴柔、defeat-target |
| `stage_19_04` | `ch19_encounter_04_returning_gatekeeper` / `ch19_s04_returning_gatekeeper` | Boss、刚猛、defeat-commander、无 vulnerability、两相位 |
| `stage_19_05` | `ch19_encounter_05_blackstone_mirror_keeper` / `ch19_s05_blackstone_mirror_keeper` | Boss、阴柔、defeat-commander、vulnerability `0.15 / 0.08`、两相位 |

19-04 保留当前 StageDef 的无 vulnerability 合同。19-05 保留 `skill_yi_jing_shuang_zhao` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId`，并保留一、二周目 vulnerability `0.15 / 0.08`。

真实消费链为 `GameRepository → combatAssignment/combatEncounter/combatRuntimeBinding → Phase0aMainlineRepositoryRuntimeBindingAdapter → createFreshPhase0aMainlineEncounter → director/objective/reducer`。五关均由真实 factory 构建并完成 dynamic headless victory，不是只登记 YAML。

## 验证证据

| 门 | 结果 |
| --- | --- |
| 初始 RED | `0/6`，assignment、identity、factory、objective、Boss runtime、dynamic victory 均按缺口失败 |
| 三向 mutation | 删 assignment、错 `base_enemy_id`、错角色语义各触发 1 个精确失败；反向补丁恢复后 3 文件 SHA-256 与变异前一致 |
| Ch19 focused | `6/6 PASS` |
| Ch18 + Ch19 | `12/12 PASS` |
| Phase 2 data | `168/168 PASS` |
| mainline application | `183/183 PASS` |
| test-contract migration | `PASS`：expect 删 1/增 39、用例删 0/增 6、登记 1 条 |
| analyze / format | `No issues found`；1641 files、0 changed |
| 候选标准 Gate | 白名单、禁改文件、commit、clean、隔离 full `5981/5981`、analyze、format 均 PASS；receipt 因 0 个 `lib/` 改动 SKIP；原始总结果仅 `FAIL: test_deletions`，该 1 行由专用迁移 Gate 覆盖 |
| 合并态 focused / full / analyze / format | `12/12` / `5981/5981` / `No issues found` / 1642 files、0 changed |
| merge exact-SHA CI | run `33844770791`，HEAD `5ab2fe351e88c1cbb3a1f46c931f03ebd6714dd8`；codegen、format、analyze、coverage tests、ratchet、上传与 macOS build 全部成功 |

## 边界

- 未修改 `data/stages.yaml`、`data/numbers.yaml`、技能、Boss 数值、掉落、奖励、经济、正文、schema/saveVersion、GDD 或 CLAUDE。
- 未处理 Ch13、Ch20+、塔或 M8/M9。
- 真人桌面、视觉、音频、手感与 Windows 均未执行，继续 `DEFERRED`；自动化不代签。
- 下一完整工程门按既定顺序为 Ch20 `91/105 → 96/105`；本批治理尾仍须提交并通过最终 exact-SHA CI。
