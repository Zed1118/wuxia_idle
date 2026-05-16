# Codex 派单 · W15 victory dialog round2(本地化 + 升层 banner + 物料 Tab)

> 派单方:Mac Opus 4.7 · 接单方:Pen Windows Codex 桌面
> 创建日期:2026-05-16
> Mac 端环境:本批 F1(本地化修复)+ F2(新 fresh seed)+ G(PROGRESS 调整)一波 commit 即将 push,**本派单不需要 Mac 再动代码**
> 关联 round1 closeout:`codex_w15_victory_dialog_visual_check_2026-05-16.md`(2 PASS / 3 WARN)
> 关联 round1 派单:`codex_dispatch_w15_victory_dialog_2026-05-16.md`

---

## 1. 一句话目标

round1 暴露 2 类 WARN:**① `item_mojianshi` 未本地化为「磨剑石」**(真 UI bug,本批已修)**② 升层多行 banner 未验到**(P5 fixture 漂移,3 角色境界已不齐 / EXP 不足升层,本批新增 `VC15-fresh` debug seed 让 3 角色全员重置回 xueTu·qiMeng + experience=0 + 主线塔进度清零)。本派单拿真硬截图收口 #34 第 2 UI 缺口 + 顺带物料 Tab(W15 #30 P3 后续 A 已落但未拿真截图)。

---

## 2. 背景

### 2.1 round1 WARN 归因

| WARN | 类别 | 本批修法 |
|---|---|---|
| A1/B1/C1 drop banner 显 `item_mojianshi ×N` | 真 UI bug | F1 抽 `ItemType.fromDefId` 到 `core/domain/enums.dart`,`stage_victory_dialog.dart:55` + `tower_entry_flow.dart:466` 走 `EnumL10n.itemType(ItemType.fromDefId(item.defId))` |
| A1/B1/C1 无升层 multi-line banner | P5 fixture 漂移(P5 实测「祖师一流+大弟子二流+二弟子三流」+ stage_01_01/01_02/塔低层 EXP 不足升层) | F2 新增 `seedVisualCheckW15Fresh`:3 active 全员 xueTu·qiMeng + experience=0 + 主线塔奇遇进度清零 + 0 装备 0 心法(三系锁死)+ 100 磨剑石 + 10 心血结晶 |

### 2.2 升层触发数值锚点(派单参考,Codex 不需算)

xueTu·qiMeng `experienceToNext = 50`。**stage_01_01 `baseExpReward = 50`** 设计上**首战恰好 1 关 1 升**,3 active 全员升 qiMeng → ruMen。**stage_01_02 `baseExpReward = 120` / ruMen `experienceToNext = 80`**,差不多再升 1 层 ruMen → shuLian。**塔第 1 层 `baseExpReward = 80`**,首通时也会触发 1 层升级。

(实际数值取 `numbers.yaml retreat.realm_scale_per_tier` / `stages.yaml baseExpReward` / `numbers.yaml realms.tiers[*].layers[*].experience_to_next`,Codex 无需算,看 dialog 显示什么就报告什么。)

### 2.3 不动 Mac 端

本派单纯 GUI 验收。**Mac 端 F1 + F2 已修完,F3 派单后接 closeout 即可**。不需要二次改代码。

---

## 3. 任务清单

### 3.1 启动准备

```powershell
cd F:\Projects\wuxia_idle
git pull --rebase --autostash
# 应到本批 F1 + F2 + G 一波 commit 的 HEAD,commit message 含
# "victory-dialog-round2" / "P5-fresh-seed" 字样

# 沿前序教训:pub cache 损坏定向清理,详 codex_dispatch_w15_stage_drop_visual §3.1
dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug
```

### 3.2 启 GUI

```powershell
# 清存档,确保从空白态起
Remove-Item -Recurse -Force "$env:APPDATA\wuxia_idle" -ErrorAction SilentlyContinue

Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe
```

窗口固定 `1280 × 1400`(本批 fresh seed 按钮加在末尾,菜单可能超过 1280×900,实证需更高,**1400 高保证 11 按钮全可视**)。若机器分辨率不够,先 `1280 × 900` 启动后用 menu 滚动到 VC15-fresh 按钮。

### 3.3 种 P5-Fresh(获取 3 active xueTu·qiMeng)

主菜单 → **Phase 2 调试场景** → **VC15-fresh · 3 active 学徒启蒙(升层 banner 验收)**(第 11 个按钮,在 VC15-res 下面)

种完自动 push 角色面板,Back 两次回主菜单。

**验收前置**:
- 3 active 角色起步 = 学徒·启蒙(`xueTu·qiMeng`)
- experience=0,内力 500/500
- 0 装备 0 心法(GDD §5.3 三系锁死,学徒只能装 tier 0 寻常货,seed 故意 0 装备避免漂移)
- 100 磨剑石 + 10 心血结晶(物料 Tab 起步可见)
- 主线 / 塔 / 奇遇进度全清(stage_01_01 可打,塔第 1 层可挑战)

