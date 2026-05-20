# Codex 桌面 @ Pen 视觉验收派单 · 候选 1 round 2(2026-05-21)

> 派单方:Mac Opus 4.7
> 执行方:Codex 桌面 @ Pen Windows(SSH 100.73.91.112 / `F:\Projects\wuxia_idle`)
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/art_assets_integration_visual_check_closeout_2026-05-21.md`**(round 1 closeout · Pen 工具链 OK + 派单 prompt UI 字符串引用教训)
3. **`PROGRESS.md` 顶段**(M4 #46 「1.0 Demo §7 UI 完善阶段」候选 1 收口,Mac 端 ~1h 实装)
4. **本会话 commit `3b5c36e` + `0f8bde3`** (`git log --oneline -3`)— 6 Screen Image.asset 接入 + 8 UI 资源全消费

---

## 1. 任务一句话

**候选 1 完工后跑 round 2 视觉验收 · 截 9 张图覆盖 6 Screen 主接入 + 8 UI 资源(seal/landscape 已 round 1 验过 baseline 复核)+ 美术克制 GDD §1 整体氛围**。

候选 1(M4 #46 「1.0 Demo §7 UI 完善阶段」)Mac 端 ~1h 实装完工,1123 pass / analyze 0,提交 `3b5c36e`。本派单为 GUI 视觉层最终验收。

---

## 2. 验收点表(9 张图)

| # | 文件名 | Screen | 验收点 | 关键资源 |
|---|---|---|---|---|
| 01 | round2_01_main_menu_mountain.png | MainMenu | 顶部 200h 远山远景 alpha 0.25 + 9 按钮全景 | `mountain_bg.png` |
| 02 | round2_02_chapter_list.png | ChapterListScreen(主菜单 → 主线) | AppBar bottom 36h scroll_horizontal 装饰条 + 3 章节卡 | `scroll_horizontal.png` |
| 03 | round2_03_inventory_equipment.png | InventoryScreen 装备 Tab | _Row 左侧 56×56 iconPath 缩略图 + tier 色边 + 各阶 ExpansionTile 展开 | `assets/equipment/<35 件>.png` 中可见 |
| 04 | round2_04_equipment_detail.png | EquipmentDetailScreen(任选 1 装备 tap 进入) | 顶部 180h detailPath 大图 + tier 色底边 + paper_bg 半透明背景 + lore 段间 ink_divider 上方 8h 装饰 + `· · ·` text | `<weapon>_detail.png` + `paper_bg.png` + `ink_divider.png` |
| 05 | round2_05_inventory_material.png | InventoryScreen 物料 Tab | _MaterialRow 左侧 coin_icon 16×16 + 物料名称量 | `coin_icon.png` |
| 06 | round2_06_lineage_panel.png | LineagePanelScreen(主菜单 → 师徒名单) | 顶部 80h scroll_vertical 装饰条 + 祖师/弟子 chip 左侧 80×80 立绘 portraitPath + 师承遗物段 | `scroll_vertical.png` + `assets/characters/*.png` |
| 07 | round2_07_technique_panel.png | TechniquePanelScreen(主菜单 → 心法面板)| AppBar 右上 24×24 lotus_icon | `lotus_icon.png` |
| 08 | round2_08_seclusion_meditation.png | SeclusionMapListScreen(主菜单 → 闭关修炼)| AppBar 右上 24×24 meditation_icon + 5 张地图缩略(round 1 已验) | `meditation_icon.png` |
| 09 | round2_09_home_feed_seal_baseline.png | HomeFeedScreen(启动第一屏)| **baseline 复核**:AppBar 右上 36×36 seal_red(round 1 已 PASS,本次 confirm 无 regression) | `seal_red.png` |

**注**:截图 03 装备 Tab 中实际可见的 iconPath 数取决于玩家存档(默认存档可能 0 装备 → 显「暂无装备」空态)。需用 Phase 2 seed 角色数据塞装备,或直接看 Phase 2 test_menu seed 后再进 InventoryScreen。**如果 0 装备**:截空态图 + 标 WARN(数据问题非视觉问题)。

---

## 3. 工具链步骤

```bash
# F:/Projects/wuxia_idle 工作树 reset 后已与 origin/main 同步(本会话候选 3 完成),HEAD = 0f8bde3
cd /d F:\Projects\wuxia_idle

# 1. 拉最新(候选 1 + 候选 3 commit)
git pull origin main

# 2. flutter clean(避免增量 build 缓存假象,memory feedback_codex_pen_windows_visual_check round2 教训)
flutter clean

# 3. pub get(libisar.dll 等 native 依赖自动下载)
flutter pub get

# 4. build_runner 跳过 — 本会话改动均为普通 widget,无 @riverpod / @collection 注解新增

# 5. flutter run -d windows(或 flutter build windows --debug + 跑 .exe)
flutter run -d windows
# 推荐 flutter run + hot reload 模式,需要切多 Screen
```

**导航路径**(主菜单 9 按钮全在):
- 截图 01 = 主菜单加载完成
- 截图 02 = 主菜单 → 「主线」按钮 → ChapterListScreen
- 截图 03 = 主菜单 → 「装备仓库」→ InventoryScreen 默认 装备 Tab
- 截图 04 = 装备 Tab → 任 tap 1 个装备 row → EquipmentDetailScreen
- 截图 05 = InventoryScreen → 切「物料」Tab
- 截图 06 = 主菜单 → 「师徒名单」→ LineagePanelScreen
- 截图 07 = 主菜单 → 「心法面板」→ TechniquePanelScreen
- 截图 08 = 主菜单 → 「闭关修炼」→ SeclusionMapListScreen
- 截图 09 = 启动第一屏(从 SplashScreen 进入后即 HomeFeedScreen)

---

## 4. 截图工具

沿用 round 1 的 PowerShell `.NET CopyFromScreen` 方案(零依赖,见 round 1 closeout §2):

```powershell
# 截 PrimaryScreen 全屏 → docs/screenshots/round2_NN_<name>.png
Add-Type -AssemblyName System.Windows.Forms
$bmp = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Location, [System.Drawing.Point]::Empty, $bmp.Size)
$bmp.Save("F:\Projects\wuxia_idle\docs\screenshots\round2_NN_<name>.png", [System.Drawing.Imaging.ImageFormat]::Png)
```

**关键**:Pen 屏幕物理 1280×720 限制(round 1 教训),不影响视觉验收(截 1280×720 也能看清各资源接入)。

---

## 5. 验收判定标准

每张图标 **PASS / WARN / FAIL**:

- **PASS**:验收点全可见 + 视觉效果合理 + 水墨克制 GDD §1
- **WARN**:验收点可见但有测试环境干扰(输入法浮条 / 屏幕限制 / 数据空态)— **非 product bug**
- **FAIL**:验收点完全 missing / 渲染异常 / 布局炸 — **product bug,Mac 端需修**

**整体判定**:
- 9/9 PASS → 候选 1 真·闭环 ✅
- 部分 WARN(测试环境)→ 实质 PASS,closeout 记录环境干扰
- 任 FAIL → 报 Mac 端 + 不动 Pen / Codex,等 Mac 修复 push 后 round 3

---

## 6. closeout 模板

在 `docs/handoff/codex_round2_visual_check_closeout_2026-05-21.md` 沿 round 1 体例写:

```
§1 9 张截图判定矩阵(表)
§2 工具链结果(git pull / clean / pub get / build / run / 截图)
§3 各资源效果点评(水墨克制 / 立绘 / mountain_bg 是否压数值 / paper_bg 是否压文字 ...)
§4 教训沉淀(如有)
§5 候选 1 视觉验收总结(round 1 + round 2 综合)
§6 下波建议(无 / 候选 2 心法相生 / 候选 4 P2 主线)
```

closeout 写完 commit + push origin。Mac 端 fetch 后看。

---

## 7. 沟通契约

- **不联系派单方**(Codex 全程独立跑)
- **失败也报**:如 flutter run 起不来 / pub get 卡 / 截图 PowerShell 报错 → 记录 closeout §2 直接报 FAIL,不硬撑
- **不动 Mac 端代码**:Codex 仅截图 + 写 closeout doc,Pen 仓库改动只是 closeout md + 截图 png
- **commit message 体例**:`docs(handoff): codex round2 视觉验收 closeout 2026-05-21`
- **不动 Mac 拥有的内容**:不动 lib/ / data/ / test/(派单方专属)— 只产 docs/handoff/ + docs/screenshots/

---

**派单完结**。Codex Pen 端按 §3 工具链 + §4 截图工具 + §5 判定 + §6 closeout 执行。
