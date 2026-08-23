# P2-G1-C17A 心魔战败物理伤势豁免

## 目标

修复生产战斗结算中“心魔战败仍进入通用伤势层”的冲突：心魔失败继续施加内息紊乱和主修修炼度 ×0.90，永久内力、境界层与装备语义不回退，但不新增轻伤或重伤；普通 Boss 战败行为保持不变。

## 实现

- `CombatResolutionService.resolveSnapshot` 仅在 `!resolvedVictory && stageDef.stageType == StageType.innerDemon` 时跳过 `InjuryService.applySettlementInjuries`。
- 保留既有 `InnerDemonService.applyFailurePenalty` 路径及当前主修修炼度 safe_default（×0.90）。
- 本切片不清理 `numbers.yaml` 或 typed def 死字段，交由 C17B 串行处理。

## 证红与验证

- 心魔失败生产结算：永久内力不变、主修层不变、修炼度按 ×0.90、内息紊乱存在、轻伤/重伤均不增加。
- 普通 Boss 战败回归：轻伤与重伤仍按原合同产生。
- `flutter pub get`；生成的 `.g.dart` 仅为忽略构建产物。
- `dart format`、`flutter analyze`、定向 `flutter test --no-pub`。

## 恢复点与风险

- 未接入新 API，未修改 data/GDD/CLAUDE/PROGRESS；只改变生产结算的 stageType 豁免条件及相关测试。
- 装备 battleCount 仍遵循通用战斗结算的既有递增语义；本修复不引入装备回退或新装备伤势字段。
- C17B 仍需单独处理 numbers/typed def 死字段，不在此切片扩大范围。