### 3.4 截图清单 + 评级

#### 场景 A:主线 stage_01_01 victory dialog(必收)

打 stage_01_01,期待**叙事屏之前**弹 dialog。3 active 全员 EXP+50 → 触发升层 qiMeng → ruMen(本批 banner 应显 3 行升层)。

| # | 截图 | 验收点 |
|---|---|---|
| **A1** | victory dialog 全屏 | ① title 显「山门之外 · 战斗胜利」② content 显「掉落:」+ drop bullets — **必须是中文「磨剑石 ×N」/「粗布衣」,不再是 `item_mojianshi ×N`**(round1 WARN 关键修复点)③ banner 显 **3 行** `Icons.auto_awesome` + 「<姓名> · 突破至 学徒·入门」④ 「继续」按钮可见 |
| **A2** | dialog 关闭后叙事屏 | 点「继续」后正常 push `NarrativeReaderScreen`(stage_01_01 narrativeVictoryId 已配),验链路不破。round1 已 PASS,本派单**可选重收**作交叉印证 |

#### 场景 B:主线 stage_01_02 victory dialog(必收)

A 通关后,3 角色都已 ruMen,继续打 stage_01_02(EXP+120 / ruMen.experienceToNext=80),期待再升 1 层 ruMen → shuLian(熟练)。

| # | 截图 | 验收点 |
|---|---|---|
| **B1** | victory dialog 全屏 | ① title 显「<stage_01_02 名> · 战斗胜利」② content drop list — **本地化中文,无 `item_mojianshi` defId**③ banner 显 **3 行** `Icons.auto_awesome` + 「<姓名> · 突破至 学徒·熟练」 |

#### 场景 C:塔第 1 层 victory dialog(必收,首通)

回主菜单 → 问鼎江湖 → 第 1 层(VC15-fresh 已清塔进度,本场景可触发首通 vs round1 因 P5 已通 1/30 只能补拍 floor2)。

| # | 截图 | 验收点 |
|---|---|---|
| **C1** | 塔 victory dialog 全屏(首通) | ① title 显「第 1 层」② content 塔首通 drop(若有)— **本地化中文**③ banner 显 **多行升层**(3 角色每人 +80 EXP 触发 1 层升级)④ 「确定」按钮可见 |

#### 场景 D:物料 Tab 真硬截图(必收,W15 #30 P3 后续 A 已落 0 真硬截图)

回主菜单 → 装备仓库 → 切到「物料」Tab。

| # | 截图 | 验收点 |
|---|---|---|
| **D1** | 物料 Tab 起步态(VC15-fresh seed 后) | ① TabBar 默认在「装备」Tab,需点「物料」切过去 ② 显示 2 个 ExpansionTile 分组:「磨剑石」组 1 行 `磨剑石 ×100` / 「心血结晶」组 1 行 `心血结晶 ×10` ③ reserved enum(经验丹 / 心法秘籍 / 杂项材料)**不显示**(0 行不暴露未实装)④ 排序按 ItemType enum 顺序(磨剑石在心血结晶上面) |
| **D2** | 物料 Tab 累积态(打 A + B + C 累积 drop 后) | ① 起步 100 磨剑石 → 累积 drop 后 ≥100 ② 若主线/塔配 dropTable 还有心血结晶 → ×10+N ③ ExpansionTile 仍按 enum 顺序,不出现 reserved enum 空组 |

#### 场景 E:升层 banner 部分升层边界(选收,能给则给)

某关只触发**部分角色升层**(例如 3 active 中 EXP 已分化)→ banner 应**只显升层的那几位**。

VC15-fresh 起步 3 角色 EXP 同步,所以本场景**自然不会触发**,需打到中后期某关分化才可能。closeout 列「未验」即可,**不强制**。

---

## 4. 视觉判断重点

### 4.1 drop banner 文案体例(本批 F1 修复后)

每行格式严格对照:
- 装备 ✅ `· 粗布衣`(中文 EquipmentDef.name)
- 物料 ✅ `· 磨剑石 ×N`(本批 F1 修:走 `EnumL10n.itemType(ItemType.fromDefId(defId))`)
- ❌ 出现 `· item_mojianshi ×N` / `· item_xinxuejiejing ×N` → FAIL(本批修复未生效)
- ❌ 装备显示 `· equipment_powutyi`(defId) → FAIL(应已是 EquipmentDef.name)

### 4.2 banner 升层文案(round1 未验)

每行格式严格对照:`<姓名> · 突破至 <境界>`(单层) / `<姓名> · 连破 N 层 → <境界>`(多层)。
- ✅ 中文字符之间空格(`空格 · 空格`)
- ✅ 「突破至 学徒·入门」境界中间是 `·`(`enum_localizations.realm` 输出)
- ❌ 出现 `null` / 拼音 id(`xueTu` `ruMen`)/ 翻译键未渲染 → FAIL

