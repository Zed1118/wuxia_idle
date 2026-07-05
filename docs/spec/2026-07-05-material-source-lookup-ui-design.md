# 材料来源反查 · 统一交互入口 design spec 草案(2026-07-05 夜间批 D · 待拍板)

> backlog 项「材料来源反查:在强化、开锋、分解、商店等界面点击材料时,可查看主要来源」。
> **Phase 0 现场核查结论:派生层已 100% 建成,本项实际只剩薄 UI 接线**(backlog 描述 stale,
> 与 07-03 起多批「已实装」同型 drift)。本 spec 只画缺口与拍板点,不重复设计已有层。

## 一 · 现状(已建成 · 全部现查核实)

| 层 | 位置 | 覆盖 |
|---|---|---|
| 来源派生 | `lib/features/inventory/application/material_source_lookup_service.dart:17 sourcesFor(itemId)` | mainline/stage/tower/闭关/商店/装备分解/强化失败/桃花岛源产+配方,dedupeKey 去重 |
| 用途派生 | `item_usage_lookup_service.dart usagesFor()` | 境界丹/秘籍/疗伤/强化/开锋/保底/货币/桃花岛 |
| 折叠说明 widget | `lib/features/inventory/presentation/material_source_note.dart` | 已挂强化 dialog(`enhance_dialog.dart:303`)+开锋面板(`forging_panel.dart:188`) |
| 全量展示 | 资源总览 `_ResourceCard`(数量+用途分组+来源折叠) | 五类库存全覆盖 |
| 缺口命中 | `sweep_reward_preview.dart:70 materialHits` | 扫荡前「有掉落且有用途」过滤 |

## 二 · 真实缺口

1. **点击反查入口不统一**:强化/开锋屏是「一段折叠文字」(MaterialSourceNote),背包/商店/
   分解确认里材料只是 Text/Icon 不可点;玩家在「要消费材料的现场」查不到逐条来源。
2. **来源明细无逐条视图**:MaterialSourceNote 是压缩文案,不逐条列「哪关/哪图/哪货架」。

## 三 · 方案(一期 · 纯表现层)

新建 `MaterialSourceSheet`(`inventory/presentation/`):`showModalBottomSheet` 纸质底
(沿 `cangjingge_screen.dart:779` 底部弹层体例),内容 = 材料名+持有量 + 「来源」逐条
(ItemSourceKind 分组:主线/爬塔/闭关/商店/分解/桃花岛,复用 `sourcesFor`)+ 「用途」段
(复用 `usagesFor`)。逐条格式:`寻常货·stage_01_04 洛阳城外(Boss)` 一行一源,EnumL10n/
UiStrings 集中,不散写中文。

挂点(各处材料行为包 InkWell → 弹 sheet):
- ① 强化 dialog 材料行(`enhance_dialog.dart:293 _MetricsRow`)
- ② 开锋面板辅材行(`forging_panel.dart:180`)
- ③ 分解确认返还行(`equipment_detail_screen.dart:153`)
- ④ 商店商品卡(材料类条目,`shop_screen.dart _ShelfGroupPanel`)
- ⑤ 背包材料 tile(`inventory_screen.dart`,唯一无任何来源信息的屏)
- ⑥ 资源总览卡:不动(已有折叠来源;可选把折叠区换成同一 sheet 入口求一致)

MaterialSourceNote 保留(空间受限处的轻量摘要),sheet 是"展开态"。

## 四 · 范围排除(一期不做)

- **不做「前往」跳转**(来源条目→关卡/商店导航):有 `DiagnosisJumpTarget` 先例可抄,
  但涉跨屏路由栈语义,留二期拍板。
- 不做材料目标追踪/缺口聚合(=被否决过的「终局装备目标追踪」邻域,不越界)。
- 不做掉率数字展示(只列来源不列概率,免催刷感,守 §5.1 氛围)。

## 五 · 红线自检

纯表现层零结算/零 schema/零 saveVer;中文全进 UiStrings/EnumL10n;浅纸底用 WuxiaUi.ink/
muted(两色板不混);无教程弹窗(§5.7,点击是玩家主动);不引入每日/提醒类机制(§5.1)。

## 六 · 拍板点

| # | 问题 | 倾向 |
|---|---|---|
| P1 | 挂点范围:①-⑤ 全做 or 先 ⑤背包+④商店(信息最缺的两处)? | 全做(一次做全面,打磨期原则) |
| P2 | 浮层形态:bottom sheet(倾向·列表长度友好) vs PaperDialog? | bottom sheet |
| P3 | ⑥ 资源总览折叠区是否换成同一 sheet 入口? | 换(一致性),低成本 |
| P4 | 「前往」跳转留二期? | 留二期 |

## 七 · 估算

拍板后实装:MaterialSourceSheet + 5 挂点 + UiStrings + widget 测(sheet 渲染/挂点可点/
来源分组断言)≈ 1 个 subagent-driven 3-4 Task 批(opus high,半天内),targeted + analyze,
无跨切面故不必全量。
