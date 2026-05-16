# Codex 派单 · W15 victory dialog 升层 + drop banner 视觉验收

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-16
> Mac 端环境:HEAD `b41bf0b` 已 push,工作树 clean,**本派单不需要 Mac 再动代码**
> 关联 closeout:`week15_30_phase3_followup_victory_dialog_2026-05-16.md`(本批主线 victory dialog 0→1 新建 + 塔 dialog 加升层 banner)
> 上游同类前序:`codex_dispatch_w15_stage_drop_visual_2026-05-16.md`(#34 stage drop 验收,3 WARN 闭环,本批落 UI 缺口 1/2)

---

## 1. 一句话目标

验收**本批新落的 victory dialog UI**:① 主线 victory **0→1 新建 dialog**(战斗胜利屏 + drop banner + 升层 banner + 「继续」按钮);② 塔 victory dialog **重构后**兼容"drop empty + 升层"场景 + 升层 banner。**3 active 角色每人独立升层**,banner 应**多行显示每个角色名 + 突破到的境界**。

#34 老挂账 closeout §7 暴露的 victory drop banner UI 缺口由本批 dialog 落地,本派单拿真硬截图收口。

---

## 2. 背景

### 2.1 本批改动概述

- **主线 victory 此前完全无 dialog**,仅 push `NarrativeReaderScreen` 显胜利剧情,玩家无法在战后第一屏看到掉落 / 升层。本批 0→1 新建 `stage_victory_dialog.dart` 在叙事屏之前弹。
- **塔 victory dialog** 已有但只列 drop,无升层 banner。本批 `_FirstClearContent` 重构,drop list 后追 `AdvancementSummary`(多角色多行,每行 `Icons.auto_awesome` + 「<姓名> · 突破至 <境界>」)。
- **`AdvancementSummary` widget** 抽到 `lib/features/cultivation/presentation/advancement_summary.dart`,mainline + tower 共享。seclusion 单角色 `_AdvancementBanner` 不动(本派单**不验**闭关 banner,P3 已验)。

### 2.2 升层触发数值锚点(派单参考,Codex 不需算)

P5 起步角色 = 学徒.qiMeng(启蒙),`experienceToNextLayer = 50`。**stage_01_01 `baseExpReward = 50`** 设计上**首战恰好 1 关 1 升**,3 active 全员升 qiMeng → ruMen(入门)。**stage_01_02 `baseExpReward = 120` / ruMen.experienceToNext = 80**,差不多再升 1 层 ruMen → shuLian(熟练)。**塔第 1 层 `baseExpReward = 80`**,首通时也会触发 1 层升级。

### 2.3 不动 Mac 端

本派单纯 GUI 验收。**Mac 端不加 fixture,不加 debug seed,不改代码**。P5 师徒种子 + 主线/塔现有数据已够触发所有场景。

---

## 3. 任务清单

### 3.1 启动准备

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到 HEAD b41bf0b 或更新

# 沿前序教训(若必要):pub cache 损坏定向清理,详 codex_dispatch_w15_stage_drop_visual §3.1
dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI

```powershell
# 清存档,确保从空白态起
Remove-Item -Recurse -Force "$env:APPDATA\wuxia_idle" -ErrorAction SilentlyContinue

Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```

窗口固定 `1280 × 900`(2026-05-16 round 实证可用)。若主菜单底部按钮挡,改 `1280 × 800` 也 OK。

### 3.3 种 P5 师徒(获取 3 active 角色)

主菜单 → **Phase 2 调试场景** → **P5 · 师徒种子**

种完自动 push 角色面板,Back 两次回主菜单。

**验收前置**:3 active 角色起步 = 学徒.qiMeng,experience=0,内力 500/500。

### 3.4 截图清单 + 评级

#### 场景 A:主线 stage_01_01 victory dialog(必收)

打 stage_01_01,期待**叙事屏之前**弹 dialog。

| # | 截图 | 验收点 |
|---|---|---|
| **A1** | victory dialog 全屏 | ① title 显「山门之外 · 战斗胜利」② content 显「掉落:」+ drop bullets(粗布衣 / 磨剑石 ×N)③ banner 显 3 行 `Icons.auto_awesome` + 「<姓名> · 突破至 学徒·入门」④ 「继续」按钮可见 |
| **A2** | dialog 关闭后叙事屏 | 点「继续」后正常 push `NarrativeReaderScreen`(stage_01_01 narrativeVictoryId 已配),证明 dialog 不破坏 narrative 链路 |

#### 场景 B:主线 stage_01_02 victory dialog(必收)

回主菜单 → 主线 → stage_01_02 打通。

| # | 截图 | 验收点 |
|---|---|---|
| **B1** | victory dialog 全屏 | ① title 显「<stage_01_02 名> · 战斗胜利」② content drop list / 或「本战无固定掉落」(看 yaml 是否配 drop)③ banner 显 3 行 `Icons.auto_awesome` + 「<姓名> · 突破至 学徒·熟练」 |

#### 场景 C:塔第 1 层 victory dialog(必收,首通)

回主菜单 → 问鼎江湖 → 第 1 层。

| # | 截图 | 验收点 |
|---|---|---|
| **C1** | 塔 victory dialog 全屏(首通) | ① title 显「第 1 层」② content 显塔首通 drop 或「首通!本层无固定奖励」③ banner 显 3 行升层(若 qiMeng/ruMen → 下 1 层)④ 「确定」按钮可见 |
| **C2** | 塔 victory dialog 全屏(**重打**第 1 层)| 重打 = 不首通,期待 content 显「已重打通关,重打不发奖」**且无升层 banner**(`isFirstClear=false` 不发 EXP) |

#### 场景 D:升层 banner 多行边界(选收,能给则给)

某关只触发 **部分角色升层**(例如 3 active 中 1 个境界已高于平均,本关 EXP 不够升)→ banner 应**只显升层的那几位**。

P5 种子下 3 角色都是同境界 qiMeng,所以本场景**自然不会触发**。若需要专门验,需 Mac 端加专用 seed,**本派单不强制**,closeout 列「未验」即可。

#### 场景 E:dialog 空 drop + 0 升层(选收)

理论上 stage 配 `baseExpReward=0` 且 dropTable 空 → dialog 应显「本战无固定掉落」**且无 banner**。Demo §8.1 主线关全配 baseExpReward,这场景可能找不到合适关卡。closeout 列「未验」即可。

---

## 4. 视觉判断重点

### 4.1 banner 文案体例核对(主线 + 塔共用)

每行格式严格对照:`<姓名> · 突破至 <境界>`(单层) / `<姓名> · 连破 N 层 → <境界>`(多层)。
- ✅ 中文字符之间空格(`空格 · 空格`)
- ✅ 「突破至 学徒·入门」境界中间是 `·`(`enum_localizations.realm` 输出)
- ❌ 出现 `null` / 拼音 id(`xueTu` `ruMen`)/ 翻译键未渲染 → FAIL

### 4.2 banner 视觉风格(对照 seclusion `_AdvancementBanner`)

- 容器底色 `WuxiaColors.gangMeng` 18% alpha,边框 60% alpha
- 圆角 8px
- 图标 `Icons.auto_awesome` 20px gangMeng 色
- 文字 fontSize 15 bold textPrimary

风格应与闭关收获屏的升层 banner **视觉一致**(同 widget 不同 caller,只是单行 vs 多行)。

### 4.3 dialog 整体节奏

- 弹层 + 渐入流畅(showDialog 默认动画)
- barrierDismissible=false → 点 dialog 外不关
- 「继续」/「确定」按钮 tap → dialog 关
- dialog 关闭后正常进 narrative(主线)/ narrative + encounter hook(塔 Boss 层 + 主线)

### 4.4 主线 vs 塔 dialog title 区别

- 主线:`<stage.name> · 战斗胜利`(本批新文案)
- 塔:`第 N 层`(沿用)

---

## 5. 工程层硬约束(沿用 W15 系列)

- ❌ 不动 GDD.md / CLAUDE.md / numbers.yaml / IDS_REGISTRY.md / data_schema.md
- ❌ 不动 `data/narratives/` `data/lore/` `data/events/`(DeepSeek 领地)
- ❌ 不改 `lib/` `test/` 代码 — 仅 closeout markdown + 截图
- ❌ 不 push 任何分支(纯本地工作树)
- ❌ 不装新包(若 build_runner / pub cache 卡,沿前序 dispatch 教训定向清理)
- ✅ 只动 `docs/screenshots/w15_victory_dialog/` + `docs/handoff/codex_*_2026-05-16.md`

---

## 6. closeout 必交付

模板:`docs/handoff/codex_w15_victory_dialog_visual_check_2026-05-16.md`

| 段 | 内容 |
|---|---|
| §1 | 一句话结论(几 PASS / WARN / FAIL,#34 第 2 UI 缺口是否闭环)|
| §2 | 环境与启动记录(HEAD / build / launch / 窗口尺寸) |
| §3 | 截图清单 + PASS/FAIL 评级表(对照 §3.4 编号)|
| §4 | 视觉层反馈(文案 / 颜色 / 节奏 / banner 多行渲染)|
| §5 | 节奏层反馈(dialog → narrative → encounter 链路)|
| §6 | 工程教训(本会话产,坑 / 截图工具调用变化)|
| §7 | 下次推荐(若 FAIL,Mac 端要怎么修;若全 PASS,#34 UI 缺口 1/2 闭环 + 物料 Tab 留下波)|

截图路径:`docs/screenshots/w15_victory_dialog/<scenario>_<desc>.png`,例如:
- `A1_mainline_01_01_dialog.png`
- `A2_mainline_01_01_narrative_after_dialog.png`
- `B1_mainline_01_02_dialog.png`
- `C1_tower_floor1_firstclear.png`
- `C2_tower_floor1_replay_no_banner.png`

---

## 7. 沟通契约

- 全程不联系派单方,只在 closeout 报回
- 探路失败也有价值,**真跑不通就 closeout 详写卡点**,不要伪造截图占位
- 必收 5 张(A1/A2/B1/C1/C2)拿到 3 张 + 1 张占位反证 > 5 张占位
- 优先级:**链路打通 > 必收张数 > 选收覆盖**

---

## 8. 验收口归 Mac

Codex 交 closeout 后 Mac 端按以下口闭环:
- **5/5 PASS** → #34 UI 缺口 1/2 闭环(剩物料 Tab),`PROGRESS.md` §下一步候选 E 销账,候选 A 物料 Tab 进下波
- **任意 FAIL** → Mac 端按 closeout §7 修,可能新一轮派单或直接 fix
- **WARN**(非 bug 工程改善建议) → Mac 端评估是否本批落 / 留下次 polish

工作树本地 clean,push 等 Mac 验收后统一操作。
