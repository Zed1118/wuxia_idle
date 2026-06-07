# Codex 37 组 MJ 素材筛选交接 2026-06-07

## 范围

- 原始目录：`/Users/a10506/Downloads/autojourney`
- 本轮只筛选 Codex 输出的 37 个提示词对应素材。
- 按 37 个文件名前缀精确匹配，实际找到 148 / 148 张，37 / 37 组，每组 4 张齐全。
- 未纳入旧装备图、旧头像图、历史归档图，也未纳入此前误宽筛的 339 张结果。

## 输出物

- 筛选工作区：`/Users/a10506/Downloads/autojourney_screening_37prompts_2026-06-07`
- 独立留用目录：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07`
- 37 组全量总览：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07/all_37_groups_contact_sheet.jpg`
- 留用总览：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07/selected_contact_sheet.jpg`
- 全量 manifest：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07/manifest_37groups.csv`
- 留用 manifest：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07/selected_manifest.csv`
- 筛选报告：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07/selection_report.md`

## 留用结论

148 张中一筛留用 39 张：

| 类别 | 数量 | 用途 |
|---|---:|---|
| `menu_bg` | 4 | 主菜单、封面、加载/章节背景 |
| `system_thumbnail` | 9 | 主入口系统卡、功能入口缩略图 |
| `ceremony` | 9 | 胜利、首通、突破、领悟、收功结果等仪式底图 |
| `battle_fx` | 10 | 刚猛、灵巧、阴柔、暴击、破甲、闪避、内伤等战斗反馈 |
| `overlay` | 4 | 雾层、墨云、远灯、Boss 低血压迫暗角 |
| `ui_parts` | 2 | Boss / 大 Boss 头像框候选 |
| `battle_bg` | 1 | Boss 登场背景纹理 |

## 接入建议

1. 先接 `menu_bg`：优先试 `menu_mountain_gate_wide_01.png` 与 `menu_splash_pier_01.png`。
2. 再接 `system_thumbnail`：替换主入口功能卡，优先角色、装备、心法、闭关、爬塔、主线。
3. 接 `ceremony`：用于胜利、首通、突破、领悟、心法升层、闭关收功；伪文字区域必须遮盖，关键中文仍由 Flutter 字体渲染。
4. 接 `overlay`：作为主菜单/战斗/低血状态的氛围层，需要 blend/mask。
5. 最后接 `battle_fx`：多数是纸底/白底图，先做透明、混合或裁切预处理，再进战斗动画层。
6. `ui_parts` 头像框作为独立小任务，接入前做 mask 或透明通道。

## 注意事项

- 旧目录 `/Users/a10506/Downloads/autojourney/筛选留用_2026-06-07` 是此前范围过宽的一筛副本，不作为后续接入依据。
- 后续 Claude 应以 `/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07` 为唯一素材入口。
- 本轮还没有把图片复制到项目 `assets/`，也没有修改 `pubspec.yaml`。
- 本轮还没有做图片压缩、裁切、透明通道、色温统一和 Flutter 视觉验收。
