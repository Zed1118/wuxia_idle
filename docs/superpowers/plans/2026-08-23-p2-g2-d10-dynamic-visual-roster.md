# P2 G2 D10：动态视觉名册工厂

## 目标

为 `Phase0aVisualRoster` 增加全量 `combatants` 工厂，覆盖 reserve / warning / active，保持 `fromMapping` 兼容；不修改生成文件、data、host 或 UI 行为。

## 分支与所有权

- 分支：`codex/phase2-g2-d10-dynamic-visual-roster-20260823`
- 允许文件：`lib/features/battle/presentation/phase0a/phase0a_visual_roster.dart`、对应新测试、本文档。

## 验收标准

- 玩家必须唯一存在，使用既有 founder fallback；敌人使用 snapshot `iconPath`。
- 空白 `playerId` / `actorId`、重复 actor、玩家缺失/重复、敌人 null/空白 asset 均 fail closed。
- `fromMapping` 委托 `fromCombatants`，既有主线映射口径保持兼容。
- 只运行 targeted visual roster 测试、现有 mainline wiring 回归与 scoped analyze；禁止 build_runner / 全仓生成。
- `git diff --check` 通过，工作区 clean，tip 使用 `[READY]` 封签。

## 当前恢复点

- 状态：已接管 Qoder 候选，完成边界审查、修正空白输入校验并通过定向验证；准备提交 READY。
- 最后完成：确认无生成物，仅两项候选改动；补充本计划文件。
- 下一步：提交 `[READY][CODEX][P2-G2-D10]`，保持工作区 clean 交接主控复审。
- 已跑验证：`dart format`；visual roster + stage content mapper 共 36 tests passed；scoped `flutter analyze` 0 issues；`git diff --check` passed。
- 阻塞项：无。
