# 今晚挂机任务 10：闭关地图专属小产出

## 目标

让五张闭关地图各自拥有一类轻量特色产出，强化地图选择差异；所有产出仍走现有闭关配置与结算路径，在线/离线同源，不新增加速、buff、刷新或日课机制。

## 分支

`codex/night-tier2-seclusion-map-yields`

## 验收标准

- 五张闭关地图的 `base_outputs.item_outputs_per_hour` 均有配置，且至少各有一类特色物品。
- 产出数值只写在 `data/numbers.yaml`，Dart 不新增数值常量。
- `SeclusionService.computeOutputs` 和 `completeRetreat` 继续复用同一产出模型，离线回归估算与在线收功一致。
- 补 targeted tests 覆盖五图特色产出、配置引用、入库与 `actualRewards`。
- 跑 targeted tests 和 touched-file analyze。

## 任务切片

1. 读取项目约束与闭关现状，确认不依赖暂缓的爬塔/Boss 分支或未稳定桃花岛接口。
2. 写本计划文件并提交。
3. 在 `data/numbers.yaml` 为五张地图补齐/调整轻量特色产出。
4. 补 `test/features/seclusion/application/seclusion_service_test.dart` 回归测试。
5. 跑 targeted tests/analyze，修正问题。
6. 更新计划恢复点与 `PROGRESS.md`，小提交收口。

## 当前恢复点

- 状态：执行中。
- 最后完成：已读 `AGENTS.md`、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/spec/playability_phase2_backlog.md`、`/Users/a10506/Desktop/挂机武侠_已否任务.md`；已创建分支。
- 下一步：提交计划文件，然后补闭关地图特色产出配置与测试。
- 已跑验证：尚未运行。
- 阻塞项：无。
