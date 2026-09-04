# Phase 2 M7 第二十一章内容迁移审计（2026-09-04）

## 结论

第二十一章 `stage_21_01..05` 已从既有 StageDef 接入 typed production catalog、runtime binding 与 production encounter factory。候选 `5e91fd9fa9a7aafe3f78c6c94f317f47daaeb377` 经 no-ff merge `5ca94415fc482db69c3831de8b934071aacaee1a` 进入 `main` 与 `origin/main`；该 merge exact-SHA CI run `33862752755` 已全部成功。

本批只把主线 typed catalog 工程水位从 `96/105` 推进到 `101/105`。塔保持 `0/49`，五处 legacy 生产接缝仍开放，正式 M7 未关闭，Phase 2 正式里程碑仍为 `1/10`。

## 生产接线

| 关卡 | 生产 encounter / actor | 冻结语义 |
| --- | --- | --- |
| `stage_21_01` | `ch21_encounter_01_pass_soldier` / `ch21_s01_pass_soldier` | 单敌、刚猛、defeat-target |
| `stage_21_02` | `ch21_encounter_02_veteran_ferryman` / `ch21_s02_veteran_ferryman` | 单敌、阴柔、defeat-target |
| `stage_21_03` | `ch21_encounter_03_sword_debate_descendant` / `ch21_s03_sword_debate_descendant` | 单敌、灵巧、defeat-target |
| `stage_21_04` | `ch21_encounter_04_path_blocking_old_servant` / `ch21_s04_path_blocking_old_servant` | Boss、刚猛、defeat-commander、vulnerability `0.16`、三相位 |
| `stage_21_05` | `ch21_encounter_05_talisman_following_youth` / `ch21_s05_talisman_following_youth` | Boss、灵巧、any(defeat-commander, survive 10 ticks)、vulnerability `0.10 / 0.05`、三相位 |

21-04 保留既有蓄力技与三段 phase。21-05 保留 `skill_shan_wai_wu_shan` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId`，并保留一、二周目 vulnerability `0.10 / 0.05`。typed objective 明确使用 `completion_rule: any`，保留“击败 Boss 或守满 10 ticks 均胜利”的既有语义。

真实消费链为 `GameRepository → combatAssignment/combatEncounter/combatRuntimeBinding → Phase0aMainlineRepositoryRuntimeBindingAdapter → createFreshPhase0aMainlineEncounter → director/objective/reducer`。五关均由真实 factory 构建并完成 dynamic headless victory，21-05 额外验证 survive 替代胜利，不是只登记 YAML。

## 验证证据

| 门 | 结果 |
| --- | --- |
| 初始 RED | `0/6`，assignment、identity/role、factory、objective、Boss runtime、dynamic victory 均按缺口失败 |
| 三向 mutation | 删 assignment、错 `base_enemy_id`、错角色语义各触发精确失败；反向补丁恢复后 3 文件 SHA-256 与变异前一致 |
| Ch21 focused | `6/6 PASS` |
| Ch20 + Ch21 | `12/12 PASS` |
| Phase 2 data | `180/180 PASS` |
| mainline application | `183/183 PASS` |
| test-contract migration | `PASS`：expect 删 1/增 45、用例删 0/增 6、登记 1 条 |
| analyze / format | `No issues found`；1736 files、0 changed |
| 候选标准 Gate | 白名单、禁改文件、commit、clean、隔离 full `5993/5993`、analyze、format 均 PASS；receipt 因 0 个 `lib/` 改动 SKIP；原始总结果仅 `FAIL: test_deletions`，该 1 行由专用迁移 Gate 覆盖 |
| 合并态 focused / full / analyze / format | `12/12` / `5993/5993` / `No issues found` / 1737 files、0 changed |
| merge exact-SHA CI | run `33862752755`，HEAD `5ca94415fc482db69c3831de8b934071aacaee1a`；codegen、format、analyze、coverage tests、ratchet、上传与 macOS build 全部成功 |

## 边界

- 未修改 `data/stages.yaml`、`data/numbers.yaml`、技能、Boss 数值、掉落、奖励、经济、正文、schema/saveVersion、GDD 或 CLAUDE。
- 未处理 Ch13 剩余四关、塔或 M8/M9。
- 真人桌面、视觉、音频、手感与 Windows 均未执行，继续 `DEFERRED`；自动化不代签。
- 下一唯一权威任务为 Ch13 生态边界决策审计；审计本身不增加 `101/105` 分子，不在本批启动 Ch13 实现。
