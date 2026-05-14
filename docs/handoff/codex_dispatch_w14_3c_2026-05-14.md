# Codex 桌面 @ Pen 视觉验收派单 · W14-3-C 奇遇 dialog 节奏 + 装备 UI(2026-05-14)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**(本文档)
2. `PROGRESS.md`(当前阶段 + W14-3-A/B/C 上下文)
3. `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md`(W14-3-A 装备 UI 实现细节,§3.4 EncounterSkillSection)
4. `docs/handoff/week14_2_biome_weather_idle_tick_2026-05-14.md`(W14-2 biome/weather + 12 条新 events 清单 §4.2)
5. `CLAUDE.md` §5(数值红线 + 反主流不做清单)+ §10(拿不准处理顺序)
6. **方法论参考**:`docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md`(Codex 自己之前写的方法论 + 工具链 + 踩坑)
7. **派单体例参考**:`docs/handoff/codex_dispatch_w7_w11_2026-05-13.md`(W7-W11 首跑模板)

---

## 1. 任务一句话

**验证 W14-3-A 装备 UI(CharacterPanelScreen EncounterSkillSection)+ W14-3-C dialog 节奏精修(入场 fade-in + opening↔outcome cross-fade)的实战效果**。

W14-3-A 闭环 commit `9320286`,W14-3-B/C 闭环 commit `da61652`。Pen 端 `git pull` 后 HEAD 应到 `da61652`。

---

## 2. fixture self-check(必读 — 派单方已 self-check)

| # | 验收点 | 现状 | 影响 |
|---|---|---|---|
| ✅ 1 | W14-3-A 装备 UI(EncounterSkillSection)代码落地 | commit `9320286` | 可验 |
| ✅ 2 | W14-3-C dialog 节奏改动(AnimatedSwitcher + AnimatedOpacity) | commit `da61652` | 可验 |
| ✅ 3 | W14-1 已落 3 条 events 文案 | `bamboo_listen_rain` / `cha_ting_dui_ju` / `du_ke_wen_dao` | 可验 dialog 节奏(用这 3 条) |
| ⚠️ 4 | W14-2 新 12 条 events 文案 | **全 placeholder**(DeepSeek W14-3-B 未落) | **本次跳过,等下批** |
| ⚠️ 5 | Character 已 unlock encounter skill 的 seed | 无现成 seed | 限制完整 EncounterSkillSection 验收 |

**因 #4 + #5,本次验收范围调整**:
- ✅ dialog 节奏:用 W14-1 3 条已落文案(尤其 `du_ke_wen_dao` 只需 fortune ≥ 4,门槛最低)
- ✅ EncounterSkillSection **disabled 空态**(角色无任何 unlocked skill 时显示"尚无可装备奇遇招式"按钮 disabled)
- ❌ EncounterSkillSection **完整 unlocked 态 / bottom sheet / lock icon**:**留下批**(等 Mac 端补 visual_check seed + DeepSeek W14-3-B 文案落地)

---

## 3. 启动 + 准备(用户已 SSH 拉起,Codex 接手即开干)

派单方 Mac 端用 SSH 远程 `git pull` + 启动 wuxia_idle.exe(走 schtasks Console Session 1)。Codex 桌面接手时:

1. Pen RDP 桌面应已有 wuxia_idle 窗口(若无 → 见 `reference_pen_wuxia_flutter_run.md` 重启路径)
2. 验证 HEAD 是 `da61652`:`cd F:\Projects\wuxia_idle && git log -1 --oneline`
3. 窗口尺寸建议固定 **1280×900**(W7-W11 教训:1280×720 主菜单底部按钮被屏幕边缘挡)

---

## 4. 工具链 cheatsheet(零依赖 PowerShell .NET 路线)

| 用途 | 调用 |
|---|---|
| 鼠标点击 | PowerShell `user32.dll` `SetCursorPos` + `mouse_event` |
| 键盘输入 | `keybd_event` / `Add-Type Forms.SendKeys` |
| 滚轮 | `mouse_event MOUSEEVENTF_WHEEL` |
| 截图 | `.NET System.Drawing.Bitmap.CopyFromScreen` |
| 窗口固定 | `SetWindowPos` |

详情见 `docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md`(Codex 自产复盘)。

---

## 5. 验收点 1:W14-3-C dialog 节奏(优先级最高,先验)

### 5.1 触发方式

挂机武侠主菜单 → 「Phase2 测试菜单」 → 「VC」按钮(`seedVisualCheckW7W11`)标 Ch1 01-04 cleared + 师徒齐 + stage_01_05 可挑战。

但更稳的触发奇遇路径:**走 stage_01_01 - stage_01_05 任一关战斗** → victory 后 `runEncounterHookAfterVictory` 会软概率 check `du_ke_wen_dao`(只需 fortune ≥ 4,baseProbability 0.5)。师徒 3 人中至少 1 人 fortune ≥ 4 即可触发。

**若 5 次战斗后仍未触发** → 改试 `bamboo_listen_rain`(需击败 lingQiao 100 + fortune ≥ 3,门槛较高)或 `cha_ting_dui_ju`(三派各 10 + fortune ≥ 5)。或者**重启游戏重 roll fortune**(角色生成时随机)。

