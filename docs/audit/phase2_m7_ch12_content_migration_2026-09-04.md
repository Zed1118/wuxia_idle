# Phase 2 M7 第十二章内容迁移审计（2026-09-04）

## 当前结论

第十二章 `stage_12_01..05` 的 StageDef 与 13 份正文原已完整，但 production assignment、encounter 与 runtime binding 均缺失。本批已在候选分支把该章真实缺口由 `0/5 → 5/5`，接入 repository、factory、runtime adapter、AI/director、objective 与 reducer 终局链；全主线 typed catalog 候选水位由 `56/105 → 61/105`。

当前仅是工程候选：主线集成水位仍为 `56/105`，正式 M7 仍开放，Phase 2 仍 `1/10`，塔 `0/49`，legacy runtime consumer 退役未完成。真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。

## 审计选择与生产接线

第十二章并非按顺序默认选择。只读审计比较剩余章节后确认：五关正文均明确为单一对手，StageDef、Boss、技能与叙事完整，且无既有 typed route 重叠。第十三章既有 `stage_13_02` 25 actor 生态与“一名知客僧”正文冲突并受 M4 合同约束，未混入本批。

| stage | encounter | StageDef 基敌 | 角色 / 行为 | 目标 |
| --- | --- | --- | --- | --- |
| `stage_12_01` | `ch12_encounter_01_hanjiang_boatman` | `enemy_yiLiu_zhongzhou_hanjiang_chenggao` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_12_02` | `ch12_encounter_02_huaixiang_boxer` | `enemy_yiLiu_zhongzhou_huaixiang_quanshi` | `sect_outer` / 近战直进 | defeat target |
| `stage_12_03` | `ch12_encounter_03_qiushan_porter` | `enemy_yiLiu_zhongzhou_qiushan_tiaoshan` | `sect_lightfoot` / 侧翼突进 | defeat target |
| `stage_12_04` | `ch12_encounter_04_laotie_blacksmith` | `enemy_yiLiu_zhongzhou_laotie_tiejiang` | `sect_lightfoot` / 侧翼突进 | defeat commander |
| `stage_12_05` | `ch12_encounter_05_huangcun_nameless` | `enemy_yiLiu_zhongzhou_huangcun_wuming` | `sect_lightfoot` / 侧翼突进 | defeat commander |

五关冻结为单敌 `1 / 1 / 1 / 1 / 1`。复用层只提供 AI、姿态与表现资源；StageDef 的姓名、原图、流派与全技能保持原值，12-04/05 的 Boss 身份、蓄力技与阶段由精确合同守住。本批未改 `stages.yaml`、`numbers.yaml`、技能、掉落、奖励、经济、正文、解锁、周目或结算 owner。

## RED、变异与恢复

- 初始有效 RED 为 `0/6`：assignment、runtime、factory、objective、Boss identity 与 dynamic host 均真实缺失。
- 删除 `stage_12_01` assignment，loader 精确拒绝无 stage 引用的 encounter。
- 将 `stage_12_05.base_enemy_id` 错绑为 12-04 基敌，runtime loader 精确拒绝与唯一 StageDef enemy template 不一致。
- 将 12-03 actor ID 在 manifest、spawn 与 objective 中同步改名，结构保持闭包，但 exact actor 与 objective 语义合同转红。
- 三次均以反向补丁恢复；最终 SHA-256：manifest `714b7f47da9715300a05348cbc403666e678b2a4bdbcb292fd574edfaaa23786`、assignments `0279e80e060d29153df8156f3e6bfb3f90855b499ac15efc73f842b91c7f582f`、encounter `4f2a17175ebd29fbe9a39a7d93a5168ece2f62e4da3f50b06da9a7d3e67fa68e`、runtime `c64c3402ae1b5a8228fe3969daf9e7b2a79c6db4eaab7cbbb85b694d59a32d5c`、test `8207766a8798d49605522238ac7ed4e67a84c63c06964d335e51875f4eda43cc`。

## 已完成验证

| 门 | 结果 |
| --- | --- |
| 第十二章 targeted | `6/6` |
| 第十一、十二章 adjacent | `12/12` |
| Phase 2 data | `132/132` |
| mainline application | `183/183` |
| 测试契约迁移门 | `expect 删 1 / 增 32；用例删 0 / 增 6；登记 1`，`PASS` |

第十一章旧测试的全局精确水位 `56` 改为已集成下限 `>=56`，第十二章新测试精确守住候选 `61`。删除已登记在 `p2-m7-ch12-content-migration-20260904.yaml`。analyze、format、持锁全量、标准 Gate 与受控集成仍待执行；未发生的结果不预写。

## 提交与验收边界

内容实现为 `0fdeac4c`，旧合同迁移为 `d2b76765`，登记表为 `864b9b8e`。主代理已复核实际 diff、五组 production consumer、StageDef 基敌与正文单敌边界，当前无已知 P0/P1；这不冒充独立 agent 或真人验收。
