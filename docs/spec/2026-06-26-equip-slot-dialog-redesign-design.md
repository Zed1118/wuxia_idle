# 装备槽对话框重做 · 一步到位 + 全量对比（design）

> 2026-06-26 · brainstorm 拍板（用户全采纳推荐 + 两点定制：一步到位 / 全量对比 / 两栏布局）
> 范围 = 第八阶段后续「装备 UI」批（#3 弹窗居中 + #4 换装属性差异），**纯表现层**，0 改战斗数值/saveVer。
> 队伍解锁靠后（#2）、问鼎九霄塔剧情（#1）另起 spec，随后做。

## 1. 问题

点角色面板装备槽 → `showModalBottomSheet` 贴底弹出（截图 `17:01:28` 确诊局促）：
- 已装备态先弹 `_EquipQuickActionSheet`（更换/强化/开锋/典故/卸下 5 项菜单），点「更换」再二次弹 `_EquipPickerSheet` 列表 —— 两步、贴边、不美观。
- `_EquipPickerSheet` 候选列表只显「名 + 阶 · 强化等级」，**无属性对比** → 玩家换装看不出亏不亏。

## 2. 目标

点装备槽 **一步到位** 进一个居中、全量对比的装备管理界面：左栏候选列表（带快速 diff），右栏「当前 ▸ 候选」全量对比，操作（强化/开锋/典故/卸下）收成顶部图标。

## 3. 落点（现状 file:line）

- `character_panel_screen.dart:955` `_tappableSlot` showModalBottomSheet（宿主）
- `character_panel_screen.dart:981` `_EquipQuickActionSheet`（5 项菜单，本次**移除**，操作收成图标行）
- `character_panel_screen.dart:1090` `_EquipPickerSheet`（候选列表，本次**重做**为两栏对话框）
- `equipment_detail_screen.dart:313` `_StatRow` / `481` 渲染体例（复用参考）
- `CharacterDerivedStats.effectiveEquipment{Attack,Hp,Speed}(eq, numbers)`（实战值，已存在）

## 4. 设计

### 4.1 宿主：居中 Dialog

`_tappableSlot` onTap：`showModalBottomSheet` → `showDialog` + `Dialog`（外套 `WuxiaPaperPanel`）。
- 桌面 `maxWidth = 640`、`maxHeight = 屏高 × 0.75`；不再分空槽/已装备两个 sheet，统一进 `EquipSlotDialog`。
- 滚动列在 `Flexible` + 约束高度内（防 WuxiaPaperPanel 无界高度塌，memory `feedback_wuxia_paper_panel_scroll_tile`）。

### 4.2 EquipSlotDialog（新 widget · 两栏）

```
┌─────────────────────────────────────────────┐
│ 槽名 · 当前装备名        [强化][开锋][典故][卸下][×] │  ← 顶部操作图标行(已装备态)
├───────────────────┬─────────────────────────┤
│ 候选列表(左 ~44%)  │ 全量对比(右 ~56%)        │
│ · 名 阶 强化       │  「当前 ▸ 候选」          │
│   攻↑12 血↓0 速↑3  │  实战攻  3100 ▸ 3220 ↑   │
│ · …(灰显不达境界)  │  实战血  ...             │
│   [当前]标注       │  实战速  ...             │
│                   │  强化   +18 ▸ +12 ↓      │
│                   │  品阶   利器 ▸ 重器 ↑    │
│                   │  共鸣   默契 ▸ 生疏      │
│                   │  流派   刚猛 ▸ —         │
│                   │  师承   — ▸ 遗物         │
│                   │  开锋槽 破甲+200/—/— ▸    │
│                   │        吸血+150/攻+80/—  │
│                   │        [ 确认更换 ]       │
└───────────────────┴─────────────────────────┘
```

**左栏候选行**（沿用现 `_EquipPickerSheet` itemBuilder 逻辑）：
- 名 + `EnumL10n.equipmentTier` + `enhanceLevel` + 内联 effective 攻/血/速 mini-diff（↑绿/↓红/灰平）。
- §5.3 `isEquippableAtRealm` 不达 → 灰显 + 锁图标（不可选，不进右栏对比）。
- 队内他人穿戴 → 标注（沿用 `equipWornByOther`）。`[当前]` 标注当前件。
- 选中态高亮；点候选 → 右栏刷新对比（**选中不立即换装**，换装走右栏「确认更换」）。