### 4.3 banner 视觉风格(对照 seclusion `_AdvancementBanner`)

- 容器底色 `WuxiaColors.gangMeng` 18% alpha,边框 60% alpha
- 圆角 8px
- 图标 `Icons.auto_awesome` 20px gangMeng 色
- 文字 fontSize 15 bold textPrimary

风格应与闭关收获屏的升层 banner **视觉一致**(同 widget 不同 caller,只是单行 vs 多行)。

### 4.4 物料 Tab 渲染重点(D1/D2)

- TabBar 切换流畅,默认在「装备」Tab 不破老路径
- ExpansionTile 分组**按 ItemType enum 顺序**:磨剑石 → 心血结晶 →(reserved enum 不显)
- 每行 `<itemType 中文名> ×<quantity>`
- 空状态走 `inventoryTabMaterialEmpty` 占位「暂无物料」(本派单 fresh seed 已给 110 物料不触发,但若 D2 累积后某 enum 完全清空也不该出现空组)

### 4.5 dialog 整体节奏

- 弹层 + 渐入流畅(showDialog 默认动画)
- barrierDismissible=false → 点 dialog 外不关
- 「继续」/「确定」按钮 tap → dialog 关
- dialog 关闭后正常进 narrative(主线)/ narrative + encounter hook(塔 Boss 层 + 主线)

---

## 5. 工程层硬约束(沿用 W15 系列)

- ❌ 不动 GDD.md / CLAUDE.md / numbers.yaml / IDS_REGISTRY.md / data_schema.md
- ❌ 不动 `data/narratives/` `data/lore/` `data/events/`(DeepSeek 领地)
- ❌ 不改 `lib/` `test/` 代码 — 仅 closeout markdown + 截图
- ❌ 不 push 任何分支(纯本地工作树),交付后通知派单方 push
- ❌ 不装新包(若 build_runner / pub cache 卡,沿前序 dispatch 教训定向清理)
- ✅ 只动 `docs/screenshots/w15_victory_dialog_round2/` + `docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`

---

## 6. closeout 必交付

模板:`docs/handoff/codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`

| 段 | 内容 |
|---|---|
| §1 | 一句话结论(几 PASS / WARN / FAIL,#34 第 2 UI 缺口本批是否闭环,本地化是否生效)|
| §2 | 环境与启动记录(HEAD / build / launch / 窗口尺寸)|
| §3 | 截图清单 + PASS/FAIL 评级表(对照 §3.4 编号 A1/A2/B1/C1/D1/D2,E 选收)|
| §4 | 视觉层反馈(本地化是否生效 / 升层 banner 多行渲染 / 物料 Tab 排序)|
| §5 | 节奏层反馈(dialog → narrative → encounter 链路;TabBar 切换)|
| §6 | 工程教训(本会话产,坑 / 截图工具调用变化)|
| §7 | 下次推荐(若全 PASS,#34 完整闭环,物料 Tab 真硬截图收尾;若 FAIL,Mac 端要怎么修) |

截图路径:`docs/screenshots/w15_victory_dialog_round2/<scenario>_<desc>.png`,例如:
- `A1_mainline_01_01_dialog_localized.png`
- `A2_mainline_01_01_narrative_after_dialog.png`(选收)
- `B1_mainline_01_02_dialog_advancement.png`
- `C1_tower_floor1_firstclear_advancement.png`
- `D1_inventory_material_tab_fresh.png`
- `D2_inventory_material_tab_accumulated.png`

---

## 7. 沟通契约

- 全程不联系派单方,只在 closeout 报回
- 探路失败也有价值,**真跑不通就 closeout 详写卡点**,不要伪造截图占位
- 必收 6 张(A1/B1/C1/D1/D2 + A2 沿 round1 PASS 可选)拿到 4 张 + 1 张占位反证 > 6 张占位
- 优先级:**链路打通 > 必收张数 > 选收覆盖**

---

## 8. 验收口归 Mac

Codex 交 closeout 后 Mac 端按以下口闭环:

- **本地化 5/5 PASS**(A1/B1/C1 drop banner + D1/D2 物料 Tab 中文)→ F1 修复闭环
- **升层 banner 多行验**(A1/B1/C1)→ #34 第 2 UI 缺口闭环 + #34 完整闭环销账(从 WARN 闭环升级)
- **物料 Tab 2 屏 PASS**(D1/D2)→ W15 #30 P3 后续 A 物料 Tab 真硬截图首达
- **任意 FAIL** → Mac 端按 closeout §7 修
- **WARN**(非 bug 工程改善建议) → Mac 端评估是否本批落 / 留下次 polish

工作树本地 clean,push 等 Mac 验收后统一操作。
