# Codex 桌面 @ Pen 视觉验收派单 · Ch4「西出阳关」全收口(2026-05-22)

> 执行方:Codex 桌面 @ Pen Windows(SSH `100.73.91.112` / `F:\Projects\wuxia_idle`)
> 沟通契约:全程不联系派单方,只 closeout 报回。失败也有价值不硬撑。

## 必读

1. 本派单 + `docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md`(Ch4 全收口 9 commit)
2. `git log --oneline -10` 看本会话 commit
3. memory `feedback_codex_pen_windows_visual_check` + `reference_pen_wuxia_flutter_run`

## 任务

**截 8-10 张图覆盖 Ch4**:4 章卡 + 5 关战斗 + biome desert/frontier sceneBackground + narrative 显示 + 主菜单 `mainlineHint「4 章 20 关」`

## 验收点(8-10 张图)

| # | 文件 | Screen | 验收点 |
|---|---|---|---|
| 01 | ch4_01_main_menu_hint | MainMenu | 主线 hint「4 章 20 关」(`strings.dart mainMenuMainlineHint`) |
| 02 | ch4_02_chapter_list_4chapters | ChapterListScreen | 4 章卡 + Ch4「西出阳关」hint「潼关西行,玉门古道、大漠迷踪、嘉峪关一决」 |
| 03 | ch4_03_chapter4_stages | ChapterDetailScreen Ch4 | 5 关列表(stage_04_01..05) |
| 04 | ch4_04_stage_04_01_opening | narrative dialog | opening 4 段(出潼关一路向西…) |
| 05 | ch4_05_stage_04_02_battle_frontier | 战斗中 | biome=**frontier**(玉门古道)sceneBackground(可能 fallback) |
| 06 | ch4_06_stage_04_03_battle_desert | 战斗中 | biome=**desert**(大漠) |
| 07 | ch4_07_stage_04_04_battle_drillGround | 小 Boss 战斗 | drillGround + 西凉武林名宿 + 2 副 + isBossStage |
| 08 | ch4_08_stage_04_05_battle_boss | 大 Boss 战斗 | frontier + night + **西凉霸主 jueDing·qiMeng HP 15,500** + 2 护法 + 跨阶 boss |
| 09 | ch4_09_stage_04_05_victory_narrative | 战胜 narrative | 章末顿悟「中原的剑——比我想的快了半寸」+ 小铜镜 hook |
| 10(选)| ch4_10_chapter4_epilogue | 章末(若 UI 有)| ⚠ chapter narrative **lib/ 0 引用半完成**,可能无显示,跳过截即可 |

**注**:Ch4 enemy iconPath 15 张 png 全缺失(已 audit 挂账,`character_avatar.dart:54` errorBuilder 兜底首字头像)— 截图能看到首字头像即 OK,非 FAIL。

## 工具链

```bash
cd /d F:\Projects\wuxia_idle
git pull origin main         # HEAD ≥ bfa7c67
flutter clean && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # encounter_progress.g.dart 重生
flutter run -d windows       # hot reload 切 Screen 截图
```

PowerShell .NET 截图(memory `feedback_codex_pen_windows_visual_check`):
```powershell
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$scr = [System.Windows.Forms.Screen]::PrimaryScreen
$bmp = New-Object System.Drawing.Bitmap $scr.Bounds.Width, $scr.Bounds.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($scr.Bounds.Location, [System.Drawing.Point]::Empty, $scr.Bounds.Size)
$bmp.Save("F:\Projects\wuxia_idle\docs\screenshots\ch4_<N>_<name>.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
```

## 数据 seed

Ch4 锁住需先通关 Ch3 末关。**Codex 自行决定**:① dev menu 调玩家境界 + mainline progress fast-forward / ② 写 `seedP5_ch4_unlocked()` test fixture / ③ 实跑 15 关(~30-60min,不推荐)。

## closeout 体例

回写 `docs/handoff/ch4_visual_check_closeout_2026-05-22.md`:8-10 图归档 + PASS/WARN/FAIL 各一句话 + HEAD sha。**预计 ~1-1.5h 全程**(seed + 截图 + closeout)。

## 判定

- **PASS**:截图 + 关键文字 / 数值正确 + UI 不 broken
- **WARN**:细节问题(字体重叠 / fallback 背景 / Boss 标记缺)
- **FAIL**:章卡未解锁 / 战斗抛 exception / narrative 0 段
