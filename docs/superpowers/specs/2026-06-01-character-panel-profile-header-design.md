# 角色页档案化（半身像档案头）设计

> 出版美术 Phase A 收尾切片之一 · 范围 = 仅 `character_panel`（用户拍板 A 范围 + 选项 2 半身像档案头）
> 上游：`docs/PUBLISHING_ART_PASS_1_0.md` §5.4「角色立绘占更高视觉权重 + 基础属性做成武侠档案，不像表格」

## 目标

把角色页头部从「窄色条 + 姓名 + 境界」+ 独立属性 section 两张分离卡片，
合成**一张武侠档案卡**：立绘 + 身份信息 + 4 基础属性聚成「档案」观感，
正对 §5.4 验收门「看到角色页应感觉是人物档案，不是表格」。

**零新美术**：复用已入库立绘（祖师 founder.png / 弟子图）+ 上一切片落地的
`Character.portraitPath` 字段 + `PortraitFrame` 共享 widget。无图角色优雅退化。

## 范围

### IN

- 新 `_ProfileHeaderCard`（替换现 `_TopBar`，折并现 `_AttributesSection`）：
  - 左：`PortraitFrame(portraitPath: character.portraitPath, size: 110, borderColor: schoolColor)`
  - 右档案列：
    1. 姓名（`fontSize 22 / w600 / textPrimary`，题字感）
    2. 境界·层（`EnumL10n.realm`）+ **流派名**（流派色点缀 — 补现状只有色条无文字的缺 · 用 `EnumL10n` 流派本地化）
    3. 墨色 hairline 分隔（`WuxiaColors.border` 1px）
    4. 4 基础属性横排（根骨/悟性/身法/机缘 · 复用现 `_LabeledValue`）
  - 沿用现 `_PanelCard` 宣纸外壳
- 删 `_AttributesSection`（内容折进档案头）+ `_Body` 中移除其调用
- 流派色 = 现成 `WuxiaColors.schoolColor` · **不新建色板**（§17.3）

### OUT（明确非目标）

- 装备槽 `_EquipmentSlotTile`：**已有完整阶位视觉**（`tierColorForEquipment` 边框 + 阶名 + 强化级染色 + 共鸣段）→ 不动
- `_DerivedStatsSection`（5 派生数值）/ `_TechniqueSection` / `_LineageSection` / `_BreakthroughBlockerSection` → 不动
- 装备列表 `inventory_screen` / 装备详情 `equipment_detail_screen` → 本切片范围外（后续独立 spec）
- 其余养成屏（师徒/闭关）/ 抽剩余 `Wuxia*` 组件 → 范围外

## 关键决策

1. **4 属性折进档案头**（用户拍板），不保留独立属性 section → 一张内聚档案卡。
2. **半身像档案头**（选项 2），立绘 110×110 有存在感但不喧宾夺主；非选项 3 hero 大图（吃垂直空间 + 强依赖立绘质量，玩家无图大面积空框）。
3. **流派名补文字**：现 TopBar 仅 4px 色条无流派文字，档案头补「刚猛/灵巧/阴柔」本地化文字 + 流派色，信息更完整。
4. 无立绘角色（player 自身若 portraitPath=null / NPC）：`PortraitFrame` 已内建退化（null → 占位框，加载失败 → avatarFill），不破布局。Demo 中玩家=祖师有 founder.png，常态有图。

## 组件边界

- `_ProfileHeaderCard extends StatelessWidget`，入参 `Character character`（与现 `_TopBar` 同签名）。
- 自包含：内部算 `schoolColor`、读 `character.{name, realmTier, realmLayer, school, attributes, portraitPath}`，无新 provider 依赖。
- 立绘渲染委托 `PortraitFrame`（已测覆盖）；属性渲染委托现 `_LabeledValue`。

## 测试纪律（守 baseline 1627 测 / 0 analyze）

- character_panel 现有 widget 测须保持绿；属性从独立 section 移到档案头 → **断言定位随之调整**（find 属性 label 仍命中即可，不假设父级 widget 树）。
- 新增/调整断言：
  - 档案头渲染 `PortraitFrame`（portraitPath 非空时含 `Image`）
  - 4 属性 label（根骨/悟性/身法/机缘）仍可见
  - 流派名文字显示（school 非空角色）
- 遵 memory `feedback_isar_widget_test_deadlock`：纯渲染测用 `test()` / `testWidgets()` 不进 `writeTxn`；character 构造走内存对象不落 Isar 即可。
- 遵 `feedback_listview_widget_test_viewport`：若测命中滚动需 `setSurfaceSize`。
- `flutter analyze` 0 + 全量 `flutter test` 绿。

## 验收

- **CLI**：analyze 0 + 全量测绿 + 档案头 widget 测断言通过。
- **视觉**（Mac 本地 Codex）：`VISUAL_ROUTE` 直达角色页，截图判「档案卡」观感 —
  立绘 + 姓名题字 + 境界/流派 + 4 属性聚成一卡，不再是表格堆叠。无图角色不空框破布局。

## 风险

- **属性测定位漂移**：现有测若按 widget 树路径 find 属性，重组后可能 fail → 改为按 label 文本 find（语义断言，memory `feedback_red_line_test_semantics`）。
- **档案头高度**：立绘 110 + 姓名 + 境界 + 分隔 + 属性行 ≈ 150px，单卡不溢出；若窄窗换行验布局。
- ~~`EnumL10n` 流派本地化是否存在~~ **已确认**：`EnumL10n.school(TechniqueSchool)` 存在（`enum_localizations.dart:20`）+ `Character.school` 类型为 `TechniqueSchool?`（`character.dart:41`）→ 直接用，不硬编码中文。
