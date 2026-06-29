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

- 状态：完成。计划切片提交 `108349f0`；实现切片待提交。
- 最后完成：新增 `taohua_island.synergies` 固定配置与红线校验；配置三条链路：铁匠厂→打造台、灵泉→丹房、木工坊→铸造台；`IslandProductionService.settle` 将协同作为加工产速与用料效率同乘区，仍由同一纯函数保证在线=离线；桃花岛主屏加工建筑卡显示当前协同来源与百分比。
- 下一步：主窗口复核/合并；如需体验验收，可真机看桃花岛建筑卡协同行的信息密度。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`（成功，当前 build_runner 版本提示该参数已忽略，写出 112 个 gitignored outputs）；`flutter analyze lib/features/taohua_island/domain/taohua_island_config.dart lib/features/taohua_island/application/island_production_service.dart lib/features/taohua_island/presentation/taohua_island_screen.dart lib/shared/strings.dart test/features/taohua_island/island_production_service_test.dart test/features/taohua_island/island_offline_online_invariant_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/taohua_island_screen_test.dart` 0 issue；`flutter test --no-pub -j1 test/features/taohua_island/island_production_service_test.dart test/features/taohua_island/island_offline_online_invariant_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/taohua_island_screen_test.dart` 60/60 passed。
- 阻塞项：无。
