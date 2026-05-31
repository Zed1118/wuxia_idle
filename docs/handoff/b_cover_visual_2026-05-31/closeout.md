# B Cover Visual Closeout - 2026-05-31

## 截图路径

- `docs/handoff/b_cover_visual_2026-05-31/technique_panel_top.png`
- `docs/handoff/b_cover_visual_2026-05-31/technique_panel_full.png`
- `docs/handoff/b_cover_visual_2026-05-31/technique_panel_bottom.png`
- `docs/handoff/b_cover_visual_2026-05-31/technique_panel_1280x720.png`

## 窗口尺寸

- 最大化采集：逻辑 `1440 x 794 px`；截图像素 `3104 x 1812 px`（含 macOS 窗口阴影，内容约 2x Retina）
- 1280 采集：逻辑 `1280 x 720 px`；截图像素 `2784 x 1664 px`（含 macOS 窗口阴影，内容约 2x Retina）

## Seed 核对

- PASS：进入心法面板后 seed 生效。
- 可见主修：刚猛 / 名家功 / 圆满，当前 `5 / 9 层`，打坐图与内丹金光点存在。
- 可见阶梯：前 4 段为流派色，第 5 段为当前金色，后 4 段为灰色。
- 可见辅修：阴柔 / 名家功 / 大成。
- 可见入口：`凝练领悟 · 50 点`。
- 可见 cover：名家功 section 顶部有卷轴 cover banner。

## 验收表

| # | 验收点 | 结论 | 说明 |
|---|---|---|---|
| 1 | cover 卷轴 banner 完整呈现（含上下织锦/做旧装帧边框），没有被裁成中间窄条 | PASS | banner 完整显示，褐色做旧边框、宣纸主体、题跋与印章均可见，没有被压成窄条。 |
| 2 | banner 高度约 150 与整屏出版感：单 section 比例是否协调、面板是否过长 | PASS | 最大化与 1280x720 下比例都可接受；banner 有主视觉存在感，但未压过主修 hero 和下方 tile。 |
| 3 | 9 层段位阶梯三态清晰：已过流派色 / 当前金徽章 / 未到灰 | PASS | 5/9 状态清楚：前 4 段红色、当前第 5 段金色、后 4 段灰色，补上了上次 1/9 未覆盖的已过色段验证。 |
| 4 | 主修 hero 打坐图 + 内丹金光点是否克制 | PASS | 打坐图尺寸克制，金点偏小且不刺眼，没有大光效或 Material 感。 |
| 5 | 复验上次 WARN：印章 seal_red 放大到 48 后，与 tile 融合度是否改善、是否仍偏小贴右 | WARN | 尺寸比上次更明确，tile 内识别度改善；但仍靠右独立感较强，和 tile 内容的融合度还可以继续精修。 |
| 6 | 复验上次 WARN：宣纸 opacity 提到 0.24 后，滚到底部深色空底是否改善、暖宣纸是否铺出来 | WARN | 暖宣纸质感已铺到主要内容区，改善明显；但最大化窗口底部仍露出一段深色空底，建议继续处理底部填充或最小内容高度。 |
| 7 | cover 上的书法题字（MJ 随机字）是否违和 | PASS | 题字与题跋风格统一，随机字没有明显穿帮；右侧文字和淡红印章能融入卷轴。 |
| 8 | 整体基调统一：青墨 + 宣纸黄 + 绛红印 + 克制金，无 Material 高饱和违和 | PASS | 整体偏青墨、宣纸、绛红和低饱和金；未见高饱和 Material 色块。 |

## 总评

基本达标。

最需精修项：底部深色空底仍是最明显的遗留问题；其次是 tile 右侧 seal_red 与卡片内容的融合度，可考虑减少贴边感或让印章与文字/背景建立更明确的层级关系。

## 踩坑记录

- 误连旧 app：有。第一次打开后发现同时存在旧 `build/macos/Build/Products/Debug/wuxia_idle.app` 进程和目标 `visual_builds/wuxia_idle_702969d.app` 进程；已全部 kill 后只重开 `/Users/a10506/Desktop/visual_builds/wuxia_idle_702969d.app`，正式截图均来自目标 app。
- 是否需 build_runner：不需要。未运行 `flutter run` / `flutter build` / `build_runner`。
- 截图权限：可用。`screencapture` 正常保存四张 PNG。
- 存档影响：点击了 debug seed「凝练态验证」，会写入/覆盖本地调试存档状态；未改代码、未改 yaml、未 push。
