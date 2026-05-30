# Phase A 主菜单 视觉垂直切片 · 工程 spec

> 2026-05-31 起草 · 出版美术阶段(1.0 Presentation Pass)第一刀 · 配套 `docs/PUBLISHING_ART_PASS_1_0.md`
> 决议来源:§0.6 方向决议(光效水墨为主+关键节点彩光 · 第一刀主菜单 · 精度 B)

## 目标

把主菜单从「调试面板感」(15 入口平铺 maxWidth 480 居中竖列 + 顶部 200px 局部山景 + 扁卡按钮)做成**门面**:不解释背景旁人能判断这是武侠游戏主界面;1280×720 不遮挡、1920×1080 不空洞;release build 无 debug/Phase/seed。

## 三决议(用户拍板)

1. **入口分组**:主入口(主线/角色/装备/心法/闭关/爬塔)+ 次入口(师徒/江湖/门派/排行/百科 + 战斗形态心魔/轻功/群战/PVP)。**不加「继续江湖」**(无单一继续语义)·**「设置」延后**(无 settings 屏)。
2. **题字**:可商用中文书法字体方向(非图),本切片先现有字体占位,字体授权确认后替。
3. **全屏 bg**:先 mountain_bg 拉伸占位把布局/组件跑通,精修 bg 后补(代码与素材解耦)。

## 任务拆解(A1-A5 · 各自可独立 + 验收)

| # | 任务 | 涉及文件 | 复用/缺素材 | 风险 | 模型 |
|---|------|---------|-----------|------|------|
| A1 | 抽 `WuxiaInkButton` 组件(收敛 `_MenuButton` inline,**行为不变**) | 新 `lib/shared/widgets/wuxia_ink_button.dart` + widget 测 | 复用 WuxiaColors,不新建色板 | 低(纯加新文件) | high |
| A2 | 全屏门面背景层(顶部 200px → 全屏水墨+渐隐) | `main_menu.dart` L100-113 | 缺主菜单全屏 bg,先 mountain_bg 占位 + errorBuilder | 低 | high |
| A3 | 题字标题(书法字体占位 + 印章角标可选) | `main_menu.dart` L124-133 + 可选 `WuxiaSealBadge` | 缺书法字体(占位先行) | 字体授权 | high |
| A4 | **入口分组 + 宽屏布局**(主/次分组 + 折叠次入口 + bg 占满靠左栏) | `main_menu.dart` L114-308 重排 + `main_menu_test` 重写 | 纯代码 | **中(跨文件大改 · widget 测重写 · 两分辨率验)** | **xhigh** |
| A5 | 锁态样式(锁印 icon + 克制灰) | `WuxiaInkButton` disabled 态 | 缺锁印小图标(占位) | 低 | high |

## 素材缺口(本切片占位 → 后补精修)

| 素材 | 状态 | 本期 |
|---|---|---|
| 主菜单全屏门面 bg | 缺(仅 mountain_bg 局部) | 占位拉伸,精度 B 关键屏后出图 |
| 书法题字字体 | 缺 | 占位字体,授权确认后替 |
| 锁印小图标 | 缺 | 简单图标占位 |
| 角色立绘点缀(可选) | 有 founder.png | 直接复用试 |

## 验收(Mac 本地 Codex · 2026-05-31 本地化)

- Mac 本地 `flutter run` 启动 → Codex 截 1280×720 + 1920×1080 两张主菜单。
- 标准:不解释背景旁人能判断武侠游戏主界面 · 1280 不遮挡 / 1920 不空洞 · release 无 debug/Phase/seed。
- 我多模态 Read 截图亲验布局/色阶,美感由用户定夺。

## 测试纪律(守 1602 测 / 0 analyze)

- 每个任务 PR 跑 `flutter test` + `flutter analyze`。
- `WuxiaInkButton` 抽取后,原 `_MenuButton` 行为(disabled 0.4 透明 + 拦点击 + label/hint)由 widget 测锚住。
- A4 重排后 `main_menu_test`(现 12 按钮断言)需同步重写。
- 所有 `Image.asset` 带 errorBuilder。

## 工作量(代码侧 · 美术另算)

A1 ~半天 / A2 ~2-3h / A3 ~2-3h(卡字体) / A4 ~半天-1天(含测重写) / A5 ~1-2h → **代码侧合计 ~2-3 天**,卡点在素材占位与字体授权,可解耦推进。

## 顺序

A1(安全 · 先行)→ A2/A3/A5(占位,可并)→ A4(跨文件重排,**建议 xhigh**,放最后整合)。
