# 出版美术资产压缩 + 9 NPC 立绘合并视觉复验

日期: 2026-05-31
HEAD: c1478a1

## 结论

| 段落 | 结果 | 说明 |
|---|---|---|
| A. techniques 7 阶 cover 压缩后复验 | PASS | `technique_panel_tier_all` 正常就绪；7 阶 cover 均加载，无灰占位/破图；未见明显色带或色彩失真，金框「传说神功」浮雕与素纸到重装帧梯度仍清晰。 |
| B. 9 NPC 立绘呈现复验 | FAIL | 9 张 indexed PNG 资产本身可被 Flutter `Image.asset` 解码且辨识正确；收徒 picker 的 3 张正常呈现。但当前生产 UI 的 `sect_recruit` 确认 dialog 与「强制招募 NPC」候选列表未渲染 sect_candidate 立绘；`sect_screen` 成员行也没有 portrait 渲染链路，无法满足“sect_candidate 6 张在成员列表呈现”的验收项。 |

## A 复验记录

- 运行命令: `flutter run -d macos --dart-define=VISUAL_ROUTE=technique_panel_tier_all`
- 就绪日志: `VISUAL_ROUTE_READY: technique_panel_tier_all`
- 对照基线: `docs/handoff/visual_capture_manual_33265c8_20260531_165322/`
- 截图:
  - `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_top_fullscreen.png`
  - `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_mid_fullscreen.png`
  - `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_lower_fullscreen.png`
  - `docs/handoff/codex_visual_compress_portraits_20260531/a_technique_bottom_fullscreen.png`

观察:
- `传说神功 / 失传神功 / 江湖秘传 / 门派绝学 / 名家功 / 常练功 / 入门功` 均在滚动路径中可见。
- indexed PNG 未触发 `errorBuilder` 灰占位。
- 金框「传说神功」仍可见浮雕、红印、暗金纹理；中低阶装帧与素纸阶梯差异可辨。

## B 复验记录

### 生产 UI 可达路径

截图:
- `docs/handoff/codex_visual_compress_portraits_20260531/b_main_debug_entry.png`
- `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_candidate_debug_list_no_portraits.png`
- `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_recruit_dialog_no_portrait.png`

观察:
- 「强制招募 NPC」候选列表只显示图标、姓名、id、流派、境界，没有立绘。
- `sect_recruit` 确认 dialog 只显示姓名、流派、属性、lore，没有立绘。
- 这不是 PNG 解码失败，而是生产 UI 未接入 `candidate.portraitPath`。

### 收徒 picker

截图:
- `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_top.png`
- `docs/handoff/codex_visual_compress_portraits_20260531/b_recruit_picker_bottom.png`

观察:
- 云寒青 / 柳拂陻 / 马智远 3 张 `recruit_candidate_*.png` 正常加载，无灰占位。
- 画风与 founder / first_disciple / second_disciple 基线一致，未见明显压缩色带。

### sect_candidate 资产解码确认

因生产 UI 当前不渲染 6 张 sect candidate 立绘，临时跑本地 Flutter 视觉 harness 直接用 `Image.asset(candidate.portraitPath)` 渲染 6 张图，确认 indexed PNG 解码正常。该 harness 已删除，未作为代码增量保留。

截图:
- `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_top.png`
- `docs/handoff/codex_visual_compress_portraits_20260531/b_sect_portrait_harness_bottom.png`
- `docs/handoff/codex_visual_compress_portraits_20260531/b_portrait_asset_contact_sheet.png`

角色辨识:
- 竹影客: 竹林剑客，正确。
- 漠行客: 沙漠刀客，正确。
- 山隐子: 清癯长须隐士，正确。
- 江湖客: 酒葫芦，正确。
- 幽谷客: 背药篓，正确。
- 铁匠之子: 围裙腰刀，正确。
- 云寒青: 边塞短须刀客，正确。
- 柳拂陻: 女侠背剑，正确。
- 马智远: 书生书卷，正确。

## 资产格式确认

`file assets/characters/sect_candidate_*.png assets/characters/recruit_candidate_*.png` 显示 9 张均为:

```text
PNG image data, 896 x 1344, 8-bit colormap, non-interlaced
```

对照的师徒基线图 `founder.png / first_disciple.png / second_disciple.png` 为 RGB PNG。

## 异常项

1. `sect_recruit` 确认 dialog 缺少 portrait。
   - 证据: `b_sect_recruit_dialog_no_portrait.png`
   - 影响: `sect_candidate_*` 无法在该验收位置呈现。

2. 「强制招募 NPC」候选列表缺少 portrait。
   - 证据: `b_sect_candidate_debug_list_no_portraits.png`
   - 影响: 只能证明数据池可达，不能证明生产 UI 呈现立绘。

3. `sect_screen` 成员列表当前没有可用 portrait 链路。
   - 代码观察: `Character` 没有 `portraitPath` 字段；`SectMemberService` 从 `SectCandidateDef` 创建 `Character` 时未保留 `portraitPath`；`sect_screen` 的成员行未调用 `Image.asset`。
   - 影响: 即使 NPC 入派，成员列表也无法显示对应 6 张 `sect_candidate_*` 立绘。

## 建议后续

为 B 段补一条小型基建任务:
- 给 sect recruit dialog 接入 `SectCandidateDef.portraitPath`。
- 给入派 NPC 保留 portrait 引用，或在 member row 上通过候选来源 id 反查 portrait。
- 给 `sect_screen` / 角色面板补 `VISUAL_ROUTE`，一次性覆盖 6 张 sect candidate 和 3 张 recruit candidate 的生产呈现截图。
