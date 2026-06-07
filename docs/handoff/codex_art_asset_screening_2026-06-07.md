# Codex 美术素材一筛交接 2026-06-07

## 范围

- 原始目录：`/Users/a10506/Downloads/autojourney`
- 筛选工作区：`/Users/a10506/Downloads/autojourney_screening`
- 本轮优先处理根目录新图：339 张 PNG。
- 全目录递归共有 1304 张 PNG，约 2.3GB；旧批次位于 `批量美术素材/已采用`、`未采用`、`_archived`，本轮未混入一筛。

## 输出物

- 根目录 manifest：`/Users/a10506/Downloads/autojourney_screening/root_manifest.csv`
- 全量 manifest：`/Users/a10506/Downloads/autojourney_screening/all_png_manifest.csv`
- contact sheets：`/Users/a10506/Downloads/autojourney_screening/contact_sheets/`
- 一筛精选目录：`/Users/a10506/Downloads/autojourney_screening/selected/`
- 一筛精选 manifest：`/Users/a10506/Downloads/autojourney_screening/selected_manifest.csv`
- 一筛精选总览：`/Users/a10506/Downloads/autojourney_screening/selected_contact_sheet.jpg`
- 一筛报告：`/Users/a10506/Downloads/autojourney_screening/selection_report.md`

## 一筛结论

一筛通过 43 张：

| 类别 | 数量 | 用途 |
|---|---:|---|
| `menu_bg` | 4 | 主菜单、封面、加载/章节背景 |
| `system_thumbnail` | 14 | 主入口系统卡、功能入口缩略图 |
| `ceremony` | 8 | 胜利、首通、领悟、心法升层等仪式底图 |
| `battle_fx` | 14 | 刚猛、灵巧、阴柔、破甲、闪避、内伤等战斗反馈 |
| `ui_parts` | 3 | Boss 头像框候选 |

## 接入建议

- 主菜单优先试 `selected/menu_bg/menu_mountain_gate_wide_01.png` 与 `selected/menu_bg/menu_splash_pier_01.png`。
- 系统入口缩略图可作为下一轮 UI 替换重点，但需要统一暗角、宣纸遮罩和色温，避免每个入口像不同项目。
- 战斗特效多为白底或纸底图，接入时建议先做 blend/mask 或离线抠图，不要直接按透明 PNG 叠上去。
- 仪式图中有伪文字的图只适合作底纸、纹理或遮罩；关键中文必须仍由 Flutter 字体渲染。
- Boss 头像框需要透明通道或 mask 处理后再接入。

## 入选清单

详见 `/Users/a10506/Downloads/autojourney_screening/selection_report.md`。该报告记录了每张入选图的原始编号、精选文件名和使用备注。

## 未做

- 尚未把精选图片复制到项目 `assets/`。
- 尚未做透明通道、裁切、压缩或色彩统一预处理。
- 尚未筛选旧批次里的 965 张归档图。
- 尚未做 Flutter 接入和视觉验收截图。
