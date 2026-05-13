# W7-W11 五周累积视觉验收（Pen Windows）

- **日期**：2026-05-13 派单 / Pen 执行日期待定
- **执行方**：Pen + Windows RDP 桌面（Mac SSH schtasks 启 GUI，验收人手动操作 + ShareX 截屏）
- **分支 / commit**：main @ `7404952`
- **关联**：W7 装备 35 件 / W8 心法 21 本 + 63 招 / W9 爬塔 30 层 / W10 Boss 战败散功代价 / W11 victory 路径接 resolveBattle 双端（销账 #32）
- **代码状态**：Mac 端 **546/546** 测试 + analyze 0 issues
- **截图归档**：`docs/screenshots/phase4_w7_w11/`（已建空目录）

通过后 Mac 端：归档截图入仓 + `phase4_summary.md`（或追加 phase3_summary.md Phase 4 段）撰写 + tag **v0.4.0-w11** push origin。

---

## 0. 环境准备（Mac SSH 派 Pen）

### 0.1 启动游戏（Mac 端 SSH，路径走 `reference_pen_wuxia_flutter_run.md`）

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Set-Location F:\Projects\wuxia_idle; git fetch; git checkout main; git pull; git log --oneline -3"'
```

期望最新 3 条 commit：
```
7404952 docs(handoff): W12 Phase 5 收尾 closeout（#12 销账 + #28 探路终结）
fb6d777 docs(progress): #28 探路终结判不可解（W6 后 5 轮 fake_async 边界失败）
0771c90 refactor(phase5): LevelDiff 数据层与公式层语义统一（销账 #12）
```

### 0.2 build_runner（沿用 W4 教训：`*.g.dart` 全 gitignored）

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Set-Location F:\Projects\wuxia_idle; flutter pub run build_runner build --delete-conflicting-outputs"'
```

期望末尾 `Succeeded after Xs with N outputs`。失败立刻报回。

### 0.3 基线核对

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Set-Location F:\Projects\wuxia_idle; flutter analyze; flutter test"'
```

期望：**analyze 0 issues / 546 tests pass**。任一失败立刻报回。

### 0.4 清开发态存档（Isar saveVersion 升级路径已沉淀，但 W7-W11 数据形态变化保险起见全清）

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Remove-Item -Recurse -Force $env:APPDATA\wuxia_idle -ErrorAction SilentlyContinue; Write-Host cleared"'
```

### 0.5 启动 GUI（schtasks Console Session 1）

```bash
ssh Administrator@100.73.91.112 'powershell -Command "$task = New-ScheduledTaskAction -Execute powershell.exe -Argument \"-NoExit -Command Set-Location F:\Projects\wuxia_idle; flutter run -d windows\"; $trigger = New-ScheduledTaskTrigger -At (Get-Date).AddSeconds(5) -Once; $principal = New-ScheduledTaskPrincipal -UserId Administrator -LogonType Interactive; Register-ScheduledTask -TaskName WuxiaRun -Action $task -Trigger $trigger -Principal $principal -Force | Out-Null; Start-ScheduledTask -TaskName WuxiaRun; Write-Host launched"'
```

约 30-60s 后 RDP 桌面出现游戏窗口。

### 0.6 全局前置（每个场景都从此开始，除非另有说明）

进游戏 → 主菜单 → 点「Phase 2 调试场景」→ 点「P5 · 师徒种子」→ 看到 SnackBar 提示 → 返回主菜单。**这一步种入 3 师徒（祖师/大弟子/二弟子）+ 9 件装备 + 4 本心法 + 基础物料**。

---

## 场景 A · W7 装备 fixture 35 件渲染（覆盖度验证）

**入口**：主菜单 → Phase 2 调试场景 → 进入仓库面板（或 P5 后角色面板 → 仓库 Tab）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| A1 | 仓库面板 | 7 阶装备（寻常货→神物）每阶 ≥5 件渲染；至少能滚到「神物」阶；item 名 + tier chip 配色随阶递进 | `01_w7_inventory_35items.png` |

**A 通过条件**：能滚到列表末尾看到 tier=7（神物 / 武圣阶）装备；不出现「未知装备」或 def 缺失提示。

