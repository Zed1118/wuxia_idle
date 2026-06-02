# P0-3 角色面板装备外观可视化 · Codex@Pen 截图验收派单

分支：`feat/p0_3_equipment_visual`（merge main 后 Pen `git pull`）
目标：角色面板装备 3 槽从「纯文字」加上装备图标(§5.4 装备外观一眼可读)。
本批仅 ① 装备外观；② 主修仪式感 / ③ 成长瓶颈进度 留 P0-3b。

验收路由：`flutter run -d windows --dart-define=VISUAL_ROUTE=character_panel`

| # | 验收门 | 期望 |
|---|--------|------|
| 1 | 装备图标显示 | 武器/护甲/饰品 3 槽顶部各显装备图标(iconPath, contain)；有图显图、缺图显 tier 色槽位首字(武/护/饰)占位，不空框。 |
| 2 | tier 边框分阶色 | 槽框边色随装备阶(寻常货灰 → 神物金, `tierColorForEquipment`)；高阶一眼更醒目。 |
| 3 | 强化徽章 | 槽内右上仍显 +N 强化等级(tier 色)；阶名 + 共鸣段 + battleCount 保留。 |
| 4 | 3 槽高度对齐 | 3 槽等高(144px _EquipmentSlotShell)，空槽「未装备」也同高，行不参差。 |
| 5 | 布局无 overflow | 1280×720 角色面板滚动区内装备 section 无 RenderFlex overflow；身份区(立绘+属性)不受影响。 |
| 6 | 未装备占位 | 槽 id 全 null 时仍显 3 个「未装备」灰占位(回归)。 |

建议截图：`01_equipment_filled.png`(3 槽装备图+边框+徽章) / `02_equipment_empty.png`(未装备占位) / `03_panel_full.png`(整页身份区+装备区不冲突)。

注意：装备 icon 资产仍有缺(asset_audit 清单),缺图走 tier 色首字占位属预期非缺陷；门 1 看「有图的槽显图 + 缺图的槽显占位」即可。
