# T9 截图包 closeout

出图目录: `docs/handoff/visual_capture_f771ab7_20260609_131615/`  (PNG 本地, gitignored)
manifest: `docs/handoff/visual_capture_f771ab7_20260609_131615/manifest.txt`

## 截图结果

- 已跑全量候选屏: 11 routes x 2 resolutions = 22 张 PNG。
- manifest: 22/22 `READY(干净窗口)`, 无全屏兜底。
- 尺寸: 1280x720 输出为 2560x1440 px, 1920x1080 输出为 3840x2160 px, 符合 Retina 2x 真渲染。
- 额外接触表: `_contact_1280x720.jpg`, `_contact_1920x1080.jpg`。

## 逐屏验收表

| route | 720p | 1080p | debug? | 缺图? | overflow? | 风格 | 备注 |
|---|---|---|---|---|---|---|---|
| main_menu | 通过 | 不通过 | 是 | 否 | 否 | 720p 一致；1080p 受调试区影响 | 1080p 底部露出“调试”分区、`Phase 1 战斗测试`、`Phase 2 调试场景`、`强制招募 NPC`、`select recruit flow` 等开发占位 |
| battle_scene | 通过 | 通过 | 否 | 否 | 否 | 一致 | 战斗角色、敌人头像、背景均正常加载 |
| battle_victory_first_clear | 通过 | 通过 | 否 | 否 | 否 | 一致 | 胜利结算信息完整, 无截断 |
| character_panel | 通过 | 通过 | 否 | 否 | 否 | 一致 | 720p 底部进入下一分区属正常滚动内容, 非 overflow |
| inventory | 通过 | 通过 | 否 | 否 | 否 | 一致 | 装备图标完整；“未达境界”为正常锁定遮罩 |
| equipment_detail_screen | 通过 | 通过 | 否 | 否 | 否 | 一致 | 装备大图与属性卡正常；典故区下半屏为正常滚动内容 |
| technique_panel_tier_all | 通过 | 不通过 | 是 | 否 | 否 | 一致 | 1080p 下方卡片露出 `skillUsage: 0` |
| technique_panel_hero | 通过 | 不通过 | 是 | 否 | 否 | 一致 | 1080p 下方卡片露出 `skillUsage: 0` |
| stage_list | 通过 | 通过 | 否 | 否 | 否 | 一致 | 章节封面、节点和关卡列表正常 |
| tower_floor_list | 通过 | 通过 | 否 | 否 | 否 | 一致 | 功能信息完整, 无视觉错误 |
| seclusion_map_list | 通过 | 通过 | 否 | 否 | 否 | 一致 | 地图图全部加载, 卡片无截断 |

## 核心 5 张候选(商品页)

1. `battle_scene_1920x1080.png` - 最能展示 3v3 自动战斗、敌我阵位和水墨战场氛围。
2. `battle_victory_first_clear_1920x1080.png` - 胜利瞬间有强反馈, 适合展示掉落、境界推进和挂机收益。
3. `equipment_detail_screen_1920x1080.png` - 装备大图、属性、共鸣解锁信息完整, 商品页辨识度高。
4. `stage_list_1920x1080.png` - 清楚展示章节推进、Boss 节点和主线关卡结构。
5. `seclusion_map_list_1920x1080.png` - 地图美术密度最高, 能体现闭关挂机地图与水墨基调。

## 问题清单(需 Claude 修)

1. `main_menu_1920x1080.png`: 1080p 底部露出调试/开发占位内容, 包括“调试”分区、`Phase 1 战斗测试`、`Phase 2 调试场景`、`强制招募 NPC`、`select recruit flow`。建议商品页截图路线隐藏调试分区或改为正式入口。
2. `technique_panel_tier_all_1920x1080.png`: 下方心法卡片显示 `skillUsage: 0`, 属 debug 字段。
3. `technique_panel_hero_1920x1080.png`: 下方心法卡片显示 `skillUsage: 0`, 属 debug 字段。

其余候选图未发现缺图、RenderFlex 黄黑条、明显文字截断或 Material 饱和色突兀问题。

---

## Claude 过闸 + 修复(2026-06-09)

Codex 报的 3 处「debug 字段」逐项诊断:**全部已 `kDebugMode` 门控,非 bug**——只因截图用 debug build(`flutter run` 默认 debug → kDebugMode=true)才显,release/Steam 发布版本本就不显:
- main_menu 调试分区:`main_menu.dart:294` `final debugItems = kDebugMode ? [...] : []`
- technique_panel skillUsage:`technique_panel_screen.dart:525` `if (kDebugMode) ...[ Text('skillUsage:...') ]`

但 VISUAL_ROUTE 机制本身也门控在 `kDebugMode`(main.dart),不能直接用 release 截(route 失效)。

**修复**(`e711a5b`):`main.dart` 门控 `kDebugMode` → `!kReleaseMode` → profile build 下 route 仍生效、kDebugMode=false 隐藏**全部** debug chrome、release 仍短路安全;`visual_capture.sh` 加 `--profile`。

**最终干净 Steam 包**:`docs/handoff/visual_capture_e711a5b_20260609_153133/`(profile build · 22/22 干净窗口 · 0 兜底 · 720p=2560×1440 / 1080p=3840×2160)。三个原问题屏(main_menu / technique_panel_tier_all / technique_panel_hero)profile 重截已读图确认 debug 内容消失。**核心 5 张候选见上,商品页图从该目录取。**

闸门:analyze 0 / 全量 1763 测过 / 0 回归。
