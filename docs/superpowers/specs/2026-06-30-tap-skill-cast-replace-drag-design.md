# 两段点选替代拖招技能释放 — 设计

**日期**: 2026-06-30
**分支**: 待开 worktree（feat/tap-skill-cast）
**状态**: 设计稿，待实装
**类型**: 战斗交互 / 表现层重构（零碰数值结算）

## 1. 背景与动机

当前战斗技能介入用「长按技能按钮 → 拖引导线到敌头像 → 松手出手」的拖招手势。真玩反馈四点不满，用户全部认同需换：

- **手感别扭/不顺**：长按 ~500ms 才触发、引导线对不准头像、松手判定飘。
- **操作太重/慢**：长按+拖动流程拖沓，够不上挂机游戏的随手介入。
- **鼠标端体验差**：发布目标 Windows 鼠标操作，拖拽更偏触屏隐喻，桌面端不如点击自然。
- **想换更有策略/参与感的形式**。

战斗爽感主旋律（memory `feedback_wuxia_combat_satisfaction_principle`）= 即拖即放立即出手 + 参与感 + 打击爽感。本次**保留「立即出手的打击爽感」**（底层 `interveneNow` 不变），仅替换前端触发方式，改为更轻快、鼠标友好、保留选目标策略性的**两段点选**。

## 2. 当前机制（file:line，实装前已核，非凭记忆）

- **手势入口**：`lib/features/battle/presentation/battle_screen.dart` L2573-2587 `GestureDetector`（onLongPressStart/Move/End/Cancel），L2576 onDragStart 取按钮中心为引导线起点。
- **命中**：`hitTestEnemyId()` L126-131 纯函数；`_collectEnemyTargets()` L981-998 GlobalKey 矩形收集；敌头像 keys L369。
- **介入结算**：UI `_onSkillDragEnd` L953 → `_onSkillCommand` L892 → `interveneNow` 策略层 `lib/features/battle/domain/strategy/default_ground_strategy.dart:198-226`（借 AP=1000 预支，`_resolveAction` 立即结算，**唯一战斗真相源，消费 rng**）。
- **自动/手动模型**：`auto_play_mode.dart` `AutoPlayMode{auto, interactive}`；`stage_auto_play_pref.dart` per-stage override；首通强制 interactive；`allowPlayerIntervention` 门控 L215。
- **暂停基建（关键，复用）**：`_isPaused` L298 / `_togglePause` L466 / `_startTimer` 内 `_isPaused` gate L441（H3 兜住所有重启路径）/ hit-stop 临停 Timer 范式 L668。
- **快进**：`_rushToActorId` L336（拖招触发快进到出手，C5，L1197/1204-1208）；`_isFastForward`（玩家快进键，独立）。
- **拖招状态**：`_dragSkill`/`_dragCharId`/`_dragOrigin`/`_dragPointer`/`_hoveredEnemyId` L325-336。
- **技能优先级（不动）**：`battle_ai.dart` L84-150，pending(manualTargetId) > 破招 > 人剑合一 > boss 阶段新招 > 强力 > 普攻；目标选择 L40-80（single 技 manualTargetId 优先于一切，L54-58）。
- **测试**：`test/features/battle/presentation/battle_drag_skill_test.dart`（UI）、`test/features/battle/domain/strategy/intervene_now_test.dart`（策略）、`test/features/battle/intervene_determinism_test.dart`（种子）；route `battleDragLive`/`battleDragPreview`（`lib/features/debug/application/visual_route.dart` L117-123）。

## 3. 设计

### 3.1 交互模型（B · 两段点选）

删除 L2573-2587 长按拖手势，技能按钮改 `onTap`：

- **单体技** `onTap` → 进入「待发态」：`_pendingSkill`/`_pendingCharId` 置位 + `_isPaused=true` 软暂停 + 按钮高亮 + 敌头像浮现可选标记。点敌头像（复用 `hitTestEnemyId`/`_collectEnemyTargets`）→ `interveneNow(charId, skill, targetId)` → 清待发态 + `_isPaused=false` 恢复 tick。
- **AOE/大招** `onTap` → 直接 `interveneNow(charId, skill, 无 targetId)`，**不进待发态**（沿用 AOE 忽略落点语义）。
- **取消（三条都支持）**：① 再点该技能按钮 ② 点战斗区空白处 ③ ESC 键 → 清待发态 + 恢复 tick，**不出手、不消费 rng**。

### 3.2 软暂停态（复用现有基建）

