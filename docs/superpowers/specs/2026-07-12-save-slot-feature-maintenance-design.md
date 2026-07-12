# 存档槽启动 Feature 维护编排设计

## 背景

`IsarSetup._ensureSaveData()` 在数据库打开、SaveData 迁移之外，还直接导入并调用：

- `BossMemoryService.backfillFromProgress`；
- `EquipmentCatalogService.reconcileFromInventory`。

两者都是 feature application 行为，而不是数据库生命周期或 schema 迁移。
这使 `lib/data/isar_setup.dart` 反向依赖 feature implementation，并让所有直接
`IsarSetup.init()` 的测试隐式承担 feature 启动顺序。

## 目标

- `IsarSetup` 只负责数据库打开/关闭、schema、SaveData、迁移、恢复、槽位和
  数据完整性修复。
- save-slot application 在真实槽位打开后统一执行战绩册与兵器谱的幂等维护。
- 保持原先“单项失败不阻塞进入存档、输出可追踪 debug 日志”的行为。

## 方案

新增 `SaveSlotStartupService`：

1. `openSlot(slotId)` 先调用 `IsarSetup.switchSlot(slotId)`；
2. 然后对当前 Isar/slot 运行 `runFeatureMaintenance()`；
3. 战绩册与兵器谱各自独立 `try/catch`，一个失败不阻止另一个；
4. `SaveSelectScreen` 的已有档与新档两条真实入口都改用该 service。

`repairCharacterLevels` 继续留在 `IsarSetup`，因为它修复 Isar 字段默认值未应用
造成的数据完整性问题，属于 storage maintenance，不是 feature 回填。

## 非目标

- 不修改 schema、saveVersion、数据库文件名、用户目录或恢复文件算法。
- 不改变 migration、备份、原子替换、失败回滚或多槽隔离语义。
- 不把所有 `IsarSetup.init()` 测试迁到新 service；底层测试应继续只测 storage。
- 不引入新的配置、缓存或公共 adapter interface。

## 测试策略

- RED：新增启动 service 测试，期望真实槽位打开后同时回填旧 Boss 进度和库存装备。
- GREEN：实现 service 并迁移两条 production 入口。
- 回归：战绩回填、兵器谱回填、SaveSelect UI、Isar 迁移、恢复失败回滚和多槽测试。
- 架构守卫：`isar_setup.dart` 不再导入 feature application 文件。

