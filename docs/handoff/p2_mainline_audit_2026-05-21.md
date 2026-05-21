# P2 第二条主线 · Phase 0 reality check audit(2026-05-21)

> **会话**:2026-05-21 主对话(/clear 后)Mac opus xhigh
> **任务**:候选 4 · P2 第二条主线启动准备 · Phase 0 audit + 6 关键决策清单
> **范围**:仅 audit + decision document,**不动 lib/**
> **路线图位置**:`docs/ROADMAP_1_0.md` P2 主战场 M5-M10(6 月),前置 P0 100% + P1.1 ~60% + P1.3 美术 100%

---

## §0 audit 起手:Phase 0 四维 grep 清单(memory `feedback_phase0_grep_two_axes`)

| 维度 | 命令 / 范围 | 结论 |
|---|---|---|
| **A schema** | grep `secondMainline\|MainlineId\|MainlineProgress` lib/ test/ data/ | **0 命中 schema 层** · 仅 9 处 caller 注释引用 |
| **B caller** | grep `MainlineProgress\|mainlineProgressProvider` lib/features/ | 跨 feature 5 处:tutorial / event / main_menu / phase2_seed / debug |
| **C 邻近目录** | `find lib/features/mainline -type f` | 已建 9 文件 1576 行(domain/application/presentation 三层全) |
| **D UI widget** | grep `ChapterListScreen` | 单入口:main_menu.dart:117 `_push(context, const ChapterListScreen())` |

---

## §1 现状 schema(维度 A 详条)

### 1.1 `MainlineProgress`(Isar @collection)
`lib/features/mainline/domain/mainline_progress.dart:17` 32 行:

```dart
@collection
class MainlineProgress {
  Id id = Isar.autoIncrement;
  late int saveDataId;             // SaveData.slotId(Phase 3 固定 1)
  int currentChapterIndex = 1;     // 当前焦点章节
  List<String> clearedStageIds = [];   // append-only,无序集合语义
  List<DateTime> clearedAt = [];       // 与 clearedStageIds 同序
}
```

**关键缺口**:**无 `mainlineId` 字段** — 当前 schema 表达「**单条**主线进度」。每存档(saveDataId)只有 1 行 MainlineProgress,所有 cleared stage 全归入单一集。

### 1.2 `StageDef`(纯 Dart,不入 Isar)
`lib/data/defs/stage_def.dart` 14 字段:

```dart
class StageDef {
  final String id;                  // stage_01_01 .. stage_03_05
  final String name;
  final StageType stageType;        // mainline / tower / seclusion
  final int? chapterIndex;          // 1/2/3 主线;tower 走 towerLayer
  final int? towerLayer;
  final RealmTier requiredRealm;
  final List<EnemyDef> enemyTeam;
  final bool isBossStage;
  final String? prevStageId;        // 章节内顺序链
  final String? narrativeOpeningId; // 联结 data/narratives/stages/
  final String? narrativeVictoryId;
  final String? narrativeDefeatId;
  // dropTable / baseExpReward / difficultyMultiplier / biome / weather
}
```

**关键缺口**:**无 `mainlineId` 字段** — `chapterIndex 1/2/3` 是全局单维,无主线区分。

### 1.3 `MainlineProgressService` 业务逻辑
`lib/features/mainline/application/mainline_progress_service.dart` 139 行 4 方法:
- `getOrCreate({saveDataId})` — 单存档单行
- `availableStages({progress, chapterIndex})` — 按 chapterIndex 过滤 stageDefs.values + prev 链 BFS
- `recordVictory({stageId, now, tutorialService?})` — 全局 cleared 集 append + 同事务推 tutorialStep
- `chapterCompleted({progress, chapterIndex})` — 该章所有 stage 是否都在 cleared 集

**单主线假设**:所有方法以「单一 cleared 集 + chapterIndex 1-3」为锚点。

---

## §2 caller 端耦合(维度 B 详条)

| # | 文件:line | 用法 | P2 改造影响 |
|---|---|---|---|
| 1 | `lib/features/main_menu/presentation/main_menu.dart:117` | `_push(context, const ChapterListScreen())` 单入口 | UI 入口策略待定(Decision 4) |
| 2 | `lib/features/mainline/presentation/chapter_list_screen.dart:23` | `_chapters = [1, 2, 3]` 硬编码 3 章 | 需扩 4-6 或加主线分段(Decision 1+4) |
| 3 | `lib/features/tutorial/application/tutorial_service.dart:78` | `advanceForStageCleared(stageId)` 推进 tutorialStep | 第二条主线不触发 tutorial(Decision 5) |
| 4 | `lib/features/tutorial/application/tutorial_providers.dart:20` | invalidate 体例沿 `mainlineProgressProvider` | provider key 待定(Decision 1 决定) |
| 5 | `lib/features/event/application/game_event_service.dart:217` | isFirstClear 走 `MainlineProgress.clearedStageIds` | 跨主线 cleared 集合并 / 分离(Decision 1) |
| 6 | `lib/features/debug/application/phase2_seed_service.dart:275,725,727` | debug seed 用 `MainlineProgressService` 注入 stage_01_05 cleared | seed fixture 需扩 P2 进度状态 |
| 7 | `lib/features/tower/application/tower_progress_service.dart:16` | 注释「与 MainlineProgressService 完全独立」 | 无影响(独立模块) |
| 8 | `lib/features/seclusion/application/seclusion_service.dart:52` | 注释「与 TowerProgressService / MainlineProgressService 完全独立」 | 无影响(独立模块) |

---

## §3 数据现状(维度 D 详条)

| 项 | Demo 现状 | P2 目标 | delta | 备注 |
|---|---|---|---|---|
| 主线关卡 | 15(3 章 × 5) | 30-35(6 章 × 5)| +15-20 | ROADMAP 表 |
| 章节 | 3(Ch1/2/3)| 6 | +3 | 第二条主线 3 章 |
| `data/stages.yaml` 行 | ~900 行 | ~1800 行 | +900 | yaml 配置扩 |
| `data/narratives/chapters/` | chapter_01/02/03.yaml | +chapter_04/05/06 | +3 | 章节概要 |
| `data/narratives/stages/` | 36 文件(opening + victory + 6 defeat) | ~72 文件 | +36 | 每 stage 2-3 narrative |
| 主线字数 | 3-5k(实测 6778)| 6-10k | +3-5k | DeepSeek 退役后 Mac+Opus 单端写 |
| `data/lore/` 装备典故 | 35 件 ×2 段 = 70 段(部分待补)| 80 件 ×2 段 = 160 段 | +90 段 | P2.1 衍生 |
| `data/equipment.yaml` | 35 件 | 80 件 | +45 | 全 7 阶覆盖 |
| `data/techniques.yaml` | 21 心法 | 50 心法 | +29 | 全 7 阶 × 3 流派 |

---

## §4 P2 关键决策清单(6 项待用户拍板)

> 每项给出**推荐方案 + 备选 + 影响面 + 理由**,等用户拍板后再起 spec。

### Decision 1 · Schema 改造方案 ⭐ 核心

| 方案 | 改动点 | 优点 | 缺点 |
|---|---|---|---|
| **A ⭐推荐** | `MainlineProgress` 加 `mainlineId` String 字段(默认 "primary") · `StageDef` 加同名字段 · Service 4 方法签名加参数 | Isar collection 沿用 · 每 mainlineId 一行 · 1.0 之外可扩(P3+ 主线 3) | Service 全改 + 测试 fixture 扩 |
| B | 新 collection `SecondaryMainlineProgress`(复制 schema)| 主线 1 不动 · 零回归 | 代码重复 · UI/event/tutorial 双套耦合 |
| C | 只在 `StageDef` 加 `mainlineId`,`MainlineProgress.clearedStageIds` 不分主线 | Service 改动最小 | 跨主线 cleared 集语义模糊 · isFirstClear/codex 解锁逻辑会跨主线串 |
| D | `chapterIndex` 扩 4-6,不引入 mainlineId | schema 零改 | UI 端「主线 vs 第二主线」无语义区分 · 玩家流程感受混 |

**推荐 A 理由**:① Isar 索引开销小(`saveDataId+mainlineId` 联合 filter);② 业务语义清晰(每主线独立进度);③ 兼容未来主线扩展;④ 与 GDD §12.4「第二条主线」原意贴。

### Decision 2 · `mainlineId` 类型

| 方案 | 备注 |
|---|---|
| **A ⭐推荐** String("primary" / "secondary")| 与 stage id 等其他 yaml String key 一致 |
| B enum `MainlineId { primary, secondary }`| 类型安全但扩展性差(每加新主线改 enum) |

**推荐 A 理由**:与 yaml 现有体例一致(stageType / school / school 等都用 enum,但 mainlineId 是「内容范围标识」更近 stage id 语义)。

### Decision 3 · 章节 ID 命名 & chapterIndex 编号

| 方案 | chapter index | stage id 命名 | 备注 |
|---|---|---|---|
| **A ⭐推荐** | secondary 主线复用 1-3 | `stage_p2_01_01..stage_p2_03_05` | mainlineId="secondary" + chapter 1-3 双键 · stage id 显式 p2 prefix 防混 |
| B | 全局连续 4-6 | `stage_04_01..stage_06_05` | mainlineId 仅用于 UI 分段,chapter 唯一 |
| C | 全局连续 4-6 | `stage_p2_04_01..stage_p2_06_05` | A/B 混合 |

**推荐 A 理由**:① mainlineId 已表达「哪条主线」,chapter 复用 1-3 更对称(每主线 3 章);② stage id `p2` prefix 让 yaml/grep/log 一眼可分;③ ChapterListScreen 分段时 mainlineId 是 group key,chapter 是 group 内 sort key,清晰。

### Decision 4 · UI 入口策略

| 方案 | 改动 | 玩家体验 |
|---|---|---|
| **A ⭐推荐** | ChapterListScreen 内分两段「第一主线」「第二主线」 | 单按钮入口,内部分段;第二主线满足条件前显示 locked 整段 |
| B | MainMenu 加新按钮「第二条主线」| 双按钮入口 · 玩家可见但点击受限 |
| C | 玩家境界达成自动出现新章节 | 1 章列表流式扩展 · 无主线区分概念 |

**推荐 A 理由**:① MainMenu 不复杂化(现有 9 按钮,加新按钮即 10);② 玩家从 Ch3 通关到 第二主线 Ch1 是「连续路径」语义;③ ChapterListScreen `_chapters` 改 group + chapter index 双键即可。

### Decision 5 · 解锁条件 ✅ 用户拍板简化为方案 B(单门槛)

| 方案 | 条件 | 工期独立性 |
|---|---|---|
| A | 第一主线 Ch3 全通 + 玩家境界达**一流(erLiu)** | 双重门槛 · 原推荐 |
| **B ✅ 拍板** | 仅第一主线 Ch3 全通 | 单门槛 · 简化 UI · erLiu 检查保留作 service 层 assert |
| C | 仅玩家境界达一流 | 跳过第一主线 · 不合理 |
| D | 第一主线 Ch3 全通 + 飞升 wushen | 必须 P2.3 先完成,P2.1 阻塞 |

**拍板理由**:① 第一主线 Ch3 章末 boss(stage_03_05)数值贴 erLiu 上限,通关时玩家境界几乎必达 erLiu,**双门槛实际无差异**;② UI 端「玩家境界未达 erLiu 但 Ch3 全通」状态太少见,不值得画 UI;③ 保留 erLiu 检查作 service 层 assert 防 cheat(yaml 红线校验或 game_repository._enforceSecondaryMainlineUnlock)。

### Decision 6 · Tutorial 推进策略

| 方案 | 改动 | 备注 |
|---|---|---|
| **A ⭐推荐** | 第二主线 stageCleared **不触发** tutorial | 玩家到第二主线已过 tutorial 全流程 · tutorialStep enum 不扩 |
| B | 第二主线扩新 tutorialStep 阶段 | enum 加值 · 引导设计复杂 |

**推荐 A 理由**:① GDD §10 教程在第一主线 Ch1 内完成(tutorialStep 当前 ch1 stage_01_01-04 推进);② 第二主线是「老玩家进阶内容」,无教学需求;③ `MainlineProgressService.recordVictory` 内 `tutorialService.advanceForStageCleared(stageId)` 改为「if mainlineId=='primary' 才触发」一行守卫。

---

## §5 改造影响面预估(Decision 1 = A 前提)

### 5.1 Schema 层(2 文件)
- `lib/features/mainline/domain/mainline_progress.dart` 加 `String mainlineId = 'primary';` + 重新 build_runner(.g.dart 重生)
- `lib/data/defs/stage_def.dart` 加 `final String mainlineId;` + `fromYaml` 默认 'primary'

### 5.2 Service 层(1 文件 + 4 方法)
- `lib/features/mainline/application/mainline_progress_service.dart`:
  - `getOrCreate({saveDataId, mainlineId})` — 加参数 · filter 双键
  - `availableStages({progress, chapterIndex, mainlineId})` — stageDefs.where 双键过滤
  - `recordVictory({stageId, now, tutorialService?, mainlineId?})` — Decision 6 守卫
  - `chapterCompleted({progress, chapterIndex, mainlineId})` — where 双键过滤

### 5.3 Provider 层(1 文件 + 重新 build_runner)
- `lib/features/mainline/application/mainline_providers.dart`:
  - `mainlineProgress(Ref ref, {required String mainlineId})` 改 family provider · 或 `mainlineProgressPrimaryProvider` + `mainlineProgressSecondaryProvider` 双 provider
  - 推荐 family,扩展性好

### 5.4 UI 层(2 文件 + 新 widget)
- `chapter_list_screen.dart`:`_chapters` 改 group/chapter 双键 + 加「第二主线」分段 + locked 状态
- `stage_list_screen.dart`:加 mainlineId 参数透传
- 可能加 `MainlineGroupCard` widget(分段标题 + locked overlay)

### 5.5 数据层
- `data/stages.yaml`:每 stage 加 `mainlineId: primary`(默认值,可选 yaml 不写 Dart 兜底)
- 新增 15-20 stage `mainlineId: secondary`
- `data/narratives/chapters/chapter_04/05/06.yaml`(P2.1 内容)
- `data/narratives/stages/stage_p2_*.yaml`(36-72 文件)

### 5.6 Caller 层守卫
- `tutorial_service` 不动(由 Service 层 Decision 6 守卫)
- `game_event_service.isFirstClear` 单存档全局 cleared 集已含,无变化(跨主线 stage id 唯一)
- `phase2_seed_service` debug fixture 可选扩 P2 进度

### 5.7 Test 层
- `test/features/mainline/` 已建 3 层目录 → 加 mainlineId 维度 case
- 新红线测试:`mainlineId='secondary'` stage 必须解锁条件齐
- 现有 1127 pass 不破(默认值 'primary' 兜底)

---

## §6 工期估算(P2.1 第二主线主体,P2.2 P2.3 独立)

| Phase | 内容 | 估时 | 模型 |
|---|---|---|---|
| **P2.1.0 schema + service 改造** | Decision 1+2+3+5+6 落地 · build_runner · test 加 mainlineId 维度 | **opus xhigh 4-6h** | 单端 |
| P2.1.1 UI 分段 | ChapterListScreen 双段 · StageListScreen 透传 · locked overlay | opus high 2-3h | 单端 |
| P2.1.2 yaml 数据扩 ch4 5 stage | 1 章 5 stage + narrative + drop · 走 GDD §5.3 三系锁死 | opus xhigh + sonnet 6-10h | 单端(P2.1 全程 Mac+Opus) |
| P2.1.3 yaml ch5+ch6 | 2 章 10 stage 同上 | opus xhigh + sonnet 12-20h | 单端 |
| P2.1.4 装备扩 35→80 | 7 阶 × 流派 ×~6 件 + lore 典故 | opus xhigh 12-20h | 单端 |
| P2.1.5 心法扩 21→50 | 7 阶 × 3 流派 × ~7 心法 + 心法相生扩 | opus xhigh 8-12h | 单端 |
| P2.1.6 武学领悟扩 35→70 招 | encounter techniqueInsight +20 触发 +35 招 | opus high 6-10h | 单端 |
| **P2.1 合计** | 主线扩 + 装备 + 心法 + 招式 | **~50-80h(~2-3 周连工)** | M5-M6 月内可收口 |
| P2.2 心魔系统 | §12.1 心魔关卡 · 数值 · UI | opus xhigh 10-15h | M7-M8 |
| P2.3 飞升 + 遗物 transfer | E.2 + E.3 · cultivation + inheritance + character + equipment + save_data 跨模块 | opus xhigh 15-25h | M9-M10 |

**P2 合计估时**:~75-120h(M5-M10 实际工期 6 月,大量留 DeepSeek 文案产能压测 + 美术接图节奏 + Phase 测试)。

> **opus xhigh 单任务实测系数**:memory `feedback_opus_xhigh_interactive_duration` 实测主对话同 context 比 spec 估时快 1.7-5×。**保守口径**:P2 实际工期可能 ~30-60h(spec 估时 ×0.6 系数)。

---

## §7 风险清单

| # | 风险 | 缓解 |
|---|---|---|
| R1 | Schema 改造 build_runner 重生破坏 1127 pass | TDD 分阶段验证 · mainline_progress.g.dart 重生后跑 test/features/mainline 优先 |
| R2 | mainlineId family provider 与 Riverpod codegen 兼容性 | memory `feedback_riverpod_codegen_provider_split` 有 cookbook |
| R3 | data 量大(35→80 装备 + 21→50 心法)文案产能压测 | P1.4 ROADMAP 已留 DeepSeek 产能压测 · 现 Mac+Opus 单端接管 |
| R4 | UI 双段分组复杂度 | Decision 4 推荐 A 内部分段,MainMenu 单按钮入口不动 |
| R5 | P0 base maxHp #38 数值红线 P2 wushen 路径会触上限 | P0.1 已 100% 收口(base ≤ 16667),无阻塞 |
| R6 | tutorial 推进逻辑跨主线串 | Decision 6 推荐 A · `if mainlineId=='primary'` 守卫一行解 |
| R7 | 美术 AI 出图节奏跟不上 P2.1 装备 35→80 | P1.3 美术 PoC ~100%(W6 平均 8.55/10)· $0.40/张 ROI · 量产配方 18 条 memory · 节奏伴生 |

---

## §8 1.0 ROADMAP 与 P2 关系审视

### 8.1 ROADMAP 状态
- P0 100% ✅(#38 base maxHp + strategy 重构 + itch.io 砍 + 销账段)
- P1.1 ~60%(A1 师徒 / A3 共鸣 / A4 开锋 sonnet 各 1-3h 待开)
- P1.2 0%(§12 江湖恩怨 / 声望 / 心魔 P2.2 / 节日 W16/W17 框架已建,内容待补)
- P1.3 美术 100% ✅(M4 PoC + 89 张归档 + Flutter UI 全接入 + round 2 9/9 PASS)
- P1.4 文案产能压测 退役(v1.8 DeepSeek 退役后 Mac+Opus 单端接管)

### 8.2 P2 启动前置依赖
- **硬阻塞**:无
- **建议先收口**:P1.1 A1/A3/A4(系统纵深完整化,影响 P2.1 玩家体验完整度)
- **可并行**:P1.2 §12 独立模块(江湖恩怨 / 声望 ROADMAP P1.2 + 心魔 P2.2)

### 8.3 推荐执行顺序
1. **当前(2026-05-21)**:本次 audit + decision 拍板
2. **第 1 步**:P2.1.0 schema + service 改造(opus xhigh 4-6h,基础设施先行)
3. **第 2 步**:P2.1.1 UI 分段(基础设施验证)
4. **第 3-N 步**:并行推进:
   - P2.1.2-1.6 内容扩(主对话连续工期)
   - P1.1 A1/A3/A4 收口(穿插)
   - P1.2 §12 独立模块(可后置 / 与 P2.1 并行)
5. **后期**:P2.2 心魔 + P2.3 飞升

---

## §9 决策清单一览 ✅ 2026-05-21 用户拍板

| # | Decision | 拍板方案 | 备注 |
|---|---|---|---|
| 1 | Schema 改造 | ✅ A · `MainlineProgress`+`StageDef` 加 `mainlineId` String | 强推荐方案 |
| 2 | mainlineId 类型 | ✅ A · String("primary"/"secondary") | 与 yaml 体例一致 |
| 3 | 章节/stage 命名 | ✅ A · secondary 复用 ch1-3 + `stage_p2_*` prefix | UI 显示用「序章/中卷/终卷」语义标签 |
| 4 | UI 入口 | ✅ A · ChapterListScreen 内分两段 | MainMenu 不加按钮 |
| 5 | 解锁条件 | ✅ **B · 仅 Ch3 全通**(单门槛简化) | 原推荐 A 双门槛简化为单门槛 · erLiu 保留作 service assert |
| 6 | Tutorial 推进 | ✅ A · 第二主线不触发 tutorial | 一行守卫解 |

---

## §10 执行路径 ✅ 2026-05-21 用户拍板:**保守路径**

```
✅ 当前会话:audit + decision 拍板(本 doc)
↓
⭐ 下波:P1.1 A1/A3/A4 收口(sonnet 各 1-3h ≈ 1 工作日)
  - A1 师徒 E.1 收徒弹窗 + E.5 founder_ancestor_buff sect buff
  - A3 共鸣度满级体验完整化(joint_skill 表现层 / banner 时机 / 拆分提示)
  - A4 开锋 3 槽 build 内容扩(审计每件装备开锋方案)
↓
下下波:P1.2 §12 江湖恩怨 + 声望(opus xhigh 6-8h,独立模块)
↓
再下波:P2.1.0 schema + service 改造(opus xhigh 4-6h · 拍板 D1-6 落地)
↓
后续:P2.1.1 UI 分段 → P2.1.2-1.6 内容大扩(M5-M10 主战场)
```

**拍板理由(保守路径胜出)**:① ROADMAP M5-M10 时间宽裕;② P1.1 / P1.2 收口让 Demo 真 100% + 内容铺垫 P2;③ 避免 P2 schema 改完到 P2.1 内容通流程的「中间态 secondary 永远 locked」dogfooding 体验缺失。

---

## §11 audit 完结

- **Phase 0 reality check** 全维度覆盖(schema / caller / 邻近目录 / UI widget / 数据 / ROADMAP / 测试 / 风险)
- **lib/features/mainline/ 现状**:9 文件 1576 行(三层完整,单条主线 schema)
- **跨 feature 耦合点**:8 处(2 UI / 1 tutorial / 1 event / 1 main_menu / 1 debug / 2 独立模块注释)
- **6 关键决策**:推荐方案 + 影响面 + 工期估算齐
- **P2 工期**:~75-120h spec 估时,~30-60h opus xhigh 实测系数

**不动 lib/,不动 data/yaml,不动 GDD/CLAUDE/numbers/data_schema/IDS_REGISTRY**。等用户拍板 Decision 1-6。
