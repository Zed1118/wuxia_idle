# Codex 视觉验收提速提示词规范

面向：Claude / 派单方  
项目：挂机武侠  
用途：让 Codex 做本地视觉验收时更快、更稳、更少误连旧 app 或卡在构建/导航/存档问题上。

## 一句话原则

把 Codex 的任务从“现场搭环境 + 猜路径 + 找数据 + 截图 + 判断”压缩成“打开已知 app + 直达已知页面 + 截图 + 判断”。

视觉验收最快的输入不是 commit，而是“已编译好的目标 app + 目标页直达方式 + 固定 seed + 明确截图清单”。

## 最推荐派单方式

优先给 Codex 一个已经编译好的 app 路径：

```text
打开这个 app：
open /absolute/path/to/build/macos/Build/Products/Debug/wuxia_idle.app

该 app 已确认来自 commit <sha>，不用 checkout，不用 build。
```

并给直达目标页面的方式：

```text
启动后会自动进入 <目标页面>。
如果没有自动进入，用 debug route：
--dart-define=VISUAL_ROUTE=<route_name>
```

如果没有直达 route，也要给最短可点路径：

```text
导航路径：
江湖见闻 → 直入江湖 → 修行 → 心法面板
```

还要给确定的数据状态：

```text
本 app 内置 visual seed：
- 主修 1 条：当前 5/9 层
- 辅修 4 条：覆盖刚猛 / 灵巧 / 阴柔
- 列表超过一屏，可验证滚动连续性
```

这样 Codex 只需要：

1. 关旧 app。
2. 打开指定 app。
3. 进入目标页。
4. 截图。
5. 目视验收并写 closeout。

## 不推荐派单方式

不要只给：

```text
git checkout <sha>
flutter run -d macos
自己导航到目标页
空面板就想办法 seed
```

这会慢，因为 Codex 需要处理：

- 主工作树未提交改动，不能直接 checkout。
- commit 缺生成文件，需要 build_runner。
- pod / Flutter 构建耗时。
- macOS 上同 bundle id 旧 app 和新 app 可能同时存在，容易误连旧构建。
- 当前本地存档不可控，目标页面可能没有验收所需数据。
- 页面路径不稳定，要靠 UI 探路。
- `screencapture` 可能截到桌面其他窗口，需要裁图。

## 标准提示词模板

下面模板可直接复制给 Codex。

```text
项目：挂机武侠 (/Users/a10506/Desktop/Projects/挂机武侠)
任务：<模块名> 视觉验收，截图 + closeout，不改代码，不 push。

【版本/启动】
优先使用已编译 app，不要 checkout：
open <绝对路径>/wuxia_idle.app

该 app 已确认来自 commit <sha>。
若 app 已在运行，先关旧进程：
pkill -f wuxia_idle || true

不要执行 flutter build / flutter run，除非 app 路径不存在。

【目标页】
目标页面：<页面名>
直达方式：
<例如：启动自动进入 / debug route / 菜单路径>

【验收数据】
使用内置 visual seed：<seed_name>
该 seed 应包含：
- <必须出现的数据状态 1>
- <必须出现的数据状态 2>
- <必须出现的数据状态 3>

如果没有看到上述数据，先截图记录，不要临时改代码。

【截图输出】
保存目录：
docs/handoff/<task_name>_<date>/

必收截图：
1. <name>.png — <说明>
2. <name>.png — <说明>

截图要求：
- 尽量最大化窗口。
- 如果 1920x1080 和 1280x720 都要验，请明确写出。
- 如果内容需滚动，请写清要截上半 / 中段 / 底部。

【验收点】
逐条 PASS / WARN / FAIL：
① <验收点 1>
② <验收点 2>
③ <验收点 3>

【closeout】
写到：
docs/handoff/<task_name>_<date>/closeout.md

必须包含：
- 每条验收点结论表
- 截图路径
- 实际窗口尺寸
- 是否遇到构建/权限/导航/存档问题
- 一句话总评

【边界】
- 不改代码
- 不改 yaml
- 不 push
- 不装新包
- 如果必须生成代码或 build_runner，只能在临时 worktree 内做，并在 closeout 说明
```

## 如果只能给 commit

如果没有已编译 app，只能给 commit，请明确允许 Codex 用临时 worktree：

```text
主工作树可能有未提交改动。
不要在主工作树 checkout。
请使用临时 worktree：
/tmp/wuxia_idle_visual_<sha>

命令：
git worktree add --detach /tmp/wuxia_idle_visual_<sha> <sha>
cd /tmp/wuxia_idle_visual_<sha>
dart run build_runner build --delete-conflicting-outputs  # 如缺 .g.dart 才跑
flutter run -d macos

截图仍保存到主项目：
/Users/a10506/Desktop/Projects/挂机武侠/docs/handoff/<task>/
```

这会比已编译 app 慢，但比直接污染主工作树安全。

## 工程侧最好补的能力

为了让视觉验收稳定，建议加 debug-only visual route：

```bash
flutter run -d macos --dart-define=VISUAL_ROUTE=technique_panel_b
```

应用启动时：