**右栏全量对比**（选中候选时）：
- 数值维（实战攻/血/速、强化等级）：当前 ▸ 候选 + delta 箭头配色。
- 类别维（品阶/共鸣阶段/流派/师承遗物）：当前 ▸ 候选并列；品阶/共鸣升 → 高亮升色。
- 开锋槽 ×3：两侧逐槽列出（`EnumL10n.forgingSlotType` + bonusValue，未解锁/空显「—」），不算 delta（非数值可减，列出让玩家判）。
- 底部 `确认更换` → `EquipmentService.equip`（不绕 §5.3 校验；`lockedByRealm` 仍 SnackBar 兜底）。

**空槽态**（无当前件作基线）：右栏初始空提示「选一件查看属性」；选中候选后右栏显候选**绝对实战值**（无 ▸/箭头），底部「装备」。左栏无「卸下」「当前」标注。

### 4.3 纯函数 EquipmentStatDiff（可 TDD）

新 `lib/features/character_panel/domain/equipment_stat_diff.dart`：

```dart
EquipmentComparison equipmentFullDiff({
  Equipment? current,        // 空槽 → null
  required Equipment candidate,
  required NumbersConfig numbers,
});
```

返回结构化结果（widget 只渲染）：
- `isBaseline: bool`（= `current==null` 空槽态；为 true 时渲染层**不画箭头**，只显候选绝对值）。
- `numericRows`: List<{label, currentValue:int?, candidateValue:int, direction: up/down/flat}>
  —— 实战攻/血/速（`effectiveEquipment*`，已是 `int`，直接用）、强化等级。
- `categoryRows`: List<{label, currentText:String?, candidateText:String, highlightUp:bool}>
  —— 品阶（`tier.index` 比较升色）、共鸣（`resonanceStage` 比较）、流派、师承遗物（bool→标记）。
- `forgingCurrent` / `forgingCandidate`: List<String>(长 3, 每槽「类型+值」或「—」)。

口径锁定：`current==null` 时 `isBaseline=true`、numericRows.currentValue=null、direction=flat（无基线不比较，渲染层按 isBaseline 只显候选绝对值不画箭头）；非空槽 direction 由 `candidate-current` 符号定（>0 up / <0 down / =0 flat）。

## 5. 测试

- `equipment_stat_diff_test`（纯函数，新）：
  - 候选攻高/血低 → direction up/down 正确；持平 → flat。
  - `current==null`（空槽）→ currentValue=null、全 up、绝对值正确。
  - 品阶升 → categoryRow.highlightUp=true；共鸣阶段当前→候选文案对。
  - 开锋槽：满槽 vs 空槽 → forging 列表长 3、空槽「—」。
  - effective 取派生乘法链（强化×共鸣×开锋），非裸 base（memory `feedback_redline_test_derived_not_flat`）。
- `equip_slot_dialog_test`（widget，新，ListView 用 `setSurfaceSize` 扩 viewport · memory）：
  - 已装备态：渲染顶部 4 图标 + 左候选 + 选中候选后右栏出「确认更换」。
  - 空槽态：无「卸下」、右栏初始空提示、选中后「装备」。
  - §5.3 灰显候选不可选（点无对比刷新）。
  - 点确认 → `EquipmentService.equip` 调用（轻量测撞 GameRepository config 读 → 防御兜底，memory `feedback_battle_result_path_config_read_crashes_light_test`）。
- 全量 `flutter test` 0 回归。

## 6. 红线 / 范围纪律

- 纯表现层：不写 BattleState、不改 numbers 战斗数值、不动 saveVer、不绕 `equip` 校验（§5.3 锁死）。
- 不显百分比/隐藏属性（§2.1 水墨克制·不显数值焦虑）。
- 中文全走 `UiStrings` / `EnumL10n`（新标签如「确认更换」「选一件查看属性」「实战攻击」等进 UiStrings）。
- YAGNI：不做拖拽换装、不做多角色横向对比、不存对比历史。

## 7. 不在本 spec（随后单开）

- #2 队伍三人解锁靠后：`numbers.yaml disciple_joins` stage_id `01_02→02_05` / `01_04→03_05` + 测断言同步 + 拜入 narrative 时点。
- #1 问鼎九霄 25-30 层剧情：`towers.yaml` narrativeOpeningId/VictoryId + events 文案创作。
