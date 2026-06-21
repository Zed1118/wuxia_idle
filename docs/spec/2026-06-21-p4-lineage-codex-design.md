# 门派谱 1.1（传承族谱档案）· 设计 spec

> 2026-06-21 · P4 长期档案子项 4/6（战绩册✅ 兵器谱✅ 材料经济✅ 之后）
> brainstorm 拍板：范围 B（传承族谱）· 主屏 A（纵向世代卷）· 详情屏只做角色详情 · 飞升入口放屏底
> 阶段：1.0 长线打磨期 · opus xhigh

## 一、目标与定位

把现有「门派谱功能面板」（`character_panel/presentation/lineage_panel_screen.dart`，功能面板风格）升级成一本**可翻阅的传承族谱档案**，与战绩册/兵器谱对齐「江湖四本档案」体例（主屏 + 详情屏 + 主菜单入口 + VISUAL_ROUTE）。做完后四本档案风格统一闭环。

**核心红利：纯展示层升级**——全部从现有 `Character`/`Equipment`/`SaveData` 字段派生，**零新 Isar collection、零 saveVer bump、零迁移**（区别于兵器谱续33 新增 `EquipmentCatalogEntry` collection）。

**关键 UX 现实**：飞升是终局门槛（武圣登峰 + 通关 inner_demon_07 + stage_06_05），故**绝大多数玩家门派谱只有「一代」**（玩家=太祖+弟子），多代是稀有终局态。布局必须「一代为常态、多代能生长」两态都优雅。

## 二、数据来源（全派生 · 零埋点）

| 谱系要素 | 派生自 | 锚点 |
|---|---|---|
| 历代祖师 | `characters` 中 `isFounder==true`，按 `id`（≈`createdAt`）升序 = 世代序（太祖在前） | `character.dart:92 isFounder` |
| 当代标识 | `SaveData.founderCharacterId` | `ascend_service.dart:50` |
| 退隐历代祖师 | `isFounder==true && isActive==false` | `ascend_service.dart:272` |
| 当代门人 | 该代祖师的弟子：`masterId` 链 + `recruitedDiscipleIds` + `lineageRole`(senior/junior/disciple) | `character.dart:86 masterId / 90 lineageRole` |
| 师承遗物 | `equipment` 中 `isLineageHeritage==true`；「传 N 代」= `previousOwnerCharacterIds.length` | `equipment.dart isLineageHeritage` |
| 纪事·弟子拜入 | `birthInGameYear`（江湖 XX 年）+ 来源关（`DiscipleJoinDef` role→stageId 反查） | `character.dart:94 birthInGameYear` / `disciple_join_service.dart:28` |
| 纪事·祖师 | 太祖/第 N 代 + 当代/已退隐（由上面派生） | — |

**不做**：飞升渡劫叙事性「纪事」事件——无埋点记录，属 C 范围。

**世代分组算法**（纯函数，可单测）：以 isFounder 角色按 id 升序为各代锚点；每代「门人」= masterId 指向该代祖师、或在该代区间内招收的弟子。一代时即单段。Demo 常态只有 1 个 isFounder，自然单段。

## 三、主屏：门派谱（纵向世代卷）

原地升级 `lineage_panel_screen.dart`（不新建并行 feature，避免两个门派谱）。

布局：
- 顶部进度行：「传承 N 代 · 门人 M 人」
- 每代一段（自上而下，太祖在顶）：
  - 代系标题条（第一代·太祖 / 第 N 代 + 当代/已退隐标）
  - 祖师卡（立绘 + 名号 + 境界 + 祖师恩泽摘要），点击进角色详情
  - 该代门人卡行（大弟子/二弟子/其他收徒），点击进角色详情
  - 该代传承遗物行（名 + tier 色点 + 传 N 代 chip）
- **屏底：飞升入口**（复用现有 `_AscensionSection` + `AscendService`/`AscensionScreen`，逻辑零改动），资格达成才亮——门派谱=传承之书、飞升=续写传承，概念自洽，功能不丢

视觉约束：唯一色源 `tierColorForEquipment`（遗物）；水墨配色（青/墨/宣纸黄）；`IntrinsicHeight`（WuxiaPaperPanel 滚动列 tile）；`Image.asset` 必带 `errorBuilder`。文件偏大时抽 per-代 widget（`_GenerationSection`）保持单文件聚焦。

空态：无弟子（单人开局未过 stage_01_02）时门人区显「孤身一人，传承待续」（文案进 UiStrings）。

## 四、详情屏：角色详情（祖师/弟子共用）

新建 `lineage_character_detail_screen.dart`（character_panel feature 下）。内容：
- 立绘（errorBuilder 退化）+ 名号 + 代系/境界/定位（祖师/大弟子/二弟子/收徒）
- 纪事（轻，派生）：弟子「江湖 XX 年拜入 · 过〇〇之战」；祖师「第 N 代 · 当代/已退隐」
- 四项属性 + 主修心法
- 所持师承遗物（内联：名 + tier 色 + 传 N 代）
- 祖师恩泽（仅 `isFounder` 显：内力 +5% / 血量 +5% / 暴击率 +2%，复用现有 `_FounderBuffSection` 数据源 `FounderBuffService`）

## 五、入口 + 路由

- **主菜单入口**：保持现有（`main_menu.dart:21` push `LineagePanelScreen()`）——门派谱从开局即在（祖师=玩家本身），不 gating（不回归现状，区别于战绩册首胜/兵器谱首装备 gating）
- **新增 VISUAL_ROUTE**：`lineage_codex`（主屏）+ `lineage_character_detail`（详情屏，seed 祖师+弟子真数据），补齐与战绩册/兵器谱对称的目检路由

## 六、红线与约束

- **纯展示零数值改动**：不碰伤害/经济/掉落/概率（§5.4/§5.1）
- §5.5 离线无关（纯 UI）· §5.6 文案全进 `UiStrings`/`EnumL10n`（代系名/纪事模板/进度行/空态），无散写中文 · §5.7 无教程弹窗
- 飞升逻辑复用现有 `AscendService`/`AscensionScreen`/`FounderBuffService`，**零改动**
- 零 saveVer bump / 零迁移（纯派生现有字段）

## 七、测试

- **派生纯函数测**：世代分组（1 代/N 代）· 当代边界（founderCharacterId 命中）· 遗物传 N 代计数 · 纪事来源反查（role→stage）· 空态
- **widget 测**：主屏渲染一代/多代/空遗物/空门人 + 详情屏祖师态/弟子态 + 路由 parse 往返（`lineage_codex` / `lineage_character_detail`）
- 全量零回归 + analyze 0（主 checkout 实测；fresh worktree 先拷 libisar.dylib + build_runner）

## 八、不做（YAGNI / C 范围 / backlog）

弟子参战统计、个人成长快照、历代飞升仪式回放、独立遗物传承链详情屏、飞升渡劫叙事埋点。这些需新埋点或重表现层，超 B 范围；如后续要做另起子项。

## 九、实装顺序提示（交 writing-plans 细化）

派生纯函数层（domain）→ 主屏世代卷重写（presentation）→ 角色详情屏（presentation）→ 飞升入口保留接线 → VISUAL_ROUTE 双路由 → 文案归集 UiStrings/EnumL10n → 测试。每 task implementer + spec/质量两阶段 review。
