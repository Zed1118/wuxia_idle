# P0-3 角色面板身份区重排 · spec + TDD plan

> 1.0 出版美术 pass · Phase C「角色卡」· §5.4「档案不像表格」
> 上游:`docs/handoff/wuxia_idle_ui_gap_guidance_2026-06-02.md` §5.3 + PUBLISHING_ART_PASS §20.4 Phase C
> 状态:**spec 就绪待用户拍板升 xhigh 实装**(沿 P0-2 spec→plan→实装节奏 · 主观视觉留用户/Codex 验)

## 现状(2026-06-01 `2a4dba7` 已做)

`character_panel_screen.dart` 区块序:`_ProfileHeaderCard`(立绘 PortraitFrame 110 + 姓名 + 境界·层 + 流派名 + 4 属性聚卡)→ `_BreakthroughBlockerSection` → `_DerivedStatsSection` → `_EquipmentSection` → `_TechniqueSection` → `EncounterSkillSection` → `_LineageSection`。
身份区(立绘+姓名+境界+流派+属性)**已档案化达标**。

## 真缺口(对照 Phase C「角色卡 = 立绘+身份+装备外观+主修+成长瓶颈」)

| 项 | 现状 | 缺口 |
|---|---|---|
| 立绘/身份/4 属性 | ✅ ProfileHeaderCard | 0 |
| **装备外观一眼可读** | ❌ `_EquipmentSlotTile`(L805) **纯文字**:槽名/强化级/阶名/共鸣 + tier 边框,**无装备图** | **本批主项 ①** |
| 主修心法仪式感 | 🟡 `_MainTechniqueTile`(L1048)有进度条但像表格行 | P0-3b(主观·缓) |
| 成长瓶颈进度 | ❌ `_BreakthroughBlocker`(L353)纯文字拦截 | P0-3b(需数据管线·缓) |

## 设计决策(自主拍板 · 2026-06-03)

- **① 装备外观可视化(本批 · ready-to-implement)**:`_EquipmentSlotTile` filled 分支顶部加装备图(`EquipmentDef.detailPath`),contain ~44px + errorBuilder 兜底(缺图→tier 色首字占位,沿 asset_audit + battle CharacterAvatar 体例)。tier 边框 / 强化徽章 / 阶名保留。
  - **def 解析**:`GameRepository.instance.getEquipment(eq.defId)?.detailPath`(sync · 已 loaded · 沿 battle_providers `equipmentDefLookup` 体例)。测试 setUpAll 已加载真实 GameRepository。
  - **高度**:共享 `_SlotShell` 固定 88px 被辅修槽复用,**不动**。新建 `_EquipmentSlotShell`(height 128)供装备 3 槽(empty/loading/filled 全用,3 槽对齐)。
- **② 主修仪式感 → P0-3b**:放大 `_MainTechniqueTile`(min-h 120)+ 纸质/半透金底 + 主修名加大。**主观视觉,留用户/Codex 在场时做**。
- **③ 成长瓶颈进度 → P0-3b**:`_BreakthroughBlocker` 加「心魔 X/7」进度条 + 突破按钮。**需心魔通关计数数据管线,单列批次**。

## TDD plan(① · 3 task)

### Task 1: `_EquipmentSlotShell`(height 128)+ empty/占位接入
- 测试(用例 2 维持):3 槽全 null → `find.text('未装备')` findsNWidgets(3) 不破。
- 实装:新增 `_EquipmentSlotShell`(复制 `_SlotShell` 改 height 128 · 同 border/padding/radius),`_EquipmentSlotTile` 所有分支 `_SlotShell`→`_EquipmentSlotShell`。
- verify:scoped test green。commit。

### Task 2: filled 分支加装备图 + errorBuilder 占位
- 测试(新增 2):
  - `装备槽显示装备图(detailPath 非空)`:用真实 defId(`GameRepository.instance.equipmentDefs.values.firstWhere((d)=>d.detailPath!=null).id`)→ `expect(find.byType(Image), findsWidgets)`。
  - `装备槽缺图走占位不崩(默认 test_eq defId)`:`expect(find.text(UiStrings.enhanceLevel(5)), findsOneWidget)` + `takeException isNull`。
- 实装(`_EquipmentSlotTile` data 分支顶部 Column):
  ```dart
  final detailPath = GameRepository.instance.getEquipment(eq.defId)?.detailPath;
  // Column 顶部:
  SizedBox(
    height: 44,
    child: detailPath == null
        ? _EquipGlyph(tierColor: tierColor, slot: eq.slot)
        : Image.asset(detailPath, fit: BoxFit.contain,
            errorBuilder: wuxiaAssetErrorBuilder(
                () => _EquipGlyph(tierColor: tierColor, slot: eq.slot))),
  ),
  const SizedBox(height: 4),
  // ...原有 槽名/强化/阶名/共鸣 行(字号压到 11 省高度)...
  ```
  `_EquipGlyph` = tier 色框 + 槽位首字(剑/甲/饰)占位,沿 PortraitFrame placeholder 体例。
- verify:全量 test + analyze。commit。

### Task 3: Codex@Pen 截图验收派单 doc
- 验收门:3 装备槽显装备图(有图显图/缺图显 tier 色占位)+ tier 边框分阶色 + 强化徽章 + 3 槽高度对齐 + 1280×720 无 overflow。
- 路由:角色面板 VISUAL_ROUTE(查现有 character_panel 验收屏)。

## 红线 / 约束
- 不动共享 `_SlotShell`(辅修槽复用);装备图缺失走 errorBuilder 兜底(§asset_audit gate)。
- 不引新数值/文案硬编码;占位首字走 EnumL10n。
- ②③ 不在本批(主观视觉 + 数据管线,留 P0-3b 用户在场)。