**注**：P5 seed 只给 9 件装备入背包（祖师 3 + 大弟子 3 + 二弟子 3），35 件 fixture 是 yaml 层的，背包不会直接显示全部。**若仓库面板只显示玩家持有的 9 件**：改去 Phase 2 调试场景里的「装备图鉴 / 全装备列表」按钮（若有），或者直接验「角色面板 → 装备槽 → 鉴定」能展开所有 tier 的装备名。**Pen 验收时若找不到 35 件展示路径，仅截背包当前 9 件，附文字说明「35 件需 schema 层验证，运行时玩家持有 9 件」即可,不重跑**。

---

## 场景 B · W8 心法 fixture 21 本 + 63 招渲染（覆盖度验证）

**入口**：主菜单 → 进入心法面板（具体路径以 P5 后角色面板的「心法」Tab 为准）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| B1 | 心法面板（祖师/大弟子/二弟子三 Tab 各看） | 每角色至少 1 本主修 + 1 本辅修（P5 seed 给）；心法名 + 流派 chip 渲染；点开看招式列表 3 招（普攻 / 强力 / 大招）| `02_w8_techniques_panel.png` |

**B 通过条件**：心法名走 yaml 解析（不出现 `tech_xxx` 原 ID）；招式名走 yaml 解析（不出现 `skill_xxx` 原 ID）。

**注**：同场景 A 注。P5 只给 4 本心法,21 本是 yaml schema 层。若有「全心法图鉴」入口走那条;否则截当前 4 本附文字说明。

---

## 场景 C · W9 爬塔 30 层三态 + Boss outline（UI 实地走）

**入口**：主菜单 → 点「问鼎九霄」→ TowerFloorListScreen。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| C1 | TowerFloorListScreen 滚到顶 | 顶部进度卡「已通 0 / 30 层」+「总尝试 0 次」+「失败 0 次」；floor_1 显示「挑战」chip（available）；floor_2-30 显示锁图标（locked） | `03_w9_tower_floor_list_top.png` |
| C2 | 滚到第 5 层附近 | floor_5 / floor_10 / floor_15 等 5 倍数层是 Boss：floor_5 / 15 / 25 是 minor（**金色** outline + 「小 Boss」chip）；floor_10 / 20 / 30 是 major（**紫色** outline + 「大 Boss」chip）| `04_w9_tower_boss_outline.png` |
| C3 | 滚到第 30 层 | floor_30 显示大 Boss outline + 锁图标 + 副标题「通关前一层解锁」 | `05_w9_tower_floor_30.png` |

**C 通过条件**：金紫 outline 配色与 chip 文案肉眼可分；30 层都能滚到末尾不卡 build；Boss 严格在 5·10·15·20·25·30 层。

---

## 场景 D · W11 主线 victory 副作用（核心销账 #32 验收）

**入口**：主菜单 → 主线 → Ch1 → stage_01_01（山门之外）。

### D1 · 战前快照

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| D1-1 | 返回主菜单 → 角色面板 → 祖师 Tab → 装备段 | 记下祖师武器名 + battleCount（初始值，应为 0 或种子默认值） | `06_w11_before_stage_eq_battlecount.png` |
| D1-2 | 同屏切心法段 | 记下祖师主修心法名 + progress 数值（如 0/100） | `07_w11_before_stage_tech_progress.png` |

### D2 · 跑 stage_01_01 胜利

| 步骤 | 操作 | 期望 |
|---|---|---|
| D2-1 | 主菜单 → 主线 → Ch1 → 点「山门之外」| opening 剧情「山门之外 · 启」→ 点继续进战斗 |
| D2-2 | 3v3 战斗 | 玩家方 3 师徒 vs 3 流民弱敌，约 3-5 tick 速胜（祖师 + 弟子用主修招式） |
| D2-3 | victory 剧情「山门之外 · 胜」→ pop 回 stage list | 01 显示 cleared icon |

### D3 · 战后对比（核心验收）

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| D3-1 | 返回主菜单 → 角色面板 → 祖师 Tab → 装备段 | **同件武器 battleCount 应 ++1**（D1-1 的 0 → 1，或 N → N+1）| `08_w11_after_stage_eq_battlecount.png` |
| D3-2 | 同屏切心法段 | **主修心法 progress 应增加**（D1-2 的 0/100 → ≥1/100，按使用 skill 行动次数累）| `09_w11_after_stage_tech_progress.png` |

