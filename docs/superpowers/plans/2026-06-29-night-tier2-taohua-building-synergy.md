# 2026-06-29 今晚挂机任务 16：桃花岛建筑协同加成

## 目标

- 为桃花岛建筑加入固定协同加成，让原料建筑能稳定支援对应加工建筑。
- 协同只影响桃花岛产出结算，不引入随机、限时刷新、日课、登录奖励或在线专属收益。
- 协同数值全部走 `data/numbers.yaml`，Dart 只解析和套用配置。

## 分支

- `codex/night-tier2-taohua-building-synergy`

## 验收标准

- `taohua_island` 配置能声明固定建筑协同，至少覆盖灵泉→丹房、铁匠厂→打造台、木工坊→铸造台三条链路。
- `IslandProductionService.settle` 在线/离线共用同一公式；一次性结算与分段结算在既有不变性测试中仍一致。
- 协同配置有红线校验：引用建筑必须存在、目标必须是加工建筑、加成不能为负或异常膨胀。
- 桃花岛主屏能看见当前建筑受到的协同来源和百分比，不散写中文文案。
- targeted tests 与 touched-file analyze 通过；完成后更新恢复点并提交。

## 任务切片

1. 读取必读文档，确认 worktree/分支，写本计划文件。
2. 扩展 `TaohuaIslandConfig`：新增固定建筑协同定义、yaml 解析和校验。
3. 扩展 `IslandProductionService`：加工产速按协同乘区计算，保持纯函数和在线=离线。
4. 在 `numbers.yaml` 配置固定协同链路，并补解析/红线/不变性/产量测试。
5. 在桃花岛主屏加工建筑卡展示协同提示。
6. 跑 targeted tests/analyze，更新 `PROGRESS.md` 与恢复点，按小切片提交。

## 当前恢复点

- 状态：计划已建立，尚未改代码。
- 最后完成：已读取 AGENTS.md、CLAUDE.md、GDD.md、PROGRESS.md、`docs/spec/playability_phase2_backlog.md`、`/Users/a10506/Desktop/挂机武侠_已否任务.md`；确认 CodeGraph 未初始化，改用 `rg`/定点读文件。
- 下一步：扩展配置模型与结算公式。
- 已跑验证：无。
- 阻塞项：无。
