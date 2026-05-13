# Phase 3 Week 4 T53 / T54 / T55 收尾（2026-05-13）

> 写给下一会话开局后回来接 T56 的 Mac Opus 自己看。
> Week 4 D 师徒系统数据/service 子系统已经全部落地，T56 起进入 UI 子系统。
> PROGRESS.md「当前阶段」段是单一信源；本文档补充「为什么这么做」的决策链。

---

## 1. 一句话结论

Week 4 D 师徒系统 **T53→T54→T55 一波 3 commit 落地**，3 师徒数据 schema + 种子 service + 师承遗物字段 + 红线校验全部到位。`main` HEAD `2d1e53e`，**516/516** 测试，analyze 0 issues。**祖师 +5% 内力上限 buff 在 Demo 战斗路径首次落地**。下一步 T56 角色面板 UI + 顺手清挂账 #26。

---

## 2. commit 时间线

| # | hash | T | 类型 | 简述 |
|---|---|---|---|---|
| 1 | `c3293c3` | — | docs | D 起手 spec + §12 #5 收口 + 挂账 #30（基线，前置） |
| 2 | `9349626` | T53 | feat | masters.yaml schema + MasterDef + GameRepository 红线校验 |
| 3 | `69738c4` | T53 | docs | PROGRESS T53 完成 |
| 4 | `ed8b183` | T54 | feat | seedMasterDisciple + P5 入口 + 销账 #25 |
| 5 | `f2bf1a6` | T54 | docs | PROGRESS T54 完成 |
| 6 | `1418176` | T55 | feat | EquipmentDef.isLineageHeritage + 祖师遗物红线启用 |
| 7 | `2d1e53e` | T55 | docs | PROGRESS T55 完成 |

---

## 3. 关键决策链（避免下次会话重新走 spec 校准）

### 3.1 §12 #5 闭关产出公式：核心已决，3 维度扩展挂账 #30

闭关核心公式（`realm_scale_per_tier=1.3` / `cap_hours=72` / `base_equip_drop_probability=0.1` / 子时 +20% / mojianshi+experience 累加）全部落实在 service。3 个 numbers.yaml 已配但 service 未消费的维度（`technique_learn_rate` / `internal_force_growth` / 节气日+30% / 正午阳刚+20%）作为挂账 #30 留 Phase 4/Week 5。

### 3.2 D 方向选定（不是 phase3_tasks 末推荐的 C）

Codex 夜班 spec 推荐 C 奇遇。我推荐 D 并落地：
- **D 不被 §12 #6（机缘值累积规则）阻塞**——C/E 必须先决 #6 才能开工
- D 代码骨架最齐（`Character.lineageRole/masterId/discipleIds/isFounder` 字段 + `numbers.yaml founder_ancestor_buff` key 都已留位）
- D 是 Demo §7 硬指标（祖师+大弟子+二弟子）
- D 不牵动战斗公式回归面

### 3.3 §12 #10/#11 在 Demo 范围内全部推迟到 1.0

关键洞察：**Demo 不做飞升 → §10 (a)(b)(c)(d) + §11 buff 内容全部不发生**。
- (a) 传递时机：无飞升 → 无传位
- (b) 多徒弟谁继承：无传位 → 无继承
- (c) buff 累代叠加：最多 1 代 → 无累代
- (d) 同部位冲突：无传递 → 无冲突
- §11 jeshi buff：`enabled_when_alive: false` 已锁 → Demo 不实现

这把"复杂规则核心未决"的张力直接消解，D 起手 0 决策阻塞。

### 3.4 方案 A 降级（祖师一流 / 大弟子二流 / 二弟子三流）

原 spec 写祖师宗师/大弟子绝顶/二弟子一流。审计时发现 yaml 现实严重错位：
- `equipment.yaml` 最高阶到 `liQi`（一流），没有更高阶遗物
- `techniques.yaml` 最高阶到 `mingJia`（二流），没有更高阶心法

3 选项里选 **A 降级**——0 改动 yaml，工期不动，且契合 GDD §7.1「一流（结丹）解锁收徒」锚点。

### 3.5 Spec 与代码现实的 2 处偏差校准

T53 阶段 A 审计时发现 spec 错误，已在代码中纠正（spec 文字本身没回改）：
- `LineageRole` 实际是 `founder / disciple / grandDisciple`（不是 `firstDisciple/secondDisciple`）。大/二弟子都是 `disciple`，靠 `slotIndex` 区分
- `Attributes` 字段实际是 `constitution / enlightenment / agility / fortune`（不是 `strength`）

**下次会话注意**：phase3_tasks.md T54-T56 spec 文字描述仍停留在原版，校准的口径以代码 + 本 closeout 为准。

### 3.6 isLineageHeritage 字段引入策略（T55）

`EquipmentDef` 之前完全没有 `isLineageHeritage` 字段；`Equipment` runtime 实例有；`EquipmentFactory.fromDef` 早已有 `isLineageHeritage` 参数但默认 false。