**D 通过条件**：D3-1 截图 battleCount 数字相比 D1-1 严格 ++；D3-2 截图 progress 数值相比 D1-2 严格增加。**这两张是销账 #32 的唯一硬证据**。

---

## 场景 E · W11 主线关卡 drop 入背包（章末 Boss）

### E0 · 真通 Ch1 01-04（约 5-7 分钟）

Ch2/Ch3 锁住，必须先通 Ch1 全部才能挑章末 stage_03_05。**为快速验 drop**，改验 stage_01_05 章末（已配 drop_table，与 03_05 同分流但敌方更弱）：

| 步骤 | 操作 | 期望 |
|---|---|---|
| E0-1 | 顺次通 stage_01_02 荒山野店 / 01_03 黑风岭 / 01_04 洛阳城外 | 01-04 全 cleared，01_05 风雨渡口「可挑战」|

**注**：01_04 mult ≈ 1.6 小 Boss，T62 已视觉验过可胜。卡关 >3 次直接报回。

### E1 · stage_01_05 章末大 Boss 战前仓库快照

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| E1-1 | 主菜单 → 角色面板 → 仓库 Tab | 记下当前装备总数（如 9 件） | 不截（D 系列附带可对照） |

### E2 · 跑 stage_01_05 胜利（**预期需调装备强化才能胜**）

| 步骤 | 操作 | 期望 |
|---|---|---|
| E2-1 | 点「风雨渡口」| opening「风雨渡口 · 启」 |
| E2-2 | 战斗 | T62 已平衡为跨 2 阶到 erLiu（撑伞高人 10000HP / 750Atk），玩家方默认必败。**若直接胜：报回（设计预期）；若必败：先去仓库面板强化武器到 +5 后再战，能胜** |
| E2-3 | victory → 「风雨渡口 · 胜」 | 01_05 cleared |

### E3 · 战后仓库验 drop

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| E3-1 | 主菜单 → 角色面板 → 仓库 Tab | **应见关卡产出新装备**（owner=null，未装备状态），数量 ≥1；items 段（磨剑石 / 心血结晶）quantity 累加 | `10_w11_stage_drop_inventory.png` |

**E 通过条件**：E3-1 仓库截图相比战前多至少 1 件装备 owner 显示「未装备」；或者 items 数量增加（看 stage_01_05 dropTable yaml 配什么）。

**若 stage_01_05 不能胜（即使强化后）**：E0+E2 跳过，直接走「stage_01_01 第二次胜利后看仓库 drop」（_applyVictoryResolution 体例对每关都生效，drop 走 stage.dropTable 不分章末）。

---

## 场景 F · W11 爬塔 victory 副作用 + 重打差异点（核心销账 #32 第二验收）

### F1 · 爬塔 floor_1 首通

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| F1-1 | 主菜单 → 问鼎九霄 → floor_1 → 挑战 | opening narrative（若有）→ 战斗 → victory | 不截 |
| F1-2 | victory dialog 显示首通发奖 | 装备 / items 列表 | `11_w11_tower_floor1_firstclear_rewards.png` |
| F1-3 | dialog 关 → 角色面板 → 祖师 Tab → 装备段 | **参战装备 battleCount 应 ++**（D3-1 已经记过基线 + 1，此处再 ++ 1）| 不截（与 D3-1 比对足够）|

### F2 · 爬塔 floor_1 重打差异点（**最关键验收**）

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| F2-1 | 返回 TowerFloorListScreen → floor_1 应显示「已通关」chip → 点 floor_1 | AlertDialog「已通关，是否重打？（重打不发奖）」+ 重打 / 取消按钮 | 不截 |
| F2-2 | 点「重打」→ 战斗 → victory | victory dialog **不显示**首通发奖（drops 为空）| `12_w11_tower_floor1_replay_no_rewards.png` |
| F2-3 | 角色面板 → 祖师 Tab → 装备段 | **参战装备 battleCount 仍 ++** 一次（W11 销账 #32 关键差异点：重打不发奖但副作用照累）| `13_w11_tower_replay_battlecount_still_inc.png` |