### 5.2 验收点(截图)

| # | 截图文件名 | 场景 |
|---|---|---|
| 5-1 | `w14_3c_dialog_opening_fadein.png` | dialog 刚弹出瞬间(尽量截到 opacity 不到 1.0 的中间帧 — 难截,可截弹出 +200ms 帧) |
| 5-2 | `w14_3c_dialog_opening_full.png` | dialog 完全显示后:title + opening 文字 + N 个 choice 按钮 |
| 5-3 | `w14_3c_dialog_outcome_full.png` | 选了 1 个 choice 后:outcome body + 「行路 →」确认按钮 |
| 5-4(选做)| `w14_3c_dialog_outcome_crossfade.png` | 切换瞬间的 cross-fade 帧(难截,可放弃) |
| 5-5(选做)| `w14_3c_dialog_skip_branch.png` | 选「skip」类 choice 后的 body 文字(W14-1 3 条都有 skip) |

### 5.3 视觉判断标准

- ✅ dialog 弹出有 fade-in(opacity 0 → 1,约 500ms)— 不是瞬间显示
- ✅ opening → outcome 切换有 cross-fade(约 420ms) — 不是瞬间替换
- ✅ 文字色调水墨克制(textPrimary / textSecondary / textMuted 三层 — 见 `lib/ui/theme/colors.dart`)
- ❌ 任一帧 dialog 内容错位 / 文字被截断 / 按钮 hit area 偏移 → 标 BUG

---

## 6. 验收点 2:W14-3-A 装备 UI(EncounterSkillSection disabled 空态)

### 6.1 进入路径

主菜单 →「角色面板」(CharacterPanelScreen) → 滚到「奇遇招式」区段(挂在心法段与师承段之间)

### 6.2 验收点(截图)

| # | 截图文件名 | 场景 |
|---|---|---|
| 6-1 | `w14_3a_encounter_skill_section_empty.png` | 角色无任何 unlocked encounter skill → 整个 section 显示空态(具体文案见 `lib/ui/character_panel/encounter_skill_section.dart`,可能是"尚无可装备奇遇招式") |
| 6-2 | `w14_3a_encounter_skill_section_in_layout.png` | 整个 CharacterPanelScreen 截图,EncounterSkillSection 与心法段、师承段的视觉顺序对比 |

### 6.3 视觉判断标准

- ✅ EncounterSkillSection 在视觉上独立可识别(不被吞进心法段)
- ✅ 空态文案存在 + 按钮 disabled(灰色,不可点)
- ✅ section 位置在心法段之后、师承段之前

---

## 7. 命名 + 存放路径(严格)

- 截图放 `docs/screenshots/w14_3c_<seq>_<name>.png`(全 ASCII 命名)
- closeout 文件:`docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`(沿 W7-W11 体例)
- closeout 内容:跑通情况表 + 工具链评价 + 截图对照验收点 + 下次推荐路径

---

## 8. 硬约束(不可破)

- ❌ **不动** `lib/` `test/` `data/*.yaml` 任何文件 — 只动 `docs/screenshots/` 和 `docs/handoff/codex_*.md`
- ❌ **不 push** — 派单方 Mac 端在收到 closeout 后归档 + 自己 push
- ❌ **不装新包**(npm / pip / 任何依赖) — PowerShell .NET 已够
- ❌ **不动 DeepSeek 领地**(`data/narratives/` `data/lore/` `data/events/`)
- ❌ 不要尝试覆盖 fixture self-check 中标 ⚠️ 的项 — 等下批
- ❌ 占位文件 / 伪造证据(W7-W11 教训):跑不通的场景**保留反证截图 + closeout 标占位**

---

## 9. 探路失败 vs 探路通过

| 通过线 | 标准 |
|---|---|
| 最低线 | 5-2 / 5-3 / 6-1 / 6-2 四张拿到,dialog 节奏文字描述能确认 |
| 中等线 | 加 5-1 / 5-5,W14-3-C 节奏改动有动效证据 |
| 完美线 | 加 5-4 cross-fade 中间帧,全 6 张拿到 |

**最低线达不到 → 直接 closeout 标失败,描述卡哪了**。

---

## 10. closeout 必交付项

- 跑通情况表(按 §5 / §6 验收点逐条)
- 工具链评价(本次新增问题?W7-W11 沿用的路径还顺?)
- 视觉判断结果(动效 OK 不 OK / disabled 空态 UI OK 不 OK)
- 下次推荐路径(W14-3-B DeepSeek 文案落地后追派的清单)

---

## 11. 派单方挂账(Codex 不用动,FYI)

- W14-3-B(DeepSeek 12 条 events 文案):Mac 等 DeepSeek 出活
- 下批 visual check seed:Mac 端补 `seedVisualCheckW14_3()` 函数,预 unlock 1-2 个 encounter skill + 模拟 sanLiu 境界,让 EncounterSkillSection 完整态(slot 填充 / bottom sheet 列表 / lock icon)可验

---

**文档结束。Codex 桌面接手后按 §3 → §5 → §6 顺序执行,§7 命名,§8 硬约束,§10 closeout。**
