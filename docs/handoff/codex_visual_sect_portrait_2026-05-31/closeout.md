# sect 立绘 portrait wiring 视觉验收 closeout

日期: 2026-05-31  
项目: 挂机武侠  
窗口尺寸: 1280 x 720 logical points；截图输出 2560 x 1440 pixels（Retina 2x）

## 结论表

| 验收点 | 结论 | 证据 |
|---|---|---|
| ① 7 人各显一张立绘,无灰空框/图标占位 | PASS (R2) | R2 `a_sect_members_top_r2.png` 显示祖师行已有 portrait，不再是空框；`a_sect_members_top_r2.png` + `a_sect_members_bottom_r2.png` 覆盖祖师 + 竹影客 / 漠行客 / 山隐子 / 江湖客 / 幽谷客 / 铁匠之子 7 行。页面仍显示 `成员数: 6 / 8`，判断为不含祖师的成员计数口径，不影响本项。 |
| ② 立绘与身份吻合 | PASS (R2) | R2 截图中祖师为师徒画风 portrait；6 个 candidate 分别呈现竹林剑客、沙漠行客、山隐士、江湖客、幽谷客、铁匠之子意象。 |
| ③ 48x48 立绘 + schoolColor 边框布局正常,不挤压姓名/境界/chip/按钮 | PASS (R2) | R2 顶部与底部截图中 portrait + 边框尺寸稳定；姓名、境界、祖师/长老 chip、初入 chip、退派按钮未被挤压。 |
| ④ 强制招募列表每行 40x40 缩略图,姓名/id/流派/境界 文本仍在 | PASS | `b_force_recruit_list.png` 中 6 行均有左侧缩略图，姓名、id、流派、境界文本保留。 |
| ⑤ 确认 dialog 顶部 96x96 立绘,下方姓名/流派/属性/lore 仍完整 | PASS | `b_recruit_confirm_dialog.png` 中竹影客 dialog 顶部大立绘可见，姓名、流派 chip、根骨/悟性/身法/机缘和 lore 文本完整。 |

## 截图路径

- `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_member_row_closeup.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_top_r2.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/a_sect_members_bottom_r2.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_force_recruit_list.png`
- `docs/handoff/codex_visual_sect_portrait_2026-05-31/b_recruit_confirm_dialog.png`

## 运行记录

- A 段启动: `open /Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app`，route 直达 `sect_screen`。
- A 段 R2 启动: `open /Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app`，复用 commit `62ab9d2` 的 route app；窗口 1280 x 720 logical points，截图 2560 x 1440 pixels。
- B 段启动: `flutter run -d macos`，触发一次 macOS debug build 并成功；未运行 `build_runner`，未使用临时 worktree。
- 权限/导航: AppleScript 普通 `click at` 对 Flutter 点击不稳定；改用键盘导航和 CGEvent 点击完成进入页面、滚动和打开 dialog。
- 存档: A 段 route 使用内置 seed；B 段只打开强制招募 dialog，未点击「招入门派」。未改代码、未改 yaml、未 push。
- R2 边界: 未 checkout、未 build、未改代码、未改 yaml、未 push、未装新包。

一句话总评: R2 已关闭 A 段祖师立绘空框缺口；sect 成员页 7 行 portrait wiring 视觉验收通过。