**F 通过条件**：F2-2 截图 victory dialog 上不出现新装备掉落区域（或显示「无掉落」/「未获得新物品」之类语义）；F2-3 截图 battleCount 数字严格比 F1-3 再 ++ 1。

**这是 W11 与 W10 之前的最核心行为差异**：以前 victory 路径 0 调用 BattleResolutionService.resolve，W11 双端补齐后即使爬塔重打无发奖，battleCount/skillUsage 仍累。

---

## 场景 G · W10 章末 Boss 战败「散功代价」红字 banner（核心验收）

### G1 · 准备 stage_01_05 必败条件

**捷径**：场景 E 已通 stage_01_05？那退档不可能。**最快路径**：

1. 清存档 → 重新进游戏 → P5 → 直接挑 stage_01_05（跳过 01-04 不通）→ 但 stage_01_05 锁在 01_04 后，无法直接进。

**替代方案**：用场景 E 的 stage_03_05（章末大 Boss `武林大会·决战`，erLiu+ 跨 1-2 阶）但需先通 Ch1+Ch2 全部。耗时不接受。

**最实用路径**：

1. 清存档（同 0.4） → 重 P5 → 进 stage_01_01 故意拖到全员阵亡（但 01_01 是普通关，narrativeDefeatId=null，不会触发 banner，**沿用 T62 场景 C 的「无结算 UI」分流**，**不是本场景目标**）
2. **必须通 01-04 + 故意败 01_05**。01_05 是 Ch1 章末（isBossStage=true，配 narrativeDefeatId），是 W10 banner 触发关。

**实际流程**：

| 步骤 | 操作 | 期望 |
|---|---|---|
| G1-1 | 0.4 清存档 + 0.5 重启 | 全新进度 |
| G1-2 | P5 种子 → 顺通 01_01 / 02 / 03 / 04（不强化，留低境界）| 01-04 cleared，01_05 可挑战 |
| G1-3 | 点 01_05「风雨渡口」→ 不强化直接战 | T62 平衡过已必败 |
| G1-4 | 战败 → push NarrativeReaderScreen「风雨渡口 · 败」| **顶部出现红字 banner** |

### G2 · banner 视觉验收

| 步骤 | 期望 | 截图 |
|---|---|---|
| G2-1 | banner 标题「**战败 · 散功代价**」红色 | `14_w10_defeat_banner_title.png` |
| G2-2 | banner 内文每个有主修的参战角色一行：「{角色名} 内力 {数字}→{数字} · {心法名} {旧层名}→{新层名} (-N层)」| 同 G2-1 同一张截图带文字 |
| G2-3 | 主修角色 banner 外的「continue」按钮可点 | 不截 |
| G2-4 | banner 下方是 defeat narrative 正文「风雨渡口 · 败」文案 | 同 G2-1 |
| G2-5 | **不应**出现装备掉落 / 损失提示（GDD §2.1 反主流不掉装备红线）| 同 G2-1 |

### G3 · 角色面板验数值实际变化

| 步骤 | 期望 | 截图 |
|---|---|---|
| G3-1 | banner 看完点继续 → pop 回 stage list → 主菜单 → 角色面板 → 祖师 Tab | **internalForce 数值** 应是战前的 ×0.5（如战前 4180 → 战后 ~2090，UI 显示当前/上限格式）| `15_w10_defeat_internalforce_halved.png` |
| G3-2 | 同屏切心法段 | **主修心法 cultivationLayer** 应回退（如「圆熟·初窥」→「精通·极境」之类回退一层），progress 数字 ×0.5 | 同 G3-1 |

**G 通过条件**：G2-1 截图清晰显示红字「战败 · 散功代价」banner + 至少 1 个角色行；G3-1 截图内力数值是战前的一半。

---

## 收尾 · 报回 Mac 端

通过后在对话里贴以下截图（**必收**：D3-1 / D3-2 / E3-1 / F2-2 / F2-3 / G2-1 / G3-1 共 7 张，其他场景能给则给）：

