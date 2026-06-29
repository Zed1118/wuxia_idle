# 第 4 梯队 · 开锋槽 3 专属技展示升级

## 范围

- 只增强装备详情中的第三开锋槽专属技只读展示。
- 不改专属技候选数量、开锋写入、战斗触发、数值或掉落逻辑。
- 避开已否任务:不做装备目标追踪、部位缺口提醒、材料替代路径、碎片来源聚合。

## 验收标准

- 已开锋第三槽且类型为 `specialSkill` 时,装备详情显示“器物绝招”信息段。
- 信息段展示招式名、触发条件、流派、目标、内力/冷却和适配角色/流派。
- 未开第三槽、第三槽非专属技或 `specialSkillId` 为空时不显示该段。
- Dart 中文文案集中在 `UiStrings` / enum 本地化层。
- Widget test 覆盖显示与隐藏路径。

## 验证

- `flutter test test/features/inventory/presentation/equipment_detail_screen_test.dart`
- `flutter analyze`
