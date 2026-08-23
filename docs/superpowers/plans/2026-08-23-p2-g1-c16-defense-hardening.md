# P2-G1-C16 防御反制加固候选

## 目标

在既有纯领域防御解析候选上补齐 C16 的安全合同：保持闪避 → 化解 → 投射物重定向 → 护盾/格挡 → 基础减伤的确定性顺序，明确 `projectileRedirect` 与 `counterDamage` 不同输出，并让标准化反击默认不可递归、不可暴击、不可吸血、不可附带受击反伤。

## 本切片

- `defense_resolution.dart` 新增 typed `CounterEffectAllowlist`，默认空；只有显式枚举的能力例外才能打开暴击、吸血或受击后反伤标记。
- 反击同时受单次 `counterUpperBound` 与可选每秒 `counterPerSecondUpperBound` 的较小者约束；重定向始终无反击伤害且单独标记 `projectileRedirect`。
- 测试覆盖分支独立性、优先级、每秒上限、默认关闭与 typed allowlist 例外、nonRecursive 安全合同。

## 生产接线边界

本批只冻结纯领域候选，未改 reducer/application/data/UI，也未接入生产战斗路径。后续若接线，必须由公共 API 统一消费该解析器，禁止 adapter 重复结算同一命中。

## 验证

- `dart format lib/features/battle/domain/phase0a/defense_resolution.dart test/features/battle/domain/phase0a/defense_resolution_test.dart`
- `flutter analyze lib/features/battle/domain/phase0a/defense_resolution.dart test/features/battle/domain/phase0a/defense_resolution_test.dart`
- `flutter test --no-pub test/features/battle/domain/phase0a/defense_resolution_test.dart`

## 风险与后续

当前环境运行 targeted Flutter test 报工具自身 `Bad state: No element`，需主审环境复跑；未因此扩大改动范围。生产接线、数据化上限来源与命中事件审计留待后续候选。