复用现有 `_isPaused`，不引入新暂停机制：进待发态 `_isPaused=true`（`_playTimer?.cancel()` + gate 兜所有重启路径），出手/取消 `_isPaused=false` + `_startTimer()`。暂停期间零 tick、零产出、零计时（纯 UI 等输入）。

### 3.3 删除项（决策：删快进，用户拍板）

- `_rushToActorId` 及其快进联动（C5，L1197 / L1204-1208）**整体删除**——软暂停让点敌即时出手，无需「加速跳到出手」。
- 引导线绘制（`_dragOrigin`/`_dragPointer`）、`_hoveredEnemyId` 拖动悬停高亮、`onLongPress*` 回调全删。
- `_isFastForward`（玩家手动快进键）**保留**，与拖招无关。
- 实装时 grep `_rushToActorId` / `rushActorId` 全引用，确保无残留（可能牵连快进 UI 提示、`battleDragPreview` 的 rushActorId 预置、相关测试）。

### 3.4 保留框架（零改）

`interveneNow` 策略层语义、`hitTestEnemyId`/`_collectEnemyTargets`、`AutoPlayMode`/`StageAutoPlayPref`/首通 interactive/`allowPlayerIntervention` 门控、`battle_ai` 优先级与目标选择全部不动。**只换 interactive 下的介入手段**。

### 3.5 玩家预期与视觉反馈

- 技能按钮加**类型角标**（单体 / 群体小图标），点一次自然学会差异。
- 待发态：按钮高亮 + 敌头像可选标记，明确「现在点敌人」，替代原引导线的视觉引导。
- ESC 取消（桌面友好，决策：加，用户拍板）。
- 色板守 memory `feedback_paper_vs_dark_text_color_palette`（深底战斗 UI 用 `WuxiaColors.text*`，勿误用浅底墨色）。

### 3.6 红线 / 不变性

纯交互+表现层，**零碰** numbers.yaml / saveVer / schema / 伤害结算 / 三系锁死 / 在线=离线。`interveneNow` 结算路径不变 → 种子确定性测原样过。软暂停 = UI 等输入（战斗为即时模拟，非离线挂机计时），暂停期间零产出零推进，不违 §5.5。

## 4. 范围

### 4.1 In scope

- `battle_screen.dart` 手势层替换为点击 + 待发态 + 软暂停接线 + 取消（含 ESC）。
- 删 `_rushToActorId` / 引导线 / 拖动状态。
- 技能按钮类型角标 + 待发态视觉反馈。
- 测试：`battle_drag_skill_test` → `battle_tap_skill_test` 重写；route `battleDrag*` → `battleTap*`。
- 如需新文案（角标/提示）走 `UiStrings` 集中层，不散写中文。

### 4.2 Out of scope（非目标）

- 不改 `interveneNow` / `battle_ai` / `AutoPlayMode` 框架语义。
- 不改任何数值 / 掉落 / 结算。
- **不加**「默认目标快捷 / 双击即放」等 A/C 方案融合（YAGNI，需要再议）。
- 不改 `_isFastForward` 手动快进键。

## 5. 验收

- `flutter analyze` 0 issue。
- 全量 `flutter test --no-pub -j1` 绿（`battle_tap_skill_test` 新测 + `intervene_now_test`/`intervene_determinism_test` 不变全过）。
- 真机 `flutter run -d macos`：单体两段点选出手 / AOE 一键 / 三种取消（再点/空白/ESC）/ 软暂停顿感可接受 / 角标可读。
- 视觉验收 route `battleTapLive` / `battleTapPreview` 截图。

## 6. 决策记录

| 决策点 | 选定 | 出处 |
|---|---|---|
| 释放形式 | B 两段点选（点技能→点敌；AOE 一键） | 用户从 A/B/C 选，2026-06-30 |
| 去拖放动机 | 手感/操作重/鼠标端/策略参与，四点全中 | 用户多选 |
| 待发态节奏 | 软暂停等输入（复用 `_isPaused`） | 用户拍板 |
| `_rushToActorId` 快进 | 删 | 用户拍板 |
| ESC 取消 | 加 | 用户拍板 |
| AOE/单体区分 | 角标 + 点一次自学 | 默认 |

## 7. 风险

- **软暂停顿感**：战斗很快（avgTicks 3-4），待发态停顿是否突兀需真机校（可接受则不调）。
- **类型角标视觉**：浅纸/深底色板别混，真机验。
- **删 `_rushToActorId` 牵连**：L1197/1204 周边及 `battleDragPreview` rushActorId 预置，实装时 grep 全引用确保无残留。
