# 2026-06-29 今晚挂机任务 01：桃花岛产物消费补齐 + 疗伤丹战后接入

## 目标

- 补齐桃花岛加工产物的终端消费，让锻材、开锋辅材、行囊补给不再只是库存孤儿。
- 战斗结束后提供疗伤丹直接处理伤势的入口，复用既有疗伤丹道具效果和库存扣减。
- 严守在线=离线；不做日课、限时刷新、氪金或留存机制。

## 分支

- `codex/night-taohua-consumption-healing`

## 验收标准

- 锻材、开锋辅材、行囊补给至少各有一条真实消费路径，并能被用途反查识别。
- 疗伤丹战后入口只在有库存且有可治疗伤势时出现；点击后原子扣减库存并更新角色伤势。
- 不新增在线加速、日课、限时刷新、付费或通知式留存逻辑。
- 定向测试覆盖新增消费路径、用途反查、战后疗伤入口或服务逻辑。
- `flutter analyze` 与相关 targeted tests 通过；若无法完成，恢复点写明原因。

## 任务切片

1. 读取必读文档、确认分支/worktree、写本计划文件。
2. 盘点现有桃花岛产物、装备强化/开锋、背包使用、战后结算入口，确定最小接线点。
3. 接入锻材、开锋辅材、行囊补给的终端消费和用途反查。
4. 接入战后疗伤丹入口，复用 `ItemUseService`，避免重复实现治疗逻辑。
5. 补定向测试并跑 targeted tests/analyze。
6. 更新恢复点、提交小切片 commit，汇报分支、提交、验证与剩余风险。

## 当前恢复点

- 状态：完成。计划切片提交 `3cd1eed1`，实现切片提交 `8d5915f3`。
- 最后完成：锻材接入强化附加消耗；开锋辅材接入开锋持久化扣料；行囊补给接入清轻伤道具效果；战后疗伤丹面板接入普通胜负 overlay、主线胜利 dialog、爬塔胜利 dialog；用途反查已覆盖新增消费路径。
- 下一步：主窗口复核/合并；如需体验验收，可真机检查强化、开锋和战后结算面板的排版密度。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`；`flutter analyze` 通过；`flutter test --no-pub -j1 test/features/equipment/application/enhancement_service_test.dart test/features/equipment/application/enhancement_persist_test.dart test/features/equipment/application/forge_persist_test.dart test/features/equipment/application/forging_service_test.dart test/features/inventory/item_use_service_test.dart test/features/inventory/item_usage_lookup_service_test.dart` 68/68 通过。
- 阻塞项：无。
