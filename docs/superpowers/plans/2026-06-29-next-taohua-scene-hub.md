# 桃花岛场景化主屏计划

## 目标

把桃花岛主屏从建筑卡片列表升级为可点建筑的场景式界面。当前美术素材未齐，本切片先落布局底座、建筑热区、选中建筑详情面板和可回退结构。

## 分支

`codex/next-taohua-scene-hub`

## 边界

- 不改服务层、结算层、数值配置、离线收益规则。
- 不改产量、升级成本、协同加成、配方逻辑。
- 中文 UI 文案只进 `UiStrings` / 既有合法集中层。
- 现有建筑卡操作能力复用，不新增存档字段。

## 验收标准

- 主屏首屏出现桃花岛场景画布，7 个建筑以可点击热区呈现。
- 点击建筑热区后，下方详情面板切换到对应建筑，仍可升级 / 选配方 / 查看仓储与协同。
- 保留整备建议、岛务工程碑、码头占位等现有只读面板。
- targeted widget/domain tests 与 `flutter analyze` 通过。

## 任务切片

- [x] 读取项目约束与桃花岛现状。
- [x] 写入本计划文件。
- [x] 新增场景画布、建筑热区与选中详情结构。
- [x] 补集中 UI 文案与 widget 测试。
- [x] 运行 targeted tests 与 `flutter analyze`。
- [ ] 更新恢复点并提交。

## 当前恢复点

- 状态: 待提交。
- 最后完成: 已将桃花岛主屏改为场景画布 + 7 个建筑热区 + 选中建筑详情面板，旧建筑卡能力复用；补充 `UiStrings` 文案与 widget 覆盖。
- 下一步: 提交本分支。
- 已跑验证:
  - `flutter test test/features/taohua_island/taohua_island_screen_test.dart --reporter expanded`：22/22 passed。
  - `flutter test test/features/taohua_island/island_production_service_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/island_offline_online_invariant_test.dart --reporter expanded`：39/39 passed。
  - `flutter analyze`：No issues found。
- 阻塞项: 无。
