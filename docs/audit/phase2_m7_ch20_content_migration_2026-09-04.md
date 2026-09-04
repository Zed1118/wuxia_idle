# Phase 2 M7 第二十章内容迁移审计（2026-09-04）

## 结论

第二十章 `stage_20_01..05` 已从既有 StageDef 接入 typed production catalog、runtime binding 与 production encounter factory。候选 `b28088eff48c6520ebfc3f3c662b612c00ccffef` 经 no-ff merge `4ff2157a1d75fac406c2fbef164ad0cf4a122c1a` 进入 `main` 与 `origin/main`；该 merge exact-SHA CI run `33851259205` 已全部成功。

本批只把主线 typed catalog 工程水位从 `91/105` 推进到 `96/105`。塔保持 `0/49`，五处 legacy 生产接缝仍开放，正式 M7 未关闭，Phase 2 正式里程碑仍为 `1/10`。

## 生产接线

| 关卡 | 生产 encounter / actor | 冻结语义 |
| --- | --- | --- |
| `stage_20_01` | `ch20_encounter_01_horse_changer` / `ch20_s01_horse_changer` | 单敌、灵巧、defeat-target |
| `stage_20_02` | `ch20_encounter_02_beacon_keeper` / `ch20_s02_beacon_keeper` | 单敌、阴柔、defeat-target |
| `stage_20_03` | `ch20_encounter_03_wall_mender` / `ch20_s03_wall_mender` | 单敌、刚猛、defeat-target |
| `stage_20_04` | `ch20_encounter_04_returning_veteran` / `ch20_s04_returning_veteran` | Boss、刚猛、defeat-commander、vulnerability `0.18`、三相位 |
| `stage_20_05` | `ch20_encounter_05_gate_opening_old_general` / `ch20_s05_gate_opening_old_general` | Boss、阴柔、defeat-commander、vulnerability `0.12 / 0.06`、三相位 |

20-04 保留 `skill_gangmeng_chuanshuo_nei_ult` 蓄力技与三段 phase。20-05 保留 `skill_gu_cheng_kai` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId`，并保留一、二周目 vulnerability `0.12 / 0.06`。

真实消费链为 `GameRepository → combatAssignment/combatEncounter/combatRuntimeBinding → Phase0aMainlineRepositoryRuntimeBindingAdapter → createFreshPhase0aMainlineEncounter → director/objective/reducer`。五关均由真实 factory 构建并完成 dynamic headless victory，不是只登记 YAML。

## 验证证据

| 门 | 结果 |
| --- | --- |
| 初始 RED | `0/6`，assignment、identity、factory、objective、Boss runtime、dynamic victory 均按缺口失败 |
| 三向 mutation | 删 assignment、错 `base_enemy_id`、错角色语义各触发精确失败；反向补丁恢复后 3 文件 SHA-256 与变异前一致 |
| Ch20 focused | `6/6 PASS` |
| Ch19 + Ch20 | `12/12 PASS` |
| Phase 2 data | `174/174 PASS` |
| mainline application | `183/183 PASS` |
| test-contract migration | `PASS`：expect 删 1/增 39、用例删 0/增 6、登记 1 条 |
| analyze / format | `No issues found`；1643 files、0 changed |
| 候选标准 Gate | 白名单、禁改文件、commit、clean、隔离 full `5987/5987`、analyze、format 均 PASS；receipt 因 0 个 `lib/` 改动 SKIP；原始总结果仅 `FAIL: test_deletions`，该 1 行由专用迁移 Gate 覆盖 |
| 合并态 focused / full / analyze / format | `12/12` / `5987/5987` / `No issues found` / 1644 files、0 changed |
| merge exact-SHA CI | run `33851259205`，HEAD `4ff2157a1d75fac406c2fbef164ad0cf4a122c1a`；codegen、format、analyze、coverage tests、ratchet、上传与 macOS build 全部成功 |

## 边界

- 未修改 `data/stages.yaml`、`data/numbers.yaml`、技能、Boss 数值、掉落、奖励、经济、正文、schema/saveVersion、GDD 或 CLAUDE。
- 未处理 Ch13、Ch21、塔或 M8/M9。
- 真人桌面、视觉、音频、手感与 Windows 均未执行，继续 `DEFERRED`；自动化不代签。
- 下一完整工程门按既定顺序为 Ch21 `96/105 → 101/105`；随后回到 Ch13 决策审计。本批治理尾仍须提交并通过最终 exact-SHA CI。
