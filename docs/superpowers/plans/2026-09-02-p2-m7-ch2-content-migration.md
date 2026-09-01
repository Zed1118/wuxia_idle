# P2 M7 第二章内容迁移计划

## 结果合同

- 单一结果：复用已集成的第二章四职能生态与既有普通关/小 Boss/章末 Boss 模板，把 `stage_02_03..05` 接入真实 typed catalog、runtime binding 和生产 encounter host，使第二章从 `2/5` 推进到 `5/5` migrated。
- 固定分母：主线 `105` 关；本批基线 `11/105`，目标 `14/105`，第二章目标 `5/5`。塔 `49` 层与其余 `91` 个主线缺口不在本批。
- 当前关键阻塞：M2/M4/M5/M6 真人与 Windows 验收继续挂账，所以本批只形成 M7 工程切片，不关闭正式 M7。
- 成本上限：一个第二章数据切片；若需要新生态、新数值、存档迁移或第二套 runtime，则停止扩面。

## 验收门

1. `stage_02_03..05` 均有唯一 migrated assignment、encounter 与 runtime binding，且基敌严格等于各自 `StageDef.enemyTeam.single`。
2. `stage_02_03` 复用既有 25 总量/10 active 四职能普通关模板；25 个 authored 目标全部击败才完成。
3. `stage_02_04` 复用既有 3 人 commander 模板；主敌与两名随从全部击败才完成。
4. `stage_02_05` 复用既有 2 人章末 commander 模板；只有 authored commander 保留姓名、美术、技能、蓄力与阶段身份。
5. 三关均经 `createFreshPhase0aMainlineEncounter` 构造，不落回 legacy mapper；双向破坏证红、targeted、analyze、format、持锁全量和 Gate 完成后才可冻结 READY。

## 禁改边界

- 不改 `numbers.yaml`、`stages.yaml`、奖励、掉落、经济、解锁、存档 schema/version、角色属性或技能。
- 不新增美术，不扩 Isar，不启动塔或其余章节迁移。
- 真人桌面节奏、辨识度和 Windows 验收继续挂账；自动测试不代签。

## 当前恢复点

- 分支：`codex/p2-m7-ch2-content-migration-20260902`；基线：`f3076cef045145cc17cc2d4098f5fba0161998e1`。
- 实现提交：`136b467d`。三关生产接线已完成，第二章定向与相邻回归 `20/20`。
- 初始真红：新增测试 `4/4` 因 assignment/encounter/factory/runtime 缺失失败。
- 破坏证红：删除 02_03 assignment 精确 `1` 项失败；把 02_05 commander 错绑随从精确 `2` 项失败；均已反向补丁还原并复绿。
- 扩展回归 `292/292`、analyze `0`、format `1716/0`、持锁整仓全量 `5879/5879`（`[E]=0`）已通过。
- 下一步：冻结最终候选并在精确 tip 运行标准 Gate；正式 M7 与真人目检保持未关闭。
