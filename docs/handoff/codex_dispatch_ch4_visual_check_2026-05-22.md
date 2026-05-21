# Codex 桌面 @ Pen 视觉验收派单 · Ch4「西出阳关」全收口(2026-05-22)

> 派单方:Mac Opus 4.7(8h autonomous 工作流 B1 批次起草,留用户起床派单)
> 执行方:Codex 桌面 @ Pen Windows(SSH `100.73.91.112` / `F:\Projects\wuxia_idle`)
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md`**(Ch4 1.0 P2 第二条主线第 1 章 Phase 2 全收口 closeout · 9 commit + 13 narrative + R5 红线压测)
3. **`docs/handoff/p1_x_chapter4_spec_2026-05-21.md`**(Ch4 spec 设计稿 · 数值矩阵 + 4 拍板叙事弧 + Tier 风格梯度)
4. **`PROGRESS.md` 顶段**(候选 2 Ch4 Phase 2.1-2.5 全收口 · P2 第二条主线 ~85%)
5. **本会话 commit `4f7fb6d` ... `537c4d4`** (`git log --oneline -10`)— 数值 + narrative + R5 + GDD/ROADMAP/PROGRESS 9 commit

---

## 1. 任务一句话

**Ch4 全收口后跑视觉验收 · 截 8-10 张图覆盖 4 章卡 + Ch4 5 关战斗 + biome desert/frontier sceneBackground + narrative 显示 + 主菜单 mainline hint 更新**。

Phase 2 已全收口(9 commit + R5 跨阶红线压测 + GDD v1.3 + ROADMAP_1_0 + PROGRESS),需 GUI 视觉层确认数据落地与 UI 渲染一致。

---

## 2. 验收点表(8-10 张图)

| # | 文件名 | Screen | 验收点 | 关键资源 / 字符串引用 |
|---|---|---|---|---|
| 01 | `ch4_01_main_menu_hint.png` | MainMenu | 主菜单「主线」按钮 hint「**4 章 20 关**」(原 3 章 15 关 → 4 章 20 关,`lib/shared/strings.dart mainMenuMainlineHint`) | `strings.dart` |
| 02 | `ch4_02_chapter_list_4chapters.png` | ChapterListScreen(主菜单 → 主线) | 4 章卡全显:Ch1「学武出山」/ Ch2「武林初识」/ Ch3「名扬江湖」/ **Ch4「西出阳关」**(原 3 章 → 4 章,Ch4 hint「潼关西行,玉门古道、大漠迷踪、嘉峪关一决」) | `chapter_list_screen.dart` |
| 03 | `ch4_03_chapter4_detail_5stages.png` | ChapterDetailScreen Ch4(章 4 tap 进) | 5 关列表全显:stage_04_01「阳关初渡」/ 02「古道行商」/ 03「沙海迷踪」/ 04「西凉论剑」(小 Boss)/ 05「阳关一决」(大 Boss · 跨 jueDing) | `stages.yaml` Ch4 5 关 |
| 04 | `ch4_04_stage_04_01_opening.png` | stage_04_01 战斗前 narrative dialog | opening narrative「阳关初渡 · 启」显示 4 段(出潼关一路向西…路上没遇见几个行人。傍晚到河西走廊…) | `data/narratives/stages/stage_04_01_opening.yaml` |
| 05 | `ch4_05_stage_04_02_battle_frontier.png` | stage_04_02 战斗中 | biome=**frontier**(玉门古道) sceneBackground 应显示对应背景(`frontier` 新加 enum,可能 fallback `mountainPath`) | EncounterBiome.frontier sceneBackground 路径 |
| 06 | `ch4_06_stage_04_03_battle_desert.png` | stage_04_03 战斗中 | biome=**desert**(大漠戈壁) sceneBackground 应显示对应背景(`desert` 新加 enum,可能 fallback `mountainPath`) | EncounterBiome.desert sceneBackground 路径 |
| 07 | `ch4_07_stage_04_04_battle_drillGround.png` | stage_04_04 战斗中(小 Boss · 西凉论剑场) | biome=drillGround 复用 + 3 敌人(西凉武林名宿 yiLiu·yuanShu·gangMeng + 2 名宿之徒 yiLiu·jingTong)+ isBossStage=true 视觉标记(若有 Boss 旗) | `stages.yaml stage_04_04` |
| 08 | `ch4_08_stage_04_05_battle_boss.png` | stage_04_05 战斗中(大 Boss · 阳关一决) | biome=frontier(嘉峪关古关塞,夜战 weather=night) + 3 敌人(**西凉霸主 jueDing·qiMeng·yinRou HP 15,500** + 左护法 gangMeng + 右护法 lingQiao)+ isBossStage=true + 跨阶 boss 视觉标记 | `stages.yaml stage_04_05` |
| 09 | `ch4_09_stage_04_05_victory_narrative.png` | stage_04_05 战胜后 victory narrative | 章末顿悟 narrative「阳关一决 · 终」显示 4 段(三个人都倒了 … 西凉霸主开口「中原的剑——比我想的快了半寸」… 小铜镜留下 hook Ch5/Ch6) | `data/narratives/stages/stage_04_05_victory.yaml` |
| 10 | `ch4_10_chapter4_epilogue.png`(选)| ChapterEpilogueScreen / 章末 narrative dialog(若有) | chapter_04 epilogue「已知不足」哲学顿悟 5 段(嘉峪关的旗子在夜里垂着 … 师父第二句遗言「听那处地方的风」终听懂一半 … 剑往上走那段路已走完,但再往上的那一段,不在剑上)| `data/narratives/chapters/chapter_04.yaml` |

**注**:截图 04/09/10 依赖 narrative dialog 渲染逻辑,若 Ch4 narrative loader 走 graceful「[剧情待补]」兜底(stage_04_05_defeat 体例),则 narrative 文件存在即活,不应 fallback。**确认 narrative 渲染显示 ✓**。

---

## 3. 工具链步骤

```bash
# F:/Projects/wuxia_idle 工作树 reset 后与 origin/main 同步,HEAD = 537c4d4
cd /d F:\Projects\wuxia_idle