- 自动跳过「江湖见闻」。
- 自动注入固定 visual seed。
- 自动进入目标页面。
- 禁止读取真实玩家存档，或优先使用临时 visual slot。
- 页面右上角可显示小字版本信息：`visual: technique_panel_b · <sha>`。

推荐 route 命名：

```text
main_menu_phase_a
technique_panel_b
equipment_detail_b
character_panel_lineage
stage_result_reward
```

推荐 visual seed 结构：

```text
technique_panel_b:
- 角色境界：一流
- 主修心法：当前 5/9 层
- 辅修心法：至少 4 条
- 覆盖三流派：刚猛 / 灵巧 / 阴柔
- 覆盖不同阶：入门功 / 名家功 / 江湖秘传
- 列表超过一屏
- 有可点击但不需要点击的按钮状态
```

## 截图自动化建议

建议提供项目脚本：

```bash
scripts/visual_capture.sh <app_path> <output_dir> <basename>
```

脚本负责：

- `pkill -f wuxia_idle`
- `open <app_path>`
- AppleScript 激活窗口
- 设置窗口尺寸
- `screencapture -x`
- Retina 2x 裁图
- 输出文件尺寸

这样 Codex 不需要反复处理 macOS 截图细节。

## Codex 最怕的歧义

派单时尽量不要出现这些句子：

```text
入口路径若不同自己找一下
空面板可用 debug seed 或换角色
如果窗口装不下就自己看着截
当前主端还在改同一文件
```

这些都能做，但会慢。更好的写法是：

```text
若没有进入目标页，点击：调试 → Visual Seeds → technique_panel_b → 打开心法面板。
目标页必须出现 1 主修 + 4 辅修；若未出现，直接 FAIL「seed 未生效」并截图。
截图分三张：top / middle / bottom。
不要自行切换其他角色。
```

## 推荐 closeout 格式

```markdown
# <任务名> 视觉验收

版本：<sha 或 app build 标识>
截图目录：<path>
实际窗口：<logical px>，截图像素：<pixel px>

| # | 验收点 | 结论 | 说明 |
|---|---|---|---|
| 1 | ... | PASS | ... |
| 2 | ... | WARN | ... |

## 总评

一句话：<达标 / 基本达标 / 不达标>。

最需要精修：
1. ...
2. ...

## 踩坑

- 是否误连旧 app：
- 是否需要 build_runner：
- 是否遇到 Screen Recording 权限：
- 是否受当前存档影响：
```

## 最快验收派单示例

```text
项目：挂机武侠
任务：心法面板 B 段视觉验收，只截图 + closeout，不改代码、不 push。

启动：
open /Users/a10506/Desktop/visual_builds/wuxia_idle_472be3e.app
该 app 已确认来自 472be3e，不要 checkout，不要 flutter run。

目标页：
启动后自动进入心法面板。
若未自动进入，点右上角 debug → Visual Seeds → technique_panel_b。

验收数据：
必须看到：
- 主修 hero
- 当前层 5/9
- 9 段阶梯含已过色、当前金、未到灰
- 至少 4 条心法 tile
- 列表可滚动到底部

截图：
输出到 docs/handoff/b_technique_panel_visual_2026-05-31/
1. technique_panel_top.png
2. technique_panel_middle.png
3. technique_panel_bottom.png
4. technique_panel_1280x720.png

验收点：
① 宣纸底 + 墨边卷轴框感
② hero 打坐图 + 内丹金光点克制
③ 9 层阶梯三态清晰
④ seal_red 印章和 ink_divider 自然
⑤ 青墨 + 宣纸黄 + 绛红 + 金色统一
⑥ 滚动到底部不露深色断层

closeout：
写 docs/handoff/b_technique_panel_visual_2026-05-31/closeout.md
包含 PASS/WARN/FAIL 表、截图路径、窗口尺寸、总评、踩坑。
```

## 速度预期

| 输入质量 | 预计耗时 | 主要风险 |
|---|---:|---|
| 已编译 app + 自动进入目标页 + visual seed | 2-5 分钟 | 截图权限 / 目视判断 |
| 已编译 app + 手动导航 + 确定 seed | 5-8 分钟 | 导航路径变化 |
| commit + 临时 worktree + 已知 build_runner | 10-20 分钟 | 构建失败 / 旧 app 误连 |
| commit + 主工作树有改动 + 无 seed + 路径不确定 | 20+ 分钟 | 环境、数据、导航都要排查 |

## 给 Claude 的派单检查清单

发给 Codex 前确认：

- [ ] 我是否能给已编译 app，而不是只给 commit？
- [ ] app 是否确认来自目标 commit？
- [ ] 是否说明不要 checkout / 不要 build？
- [ ] 是否有 debug route 或 visual seed？
- [ ] seed 是否覆盖所有需要目视的状态？
- [ ] 截图文件名是否固定？
- [ ] 是否说明窗口尺寸？
- [ ] 是否说明滚动截图范围？
- [ ] closeout 格式是否明确？
- [ ] 是否写清不改代码、不 push、不装新包？

只要这 10 项齐，Codex 的视觉验收速度会明显提升。
