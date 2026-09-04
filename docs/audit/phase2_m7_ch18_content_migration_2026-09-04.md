# Phase 2 M7 第十八章内容迁移审计（2026-09-04）

## 结论

第十八章 `stage_18_01..05` 已从既有 StageDef 接入 typed production catalog、runtime binding 与 production encounter factory。候选 `142120d7ad2082a39344b906a84f42a89cd93f3e` 经 no-ff merge `c905e50aa8494e5ca2ba557c34a88c231e3ec544` 进入 `main` 与 `origin/main`；该 merge exact-SHA CI run `33833220808` 已全部成功。

本批只把主线 typed catalog 工程水位从 `81/105` 推进到 `86/105`。塔保持 `0/49`，五处 legacy 生产接缝仍开放，正式 M7 未关闭，Phase 2 正式里程碑仍为 `1/10`。

## 生产接线

| 关卡 | 生产 encounter / actor | 冻结语义 |
| --- | --- | --- |
| `stage_18_01` | `ch18_encounter_01_pass_sentry` / `ch18_s01_pass_sentry` | 单敌、刚猛、defeat-target |
| `stage_18_02` | `ch18_encounter_02_smoke_interceptor` / `ch18_s02_smoke_interceptor` | 单敌、灵巧、defeat-target |
| `stage_18_03` | `ch18_encounter_03_city_greeter` / `ch18_s03_city_greeter` | 单敌、阴柔、defeat-target |
| `stage_18_04` | `ch18_encounter_04_xiliang_third_disciple` / `ch18_s04_xiliang_third_disciple` | Boss、阴柔、defeat-commander、vulnerability `0.20`、两相位 |
| `stage_18_05` | `ch18_encounter_05_xiliang_overlord` / `ch18_s05_xiliang_overlord` | Boss、阴柔、defeat-commander、vulnerability `0.12`、两相位 |

18-04 采用当前 StageDef 的 `yinRou`，没有用旧 spec 的漂移值覆盖生产真相。18-05 保留 `skill_yang_guan_wu_gu_ren` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId` 的既有合同。

真实消费链为 `GameRepository → combatAssignment/combatEncounter/combatRuntimeBinding → Phase0aMainlineRepositoryRuntimeBindingAdapter → createFreshPhase0aMainlineEncounter → director/objective/reducer`。五关均由真实 factory 构建并完成 dynamic headless victory，不是只登记 YAML。

## 验证证据

| 门 | 结果 |
| --- | --- |
| 初始 RED | `0/6`，assignment、identity、factory、objective、Boss runtime、dynamic victory 均按缺口失败 |
| 三向 mutation | 删 assignment、错 `base_enemy_id`、错角色语义各触发 1 个精确失败；反向补丁恢复后 3 文件 SHA-256 与变异前一致 |
| Ch18 focused | `6/6 PASS` |
| Ch17 + Ch18 | `12/12 PASS` |
| Phase 2 data | `162/162 PASS` |
| mainline application | `183/183 PASS` |
| test-contract migration | `PASS`：expect 删 1/增 37、用例删 0/增 6、登记 1 条 |
| analyze / format | `No issues found`；1636 files、0 changed |
| 候选标准 Gate | 白名单、禁改文件、commit、clean、隔离 full `5975/5975`、analyze、format 均 PASS；receipt 因 0 个 `lib/` 改动 SKIP；原始总结果仅 `FAIL: test_deletions`，该 1 行由专用迁移 Gate 覆盖 |
| 合并态 focused / analyze / format | `12/12` / `No issues found` / 1637 files、0 changed |
| merge exact-SHA CI | run `33833220808`，HEAD `c905e50aa8494e5ca2ba557c34a88c231e3ec544`；codegen、format、analyze、coverage tests、ratchet、上传与 macOS build 全部成功 |

## 边界

- 未修改 `data/stages.yaml`、`data/numbers.yaml`、技能、Boss 数值、掉落、奖励、经济、正文、schema/saveVersion、GDD 或 CLAUDE。
- 未处理 Ch13、Ch19+、塔或 M8/M9。
- 真人桌面、视觉、音频、手感与 Windows 均未执行，继续 `DEFERRED`；自动化不代签。
- 下一完整工程门仍按既定顺序为 Ch19 `86/105 → 91/105`；本批治理尾仍须提交并通过最终 exact-SHA CI。