# 1. 拉最新(Ch4 全收口 9 commit)
git pull origin main

# 2. flutter clean(避免增量 build 缓存假象,memory feedback_codex_pen_windows_visual_check round 2 教训)
flutter clean

# 3. pub get
flutter pub get

# 4. build_runner 跑(Ch4 新加 EncounterBiome desert/frontier 2 enum · encounter_progress.g.dart .gitignored 需重生)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. flutter run -d windows
flutter run -d windows
# 推荐 hot reload 模式,需切多 Screen
```

---

## 4. 截图工具

PowerShell .NET 零依赖(memory `feedback_codex_pen_windows_visual_check`):
```powershell
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$scr = [System.Windows.Forms.Screen]::PrimaryScreen
$bmp = New-Object System.Drawing.Bitmap $scr.Bounds.Width, $scr.Bounds.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($scr.Bounds.Location, [System.Drawing.Point]::Empty, $scr.Bounds.Size)
$bmp.Save("F:\Projects\wuxia_idle\docs\screenshots\ch4_<N>_<name>.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
```

---

## 5. 数据 seed(关键)

Ch4 在主线进度未到 Ch3 末关时**锁住**。需先 seed 玩家到 Ch3 末关通关状态:

**选 A(推荐)**:开 dev menu → Phase 2 seed → 选 seedP3(yiLiu·qiMeng 玩家)→ 通关 stage_01_01 → ... → stage_03_05(15 关)→ Ch4 自动解锁。但 15 关战斗费时较长(~30-60min 跑完)。

**选 B(快速)**:dev menu 调玩家境界到 yiLiu·dengFeng + 直接修改 mainline progress 到 stage_03_05 通关状态。需找 dev tool 中是否有「跳关 / 调进度」按钮。

**选 C(终极)**:写一个 `seedP5_ch4_unlocked()` test fixture 在 phase2_seed_service.dart,把 mainline progress 直接 fast-forward 到 Ch4 开启状态。**Codex 自行决定**(若 Codex 看到 dev menu 已有「跳关」按钮可走选 B;否则申请加 seedP5 fixture 跳过这一步)。

---

## 6. 关键检查点(visual layer)

| 检查项 | 期望 | WARN/FAIL 条件 |
|---|---|---|
| Ch4 章卡显示 | 章标题「西出阳关」+ hint「潼关西行,玉门古道、大漠迷踪、嘉峪关一决」| 文字截断 / 字体溢出 / 字符串引用旧值 |
| stage_04_05 西凉霸主 HP | 15,500 应显示战斗 UI 顶部 hp bar | HP 数字不对 / hp bar 比例失真 |
| stage_04_02/03/05 sceneBackground | biome=frontier/desert 应显示对应背景(EncounterBiome 新 enum,可能 fallback `mountainPath` 因为 art asset 未铺) | 黑屏 / null pointer 抛错 / fallback 不优雅(应有默认背景而非空) |
| stage_04 narrative dialog | 中文文案显示 4-6 段 paragraphs[] list,字体克制 / 行距合理 | 文案乱码 / 行距挤 / 段间分隔不清 |
| stage_04_05 跨阶 Boss 视觉标记 | jueDing·qiMeng 西凉霸主应有 Boss 旗 / 颜色区分 / 跨阶提示(若 UI 有)| 与普通敌人无区分 |

---

## 7. WARN/FAIL 判定

- **PASS**:截图覆盖验收点 + 关键文字 / 数值正确显示 + UI 渲染无 broken
- **WARN**:核心可用但有细节问题(字体偶尔重叠 / fallback 背景但功能 OK / Boss 旗缺失但战斗机制完整)
- **FAIL**:Ch4 章卡未解锁 / 战斗抛 exception / narrative 0 段显示 / null pointer

---

## 8. closeout 体例

完成后回写 `docs/handoff/ch4_visual_check_closeout_2026-05-22.md`(Pen 端写),包含:
- 8-10 张图归档路径
- 每张图 PASS/WARN/FAIL 标注 + 一句话备注
- WARN/FAIL 项后续 fix 建议(若适用)
- HEAD sha + flutter 版本 + build_runner 是否跑成功

---

## 9. 不变量沿用

- memory `feedback_codex_pen_windows_visual_check`:flutter clean 重建 + PowerShell 零依赖截图 + fixture self-check
- memory `reference_pen_wuxia_flutter_run`:schtasks Console Session 1 / Access denied fallback / kill+relaunch
- memory `feedback_flutter_subscreen_appbar_audit`:确认 ChapterDetailScreen Scaffold 有 AppBar 可返回
- GDD §1 写实武侠风 / §5.4 数值红线 / 不写网游词

---

**Codex 派单完成后报 closeout 即可,不必联系 Mac 端。预计 ~1-1.5h 跑完(含 seed 数据 + 10 截图 + closeout doc 写)。**
