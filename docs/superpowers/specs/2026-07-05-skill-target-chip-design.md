# 技能目标快捷选择栏 · 设计

**日期**：2026-07-05
**分支**：`worktree-skill-target-chip`
**范围**：战斗界面单体技能的目标选择交互（纯表现层）

## 目标

优化单体技能的目标指定手感，减少鼠标行程：

- **只有 1 个存活敌人**时：所有单体技能「点击即放」，默认打该敌，不进待发态、不软暂停、不需要选目标。
- **有 ≥2 个存活敌人**时：点技能后，在**该技能方块正上方**冒出 2-3 个敌人的选择栏（chip），直接点选放招，不用把鼠标移到右侧战场点敌人头像。

## 当前行为（改动基线）

`lib/features/battle/presentation/battle_screen.dart` 现有两段点选：

- 点单体技能 → 进「待发态」（`_pendingSkill`/`_pendingCharId`）+ 软暂停（冻结节拍）→ 到右侧战场点敌人头像（`_onEnemyTap`）指定目标 → 出手。
- 群体技（`TargetType.aoe`）→ 一键即放，AI 打全体。
- 待发态下再点同一技能 = 取消（`_clearPending`）。

出手命令统一走 `_onSkillCommand(characterId, skill, {targetId})`。

## 设计

### 1. 行为规则（改 `_onSkillTap`）

单体技能（非 aoe）点击时，按存活敌人数分流：

| 存活敌人 | 行为 |
|---|---|
| 0 | 战斗已结束，忽略（守卫） |
| 1 | 直接对该敌出手：`_onSkillCommand(characterId, skill, targetId: 唯一敌.characterId)`。**不进待发、不暂停、不选目标**。 |
| ≥2 | 进待发态 + 软暂停（沿用现有），并在该技能方块正上方渲染敌人选择栏。 |

- **群体技（aoe）不变**：无论几个敌人，一键即放打全体（没有单目标可选）。
- **再点同一技能 = 取消**（沿用 `_clearPending`）。
- **右侧战场点敌头像仍可用**（备选路径，沿用 `_onEnemyTap`），与选择栏并存。

### 2. 选择栏渲染：浮层锚定（不撑坏底栏）

底栏 `_BottomBar` 固定高 124px、技能格在横向滚动 Row 内，直接在格子上方塞 Column 会被裁剪。改用浮层锚定：

- State 加 `final LayerLink _skillTargetLink = LayerLink();`
- 待发中的那个技能格用 `CompositeTransformTarget(link: _skillTargetLink, child: ...)` 包裹。
- 外层主 `Stack`（`build()` 顶层）加一个 `CompositeTransformFollower`：
  - `link: _skillTargetLink`
  - `targetAnchor: Alignment.topCenter` / `followerAnchor: Alignment.bottomCenter` / `offset: Offset(0, -8)`
  - 仅当 `_pendingActive`（或验收路由 preview pending）且存活敌人 ≥2 时渲染。
  - child = `_TargetChipStrip`。

浮层脱离底栏布局流，精确贴住被点方块正上方，滚动/布局不受影响。方块靠屏幕边缘时选择栏可能轻微横向溢出——v1 接受，居中对齐；如真机觉得碍事再 clamp。

### 3. 新组件

- **`_TargetChip`**：小敌人头像 + 一条细血条（`currentHp / maxHp`）。
  - 点击 → `onSelectTarget(enemyId)`（= `_onEnemyTap`，复用）。
  - hover → `onTargetHover(enemyId, hovering)`（= `_onPendingEnemyHover`，复用，联动右侧战场同一敌人高亮）。
- **`_TargetChipStrip`**：存活敌人的 `_TargetChip` 横向 Row，按 `slotIndex` 升序排（对齐战场视觉顺序）。
  - 软暂停期间敌人不会死亡，chip 列表在选择期间稳定。

### 4. 数据流

- `_BottomBar` 已持有 `state`（含 `rightTeam`）、`pendingSkillId`、`pendingCharacterId`。新增下传：`layerLink`（挂到待发格）。
- `_TargetChipStrip` 放在外层 Stack，直接读 State 的存活敌人 + 复用 `_onEnemyTap`/`_onPendingEnemyHover` 回调；不必把敌人列表塞进 `_BottomBar`。

## 影响面 / 红线

**纯表现层。** 出手命令路径 `_onSkillCommand` 一字不改——1 敌自动打它 = 手点它，发出的命令完全相同。

- 零碰 `numbers.yaml` / 结算 / schema / `saveVer` / 三系锁死 / 在线=离线 / §5.1 反主流。
- chip 若引入任何中文串走 `UiStrings`（当前设计只有头像+血条，无文案）。
- 不改 `BattleState` / `battle_ai` / `default_ground_strategy`（`pendingTargets` 写入路径不变）。

## 文件 / 测试

- 改 `lib/features/battle/presentation/battle_screen.dart`（单文件）。
- 新增 `test/features/battle/battle_screen_target_chip_test.dart`：
  1. **1 敌**：点单体技能 → 立即出手（命令发出至该敌）、**不进待发态**、不暂停。
  2. **≥2 敌**：点单体技能 → 进待发态 + 选择栏显 N 个 chip → 点某 chip → 对该敌出手。
  3. **aoe**：无论几个敌人 → 立即放，不显选择栏。

测试节奏（v1.29）：自包含表现层改动 → targeted + `flutter analyze`；不跑全量（除非最终合并批末）。

## 非目标（YAGNI）

- chip「依次」错峰淡入动画：先做静态 Row，真机看后决定是否加。
- 选择栏内「AI 推荐目标」预高亮：不做。
- 边缘 clamp / 自适应换行：v1 居中接受轻微溢出。

## 规模

局部表现层 + widget 测，单文件。`high` 档足够，不需 xhigh。
