# Codex 桌面 @ Pen 视觉验收派单 · W14-3 round2 完整 EncounterSkillSection(2026-05-15)

> 派单方:Mac Opus(zhangpeng.12334@gmail.com)
> 执行方:Codex 桌面 @ Pen Windows
> 沟通契约:Codex 全程不联系派单方,只在 closeout 报回。探路失败也有价值,不要硬撑。

---

## 0. 必读清单(顺序)

1. **本派单**
2. **`docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`**(你上批自己的 closeout — 工具链 + 踩坑沿用)
3. `PROGRESS.md`(当前阶段 W14-3 整体闭环)
4. `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` §3.4(EncounterSkillSection 实现细节 — slot / bottom sheet / lock icon 设计)
5. `CLAUDE.md` §5(数值红线)+ §10(拿不准处理顺序)

---

## 1. 任务一句话

**用 Phase2TestMenu「VC14_3」按钮 → 验证 EncounterSkillSection 完整 unlocked 态(slot 填充 / bottom sheet 7 招 / lock icon 按境界分层)。**

W14-3 整体闭环已 tag `v0.5.0-w14`。本次为 round2,用上批 Codex 推荐的下次路径(`codex_w14_3c_visual_check` §7 #1):"Mac 端补 `seedVisualCheckW14_3()` 预 unlock + 让 lock icon 可验" — Mac 端已落地(commit `bcc8031` / `66f0d5b`),Pen 端 git pull 后 HEAD 应到 `66f0d5b` + tag `v0.5.0-w14`。

---

## 2. fixture self-check(已 self-check)

| # | 验收点 | 现状 | 说明 |
|---|---|---|---|
| ✅ 1 | `seedVisualCheckW14_3()` 落地 | commit `bcc8031` | Phase2TestMenu 加「VC14_3」按钮 |
| ✅ 2 | 预 unlock 池 | tier 1-7 各 1 招 = 7 招 | encounter_skills.yaml 抽样 |
| ✅ 3 | 大弟子(id=2, erLiu)预装备 | tier 3 first skill | slot 填充态 |
| ✅ 4 | 师徒境界天然分层 | yiLiu(祖师)/ erLiu(大弟子)/ sanLiu(二弟子) | 不同 lock 行为 |
| ✅ 5 | W14-3-B 12 条 events 文案落地 | commit `db046fa` | 跟本次任务无关,但环境齐 |

**境界锁死映射**(GDD §5.3):`canEquip = realmTier.index ≥ skill.tier - 1`

| 角色(id) | 境界 | realmTier.index | 可装 tier | lock 数(在 7 招池中) |
|---|---|---|---|---|
| 祖师(1) | yiLiu | 3 | ≤ 4 | tier 5/6/7 = **3 lock** |
| **大弟子(2)** | erLiu | 2 | ≤ 3 | tier 4/5/6/7 = **4 lock** |
| 二弟子(3) | sanLiu | 1 | ≤ 2 | tier 3/4/5/6/7 = **5 lock** |

大弟子已预装备 tier 3(VC14_3 seed 写死)— **slot 填充态用大弟子最直接**。

---

## 3. 启动 + 准备(Mac SSH 已拉起最新代码)

派单方 Mac 端已通过 SSH `git pull` + 重启 `WuxiaRun`。Codex 接手时:

1. Pen RDP 桌面应看到 wuxia_idle 窗口(若无 → 见 §5 重建路径)
2. 验证 HEAD = `66f0d5b`:`cd F:\Projects\wuxia_idle && git log -1 --oneline`
3. 验证 tag:`git tag --list | grep v0.5.0-w14`
4. 窗口尺寸固定 **1280×900**(沿用上批教训)

---

## 4. 工具链 cheatsheet(沿上批 PowerShell .NET 零依赖)

参考 `codex_w14_3c_visual_check_2026-05-14.md` §6。新增注意点:

- 上批教训:`WuxiaRun Running` 不等于桌面可见窗口 — 必须枚举 `MainWindowHandle` 二次确认
- 上批教训:Debug exe 可能是旧构建 → 本次代码有 `seedVisualCheckW14_3` 新方法 + UiStrings.scenarioVc14_3 新字串,**Pen 端必须重建**:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  flutter build windows --debug
  ```
  (本次 Isar schema 未升版,但 phase2_seed_service.dart 改了,需要重 build)

---

## 5. 验收路径(主要 4 张截图 + 选做 2 张)

### 5.1 触发种子

主菜单 → 「Phase 2 调试场景」 → 「VC · W14-3 奇遇 skill 视觉验收预设」按钮(挂在 VC 之后)→ 自动跳转 CharacterPanelScreen(默认角色 id=1 祖师)

### 5.2 截图清单

| # | 截图文件名 | 场景 + 验收点 |
|---|---|---|
| **必收 R2-1** | `w14_3_round2_disciple1_slot_filled.png` | 切到大弟子(id=2)→ EncounterSkillSection slot 已装备 tier 3 skill(显示 skill 名 + tier 标记 + 卸下按钮)|
| **必收 R2-2** | `w14_3_round2_disciple1_bottom_sheet.png` | 大弟子点击 slot 或装备按钮 → bottom sheet 展开 → 7 招列表(tier 1-7 各 1):tier 1-3 enabled / tier 4/5/6/7 有 lock icon + disabled |
| **必收 R2-3** | `w14_3_round2_disciple2_more_locks.png` | 切到二弟子(id=3,sanLiu)→ 进入 EncounterSkillSection → 装备按钮 → bottom sheet:tier 1-2 enabled / tier 3-7 lock(5 个 lock,比大弟子多) |
| **必收 R2-4** | `w14_3_round2_founder_fewer_locks.png` | 切到祖师(id=1,yiLiu)→ bottom sheet:tier 1-4 enabled / tier 5/6/7 lock(3 个 lock,最少) |
| 选做 R2-5 | `w14_3_round2_disciple1_unequip.png` | 大弟子点「卸下」→ slot 变空态(显示"未装备奇遇招式") |
| 选做 R2-6 | `w14_3_round2_disciple1_equip_new.png` | 卸下后从 bottom sheet 选 tier 2 skill 装上 → slot 显示新 skill |

### 5.3 视觉判断标准

- ✅ slot 填充态:skill 名 / tier 标记 / 卸下按钮 三要素齐
- ✅ bottom sheet 列表 7 项,tier 升序排列
- ✅ lock icon disabled 视觉明显(灰色 / icon / 不可点)
- ✅ 切角色后 lock 数变化(祖师 3 / 大弟子 4 / 二弟子 5)
- ❌ 任一帧布局错位 / 文字截断 / lock 数与 §2 表不符 → 标 BUG

### 5.4 切角色路径

主菜单 → 「角色面板」时只能选 id=1 默认。但 VC14_3 seed 后 SaveData.activeCharacterIds = [1, 2, 3],3 角色都在阵中。

切角色路径(Codex 自行探):
- (a)CharacterPanelScreen 顶部可能有角色切换 chip / dropdown(读 `lib/ui/character_panel/character_panel_screen.dart` 看)
- (b)走「队伍列表 / 师承段」点头像跳到该角色面板
- 若 UI 没有切换入口 → 通过 hot restart + 改 `_defaultCharacterId = 2/3`?**不,Codex 不改代码**。**报回派单方,改 UI 视为 Mac 端任务**。

---

## 6. 命名 + 存放路径(严格)

- 截图:`docs/screenshots/w14_3_round2_*.png`(全 ASCII)
- closeout:`docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md`
- closeout 内容:跑通情况表 + 工具链评价 + 切角色实现路径 + 视觉判断对照 §5.3 + 下次推荐

---

## 7. 硬约束(不可破)

- ❌ **不动** `lib/` `test/` `data/*.yaml` — 只动 `docs/screenshots/` 和 `docs/handoff/codex_*.md`
- ✅ **允许 commit + push** `docs/screenshots/` + `docs/handoff/codex_*.md`(沿上批 quick prompt 修订)
- ❌ 不装新包,沿 PowerShell .NET 路线
- ❌ 不动 DeepSeek 领地(`data/narratives/` `data/lore/` `data/events/`)
- ❌ 占位文件 / 伪造证据 → 跑不通的场景**保留反证截图 + closeout 标占位**

---

## 8. 通过线

| 等级 | 标准 |
|---|---|
| 最低 | R2-1 + R2-2 拿到(大弟子 slot 填充 + bottom sheet 列表 + 4 lock)|
| 中等 | 加 R2-3 / R2-4(切到其他角色看 lock 数变化)|
| 完美 | 加 R2-5 / R2-6(装/卸操作)|

切角色路径找不到 → R2-3/R2-4 标 BLOCKED + 报回 Mac 端补 UI。

---

## 9. closeout 必交付

- 跑通情况表(按 §5.2 R2-1 ~ R2-6 逐条)
- 切角色实现路径(走哪条 UI 入口,或证实 UI 没切角色入口需 Mac 端补)
- 工具链评价(沿用还顺?新坑?)
- 视觉判断对照 §5.3
- 下次推荐路径

---

**文档结束。Codex 桌面接手按 §3 → §5 顺序执行,§6 命名,§7 硬约束,§9 closeout。**
