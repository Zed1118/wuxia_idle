# Phase 2 M7 第十六章内容迁移审计（2026-09-04）

## 当前结论

第十六章 `stage_16_01..05` 的 StageDef、13 份正文（1 个 chapter 文件、12 个 stage 文件）与 5 个敌人图标均完整，但 production assignment、encounter 与 runtime binding 原为 `0/5`。本批已把真实缺口由 `0/5 → 5/5`，全主线 typed catalog 候选水位由 `71/105 → 76/105`。

当前仍是分支候选，不冒充 `main`/`origin/main` 集成。正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

实时审计确认五关均为冻结的单一对手，StageDef、Boss、技能、正文与图标完整，且无既有 typed route 或任务登记重叠。第十三章既有 25-actor 路径冲突继续隔离。

| stage | 对手 | 流派 | Boss / 特殊风险 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_16_01` | `enemy_zongShi_liangzhouci_songguan_jiubu` | gangMeng | 否 | defeat target |
| `stage_16_02` | `enemy_zongShi_liangzhouci_heishi_shoujing` | yinRou | 否 | defeat target |
| `stage_16_03` | `enemy_zongShi_liangzhouci_xiliang_xingke` | lingQiao | 否 | defeat target |
| `stage_16_04` | `enemy_zongShi_liangzhouci_xiliang_youqijiang` | lingQiao | 章中 Boss，无相位 | defeat commander |
| `stage_16_05` | `enemy_zongShi_liangzhouci_jieguan_ren` | gangMeng | 末 Boss，蓄力技 + 两相位 | defeat commander |

冻结战斗规模为 `1 / 1 / 1 / 1 / 1`。`16_04` 正文中的马队只是场景叙事，不改写成群战。复用层只提供 AI、姿态与表现资源；StageDef 的姓名、原图、流派与全技能保持原值，16-05 的 `skill_tie_ma_bing_he`、两相位与入相蓄力机制必须由精确合同守住。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均真实缺失。
- 删除 `stage_16_01` assignment，loader 精确拒绝无 stage 引用的 encounter（1 条红）。
- 将 `stage_16_05.base_enemy_id` 错绑为 16-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致（1 条红）。
- 将 16-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同精确 2 条红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `d4b8fd5bb409b5d74585e17b5530d05f3885352854919d584a684fed07da3732`、assignments `59e71eacbfe6a38def378e6f9a1627dd1b546946814ca67644ef963468b6919c`、encounter `6c8311a4c7782e9073d7b561803a1d5c4b44815abbb0bdaa7b81bc15b8a0ab9f`、runtime `1dfc7cc1328038d933d6f47c75a3764cd33094df0eeb74f9b4ee10af7ddfb10e`、test `a01eae88ae5e9de731e1a3a4d29b42e3755c00db11492bba2c8722ecf3922e60`。

## 当前验证

| 门 | 结果 |
| --- | --- |
| StageDef | `5/5`，全部单敌 |
| 正文 | `13/13` |
| 敌人图标 | `5/5` |
| 第十六章 targeted | `6/6` |
| 第十五、十六章 adjacent | `12/12` |
| 三向 mutation | `1/1/2` 条精确转红，全部恢复 |
| production assignment / encounter / runtime | `5/5 / 5/5 / 5/5` |
| 任务登记重叠 | `0` |
| 基线 exact-SHA CI | run `33803760075`，head `bf60ec04e28a5bab09163f749613d9aeab26bce7`，全部 jobs/steps 成功 |
| Phase 2 data | `150/150` |
| mainline application | `183/183` |
| `flutter analyze --no-pub lib test tool` | `No issues found` |
| `dart format .` | `1729 files (0 changed)` |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`，`PASS` |
| 持锁整仓 / 标准 Gate | 待运行 |

## 验收边界

内容实现为 `7e41f106`，旧合同迁移为 `c551832b`，测试契约登记为 `511d8e9d`。当前绿色证据是分支候选，不冒充 `main`/`origin/main` 集成、正式 M7、Phase 2 或真人验收。
