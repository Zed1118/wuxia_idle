# Codex 视觉复查派单:textScale=1.12 溢出 + MJ 素材观感

**日期:** 2026-06-07
**分支:** `codex/t11-inventory-section-header`(勿 checkout / 勿 rebuild / 勿合并 main)
**验收包:** `build/macos/Build/Products/Debug/wuxia_idle.app`(已由 Claude 预编译 · `VISUAL_ROUTE=hub`)
**截图存放:** `docs/handoff/codex_vis_textscale_mj_2026-06-07/`

## 背景

Codex 两天 43 commit 已通过代码层检查(analyze 0 issues / 全量测试 1763 passed / 红线未动)。
唯一查不了的是**视觉层**:全局 `WuxiaUi.textScale = 1.12` 放大 + MJ 素材接入的溢出/观感。
硬性 RenderFlex 溢出已被 widget test 排除,本次只验**软挤压 + 观感**。

## 怎么跑(零编译)

```bash
open build/macos/Build/Products/Debug/wuxia_idle.app
# 控制台等到输出:VISUAL_ROUTE_READY: hub
# 窗口里是「验收总入口」,按钮点选切到每个目标页,无需重 build
# 截图(扩展屏常见坐标,按你实际窗口调):
# screencapture -x -R 1920,0,2560,1440 docs/handoff/codex_vis_textscale_mj_2026-06-07/<name>.png
```

## 验收门(逐页逐门记 PASS/WARN/FAIL)

### 页 1 · 仓库(hub → inventory)
- G1.1 部位分组头(武器/护甲/饰品)文字不溢出格、不被裁切
- G1.2 装备格内强化徽章/师承标/tier 数字在 1.12 放大后不挤出边框
- 截图:`01_inventory.png`

### 页 2 · 装备详情(hub → equipment_detail_screen)
- G2.1 标题/共鸣/强化/典故各段文字不溢出、不重叠
- G2.2 **装备图白底**:用纸色 multiply 融合后是否仍有突兀白块(Codex 已知遗留点,重点看)
- 截图:`02_equipment_detail.png`

### 页 3 · 心法面板(hub → technique_panel_tier_all)
- G3.1 7 阶 cover 同屏,阶名/三系相克盘标签在 1.12 下不挤压换行错乱
- G3.2 三系相克关系盘文字(刚猛/灵巧/阴柔 + 震伤/暴击/内伤)完整可读
- 截图:`03_technique_panel.png`

### 页 4 · 战斗胜利(hub → battle_victory_first_clear)
- G4.1 繁体「勝」题字 + 掉落/升层/共鸣三段在 1.12 下不溢出弹窗
- G4.2 封签/结算帖构图无文字被框裁切
- 截图:`04_battle_victory.png`

### 全局门 · MJ 素材观感(可在以上各页顺带看)
- G5.1 **无伪文字泄漏**:任何 MJ 图里 AI 生成的假汉字/假英文必须被遮盖或避开(红线)
- G5.2 blend 素材(_blend.png 战斗特效/红印/overlay)融合自然,无生硬白边/方块
- G5.3 主菜单山门背景(hub → main_menu 顺带)无伪字、scrim 下文字可读
- G5.4 整体水墨克制,无 Material 饱和色乱入

## 结论(Codex 在此追加)

> 总判:FAIL
>
> 逐门:
> - G1.1 PASS：仓库「武器 / 护甲 / 饰品」分组头在 textScale=1.12 下未见溢出、裁切或压线。
> - G1.2 PASS：装备格内图片、名称、角标与边框关系正常；未见强化徽章 / 师承标 / tier 数字挤出格子。
> - G2.1 PASS：装备详情页标题、属性 / 共鸣 / 强化 / 典故区域未见文字重叠或溢出。
> - G2.2 WARN：装备图已被纸色融合，但中间仍是规则矩形浅底，和周围纸纹相比仍有「贴图白底块」观感。
> - G3.1 WARN：心法页文字和相克盘标签未见硬溢出；但 7 阶 cover 未能完整同屏呈现，底部内容在 1440p 截图中仍需向下滚动 / 被截到一部分。
> - G3.2 PASS：三系相克关系盘「刚猛 / 灵巧 / 阴柔」与「震伤 / 暴击 / 内伤」完整可读，未见换行错乱。
> - G4.1 PASS：战斗胜利页「勝」题字、掉落、升层、共鸣三段在弹窗内可读，未见溢出。
> - G4.2 PASS：封签 / 结算帖构图稳定，未见文字被框裁切。
> - G5.1 FAIL：心法面板多张 MJ cover / 横幅中可见未遮盖的伪书法 / 伪汉字痕迹，触发红线。
> - G5.2 PASS：战斗胜利背景与结算帖、红印 / overlay 融合自然，未见明显白边或方块。
> - G5.3 PASS：主菜单山门背景未见明显伪字，scrim 下标题、卡片文字可读。
> - G5.4 PASS：整体仍是水墨 / 宣纸 / 绛红点缀基调，未见 Material 饱和色乱入。
>
> 主要问题:
> 1. 红线问题：`03_technique_panel.png` 中心法 cover / banner 的 MJ 伪书法可见，需要遮盖、替换或裁切避开。
> 2. 遗留观感：`02_equipment_detail.png` 装备图中间浅色矩形底仍较突兀，建议继续做透明化 / 纸纹融合。
> 3. 软适配：`03_technique_panel.png` 的 7 阶 cover 未完整同屏，虽无文字溢出，但和验收门「7 阶 cover 同屏」不完全一致。
>
> 截图清单:
> - `docs/handoff/codex_vis_textscale_mj_2026-06-07/01_inventory.png`
> - `docs/handoff/codex_vis_textscale_mj_2026-06-07/02_equipment_detail.png`
> - `docs/handoff/codex_vis_textscale_mj_2026-06-07/03_technique_panel.png`
> - `docs/handoff/codex_vis_textscale_mj_2026-06-07/04_battle_victory.png`
> - `docs/handoff/codex_vis_textscale_mj_2026-06-07/05_main_menu.png`
