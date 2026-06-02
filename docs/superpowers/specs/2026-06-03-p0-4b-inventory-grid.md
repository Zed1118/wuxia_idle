# P0-4b 仓库格子化 · spec + TDD plan

> 1.0 出版美术 pass · Phase C「仓库→背包/装备架」· §5.4 + 外部 UI 指导 §4.3/P0-4
> 状态:**spec 就绪待用户拍板升 xhigh 实装**(布局重写 · 主观视觉留用户/Codex 在场)
> 注:P0-4a(装备详情大图 cover→contain)已 2026-06-02 `baa6070` 做掉,本批仅仓库 Tab。

## 现状(`inventory_screen.dart`)

2 Tab(装备/物料)。装备 Tab = 按 tier 的纵向 `ListView` + `ExpansionTile`(`_TierGroup` L146)+ 单行水平 `_Row`(L196):56×56 小图标(`BoxFit.cover` 裁细长武器)+ 部位 + 强化级 + 名 + 共鸣。**像数据库列表,非背包/装备架**(外部指导 §4.3 直指)。缺图 errorBuilder 返 `SizedBox.shrink()` → 空白。

## 真缺口(对照「武器图 + 部位分组 + 阶位边框 + 可装备状态一眼可读」)

| 项 | 现状 | 缺口 |
|---|---|---|
| 布局 | 纵向列表 + 水平 Row | **列表→网格/装备架**(本批主项) |
| 部位分组 | 仅按 tier 分组 | **按 slot 分组(兵器/护具/饰物)** |
| 装备图 | 56px cover 裁切 | **格子大图 contain + tier 边框** |
| 可装备状态 | 仓库未显示 | **境界锁灰化 + 锁图标**(§5.3 · 复用角色面板 L743/784 体例) |
| 缺图兜底 | SizedBox.shrink 空白 | **复用 P0-3 `_EquipGlyph` 占位** |

## 设计决策(自主拍板 · 2026-06-03)

- **布局**:装备 Tab 改「**按 slot 分组的网格**」——三段(兵器/护具/饰物),每段标题 + `Wrap`/`GridView` 排装备格子(每格 ~96-110px 方块)。tier 仍可作格子边框色区分,不再做 ExpansionTile 主轴。
- **格子内容**:iconPath 图(contain)+ tier 色边框(`tierColorForEquipment`)+ 强化级徽章(右上)+ 师承遗物标记(`isLineageHeritage`)+ **可装备状态**:`eq.isEquippableAtRealm(activeCharacter.realmTier)` false → 灰化 + 锁图标(沿角色面板体例)+ 缺图走 `_EquipGlyph`。
- **复用抽取**:把 P0-3 的 `_EquipGlyph`(+可选 `_EquipmentSlotShell`)从 `character_panel_screen.dart` **抽到 `lib/shared/widgets/equipment_glyph.dart`** 供两处复用(避免 copy)。这步先做(纯重构,0 行为变化,现有角色面板测试守)。
- **可装备状态依赖 activeCharacter**:仓库当前角色上下文 —— 查 inventory_screen 是否已有 activeCharacterProvider;无则取 active 队首/玩家主角(实装时确认,spec 留决策点)。

## TDD plan(3 task)

### Task 1: 抽 `_EquipGlyph` → shared `equipment_glyph.dart`(纯重构)
- 新 `lib/shared/widgets/equipment_glyph.dart`:`EquipGlyph`(public · tierColor + slot · 同 P0-3 实现)。
- `character_panel_screen.dart` 删私有 `_EquipGlyph`,import 共享版,调用点改 `EquipGlyph`。
- verify:character_panel 全测维持绿(34 测)+ analyze。commit。

### Task 2: 仓库装备 Tab 网格 + 部位分组 + 可装备状态
- 测试(inventory_screen_test 加):
  - `装备 Tab 按部位分组显示(兵器/护具/饰物三段标题)`:seed 3 件不同 slot → 三段标题 findsOneWidget。
  - `装备格子显图标(iconPath)`:真 defId → `find.byType(Image)` findsWidgets。
  - `境界不达装备灰化 + 锁图标`:高阶装备 + 低境界角色 → `find.byIcon(Icons.lock_outline)` findsWidgets。
  - `缺图走 EquipGlyph 占位不崩`:未知 defId → takeException isNull。
- 实装:`_List`/`_TierGroup`/`_Row` 重构为 `_SlotGroupSection`(按 slot 过滤 + 标题)+ `_EquipmentGridTile`(方格 · 沿 _EquipmentSlotShell 体例 + 状态层)。`GridView`/`Wrap` 排布。
- verify:全量 test + analyze。commit。

### Task 3: Codex@Pen 截图验收派单
- 路由:仓库 VISUAL_ROUTE(查现有 inventory 验收屏,无则加)。
- 验收门:三部位分组段 + 格子装备图 + tier 边框分阶 + 强化徽章 + 境界锁灰化/锁图标 + 缺图占位 + 1280×720 宽屏不空洞不 overflow。

## 红线 / 约束
- §5.3 境界锁可装备判定走 `isEquippableAtRealm`(已有,不重写);仓库只显状态不放穿戴入口(穿戴在角色面板 picker)。
- 缺图走 errorBuilder + EquipGlyph(asset_audit gate);0 硬编码数值/文案。
- 物料 Tab 不动。先做 Task 1 抽取(零行为)降风险,再做网格。