```
01_w7_inventory_35items.png
02_w8_techniques_panel.png
03_w9_tower_floor_list_top.png
04_w9_tower_boss_outline.png
05_w9_tower_floor_30.png
06_w11_before_stage_eq_battlecount.png       ← D1 战前快照
07_w11_before_stage_tech_progress.png        ← D1 战前快照
08_w11_after_stage_eq_battlecount.png        ← **必收（销账 #32）**
09_w11_after_stage_tech_progress.png         ← **必收（销账 #32）**
10_w11_stage_drop_inventory.png              ← **必收（销账 #32）**
11_w11_tower_floor1_firstclear_rewards.png
12_w11_tower_floor1_replay_no_rewards.png    ← **必收（重打差异点）**
13_w11_tower_replay_battlecount_still_inc.png ← **必收（重打差异点）**
14_w10_defeat_banner_title.png               ← **必收（W10 销账）**
15_w10_defeat_internalforce_halved.png       ← **必收（W10 销账）**
```

**最少 7 张必收即可放行**。

通过后 Mac 端动作：

1. 截图 commit 入 `docs/screenshots/phase4_w7_w11/`
2. PROGRESS.md「进行中」段移到「已完成」段（W7-W11 五周累积视觉验收 ✅）
3. `phase4_summary.md` 起稿（W7-W11 段汇总，对照 phase3_summary.md 体例）
4. tag `v0.4.0-w11` push origin

### Kill 重启（验收期间用户改代码 push 后）

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Set-Location F:\Projects\wuxia_idle; git pull; Get-Process flutter,dart,wuxia_idle -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 2; Stop-ScheduledTask -TaskName WuxiaRun -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-ScheduledTask -TaskName WuxiaRun; Write-Host relaunched"'
```

### 全部完成后清理 schtasks

```bash
ssh Administrator@100.73.91.112 'powershell -Command "Get-Process flutter,dart,wuxia_idle -ErrorAction SilentlyContinue | Stop-Process -Force; Stop-ScheduledTask -TaskName WuxiaRun -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName WuxiaRun -Confirm:\$false -ErrorAction SilentlyContinue; Write-Host cleaned"'
```

---

## 已知踩坑 / FAQ

- **build_runner 必跑**：W4/W5/W6 累积教训，`*.g.dart` 全 gitignored，Pen 本地无生成产物
- **存档清理**：W6 Isar 升级 community 3.3.2 saveVersion 路径已沉淀，但 W7-W11 间累积字段（TowerProgress / RetreatSession 等）clean slate 最稳
- **stage_01_05 平衡**：T62 已调跨 2 阶到 erLiu，**默认必败**——这是设计（章末 Boss 暗示升阶），不是 bug。场景 E 需强化武器 +5 后才能胜。场景 G 利用此必败状态直接走战败 banner 验收
- **scenarioP5 入口路径**：主菜单 → Phase 2 调试场景 → P5 · 师徒种子（**不是**直接「P5」按钮，要先进 Phase 2 调试场景子屏）
- **W7/W8 35 件 / 21 本展示限制**：P5 只给玩家持有 9 件装备 + 4 本心法，35/21 是 yaml schema 层覆盖度，运行时仓库/心法面板只显示玩家持有。**场景 A / B 截背包当前持有即可，附文字说明** ——schema 层覆盖度由 Mac 端 `_enforceEquipmentRedLines` / `_enforceTechniqueRedLines` 测试兜底（test pass 即覆盖度过红线）
- **W11 验收关键**：场景 D / E / F 的「前后对比」是 W11 唯一硬证据。W10 之前 victory 路径 0 调 resolveBattle，副作用全丢；W11 之后 battleCount / progress / drop 真落地。**D3-1 / D3-2 / F2-3 三张截图缺一不可**
- **W10 banner 红色配色**：`WuxiaColors.hpLow` 红/绛系，半透明 0.15 背景 + 0.45 边框 + 红字标题（详 week10 handoff §5.3）
- **CLAUDE.md 数值红线**：玩家血 ≤ 20000 / 内力 ≤ 15000 / 普伤 ≤ 8000 / Boss 血 ≤ 50000+。验收期间触发越界立刻报回
