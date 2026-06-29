# Fourth Tier: Equipment Drop Detail V2 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan step by step. Keep the checklist updated as work progresses.

**Goal:** 强化胜利结算中的新装备掉落说明,展示来源、可用角色、境界门槛、锁定建议,延续现有锁定/来源/稍后处理动作,但不新增装备目标追踪或缺口标记。

**Architecture:** 只改 `StageVictoryContent` / `_EquipmentDropRow` 展示层,通过生产调用传入当前战斗角色列表作为只读上下文。装备定义、掉落概率、锁定写库逻辑与装备详情页不变。

**Tech Stack:** Flutter widget tests, existing `EquipmentFactory`, `EquipmentSourceLookup`, Wuxia UI.

## CLAUDE.md §8.2 Checklist

- [x] 开工前读取 `docs/spec/rejected_task_registry.md`。
- [x] 确认未重复已否任务:不做终局装备目标追踪,不做装备部位缺口提醒,不做关卡掉落缺口标记。
- [x] 独立分支 / worktree:`codex/fourth-equipment-drop-detail-v2`。
- [x] 小切片实现,保持可恢复。
- [x] Targeted tests 通过。
- [x] `flutter analyze` 通过。
- [x] 提交前说明红线影响。

## Scope

- [x] `showStageVictoryDialog` 增加只读 `equipmentHintCharacters`。
- [x] `_EquipmentDropRow` 展示:
  - 来源摘要保留。
  - 境界门槛。
  - 当前队伍中可穿戴角色。
  - 锁定建议。
- [x] `UiStrings` 集中新增文案。
- [x] 现有锁定/常用/来源/稍后按钮行为不变。

## Tests

- [x] `stage_victory_dialog_test.dart`:装备掉落显示门槛、可用角色、锁定建议。
- [x] `stage_victory_dialog_test.dart`:队伍无达标角色时显示暂无达标。
- [x] 既有锁定/来源/稍后测试保持通过。

## Verification

- [x] `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart`
- [x] `flutter analyze`

## Red Lines

- 不改掉落概率、装备属性、锁定写库逻辑或装备来源配置。
- 不做装备目标追踪、部位缺口提醒、掉落缺口标记。
- 不新增出售/分解入口。