T55 策略：**保持参数签名不变，函数体内 `OR`**：
```dart
isLineageHeritage: isLineageHeritage || def.isLineageHeritage,
```

- DropService / Phase2SeedService 调用方零改动
- def=true 自动标遗物（drop 路径也对齐）
- 参数保留为"奇遇赠送临时遗物"等场景的 override 通道

### 3.7 挂账 #25 销账 + #26 剥离决策

- **#25（P1 fixture 缺主修）**：T54 销账方式 = seedMasterDisciple 路径全 3 师徒齐主修 → service-level test 验证 buildTeams(stage_01_01) 不再 fail-fast。P1 fixture 本身没动（保留体例），玩家走 P5 入口进战斗
- **#26（main_menu 闭关入口硬编码）**：原 T54 spec 计划顺手清，**实施时剥到 T56**——main_menu 是 StatelessWidget，清 #26 涉及 FutureBuilder 异步 + 跨 UI 改造，T56 反正要做 UI，一并处理更聚焦

---

## 4. 测试基线 deltas

| 阶段 | analyze | test |
|---|---|---|
| 开工前（main，c3293c3 文档基线后） | 0 issues | 495/495 |
| T53 完成（9349626） | 0 issues | 505/505（+10：MasterDef 3 + 红线 fail-fast 7）|
| T54 完成（ed8b183） | 0 issues | 511/511（+6：3 师徒结构/装备心法齐/流派透传/reseed/P1 切换/销账 #25）|
| T55 完成（1418176） | 0 issues | 516/516（+5：fromYaml 1 + Factory 透传 3 + 祖师无遗物 fail-fast 1）|

---

## 5. T56 起手者必读（下一会话开局看这段）

### 5.1 入场审计三件套

```bash
cd ~/Desktop/挂机武侠 && git log --oneline -5
flutter analyze
flutter test
```

应得到：HEAD `2d1e53e` / 0 issues / 516 passed。任一不对停下贴差异。

### 5.2 T56 spec 见 `phase3_tasks.md` 末 Week 4 段

注意 spec 还停留在「firstDisciple/secondDisciple/strength」原文，实际代码用「disciple+slotIndex 区分 / constitution+enlightenment+agility+fortune」（见本文 §3.5）。

### 5.3 起手前 2 个 UI 决策（上轮已倾向，未拍板）

**UI-1：「师承」段位置**
- 方案 A（推荐）：复用既有 `character_panel_screen` 在角色面板内加 section
- 方案 B：主菜单新增「师徒」入口跳新 panel

**UI-2：3 角色切换方式**（character_panel 现在硬编码 characterId=1）
- 方案 X：顶部 Tab（祖师/大弟子/二弟子）——我倾向
- 方案 Y：PageView 左右滑切换
- 方案 Z：不切换，只在祖师页签显示徒弟列表（最简但失去切换体验）

T56 起手前等用户拍板。

### 5.4 顺手清挂账 #26（main_menu 闭关入口硬编码）

- 现状：`lib/ui/main_menu.dart:77-78` 硬编码 `characterId=1 / RealmTier.xueTu`
- 改造方式：用 FutureBuilder 包闭关按钮 → 异步读 SaveData.activeCharacterIds 首位 + Character.realmTier
- 改造范围：仅 main_menu 闭关入口一处；character_panel 改造由 T56 主体处理

### 5.5 重要的运行时副作用

T55 让祖师 starting 含 2 件 isLineageHeritage 装备 → `internalForceMaxWithLineage` 自动叠加 +5% × 2 = +10%（"每件独立叠加"，见 `numbers_config.dart:59` 注释）。BattleCharacter 装配时会用 lineage 加成版的 internalForceMax，不是 character.internalForceMax 字段值。T56 角色面板 UI 若要显示"实际内力上限"，需调 `DerivedStats.internalForceMaxWithLineage(character, equipped)` 而非直接读字段。

---

## 6. 已知留尾

- **挂账 #26**：T56 顺手清
- **挂账 #30**（闭关 3 维度扩展）：Phase 4/Week 5
- **挂账 #25 的 P1 路径**：seedMasterDisciple 销账，P1 入口本身仍是「无主修」体例不动
- **phase3_tasks.md T54-T56 spec 文字未更新**：内容描述还停留在 `firstDisciple/secondDisciple/strength`，实施口径以代码为准；可选在 T58 收尾时统一回填

---

## 7. 关联

- **PROGRESS.md**「当前阶段」段 + 已完成段（T53/T54/T55 详条）+ 进行中段（指 T56）
- **决策草案**：`docs/handoff/week4_d_minimal_spec_2026-05-13.md`（D 方案 A + 3 决策点 ✓）
- **任务 spec**：`phase3_tasks.md` 末 Week 4 段（T53-T58）
- **Codex 前置工作**：`docs/handoff/codex_dispatch_2026-05-12.md`（C/D/E 候选 spec 来源）

---

> 下一会话开局只读 PROGRESS.md 即可起手 T56，需要"为什么"时再翻本文。
