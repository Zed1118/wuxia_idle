# Phase 2 M7 第十七章内容迁移审计（2026-09-04）

## 当前结论

第十七章 `stage_17_01..05` 的 StageDef、12 份正文与 5 个敌人图标均完整，但 production assignment、encounter 与 runtime binding 原为 `0/5`。本批已把真实缺口由 `0/5 → 5/5`，全主线 typed catalog 工程集成水位由 `76/105 → 81/105`。

候选 `ce32ab9736f74135dcc25854db1daccac25997ab` 已经 no-ff merge `b2fe4e43d060ffdb631c413dfca7846aca830611` 进入 `main` 与 `origin/main`；merge exact-SHA CI run `33824064696` 为 `completed/success`。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

实时审计确认五关均为冻结的单一对手，StageDef、Boss、技能、正文与图标完整，且无既有 typed route、分支或任务登记重叠。17-04 的 `lingQiao` 是既有签署会话对早期 spec 的明确修正，不是本批新决策；第十三章既有 25-actor 路径冲突继续隔离。

| stage | 对手 | 流派 | Boss / 特殊风险 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_17_01` | `enemy_zongShi_shahai_ta_sha_ke` | lingQiao | 否 | defeat target |
| `stage_17_02` | `enemy_zongShi_shahai_heifeng_daoke` | gangMeng | 否 | defeat target |
| `stage_17_03` | `enemy_zongShi_shahai_shoucheng_laozu` | yinRou | 否 | defeat target |
| `stage_17_04` | `enemy_zongShi_shahai_juan_sha_shou` | lingQiao | 章中 Boss，蓄力技 + 两相位，无 vulnerability | defeat commander |
| `stage_17_05` | `enemy_zongShi_shahai_linglu_ren` | lingQiao | 末 Boss，蓄力技 + 两相位 + vulnerability `0.20` | defeat commander |

冻结战斗规模为 `1 / 1 / 1 / 1 / 1`。复用层只提供 AI、姿态与表现资源；StageDef 的姓名、原图、流派、全技能、Boss phase、charge 与 vulnerability 保持原值。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss mechanics 与 dynamic host 均真实缺失。
- 删除 `stage_17_01` assignment，loader 精确拒绝无 stage 引用的 encounter（1 条红）。
- 将 `stage_17_05.base_enemy_id` 错绑为 17-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致（1 条红）。
- 将 17-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同精确 2 条红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `8eb0a3270212bbd47d622057f397953e1d61e2668466ac0fd8f0ae850f865d33`、assignments `11c0834e83c01bcc7f7b6304e63907a0ef88d1fbcf49c8c5da1fce3f9f625234`、encounter `e642460d47c5bc96bf38991009166fd6ade0c2af95afbcba67d99f181e6eed92`、runtime `66e6b7aaf385e162ae8eb9285691d242bd1a5d29736c2e965c0da81e0c32368f`、test `2dbbd74b9c60b22d20ecf78b3a2784fe8d18a2f6b0fbd7eeb9c30ce65b861b6a`。

## 当前验证

| 门 | 结果 |
| --- | --- |
| StageDef / 正文 / 敌人图标 | `5/5` / `12/12` / `5/5` |
| production assignment / encounter / runtime | `5/5 / 5/5 / 5/5` |
| 第十七章 targeted | `6/6` |
| 第十六、十七章 adjacent | `12/12` |
| 三向 mutation | `1/1/2` 条精确转红，全部恢复 |
| Phase 2 data | `156/156` |
| mainline application | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | 候选 `1730/0`；合并态 `1731/0` |
| 测试契约迁移门 | `expect 删 1 / 增 35；用例删 0 / 增 6；登记 1`，`PASS` |
| 候选标准 Gate | 原始结论 `FAIL: test_deletions`；forbidden files、commit、clean、隔离 full `5965/5965`、analyze 与 format 通过；whitelist 与 receipt 按任务形态跳过 |
| 合并后 targeted / analyze / 持锁整仓 | `6/6` / `No issues found` / `5965/5965`，错误块 `0`，锁已释放 |
| merge exact-SHA CI | run `33824064696`，head `b2fe4e43d060ffdb631c413dfca7846aca830611`，test 与 macOS build 全部 steps 成功 |

## 验收边界

内容实现为 `da352eea`，旧合同迁移为 `8ebb9c1f`，测试契约登记为 `784c276e`，候选冻结为 `ce32ab97`。标准 Gate 对旧第十六章精确水位迁移原样报 `test_deletions`；专用测试契约迁移门已经核对登记并 `PASS`，不改写标准 Gate 原始结论。工程内容已集成并通过精确 SHA CI，但不冒充正式 M7、Phase 2 或真人验收。下一完整工程门为第十八章 `81/105 → 86/105`。
