# UI 包装改造方案 v1 — 设计

> 2026-06-04 · brainstorming 收口 · 真实资产 demo 验证(`docs/handoff/ui_mockup_v1/`)
> 缘起:外部 UI 评估 + 今日 build 截图坐实——系统页停留在 Flutter 功能面板视觉语言,缺包装层/身份感/反馈。

## 1. 范围与产出

- **力度**:重度·游戏化重做(kit + 4 页重排版 + 仪式化呈现)。
- **覆盖**:统一 UI kit(9 组件)+ 5 个核心屏(主菜单 / 角色面板 / 装备仓库 / 装备详情 / 战斗胜利;仓库+详情同属装备线)。
- **本轮产出**:本设计 doc(0 代码)。定稿 → writing-plans 拆实现计划,**kit 先行**再逐页。
- **过场动画**(Boss 登场 / 章节转场 / 装备获得演出)= v2,本轮不做(YAGNI)。

## 2. 架构

- 新建 `lib/shared/widgets/wuxia_ui/`:9 个 kit 组件,在已有 `WuxiaPaperPanel` 上长(不另起 design system)。
- 新建 `lib/shared/theme/wuxia_tokens.dart`:集中母题 token(色/边/面/章/形)。
- callsite **增量替换**,一组件一组件上 + 每步 widget 测/视觉验收;不 big-bang。

## 3. 母题 token + 基调红线

- **色**:墨黑 `#241f1a` / 宣纸黄 `#e9dcc0` / 青灰 `#566b63` / 绛红 `#8a2b21` 点缀 / 金线 `#b08a47`(**仅高阶装帧**,沿 7 阶 cover 先例)。
- **边**枯笔墨边 · **面**宣纸纹理(真资产 `assets/ui/paper_bg.png`) · **章**朱印(`seal_red.png`) · **形**木牌/卷轴/册页(`scroll_*.png`/`ink_divider.png`)。
- **红线**(不得破):不用 Material 默认饱和色;不写 legendary/epic 网游词;仪式演出走「水墨+题字+朱印+vignette」**不走粒子/金光**;装饰服务识别与身份,不堆砌。

## 4. UI kit 组件(9 个跨页)

| # | 组件 | 替换对象 | 母题形态 |
|---|------|----------|----------|
| 1 | `WuxiaTitleBar` | Material AppBar | 宣纸顶栏 + 卷轴题字标题 + 朱印返回钮 |
| 2 | `PlaqueTab` | Material Tab | 木牌页签,选中=朱漆烙印 |
| 3 | `PaperPanel` | 深色矩形 panel | 宣纸纹理 + 墨边(正式化 `WuxiaPaperPanel`) |
| 4 | `SectionHeader` | 纯文字分区头 | 墨笔小标 + 枯笔分隔线 |
| 5 | `ItemSlot` | 白底缩略图格 | 宣纸格底 + tier 墨框→金框阶梯 + 图 contain + 强化朱印 + 师承烙印 + 锁=封条 |
| 6 | `MeridianBar` | Material 进度条 | 内息流轨/墨迹填充 |
| 7 | `SealBadge` | tier chip/锁/角标 | 朱印/封条/烙印 |
| 8 | `PlaqueButton` | 黄描边按钮 | 木牌按钮,主行动=朱漆 |
| 9 | `PaperDialog` | Material AlertDialog | 卷轴/册页弹窗 + 朱印封 + 仪式化掉落框 |

## 5. 逐页改造(布局见 demo `index.html`)

### 5.1 主菜单
- **现状**:水墨山门背景好,但入口卡片像 SaaS dashboard 暗矩形。
- **目标**:入口改**悬挂木牌(C 宣纸笺:半透宣纸色 + 墨字)**,底部水墨渐隐带托底,未解锁=灰化(§5.7 门控)。
- **专属件**:`MenuPlaque`(C 宣纸笺样式,已在 demo 定版)。
- **成本**:中(背景已有,主要是入口件 + 渐隐带 + 布局)。

### 5.2 角色面板(落差最大,纯后台面板)
- **现状**:深色 Material 面板 + 一行行数值 + 小立绘 + 通用 Tab/进度条,像管理工具。
- **目标**:`WuxiaTitleBar` + `PlaqueTab` + **大幅立绘装裱(`PortraitPlate`)** + **印记式属性(`AttributeStamp`,悟/骨/身/敏各成朱印)** + 心魔 `MeridianBar` X/7 + 装备 `ItemSlot`。
- **专属件**:`PortraitPlate`(立绘 + 装裱边 + 题字姓名,扩 `PortraitFrame`)、`AttributeStamp`。
- **成本**:大(版式重排 + 2 专属件 + 多 kit 组件)。

### 5.3 装备仓库(趁热用上重出的水墨图)
- **现状**:白底缩略图 + 硬边框,像素材浏览器。
- **目标**:`PlaqueTab`(装备/物料)+ `SectionHeader`(武器/护甲/饰品)+ `ItemSlot` 网格(tier 框 + 强化朱印 + 封条)。结构(分组网格)已对,换容器语言。
- **成本**:中(ItemSlot kit 套到现有分组网格)。

### 5.4 装备详情
- **现状**:detail 图缩在顶部白盒,数值/典故在暗 panel。
- **目标**:水墨大图金框装帧**居中成主视觉(`DetailHero`)**,右侧数值,下方**典故卷轴(`LoreScroll`)**,`PlaqueButton`(强化/卸下)。
- **专属件**:`DetailHero`、`LoreScroll`。
- **成本**:中(版式重排 + 2 专属件)。

### 5.5 战斗胜利
- **现状**:已有金「胜」+ 朱印 overlay(B2 `599c25a`),但顶部文字/按钮仍测试感。
- **目标**:`PaperDialog` 体系收编——金「胜」+ 朱印 + **战报卷条** + `PlaqueButton`(继续);仪式守红线不走金光粒子。
- **成本**:小-中(增强既有 overlay,非从零)。

## 6. 推进顺序 + 成本

| 序 | 模块 | 成本 | 备注 |
|---|------|------|------|
| 0 | UI kit(9 组件 + tokens) | 大 | 地基,必须先行 |
| 1 | 装备仓库 + 详情 | 中 | 趁热吃刚重出的水墨图红利 |
| 2 | 角色面板 | 大 | 落差最大,专属件最多 |
| 3 | 主菜单 | 中 | C 宣纸笺已定版 |
| 4 | 战斗胜利 | 小-中 | 增强既有 overlay |

> 顺序可调;kit 先行不可调。每模块独立 spec→plan→TDD→视觉验收循环。

## 7. 验收

- 每组件:widget 测(`assets/ui/*` errorBuilder 守、IntrinsicHeight 守见 memory)+ 路由视觉自验(Mac dart-define / hub)。
- 每页:Codex/Mac 截图比对 demo + 红线复核(无 Material 饱和、无金光粒子)。
