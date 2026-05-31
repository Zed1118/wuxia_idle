# 心法面板 7 阶 cover 视觉验收

日期：2026-05-31  
项目：挂机武侠  
HEAD：33265c8  
截图目录：docs/handoff/visual_capture_manual_33265c8_20260531_165322/

## Route 直达结果

| Route | READY | 截图 |
|---|---:|---|
| `technique_panel_tier_all` | PASS | `technique_panel_tier_all_window.png`, `technique_panel_tier_all_scrolled_window.png`, `technique_panel_tier_all_bottom_window.png` |
| `technique_panel_hero` | PASS | `technique_panel_hero_window.png` |
| `main_menu` | PASS | `main_menu_window.png` |

备注：一键脚本 `tools/visual_capture/visual_capture.sh` 三个 route 都出现 READY，但因本机窗口 id 获取失败，manifest 全部标为 `READY(全屏兜底)`，且初次图中混入旧 app 窗口。已改用手动 route + Computer Use 置前/滚动 + 全屏裁窗方式补齐干净截图。

## 验收结论

| 验收点 | 结论 | 截图 | 说明 |
|---|---|---|---|
| `technique_panel_tier_all` 7 张 tier cover 均加载 | PASS | `technique_panel_tier_all_window.png`, `technique_panel_tier_all_scrolled_window.png`, `technique_panel_tier_all_bottom_window.png` | 辅助树列出 7 阶：传说神功、失传神功、江湖秘传、门派绝学、名家功、常练功、入门功；滚动截图覆盖高/中/低阶 cover，未见空图或占位。 |
| 装帧梯度逐阶递进可辨 | PASS | 同上 | 入门功/常练功为素纸、低调旧纸装帧；中高阶逐步增加边框纹理与印章；传说神功金框最强，层级差异清楚。 |
| cover 完整呈现不裁切 | PASS | 同上 | 横幅主体完整呈现，未见左右截断或 `BoxFit.cover` 式裁边；滚动过程中可见 cover 维持横幅比例。 |
| `technique_panel_hero` 主修 hero 卡 | PASS | `technique_panel_hero_window.png` | 打坐图标与内丹金光可见；`_SealBadge` 印章、分割线、9 层段位阶梯未见错位。 |
| `main_menu` 回归 | PASS | `main_menu_window.png` | 水墨山门背景、题字、双列木牌正常；基础视觉直达基建未破坏主菜单。 |

## 剩余风险

- 本机终端缺少干净窗口截图权限或窗口 id 获取不稳定，一键脚本本次只能作为 READY 检查使用；最终验收截图来自手动 route 后的裁窗图。
- `technique_panel_tier_all` 内容高度超过当前窗口，一张静态截图无法同时展示完整 7 阶；本次用滚动分段截图和辅助树确认全量内容。

一句话总评：三条 VISUAL_ROUTE 基建直达均可用，心法 7 阶 cover 加载、梯度和不裁切验收通过。
