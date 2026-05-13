# phase3_tasks.md · 第三阶段（第 7 周起）主线 + 内容系统任务清单

> **文档地位**：给 Mac 端 Claude Code + Opus 4.7 的执行清单，每个任务自带验收标准。
>
> **遵循文档**：GDD.md v1.1 §7-§8 / CLAUDE.md v1.1 §7+§12 / data_schema.md / phase2_summary.md
>
> **阶段目标**：Phase 2 把"装备 + 心法 + 战斗联动"接通；Phase 3 把"关卡 + 主线剧情"接到玩家入口，让 Demo 第一阶段「学武出山」能从主菜单点进去玩到一关。后续 Week 2-3 再加爬塔/闭关/奇遇/师徒传承/武学领悟。
>
> **总工作量预估**：Week 1 约 6 工作日；Week 2-3 待 Week 1 跑通后再拆。
>
> **切法选定**：B 改良版（kickoff §四） —— 主线最小闭环优先，schema 同步给 DeepSeek 当主线文案模板。

---

## 0. 总体说明（必读）

### 0.1 与 Phase 2 的关系

Phase 2 已交付（v0.2.0-phase2，merge `5efe8d5` + #24 fixup `5ce76f5`）：
- 数据：Equipment / Technique / Character 三个 @collection 字段就绪 + EquipmentFactory 抽 Rng + Phase2SeedService 4 场景种子
- 服务：EnhancementService / ForgingService / CultivationService / DispelService / BattleResolutionService / DropService 全套
- UI：仓库 / 强化 / 开锋 / 心法面板 4 块（仍走调试菜单 main_menu → Phase2TestMenu）
- 战斗：纯快照 BattleEngine，结算阶段一次性 writeTxn
- 测试 335/335 全绿，analyze 0 issues

Phase 3 干的事：
- **关卡数据 schema 升级**：Phase 1 占位 StageDef 加 `prevStageId` / `narrativeOpeningId` / `narrativeVictoryId`，6 关 fixture 顺序串成 3 章
- **Isar 新增 MainlineProgress collection**：currentChapter / clearedStageIds / lastClearedAt
- **MainlineProgressService**：解锁判定 / 首通记录 / 章节完成判定
- **主线 UI**：章节列表 + 关卡列表 + 剧情阅读 + 关卡进入流程串联（接到 main_menu，替换调试入口为正式入口）
- **NarrativeLoader 容错**：缺文件兜底「[剧情待补]」，让 Pen/DeepSeek 异步补文案不阻塞 Mac

### 0.2 关键约束（不要踩雷）

1. **延续 Phase 1/2 红线**
   - 数值红线（GDD §5.2）：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000
   - 三系锁死（CLAUDE §5.3）：境界 ↔ 装备阶 ↔ 心法阶；师承遗物同样受锁，**关卡 requiredRealm 校验时不放水**
   - 反主流（CLAUDE §5.1）：不做体力/每日任务/抽卡/VIP/分解/快进券
   - 中文文案不进 Dart 代码（UI 标签 `lib/ui/strings.dart`，剧情走 `data/narratives/`）
   - 数值不硬编码（走 `numbers.yaml`）

2. **DeepSeek 领地不动**
   - `data/narratives/` `data/lore/` `data/events/` 任何文件 Mac 端不写、不改、不删
   - Mac 写 `docs/NARRATIVE_SCHEMA.md` 给 DeepSeek 看格式（这是 docs/ 不是 narratives/，合规）
   - NarrativeLoader 缺文件兜底「[剧情待补]」，让 DeepSeek 异步补；不在 Mac 端塞占位 yaml

3. **战斗依然纯快照**
   - BattleScreen 参数化 StageDef + onVictory/onDefeat 回调
   - MainlineProgressService.recordVictory 在 onVictory 回调里调，与战斗结算 writeTxn 解耦

4. **不动文件清单**
   - `GDD.md` / `CLAUDE.md` / `numbers.yaml` / `data_schema.md` / `IDS_REGISTRY.md`
   - DeepSeek 领地 `data/narratives/|lore/|events/`

### 0.3 已拍板的决策（2026-05-11）

| 决策项 | 关联任务 | 决议 |
|---|---|---|
| Phase 3 切法 | — | B 改良版（主线最小闭环优先） |
| 占位 narrative 由谁产 | T36 | NarrativeLoader 缺文件兜底「[剧情待补]」，DeepSeek 异步补 |
| §12 #1 境界 vs 修炼度名重叠 | — | Phase 1 实施时已实质消解（境界 7 层「启蒙/入门/熟练/精通/圆熟/化境/登峰」vs 心法 9 层「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」严格不同名，见 `enum_localizations.dart:39,78` 注释）；CLAUDE.md §12 #1 文档与代码已分叉，挂账记录在 PROGRESS |
| Week 1 范围 | T33-T39 | 主线最小闭环，不碰爬塔/闭关/奇遇/师徒/武学领悟 |

### 0.4 Week 1 任务依赖图

```
Phase 2 完成线（v0.2.0-phase2 + #24 fixup）
                          │
                          ▼
                 T33 stages.yaml schema 升级
                 + StageDef 扩字段 + 6 关 backfill
                          │
                          ▼
                 T34 MainlineProgressService
                 + Isar MainlineProgress collection
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
            T35         T36         T38
       章节/关卡列表 UI  剧情阅读 UI   docs/NARRATIVE_SCHEMA.md
              │           │
              └─────┬─────┘
                    ▼
               T37 关卡进入流程串联
               （UI ↔ 战斗 ↔ Service）
                    │
                    ▼
               T39 Pen 视觉验收 + tag v0.3.0-w1
```

### 0.5 目录结构（在 Phase 2 基础上扩）

```
lib/
├── data/
│   ├── defs/
│   │   └── stage_def.dart                # T33 扩字段
│   ├── models/
│   │   ├── mainline_progress.dart        # T34 新建（@collection）
│   │   └── mainline_progress.g.dart      # T34 build_runner 生成
│   └── narrative_loader.dart             # T36 新建
├── services/
│   └── mainline_progress_service.dart    # T34 新建
├── ui/
│   ├── mainline/                          # T35/T37 新建
│   │   ├── chapter_list_screen.dart      # T35
│   │   ├── stage_list_screen.dart        # T35
│   │   └── stage_entry_flow.dart         # T37（关卡按钮 → opening → 战斗 → victory）
│   ├── narrative/                         # T36 新建
│   │   └── narrative_reader_screen.dart  # T36
│   └── battle/
│       └── battle_screen.dart             # T37 参数化（接受 StageDef + 回调）
├── providers/
│   └── mainline_providers.dart            # T35 新建
data/
├── stages.yaml                            # T33 schema 升级 + 6 关 backfill
docs/
├── NARRATIVE_SCHEMA.md                    # T38 新建（DeepSeek 看的格式约定）
└── screenshots/phase3_w1/                 # T39 归档
phase3_summary.md                          # T39 起头
```

---

## Week 1：主线最小闭环（T33-T39）

### T33 · stages.yaml schema 升级 + StageDef 扩字段

- **预估时长**：0.5 天
- **依赖任务**：Phase 2 完成
- **涉及文件**：`lib/data/defs/stage_def.dart`、`data/stages.yaml`、单测

**任务内容**：
1. `StageDef` 新增字段：
   - `String? prevStageId`（章节内顺序解锁；章节首关为 null）
   - `String? narrativeOpeningId`（开场剧情 id）
   - `String? narrativeVictoryId`（胜利剧情 id）
   - **保留** `narrativeId`（向后兼容，标 `@Deprecated`，Phase 5 整理时清）
2. `StageDef.fromYaml`：解析新 3 字段（可空）
3. `data/stages.yaml`：6 关 fixture backfill：
   - `mainline_test_01.prevStageId = null`（Ch1 首关）/ `02.prevStageId = mainline_test_01`
   - `mainline_test_03.prevStageId = null`（Ch2 首关）/ `04.prevStageId = mainline_test_03`
   - `mainline_test_05.prevStageId = null`（Ch3 首关）/ `06.prevStageId = mainline_test_05`
   - 6 关全填 `narrativeOpeningId: <stage_id>_opening` / `narrativeVictoryId: <stage_id>_victory`（DeepSeek 后续按此 id 出文案，缺文件 NarrativeLoader 兜底）
4. `GameRepository._enforceRedLines` 加校验：
   - 每关的 `prevStageId` 若非 null，必须能在 `stageDefs` 找到（fail-fast）
   - `prevStageId` 必须与本关同 `chapterIndex`（防跨章引用）

**验收标准**：
- [ ] 单测 ≥ 6 用例：3 字段 fromYaml 解析 / prevStageId 跨章校验抛错 / 引用不存在 stage 抛错 / 6 关 fixture 全部能解析 / 同章 prev 链可推 / null prev 表首关
- [ ] `flutter analyze` 0 issues
- [ ] 现有 `phase2_scenarios_test` / 战斗相关测试不破

**可能的坑**：
- `narrativeId` 字段标 `@Deprecated` 但仍要解析（向后兼容，否则 Phase 1 测试爆）
- yaml `prevStageId: null` 与字段缺失等价，写明 default
- 红线校验在 `GameRepository._enforceRedLines` 加段，不要塞到 fromYaml 里（关注点分离）

---

### T34 · MainlineProgressService + Isar MainlineProgress collection

- **预估时长**：1 天
- **依赖任务**：T33
- **涉及文件**：`lib/data/models/mainline_progress.dart`、`lib/services/mainline_progress_service.dart`、单测

**任务内容**：
1. `lib/data/models/mainline_progress.dart` 新建 `@collection`：
   - `Id id = Isar.autoIncrement`
   - `int saveDataId`（关联 SaveData，固定 1 也行 —— Phase 5 多存档再说）
   - `int currentChapterIndex`（默认 1）
   - `List<String> clearedStageIds`（已通关 stage id 列表，无序集合）
   - `List<DateTime> clearedAt`（与 clearedStageIds 同序，记录首通时间）
   - **不存** stage 难度/exp/loot —— 那些算战斗结算职责，progress 只管「通没通」
2. `lib/services/mainline_progress_service.dart` 新建：
   - `Future<MainlineProgress> getOrCreate({required int saveDataId})`：拿不到就建一行
   - `Future<List<StageDef>> availableStages({required MainlineProgress progress, required int chapterIndex})`：返回当前章节内所有「prevStageId 已通 或 null」的关卡（含已通+可挑+锁三状态由 UI 判，service 只返回章节全集 + cleared 集，让 UI 算）
     - **改良**：直接返回 `List<({StageDef def, StageStatus status})>`，service 一次算完，UI 不重算
   - `Future<void> recordVictory({required String stageId, required DateTime now})`：append 到 clearedStageIds + clearedAt（重复通关只首通时记录，重复无操作）
   - `bool chapterCompleted({required MainlineProgress progress, required int chapterIndex})`：该章所有 stage 都在 cleared 集
3. `enum StageStatus { locked, available, cleared }`（放 `lib/data/models/enums.dart` 或 service 文件内）
4. **writeTxn 一律走 `IsarSetup.instance.writeTxn(...)`**（Phase 1/2 约定）

**验收标准**：
- [ ] 单测 ≥ 10 用例（接真 Isar，参考 `phase2_seed_service_test`）：
  - getOrCreate 首次创建 / 二次复用 / availableStages 三状态分布（首关 available + 已通 cleared + 后续 locked）/ recordVictory 首通记录时间 / 重复通关不重复 append / chapterCompleted 全通 true / 部分通 false / 跨章不串
- [ ] `flutter analyze` 0 issues
- [ ] **不接 BattleResolutionService**（解耦：Phase 3 先靠 UI 调 recordVictory，T26 战斗结算 hook 接 mainline 留 Phase 4 一起处理）

**可能的坑**：
- `MainlineProgress.saveDataId` 不要建 unique index，多存档要支持多行（Phase 5）
- `clearedStageIds` 和 `clearedAt` 同序约定要写在 doc comment 里，否则 Phase 5 容易忘
- Isar 的 List<DateTime> 需要 `@collection` 自动序列化，不需要 embedded
- `availableStages` 返回 `({StageDef, StageStatus})` Record 用 Dart 3 record 语法，Phase 1/2 已用过，不用引新依赖

---

### T35 · 章节列表 + 关卡列表 UI + 接 main_menu

- **预估时长**：1.5 天
- **依赖任务**：T34
- **涉及文件**：`lib/ui/mainline/chapter_list_screen.dart`、`lib/ui/mainline/stage_list_screen.dart`、`lib/providers/mainline_providers.dart`、`lib/ui/main_menu.dart`（接入口）、`lib/ui/strings.dart`（标签）、widget test

**任务内容**：
1. `lib/providers/mainline_providers.dart`：
   - `mainlineProgressProvider`（FutureProvider）：调 `getOrCreate(saveDataId: 1)`
   - `chapterStagesProvider(int chapterIndex)`（FutureProvider.family）：调 `availableStages`
2. `chapter_list_screen.dart`：
   - 列出 3 章（Ch1 学武出山 / Ch2 武林初识 / Ch3 名扬江湖）章节卡
   - 章节状态：
     - 已完成 → 卡片右上「✓」（可重复进）
     - 进行中（currentChapter）→ 高亮边框
     - 未解锁（前章未完成）→ 灰色 + 「锁」图标
   - 点已解锁章节 → push StageListScreen
   - 章节名 + 简介走 `lib/ui/strings.dart`（不进 narratives/，那是关卡剧情；章节标题属 UI 标签）
3. `stage_list_screen.dart`：
   - 列出该章所有 stage，按 prevStageId 链推顺序
   - 每行状态：cleared 绿勾 / available 主色按钮 / locked 灰
   - 点 available stage → push StageEntryFlow（T37）
4. `main_menu.dart` 入口：
   - 新增「主线」按钮，push ChapterListScreen
   - **保留** Phase2TestMenu 调试入口（不删；T39 后再决定是否藏到 dev mode）

**验收标准**：
- [ ] widget test ≥ 6 用例（不接真 Isar，FakeProgress fixture）：
  - 章节卡 3 个 / 章节锁状态正确 / 点章节跳关卡列表 / 关卡三状态渲染 / 点 available 触发跳转 / 点 locked 不响应
- [ ] `flutter analyze` 0 issues
- [ ] 文案一律走 strings.dart，不在 widget 里写中文常量

**可能的坑**：
- mainline_providers 用 family provider，注意 invalidate 时 family key 要带（recordVictory 后 invalidate）
- 章节简介虽是 UI 标签，但语气接近剧情，建议先用占位「[章节简介待定]」放 strings.dart，正式简介 Phase 3 末期跟 DeepSeek 对齐
- ChapterListScreen / StageListScreen 共用 _ChapterCard 风格，可抽 helper 但 Phase 5 再抽（CLAUDE 全局：不做未要求的抽象）

---

### T36 · 主线剧情阅读 UI + NarrativeLoader

- **预估时长**：1 天
- **依赖任务**：T33（narrativeOpening/VictoryId 字段已加）
- **涉及文件**：`lib/data/narrative_loader.dart`、`lib/ui/narrative/narrative_reader_screen.dart`、widget test

**任务内容**：
1. `lib/data/narrative_loader.dart`：
   - `Future<NarrativeContent> load(String narrativeId)`：从 `data/narratives/<narrativeId>.yaml` 读
   - **缺文件 / 解析失败兜底**：返回 `NarrativeContent.placeholder(narrativeId)`，单段「[剧情待补：$narrativeId]」
   - 不抛异常（区别于 GameRepository 的 fail-fast：那是数值/配置层；narratives 是文案层，DeepSeek 异步补，运行期不能挂）
   - `NarrativeContent` 数据结构：
     - `String id`
     - `String? title`（标题，可空）
     - `List<String> paragraphs`（段落数组，按 yaml 顺序）
     - `bool isPlaceholder`（兜底标记，UI 可显示弱提示）
2. `narrative_reader_screen.dart`：
   - 顶部 title（缺则 stage name 兜底）
   - 中部段落滚动列表，淡入动画
   - 底部按钮：「继续」（push 下一段或 finish）/ 跳过（直接 finish）
   - 接受 `onFinish: VoidCallback` 回调（T37 用）
3. yaml schema（写在 NarrativeContent doc comment + T38 docs/NARRATIVE_SCHEMA.md）：
   ```yaml
   id: mainline_test_01_opening   # 与 stages.yaml narrativeOpeningId 一致
   title: 山道试剑                 # 可空
   paragraphs:
     - 山雾未散，你立于青石之上……
     - 三道身影自林中涌出。
   ```

**验收标准**：
- [ ] 单测 ≥ 6 用例（NarrativeLoader 纯函数）：
  - 正常 yaml 解析 / title 缺省 / paragraphs 空数组 / 文件不存在兜底 placeholder / yaml 损坏兜底 placeholder / placeholder.isPlaceholder == true
- [ ] widget test ≥ 3 用例：
  - 多段渲染 / placeholder 渲染弱提示 / onFinish 回调触发
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- `rootBundle.loadString` 在 asset 不存在时抛 FlutterError 而非 FileNotFoundException，catch 要写宽泛
- `pubspec.yaml` assets 段已声明 `data/` 全目录（Phase 1 确认）—— 新增 narratives/* yaml 不需要再声明
- placeholder 文本用 strings.dart 模板：`UiStrings.narrativePlaceholder(narrativeId)`，不要在 NarrativeContent 里硬编码

---

### T37 · 关卡进入流程串联

- **预估时长**：1 天
- **依赖任务**：T35 + T36
- **涉及文件**：`lib/ui/mainline/stage_entry_flow.dart`、`lib/ui/battle/battle_screen.dart`（参数化）、widget test

**任务内容**：
1. `stage_entry_flow.dart`：状态机
   - 入参：`StageDef stage`
   - 阶段 1：`narrativeOpeningId` 非空 → push NarrativeReaderScreen → onFinish 进阶段 2；为空跳过
   - 阶段 2：push BattleScreen（传 stage.enemyTeam + onVictory/onDefeat 回调）
   - 阶段 3a（onVictory）：调 `MainlineProgressService.recordVictory(stage.id)` → invalidate `mainlineProgressProvider` → `narrativeVictoryId` 非空 push NarrativeReaderScreen → onFinish pop 回 StageListScreen
   - 阶段 3b（onDefeat）：直接 pop 回 StageListScreen（不记录、不掉装备 —— Phase 4 再加战败结算）
2. `battle_screen.dart` 参数化：
   - 接 `StageDef? stage`（Phase 2 fixture 调试入口仍可不传）
   - 接 `VoidCallback? onVictory` / `VoidCallback? onDefeat`
   - 战斗结束（result 翻转）→ 调对应回调 + 不自动 pop（让 StageEntryFlow 接管 pop）
3. **关键：BattleScreen 既有调用方（Phase2TestMenu）保持不变**，新参数全可空 + 默认行为兼容

**验收标准**：
- [ ] widget test ≥ 5 用例：
  - 完整流程：opening → 战斗（mock 立即胜利）→ victory → recordVictory 被调 1 次 → pop
  - 无 opening 跳过到战斗
  - 无 victory 战斗胜后直接 pop
  - 战败：不调 recordVictory + pop
  - BattleScreen 既有调用（无 stage 参数）行为不破
- [ ] `flutter analyze` 0 issues
- [ ] 现有 battle_screen 相关 widget test 不破

**可能的坑**：
- BattleScreen 当前内部可能直接 Navigator.pop —— 改前先 grep 一遍，重构成只调回调
- recordVictory 是 async writeTxn，UI 不要 await 阻塞动画，用 unawaited + try/catch + 失败弹 SnackBar（不影响 pop）
- Phase 2 BattleResolutionService 已经在战斗结算 writeTxn 一次（battleCount++ / cultivation），mainline 进度走单独 writeTxn，**两次 txn 不嵌套**

---

### T38 · docs/NARRATIVE_SCHEMA.md（DeepSeek 格式约定）

- **预估时长**：0.5 天
- **依赖任务**：T36
- **涉及文件**：`docs/NARRATIVE_SCHEMA.md`、`PROGRESS.md`（指向 schema 文档）

**任务内容**：
1. `docs/NARRATIVE_SCHEMA.md` 新建：
   - 文件命名约定：`data/narratives/<stage_id>_opening.yaml` / `<stage_id>_victory.yaml`
   - id 字段必须等于文件名（不含 .yaml 后缀），与 stages.yaml `narrativeOpeningId` / `narrativeVictoryId` 严格一致
   - schema：id / title / paragraphs（List<String>）
   - 占位 fallback 行为：缺文件 → UI 显示「[剧情待补：<id>]」，不抛错
   - 字数建议：每段 60-200 字，总段数 3-8 段（避免单页太长）
   - 数据 ↔ 文案隔离原则：StageDef 数值在 stages.yaml；剧情文本在 narratives/，**两侧不互相读对方字段**
2. PROGRESS.md 在「关键约束」段加一行链接 NARRATIVE_SCHEMA.md

**验收标准**：
- [ ] 文档可读，DeepSeek 端拿这一份就能开工写主线第 1 章 6 关 12 段（开/胜各 6）
- [ ] schema 与 NarrativeContent / NarrativeLoader 字段一一对应
- [ ] 不动 GDD.md / CLAUDE.md / data_schema.md（这些是上层规范，新 schema 落 docs/ 即可）

**可能的坑**：
- 文档不要重复 GDD §8.1 已有的「数值 ↔ 文案 id 联结」原则，引用即可
- 写完后让 Pen 端 DeepSeek 视角试读一遍可读性（T39 验收时可附）

---

### T39 · Pen 视觉验收 + 截图归档 + tag v0.3.0-w1

- **预估时长**：0.5 天
- **依赖任务**：T33-T38 全完
- **涉及文件**：`docs/screenshots/phase3_w1/`、`phase3_summary.md`（起头）、`PROGRESS.md`

**任务内容**：
1. Mac 端预演：
   - `flutter test` 全绿（预期 ≥360 测试）
   - `flutter analyze` 0 issues
2. 派 Pen 端拉最新代码 + flutter run -d windows 走完一遍主流程：
   - 主菜单 → 主线 → Ch1 → mainline_test_01 → opening 占位「[剧情待补：mainline_test_01_opening]」 → 战斗（赢） → victory 占位 → 回关卡列表 → 02 已解锁 ✓
3. 截图归档（5-6 张）到 `docs/screenshots/phase3_w1/`：
   - 章节列表（3 章状态）
   - 关卡列表（首关 available + 后续 locked）
   - 剧情阅读 placeholder 页
   - 战斗中
   - 战斗胜利后关卡列表（首关 cleared + 02 解锁）
4. 起 `phase3_summary.md`：
   - Week 1 交付摘要
   - 6 截图 markdown 链接
   - Week 2 切入议题（爬塔 / 闭关 / 奇遇 / 师徒 / 武学领悟 哪个先）
5. PROGRESS.md 销账 Week 1
6. 主分支合并：feat/phase3-mainline → main no-ff
7. tag `v0.3.0-w1`，push origin

**验收标准**：
- [ ] 5-6 截图归档到 docs/screenshots/phase3_w1/
- [ ] phase3_summary.md 起头，含 Week 2 议题
- [ ] PROGRESS.md 已销账 Week 1
- [ ] tag v0.3.0-w1 已 push
- [ ] Pen 验收无大 bug（小 bug 进 PROGRESS 挂账，不阻塞 tag）

**可能的坑**：
- Pen 端拉完新代码必须 stop 旧 flutter run + 全量重启（Phase 2 #24 fixup 已踩过 hot reload 不刷新结构变化的坑，参考 PHASE3_KICKOFF.md）
- v0.3.0-w1 不是完整 Phase 3 交付，只是 Week 1 里程碑；正式 v0.3.0-phase3 留 Week 3 末

---

## Week 2：爬塔 30 层（T40-T46）

> **目标**：在 Week 1 主线最小闭环基础上，加一个**与主线完全解耦**的爬塔系统。30 层结构（3 小 Boss [5/15/25] + 3 大 Boss [10/20/30] + 24 普通层），每 5 层升一阶（学徒 → 三流 → 二流 → 一流 → 绝顶 → 宗师，武圣留 Phase 4 飞升），玩家可无限重试，永久记录最高通关层。
>
> **切法**：A 爬塔（kickoff §四之 A 候选），与 §12 待决项零依赖；沿用 Week 1 节奏（schema → service → UI → 串联 → 验收）。

### 0.6 Week 2 已拍板的 minor 决策（2026-05-11）

| 决策项 | 决议 | 依据 |
|---|---|---|
| 30 层境界曲线 | 每 5 层升一阶，1-5 学徒 / 6-10 三流 / 11-15 二流 / 16-20 一流 / 21-25 绝顶 / 26-30 宗师；Boss 层在该阶巅峰 + HP/攻 ×1.5 | GDD §3 7 阶节奏；武圣留 Phase 4 飞升 |
| 失败惩罚 | 不退层，保留最高记录，无限重试 | 与主线 onDefeat 行为一致；GDD §5.1 反主流"不做留存焦虑" |
| 奖励池 | 复用现有 equipment.yaml + materials，按层数推荐阶位 | 不增 Demo 内容量；GDD §7 装备 30-50 件总配额已含 |
| 重置/赛季 | 不做重置、无赛季、永久记录最高层 | Demo 阶段；GDD §12 也未列 |
| 重打已通层是否发奖 | **不发奖**（recordClear service 端返回 isFirstClear，UI 端只对 true 发奖） | CLAUDE §5.1 反主流 + §5.5 在线=离线，防刷 |

### 0.7 Week 2 任务依赖图

```
Week 1 完成线（v0.3.0-w1）
                  │
                  ▼
         T40 towers.yaml schema
         + TowerFloorDef + 30 层 fixture
                  │
                  ▼
         T41 TowerProgressService
         + Isar TowerProgress collection
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
       T42       T43       T44
   爬塔列表 UI  进入流程串联  奖励 hook
        │         │         │
        └─────┬───┴────┬────┘
              ▼        ▼
            T45 单测 + analyze
              │
              ▼
         T46 Pen 验收 + tag v0.3.0-w2
```

### 0.8 目录结构（在 Week 1 基础上扩）

```
lib/
├── data/
│   ├── defs/
│   │   └── tower_floor_def.dart         # T40 新建
│   └── models/
│       ├── tower_progress.dart           # T41 新建（@collection）
│       └── tower_progress.g.dart         # T41 build_runner 生成
├── services/
│   └── tower_progress_service.dart      # T41 新建
├── ui/
│   └── tower/                            # T42/T43 新建
│       ├── tower_floor_list_screen.dart # T42
│       ├── tower_floor_card.dart        # T42（三态 + Boss 视觉）
│       └── tower_entry_flow.dart        # T43
├── providers/
│   └── tower_providers.dart              # T42 新建
data/
└── towers.yaml                           # T40 新建（30 层 fixture）
docs/screenshots/phase3_w2/               # T46 归档
phase3_summary.md                         # T46 追加 Week 2 段
```

---

### T40 · towers.yaml schema + TowerFloorDef + 30 层 fixture

- **预估时长**：0.5 天
- **依赖任务**：Week 1 v0.3.0-w1 已交付
- **涉及文件**：`lib/data/defs/tower_floor_def.dart`、`data/towers.yaml`、`lib/data/game_repository.dart`（红线校验扩展）、`lib/data/models/enums.dart`（加 TowerBossKind）、单测

**任务内容**：

1. `lib/data/defs/tower_floor_def.dart` 新建：
   - `int floorIndex`（1-30，唯一）
   - `RealmTier requiredRealm`（推荐境界，UI 提示用，**不做硬挡**——挑战自由，难度自然惩罚）
   - `List<EnemyDef> enemyTeam`（复用 Phase 1 EnemyDef）
   - `TowerBossKind? bossKind`（enum: minor / major / null）
   - `String? narrativeOpeningId` / `String? narrativeVictoryId`（**仅 Boss 层**可有，普通层必须 null）
   - `List<DropEntry> dropTable`（复用 Phase 2 DropEntry sealed class）

2. `enum TowerBossKind { minor, major }` 加 `lib/data/models/enums.dart` + `enum_localizations.dart` 中文映射

3. `data/towers.yaml`：30 层 fixture
   - 境界曲线（5 层一阶）：1-5 学徒 / 6-10 三流 / 11-15 二流 / 16-20 一流 / 21-25 绝顶 / 26-30 宗师
   - Boss 节点：5/15/25 minor + 10/20/30 major（共 6 Boss）
   - 敌人 HP：普通层从 800 → 12000 线性插值；Boss 层在该阶巅峰 ×1.5（不破 §5.4 玩家血 20000 / Boss 50000+ 红线）
   - 敌人攻击：守 §5.2 普伤 ≤8000；普通层 200 → 2500；Boss 层 ×1.5
   - 敌人数量：1-10 层 1 人 / 11-20 层 2 人 / 21-30 层 3 人；Boss 层固定 1 人但 HP/攻拉满
   - 奖励：每 5 层一阶段奖励池（参考 equipment.yaml 阶位），Boss 层保底掉对应阶装备一件

4. `GameRepository._enforceRedLines` 扩展：
   - 30 层 floorIndex 唯一性 + 1-30 连续
   - Boss 分布严格在 5/10/15/20/25/30（其他层 bossKind 必须 null）
   - 普通层 narrativeOpeningId/VictoryId 必须为 null（Boss 层可有可无）
   - 数值红线复用 §5.4（普伤 ≤8000、Boss 血 ≤50000）

**验收标准**：
- [ ] 单测 ≥ 8 用例：fromYaml 解析 / 30 层全部加载 / Boss 分布校验 fail-fast / 数值红线 fail-fast / 境界曲线断言 / 普通层 narrative 为 null 校验 / floorIndex 连续性 / 1-30 唯一性
- [ ] `flutter analyze` 0 issues
- [ ] 现有测试不破

**可能的坑**：
- TowerFloorDef **不要继承 StageDef** 或共享父类——爬塔与主线两套模型，让 schema 演化解耦
- `narrativeOpeningId` 在 Boss 层可空（Demo 早期 DeepSeek 还没补）；缺文件 NarrativeLoader 已兜底
- 30 层数值表手工填易出错，建议写个 Dart 脚本算曲线再 dump yaml 到 `tools/`，**脚本不进 lib/**

---

### T41 · TowerProgress @collection + TowerProgressService

- **预估时长**：1 天
- **依赖任务**：T40
- **涉及文件**：`lib/data/models/tower_progress.dart`、`lib/services/tower_progress_service.dart`、`lib/data/isar_setup.dart`（schema 注册 + saveVersion 推进）、单测

**任务内容**：

1. `lib/data/models/tower_progress.dart` 新建 `@collection`：
   - `Id id = Isar.autoIncrement`
   - `int saveDataId`（关联 SaveData，固定 1）
   - `int highestClearedFloor`（默认 0，1-30）
   - `DateTime? highestClearedAt`
   - `int totalAttempts`（累计尝试次数，含失败）
   - `int totalDefeats`（累计失败次数）
   - `DateTime createdAt`
   - **不存** 每层个体记录、不存 run-by-run 详情——Demo 阶段只关心"最高层 + 总览统计"

2. `lib/services/tower_progress_service.dart` 新建：
   - `Future<TowerProgress> getOrCreate({required int saveDataId})`：拿不到就建
   - `int availableFloor(TowerProgress progress)`：返回 `highestClearedFloor + 1`（封顶 30）
   - `Future<List<({TowerFloorDef def, TowerFloorStatus status})>> floorList({required TowerProgress progress, required List<TowerFloorDef> allFloors})`：30 行三态
   - `Future<bool> recordClear({required int floorIndex, required DateTime now})`：仅当 `floorIndex == highestClearedFloor + 1` 时更新 highest + clearedAt 并返回 `true`（首通）；重打返回 `false`；totalAttempts++ 永远执行
   - `Future<void> recordDefeat({required DateTime now})`：totalAttempts++ + totalDefeats++（不影响 highestClearedFloor）
   - `bool canChallenge({required TowerProgress progress, required int floorIndex})`：`floorIndex <= highestClearedFloor + 1`

3. `enum TowerFloorStatus { locked, available, cleared }`（放 `lib/data/models/enums.dart`）

4. `IsarSetup.schemas` 加 TowerProgressSchema；`saveVersion` 0.2.0 → 0.3.0

5. writeTxn 一律走 `IsarSetup.instance.writeTxn(...)`

**验收标准**：
- [ ] 单测 ≥ 10 用例（接真 Isar，参考 `mainline_progress_service_test`）：
  - getOrCreate 首次/二次 / availableFloor 三状态 / recordClear 首通返回 true 更新 highest / 重打返回 false / 跳层挑战非法（虽然 service 不强校验，UI 端 canChallenge 拦截）/ recordDefeat 不影响 highest / floorList 30 行三态分布 / canChallenge 边界（highest+1 可挑、highest+2 不可）
- [ ] `flutter analyze` 0 issues
- [ ] 与 MainlineProgressService 完全独立（不互相 import）

**可能的坑**：
- highestClearedFloor 用 int 不用 List<bool>——单调递增便于推理
- recordClear 用 set 而非 ++，防止状态机错乱
- saveVersion 推进 0.2.0 → 0.3.0 写迁移注释占位（Demo 不写真迁移）；Phase 5 多存档/迁移时统一收

---

### T42 · 爬塔层列表 UI + 进度展示 + main_menu 入口

- **预估时长**：1 天
- **依赖任务**：T41
- **涉及文件**：`lib/ui/tower/tower_floor_list_screen.dart`、`lib/ui/tower/tower_floor_card.dart`、`lib/providers/tower_providers.dart`、`lib/ui/main_menu.dart`、`lib/ui/strings.dart`、widget test

**任务内容**：

1. `lib/providers/tower_providers.dart`：
   - `towerProgressProvider`（FutureProvider）：调 `getOrCreate(saveDataId: 1)`
   - `towerFloorListProvider`（FutureProvider）：调 `floorList(progress, allFloors)`

2. `tower_floor_list_screen.dart`：
   - AppBar 标题「问鼎九霄」（走 strings.dart）
   - 顶部进度卡：`已通 X/30 层` + `总尝试 N 次` + `失败 M 次`
   - 主体：30 行垂直列表（ListView.builder），每行用 TowerFloorCard
   - 首次进入自动滚动到 `highestClearedFloor + 1`（initState 一次性，不循环 setState）

3. `tower_floor_card.dart`：
   - 普通层 cleared：✓ 绿勾 + 灰底
   - 普通层 available：主色按钮 + 「挑战」chip
   - 普通层 locked：灰 + 锁图标 + 「通关前一层解锁」
   - Boss 层（minor/major）：金/紫色边框（outline，避免与 cleared 灰底冲突）+ 「小 Boss / 大 Boss」标签 + 推荐境界 chip
   - 点 available → push TowerEntryFlow（T43）
   - 点 cleared → 弹 AlertDialog「已通关，是否重打？（重打不发奖）」二确

4. `main_menu.dart`：
   - 加「问鼎九霄」按钮，位置主线下方（第二位）
   - 按钮副标题：「30 层，无限重试，永久记录」
   - 按钮顺序：主线 → 问鼎九霄 → Phase1 调试 → Phase2 调试 → 角色 → 装备 → 心法（7 按钮，SingleChildScrollView 已在 Week 1 T35 加好）

5. `lib/ui/strings.dart` 加爬塔相关 UI 标签

**验收标准**：
- [ ] widget test ≥ 6 用例（不接真 Isar，FakeProgress fixture）：
  - 30 行渲染 / 三态分布渲染 / Boss 层视觉差异（边框颜色）/ 点 available 跳转 TowerEntryFlow / 点 locked 不响应 / 点 cleared 弹重打确认 dialog
- [ ] `flutter analyze` 0 issues
- [ ] 文案全走 strings.dart
- [ ] main_menu 7 按钮顺序与上述一致

**可能的坑**：
- 30 行长列表性能：用 ListView.builder + 不 inline 一次性 build 30 widget
- 自动滚动到 highest+1 在首次进入触发即可
- Boss 层视觉强化用 outline color 而非 background

---

### T43 · 爬塔进入流程串联（tower_entry_flow.dart）

- **预估时长**：1 天
- **依赖任务**：T42
- **涉及文件**：`lib/ui/tower/tower_entry_flow.dart`、`lib/services/stage_battle_setup.dart`（小重构抽公共函数）、widget test

**任务内容**：

1. `tower_entry_flow.dart`：状态机（参考 Week 1 stage_entry_flow.dart）
   - 入参：`TowerFloorDef floor`
   - 阶段 1：Boss 层（`bossKind != null`）且 `narrativeOpeningId` 非空 → push NarrativeReaderScreen → onFinish 进阶段 2；普通层直接跳到阶段 2
   - 阶段 2：用 StageBattleSetup 装配 BattleCharacter；push BattleScreen（onVictory/onDefeat 回调）
   - 阶段 3a（onVictory）：
     - 调 `TowerProgressService.recordClear(floorIndex)` → 拿 `isFirstClear` → invalidate `towerProgressProvider`
     - 调 `DropService.rollTowerRewards`（**仅 isFirstClear == true 时**，T44 接入）
     - Boss 层 + narrativeVictoryId 非空 → push NarrativeReaderScreen → onFinish pop 回 TowerFloorListScreen
     - 普通层或无 victory narrative → 直接 pop
   - 阶段 3b（onDefeat）：调 `recordDefeat` → 直接 pop 回 TowerFloorListScreen（不掉装备、不退层）

2. **BattleScreen 不动**：Week 1 T37 已参数化（onVictory/onDefeat），复用现有 API

3. **左队装配**：从 `SaveData.activeCharacterIds` 取角色 + 装备 + 主修（与主线一致；挂账 #25 P1 fixture 缺主修问题在爬塔同样适用，Phase 4 一起修）

4. `stage_battle_setup.dart` 小重构：抽 `_buildEnemyTeam(List<EnemyDef>)` 公共函数（StageDef 与 TowerFloorDef 共用敌人装配逻辑）

**验收标准**：
- [ ] widget test ≥ 5 用例：
  - 普通层流程：无 opening → 战斗（mock 胜）→ recordClear → pop
  - Boss 层流程：opening → 战斗（mock 胜）→ victory → recordClear → pop
  - 战败：recordDefeat 被调，recordClear 不调，pop
  - Boss 层无 narrative：placeholder 兜底（Week 1 T36 NarrativeLoader 已验证）
  - 重打已通层：recordClear 返回 false，奖励不发（验证 isFirstClear 分支）
- [ ] `flutter analyze` 0 issues
- [ ] Week 1 stage_entry_flow.dart 测试不破

**可能的坑**：
- `_buildEnemyTeam` 抽公共函数注意 StageDef 与 TowerFloorDef enemyTeam 字段名一致
- recordDefeat / recordClear 是 async writeTxn，UI 不要 await 阻塞动画——unawaited + try/catch + 失败弹 SnackBar
- 两次 writeTxn（TowerProgress + Inventory）**不嵌套**，与 Phase 2 BattleResolutionService 模式一致

---

### T44 · 爬塔奖励 hook（扩展 DropService）

- **预估时长**：0.5 天
- **依赖任务**：T43
- **涉及文件**：`lib/services/drop_service.dart`（扩展）、`lib/ui/tower/tower_entry_flow.dart`（接入）、单测

**任务内容**：

1. 扩展 `DropService`（**不新建 service**，守 CLAUDE 全局「不做未要求的抽象」）：
   - `List<DropEntry> rollTowerRewards(TowerFloorDef floor, Rng rng)`：与 `rollDrops`（Phase 2 T27）同接口，从 floor.dropTable 抽
   - Boss 层 dropTable 概率拉满（保底掉一件该阶装备）

2. 在 `tower_entry_flow.dart` 阶段 3a 接入：
   - recordClear 返回 isFirstClear == true → rollTowerRewards → 走现有 inventory writeTxn 入库
   - 战胜界面 dialog 显示掉落清单（复用 Phase 2 战斗结算 dialog 模板）
   - isFirstClear == false → 不发奖，dialog 仍显示「已重打通关」但奖励区显示「重打不发奖」

3. **不引入新道具**：所有奖励项必须在 equipment.yaml / materials yaml 已有 id 池内

**验收标准**：
- [ ] 单测 ≥ 4 用例：普通层抽奖 / Boss 层保底掉该阶装备 / 重打不发奖（isFirstClear == false 路径）/ dropTable 空时返回空列表
- [ ] 战斗胜利 dialog 渲染奖励清单 + 重打区分提示
- [ ] `flutter analyze` 0 issues

**可能的坑**：
- recordClear 返回 bool 是 service 端契约，UI 端必须拿这个 bool 决定奖励发放——别在 UI 端重算"是否首通"
- 奖励 inventory writeTxn 与 TowerProgress writeTxn 是**两次**（不嵌套）

---

### T45 · 单测/widget test 全绿 + analyze

- **预估时长**：0.5 天
- **依赖任务**：T40-T44
- **涉及文件**：所有上述 test 文件

**任务内容**：
1. `flutter test` 全绿，预期累计 ≥ 410（Week 1 末 377 + Week 2 约 33+）
2. `flutter analyze` 0 issues
3. 新代码覆盖率不强制指标，但每个 service public API 至少 1 用例

**验收标准**：
- [ ] 测试数 ≥ 410
- [ ] analyze 0 issues
- [ ] Pen 端 SSH 跑一遍验证 Windows 端也绿（Mac 端 analyze + test 双绿后再派 Pen）

---

### T46 · Pen 视觉验收 + 截图归档 + tag v0.3.0-w2

- **预估时长**：0.5 天
- **依赖任务**：T45
- **涉及文件**：`docs/screenshots/phase3_w2/`、`phase3_summary.md`（追加 Week 2 段）、`PROGRESS.md`

**任务内容**：

1. Mac 端预演：test + analyze 双绿
2. 派 Pen 端拉最新代码 + flutter run -d windows 走完一遍爬塔流程：
   - 主菜单 → 问鼎九霄 → 1 层挑战（普通层）→ 战斗胜 → 奖励 dialog → 回列表 02 解锁
   - 跳到 5 层（小 Boss）：opening 占位 → 战斗 → victory 占位 → 奖励
   - 跳到 10 层（大 Boss）：同上 + 大 Boss 视觉验证
   - 战败一次验证 recordDefeat + 不退层
   - 重打 1 层验证「重打不发奖」提示
3. 截图归档（6-8 张）到 `docs/screenshots/phase3_w2/`：
   - 01 主菜单加问鼎九霄按钮（7 按钮顺序）
   - 02 爬塔列表（顶部进度卡 + 30 行三态 + Boss 边框）
   - 03 普通层战斗
   - 04 小 Boss opening 占位
   - 05 大 Boss 战斗中
   - 06 战斗胜利 + 奖励 dialog（首通）
   - 07 重打通关 dialog（无奖励）
   - 08 战败 SnackBar
4. `phase3_summary.md` 追加 Week 2 段：
   - 交付清单（T40-T46）
   - 累计测试数（377 → 410+）
   - 8 截图链接
   - Week 3 议题（B 闭关 / C 奇遇 / D 师徒 / E 武学领悟 哪个先；§12 待决项先决）
5. PROGRESS.md 销账 Week 2
6. 主分支合并：feat/phase3-tower → main no-ff
7. tag `v0.3.0-w2`，push origin

**验收标准**：
- [ ] 6-8 截图归档
- [ ] phase3_summary.md Week 2 段追加完
- [ ] PROGRESS.md 已销账 Week 2
- [ ] tag v0.3.0-w2 已 push
- [ ] Pen 验收无大 bug（小 bug 挂账 PROGRESS）

**可能的坑**：
- 同 Week 1 T39：Pen 端拉新代码必须 stop 旧 flutter run + 全量重启（hot reload 不刷新 Isar schema）
- v0.3.0-w2 不是 Phase 3 完整交付，正式 v0.3.0-phase3 留 Week 3 末

---

## Week 3：闭关地图（B 方向，2026-05-11 确认）

> 方向决策：B 闭关地图。§12 #5 产出公式决议：×1.3/tier 境界缩放，72h 上限封顶，
> mojianshi 整数掉落 + 装备按地图 dropRate 单次抽检。

### T47 · SeclusionMapDef + numbers.yaml 补字段 + GameRepository 加载

- **预估时长**：0.5 天
- **依赖任务**：无（独立可并行）
- **涉及文件**：`data/numbers.yaml`（补 2 字段）、`lib/data/defs/seclusion_map_def.dart`（新建）、`lib/data/numbers_config.dart`（加 `RetreatConfig`）、`lib/data/game_repository.dart`（加 `seclusionMaps` 字段 + 红线）、`test/seclusion_map_def_test.dart`（新建）

**任务内容**：

1. **numbers.yaml 补字段**（`retreat` 段末追加）：
   ```yaml
   realm_scale_per_tier: 1.3   # 每升一大阶，产出倍率 ×1.3
   cap_hours: 72               # 离线结算封顶（小时）
   ```

2. **`SeclusionMapDef`**（`lib/data/defs/seclusion_map_def.dart`）：
   ```dart
   class SeclusionMapDef {
     final RetreatMapType mapType;
     final String mapName;
     final RealmTier requiredRealm;
     final double experiencePerHour;
     final double mojianshiPerHour;
     final double equipmentDropRate;   // 1.0 = 基础，1.5 = +50%
     final double techniqueLearnRate;
     final double internalForceGrowth;
     // fromYaml 工厂
   }
   ```

3. **`NumbersConfig` 加 `RetreatConfig`**（仿 `EnhancementConfig` 模式）：
   ```dart
   class RetreatConfig {
     final List<SeclusionMapDef> maps;  // 5 张
     final List<int> durationHours;    // [1, 4, 12]
     final double realmScalePerTier;   // 1.3
     final int capHours;               // 72
     // fromYaml; realmScaleFor(RealmTier) → 1.3^tierIndex
   }
   ```
   `NumbersConfig` 新增 `final RetreatConfig retreat`，`fromYaml` 解析 `y['retreat']`。

4. **`GameRepository`**：
   - 新增 `final List<SeclusionMapDef> seclusionMaps`
   - 加载：`_config.retreat.maps`
   - `SeclusionMapDef getSeclusionMap(RetreatMapType)` 便捷查询
   - `_enforceRetreatRedLines()`：5 张地图类型唯一 / 每张 `requiredRealm` 在已知 enum 内 / `mojianshiPerHour > 0` / `capHours ∈ [1, 168]`

**验收标准**：
- [x] 单测 ≥ 10：5 张地图 fromYaml 读回 / requiredRealm 顺序（shanLin 最低=学徒，duanYaJueBi 最高=宗师）/ realmScaleFor(xueTu)=1.0 / realmScaleFor(zongShi)≈3.71 / 红线 fail-fast 4 用例（实际 17 用例）
- [x] `flutter analyze` 0 issues（437/437）

**可能的坑**：
- `RealmTier` 索引顺序（xueTu=0, sanLiu=1, erLiu=2, yiLiu=3, jueDing=4, zongShi=5, wuSheng=6），`realmScaleFor` 用 `tier.index` 乘幂，不要硬编码 7 个 case
- numbers.yaml `map_type` 值是 camelCase（`shanLin`），与 enum name 一致，直接 `byName` 即可

---

### T48 · RetreatSession @collection + SeclusionService

- **预估时长**：1 天
- **依赖任务**：T47
- **涉及文件**：`lib/data/models/enums.dart`（加 `RetreatStatus`）、`lib/data/models/retreat_session.dart`（新建 + codegen）、`lib/data/isar_setup.dart`（加 schema + 升 saveVersion）、`lib/services/seclusion_service.dart`（新建）、`test/seclusion_service_test.dart`（新建）

**任务内容**：

1. **`enum RetreatStatus { active, completed, abandoned }`** → 加到 `enums.dart`

2. **`@collection RetreatSession`**（`lib/data/models/retreat_session.dart`）：
   ```dart
   @collection
   class RetreatSession {
     Id id = Isar.autoIncrement;
     int saveDataId = 0;
     @enumerated late RetreatMapType mapType;
     int durationHours = 0;        // 计划时长（1/4/12）
     late DateTime startedAt;
     DateTime? completedAt;        // null = 进行中或已放弃
     @enumerated RetreatStatus status = RetreatStatus.active;
     List<RewardEntry> actualRewards = [];   // 收功时填入
   }
   ```
   运行 `flutter pub run build_runner build --delete-conflicting-outputs` 生成 `.g.dart`。

3. **`IsarSetup`**：加 `RetreatSessionSchema` → `_allSchemas`；saveVersion 0.3.0 → 0.4.0。

4. **`SeclusionService`**（`lib/services/seclusion_service.dart`）：
   ```dart
   class SeclusionService {
     // startRetreat({mapType, durationHours, saveDataId, now}) → RetreatSession
     //   校验：canEnterMap(mapType, charRealm) → bool（境界锁）
     //   已有 active session 则先调 abandonRetreat
     //   写 Character.currentRetreatSessionId = session.id
     //
     // getActiveSession(saveDataId) → RetreatSession?
     //
     // computeOutputs({session, charRealm, now, realmScale}) → RetreatOutputs
     //   actualHours = min(elapsed, session.durationHours, capHours)
     //   mojianshi = (mojianshiPerHour × actualHours × realmScale × dayBonus).floor()
     //   equipDropRolls = 1（per session，不按小时重复）
     //
     // completeRetreat({session, charRealm, rng, now}) → RetreatOutputs
     //   写 completedAt / status=completed / actualRewards
     //   清 Character.currentRetreatSessionId = null
     //
     // abandonRetreat(session) → void
     //   只写 status=abandoned，不发奖
   }
   ```

   **`RetreatOutputs`** typedef / class（可用 record 类型）：
   ```dart
   typedef RetreatOutputs = ({
     double actualHours,
     int mojianshi,
     List<DropEntry> equipmentDrops,   // 从 DropService 取
     int experiencePoints,
   });
   ```

   **时辰加成**（`TimeOfDayPeriod`）：`startedAt` 时刻决定，不动态切换。
   子时(23:00-01:00) → `internalForceGrowth × 1.2`；正午(11:00-13:00) → 仅刚猛流派 technique learn rate × 1.2；其他 → ×1.0。
   Demo 阶段 mojianshi / experience 不受时辰影响（复杂度留 Phase 5）。

**验收标准**：
- [x] 单测 ≥ 15（接真 Isar 临时目录）：startRetreat 创建 session / getActive 幂等 / 72h 封顶 / 境界锁（sanLiu 进不了 duanYaJueBi）/ computeOutputs 3 用例（0h/1h/超72h）/ completeRetreat 写库 / abandon 不发奖 / 与 TowerProgress / MainlineProgress 独立（各自 saveDataId 无交叉）（实际 17 用例）
- [x] saveVersion 0.4.0 写入 _currentSaveVersion（454/454）
- [x] `flutter analyze` 0 issues

**可能的坑**：
- `RetreatSession` 的 `@enumerated` 修饰对 Isar 存 enum 是必须的（与 TowerFloorDef 里 bossKind 同理）
- 写 `Character.currentRetreatSessionId` 需要在同一 writeTxn 或确保顺序，别两次独立 txn 导致不一致
- `DropService.rollDrops` 已有，直接传 `dropTable` 即可；不要在 SeclusionService 里重实现抽奖逻辑

---

### T49 · 闭关地图列表 UI + 进入流程 + main_menu 入口

- **预估时长**：1 天
- **依赖任务**：T48
- **涉及文件**：`lib/ui/seclusion/`（新建目录）：`seclusion_map_list_screen.dart` / `seclusion_setup_screen.dart` / `active_retreat_screen.dart`；`lib/ui/main_menu.dart`（加入口）；`lib/ui/strings.dart`（加字符串常量）；widget tests

**任务内容**：

1. **`SeclusionMapListScreen`**：
   - 5 张地图卡片列表，每张显示：地图名 / 特色产出描述 / 解锁境界
   - 三态：locked（灰色 + 境界要求）/ available（可进入）/ active（进行中，显示剩余时间倒计时）
   - 顶部 `_ActiveBanner`：有活跃 session 时显示地图名 + 剩余时间 +「收功」按钮

2. **`SeclusionSetupScreen`**（从 available 卡片 onTap 进入）：
   - 显示地图详情（5 项产出基础值 × 境界缩放 = 预估产出）
   - 三档时长按钮（1h / 4h / 12h）+ 时辰加成提示（当前时辰是否有 bonus）
   - 「开始闭关」确认按钮 → `SeclusionService.startRetreat` → push `ActiveRetreatScreen`

3. **`ActiveRetreatScreen`**：
   - 显示地图名 + 开始时间 + 预计结束时间 + 进度条（elapsed/durationHours）
   - 「提前收功」按钮 + 确认 dialog → `SeclusionService.completeRetreat` → push 收功结果
   - 已超时（elapsed > durationHours）时进度条满、按钮变「收功」（不再说"提前"）
   - **不做实时 Timer**：屏幕打开时算一次，无自动刷新（Demo 足够）

4. **`main_menu.dart`**：在「问鼎九霄」按钮下方插入「闭关修炼」按钮（label/hint 走 `UiStrings`）

**验收标准**：
- [x] widget test ≥ 3：列表渲染 5 张地图 / locked 卡片无 onTap 响应 / SetupScreen 显示地图名（457/457）
- [x] `flutter analyze` 0 issues

**可能的坑**：
- 列表屏需从 Isar 读 `getActiveSession` —— 用 `FutureBuilder`，不引入新 Riverpod provider（Phase 5 再整体接入）
- 进度条数值用 `min(elapsed, durationHours)` 防超出 [0,1]

---

### T50 · 闭关结算 + 奖励分发 + 收功弹窗

- **预估时长**：0.5 天
- **依赖任务**：T49
- **涉及文件**：`lib/services/seclusion_service.dart`（completeRetreat 接 DropService）、`lib/ui/seclusion/retreat_result_screen.dart`（新建）、`lib/services/drop_service.dart`（确认 rollDrops 接口兼容）、单测

**任务内容**：

1. **结算完整路径**（`SeclusionService.completeRetreat`）：
   - 调 `computeOutputs` 得到 `actualHours / mojianshi / experiencePoints`
   - 调 `DropService.rollDrops(mapDef.dropTable, rng)` 抽装备（`mapDef.equipmentDropRate` 作为概率权重，见下）
   - 将 mojianshi 写入 `InventoryItem`（`ItemType.moJianShi`，走已有 inventory writeTxn 模式）
   - `actualRewards` 写回 `RetreatSession`（mojianshi key + 装备 defId key）
   - **experiencePoints**：当前 Character 无 exp 字段 → Demo 阶段写入 `GameEvent`（type=retreatCompleted）记录，不改 Character schema

2. **装备抽检接口**：
   - Demo 阶段 5 张地图没有独立 dropTable yaml —— 用 `equipmentDropRate` 作为"是否触发一次抽检"的概率：
     `if (rng.nextDouble() < mapDef.equipmentDropRate × 0.1)` → 触发一次 `DropService.rollDrops` 从 equipment.yaml 按阶随机抽
   - `0.1` 是基础掉率系数，写入 numbers.yaml `retreat.base_equip_drop_probability: 0.1`

3. **`RetreatResultScreen`**（收功弹窗 / 独立屏）：
   - 显示：地图名 / 实际挂机时长 / 奖励列表（磨剑石 N 颗 + 装备（若有））
   - 「返回」按钮回 main_menu
   - 空奖励（0 mojianshi + 无装备）也正常显示（"此次收获甚微"）

4. **单测 ≥ 5**：mojianshi 按小时正确累加 / 72h 封顶后 mojianshi 上限 / 装备掉率 0 不掉 / actualRewards 写库验 / abandon 后 currentRetreatSessionId 清零

**验收标准**：
- [x] 单测 ≥ 5（含于 T48，completeRetreat 写库验证已有 2 用例）
- [x] 收功后 InventoryItem.quantity 变化可从 Isar 读回验证（seclusion_service_test completeRetreat 用例）
- [x] `flutter analyze` 0 issues（含于 T49）

**可能的坑**：
- 写 mojianshi 到 Inventory 需要查「是否已有该 itemType 行」—— `filter().itemTypeEqualTo(ItemType.moJianShi).findFirst()`；存在则 quantity+=N，否则新建
- DropService 现有 `rollDrops` 参数签名可能与 seclusion 调用姿势不匹配，提前确认接口再写调用端代码

---

### T51 · 全量 test + analyze 双绿

- **预估时长**：0.5 天
- **依赖任务**：T47-T50
- **涉及文件**：所有上述 test 文件

**任务内容**：
1. `flutter test` 全绿，预期累计 ≥ 455（420 + Week 3 约 33+）
2. `flutter analyze` 0 issues
3. 每个 SeclusionService public API 至少 1 service-level test

**验收标准**：
- [x] 测试数 ≥ 455（实际 457，超出预期）
- [x] analyze 0 issues
- [ ] Pen 端 SSH 跑一遍（待下次会话视觉验收）

---

### T52 · Pen 视觉验收 + 截图归档 + tag v0.3.0-w3

- **预估时长**：0.5 天
- **依赖任务**：T51
- **涉及文件**：`docs/screenshots/phase3_w3/`、`phase3_summary.md`（追加 Week 3 段）、`PROGRESS.md`

**任务内容**：

1. Mac 端预演：test + analyze 双绿
2. 派 Pen 端拉最新代码 + `flutter run -d windows` 走完一遍闭关流程：
   - 主菜单 → 闭关修炼 → 地图列表（5 张，4 锁 1 可进）
   - 进入山林（学徒可进）→ 选 1h → 开始闭关 → ActiveRetreatScreen 倒计时
   - 强制触发收功（调试：修改 startedAt 为 2h 前）→ 收功弹窗 → 奖励显示
   - 验证 Inventory 磨剑石数量变化
3. 截图归档 ≥ 3 张到 `docs/screenshots/phase3_w3/`：
   - 01 主菜单（含「闭关修炼」按钮）
   - 02 闭关地图列表（5 张三态）
   - 03 收功弹窗（奖励列表）
4. `phase3_summary.md` 追加 Week 3 段（T47-T52 清单 + 测试数 + 截图链接）
5. PROGRESS.md 更新
6. tag `v0.3.0-w3`，push origin（非 Phase 3 完整 tag，Phase 3 末 Week 4 后补 v0.3.0-phase3）

**验收标准**：
- [ ] ≥ 3 截图归档（待 Pen 运行）
- [x] phase3_summary.md Week 3 段完（部分，待截图填入）
- [ ] tag v0.3.0-w3 已 push（待 Pen 验收后 merge + tag）
- [ ] Pen 验收无大 bug

**可能的坑**：
- Isar schema 升版（0.4.0）Pen 端旧存档会报 schema mismatch → 告知 Pen 先删 AppData 存档再跑
- 调试用 startedAt 回拨：可在 SeclusionSetupScreen 加隐藏按钮（Debug flag 判断），不改 service 逻辑

---

## 附录：每日开工 checklist

每个 T 任务开始时：
1. `git status` 确认干净 + `git pull` 最新 main
2. 看 PROGRESS.md「进行中」段确认本任务是当前焦点
3. 任务完成后：
   - `flutter analyze` 0 issues
   - `flutter test` 全绿
   - PROGRESS.md 更新「进行中」→「已完成」
   - commit 用 `[Tnn]` 前缀 + 中文简明描述
   - 不 push 单 commit，按 T 任务批次 push（减少 CI 噪音）

---

## §Week 4 候选 spec 草案（待人类决策再拆 T 任务）

> 本节只做方向草案，供 Opus 重置后 review；不代表 Week 4 已拍板。
> 正式实现前必须先确认对应 AGENTS/CLAUDE §12 待决项，并把选定方向拆成 T53+ 任务。

### C. 奇遇系统

**GDD 锚点**：
⚠ GDD 锚点：本主题在 GDD 中无独立章节，散见 §4.1 / §6.1 / §7.2 / §8.4 / §9.1 / §10.1 / §11.2。
- §4.1：机缘属性影响奇遇触发率，奇遇可微弱弥补后天属性
- §6.1：奇遇所得是高阶装备的重要来源
- §7.2：武学领悟示例使用奇遇式触发条件
- §8.4 / §9.1 / §10.1 / §11.2：Demo 奇遇数量、循环触发、解锁节奏、`data/events/` 归属

**AGENTS/CLAUDE §12 待决项映射**：
- #6 武学领悟「机缘值」累积规则未定。奇遇触发同样依赖机缘，需先决定机缘值来源、阈值、衰减或冷却。

**数据 schema 草案：`data/encounters.yaml`（Mac 端）**
- `id`：唯一 id，必须与 `data/events/<id>.yaml` 文件名和文件内 `id` 严格相等
- `type`：事件类型，如 `technique_insight` / `rare_equipment` / `trial` / `karma`
- `trigger`：触发条件块，建议字段含 `biome`、`weather`、`enemy_class`、`kill_count_threshold`、`retreat_map_type`、`stage_id`、`tower_floor_min`
- `fortune_required`：机缘属性门槛
- `enlightenment_required`：悟性门槛，可空
- `realm_min` / `realm_max`：境界窗口，可空
- `reward`：结构化奖励，如 `unlock_technique_id`、`equipment_def_id`、`skill_id`、`attribute_bonus`
- `cooldown_days`：真实日冷却，避免反复触发
- `weight`：同条件下随机权重
- `enabled_in_demo`：Demo 开关，避免未来内容提前露出

**与 DeepSeek 文案联结**：
- `data/events/<id>.yaml` 归 DeepSeek，Mac 端不写不改。
- 加载层必须强校验：`encounters.yaml.id == events/<id>.yaml.id`，任一端缺失对应 id 直接抛错，不静默跳过。
- 示例参照 `AGENTS.md §8.1`：Mac 写触发条件与数值，DeepSeek 写 title/opening/choices/outcome 文本。

**预估 T 任务数**：6
- schema + EncounterDef
- repository 加载与 id 联结校验
- EncounterService 触发判定
- 奇遇结果结算 hook
- 奇遇入口 / 事件阅读 UI
- 测试 + Pen 验收

**风险 / 依赖**：
- 机缘属性目前没有完整系统实现，需要先查 GDD §4.1 / §6.1 并确认 AGENTS/CLAUDE §12 #6。
- DeepSeek 端 `data/events/` 文本节奏会影响联结校验策略；若文案未齐，需决定是 fail-fast 还是 Demo 白名单兜底。

⚠ 待人类决策再拆 T 任务，本节仅 spec 草案

### D. 师徒系统

**GDD 锚点**：
- §7.1 师徒传承

**AGENTS/CLAUDE §12 待决项映射**：
- #10 师承遗物传递时机 / 多徒弟继承规则 / 传承 buff 是否累代叠加 / 同部位装备冲突处理
- #11 祖师爷门派 buff 的具体内容、数值范围与 Demo 阶段接口

**数据 schema 草案：`data/masters.yaml`（Mac 端）**
- `id`：唯一 id，如 `founder` / `first_disciple` / `second_disciple`
- `lineage_role`：`founder` / `disciple`
- `slot_index`：Demo 固定 0-2，对应祖师 + 大弟子 + 二弟子
- `unlock_realm`：解锁境界，如一流解锁收徒
- `default_realm` / `default_layer`：Demo 初始境界
- `attribute_profile`：四属性模板或 roll 规则引用
- `starting_technique_ids`：初始心法
- `starting_equipment_ids`：初始装备 def id
- `heritage_policy`：遗物传承策略占位，如 `none` / `on_ascension` / `manual`
- `founder_buff_key`：祖师 buff 引用，占位可空
- `enabled_in_demo`：Demo 开关

**师承遗物数据位置待定**：
- 方案 A：继续挂在 `equipment.yaml`，装备 def 增 `lineage_heritage` / `legacy_bonus` 字段，实例层沿用 `Equipment.isLineageHeritage`。
- 方案 B：单独 `lineage_heritages.yaml`，把遗物规则从普通装备池拆出。
- 当前建议先不定案；§12 #10 未决前只写接口草案，不落代码。

**预估 T 任务数**：5-7
- masters.yaml schema + MasterDef
- Character / Lineage service 查询与 Demo 三角色初始化
- 师承遗物约束校验
- 祖师 buff 接口占位
- 师徒 UI 面板
- 测试 + Pen 验收
- 若涉及装备规则，再追加 schema 迁移任务

**风险 / 依赖**：
- 飞升机制 Demo 不做（GDD §12 已说明），但 §7.1 又把传位和祖师 buff 绑定在飞升后；Demo 怎么呈现师徒，需要先讨论。
- 师承遗物已明确受三系锁死约束，任何「低境界装备神物遗物」路径都必须拦截。

⚠ 待人类决策再拆 T 任务，本节仅 spec 草案

### E. 武学领悟

**GDD 锚点**：
- §7.2 武学领悟（替代抽卡）

**AGENTS/CLAUDE §12 待决项映射**：
- #6 机缘值累积规则
- §7.2 中「挂机 / 探索时累积机缘值」的具体来源、阈值、触发频率未定

**数据 schema 草案：`data/insights.yaml`（Mac 端）**
- `id`：唯一 id，如 `bamboo_listen_rain`
- `skill_id`：被解锁的招式 id，指向 `data/skills.yaml`
- `unlock_technique_id`：关联心法 id，可空；用于「领悟招式同时解锁心法」路径
- `required_technique_id`：要求已学心法，可空
- `required_school`：刚猛 / 灵巧 / 阴柔，可空
- `trigger`：触发条件块，建议含 `biome`、`weather`、`retreat_map_type`、`enemy_class`、`kill_count_threshold`、`skill_usage_threshold`
- `fortune_value_required`：机缘值门槛，不等同基础属性机缘，具体累积规则待决
- `enlightenment_required`：悟性门槛，可空
- `realm_min`：最低境界
- `cooldown_days`：真实日冷却
- `narrative_id`：可选联结到 `data/events/<id>.yaml` 或 `data/narratives/techniques/insights/<id>.yaml`，归 DeepSeek 端
- `enabled_in_demo`：Demo 开关

**Demo 内容量目标**：
- 30-50 招
- 20-30 个触发条件
- 触发条件可复用，避免 50 招全写独立复杂条件

**预估 T 任务数**：6-8
- insights.yaml schema + InsightDef
- InsightProgress / 机缘值记录模型
- InsightService 触发与去重
- 与 TechniqueLearning / CultivationService 的边界梳理
- 领悟事件 UI
- DeepSeek 文案联结校验
- 测试 + Pen 验收
- 若机缘值需全局离线累积，再追加挂机结算任务

**风险 / 依赖**：
- 与现有 `TechniqueLearningService` 耦合较高：当前学习用领悟点成本，武学领悟可能绕过或补充该路径。
- #6 不决，无法判断机缘值是按时间、击杀、闭关地图、悟性/机缘属性，还是多源累积。

⚠ 待人类决策再拆 T 任务，本节仅 spec 草案

### §Week 4 起手前的人类决策清单（明天 Opus 跟用户对方向时用）

| 待决项 | 对应方向 | 是否阻塞起手 | 建议讨论顺序 | 备注 |
|---|---|---|---|---|
| ~~#5 闭关 5 张地图具体产出公式~~ | ~~Week 3 B 闭关收尾~~ | — | — | **已决（2026-05-13 Mac Opus 复核）**：核心闭环——`realm_scale_per_tier=1.3`、`cap_hours=72`、`base_equip_drop_probability=0.1`、5 地图 5 维度基础产出、子时 +20% 全部落实；T52 Pen 视觉验收通过。3 个扩展维度（`technique_learn_rate` / `internal_force_growth` / 节气日 +30% + 正午阳刚 +20%）未接入 service，作为新挂账 #30 留 Phase 4/Week 5。 |
| #6 机缘值累积规则 | C 奇遇 / E 武学领悟 | 阻塞 C/E 正式起手 | 2 | 需要决定机缘值来源（时间/击杀/闭关/属性）、阈值、冷却、是否离线累积。C 可先做纯 schema 草案，但服务层触发逻辑会被 #6 直接影响。 |
| #10 师承遗物细节 | D 师徒系统 | 阻塞 D 正式起手 | 3 | 已确定师承遗物受三系锁死；仍需定传递时机、多徒弟归属、buff 是否累代、同部位冲突处理。 |
| #11 祖师爷门派 buff 内容 | D 师徒系统 | 阻塞 D 的 buff 接口；不阻塞纯角色展示 | 4 | Demo 不做飞升，但若 D 起手就留接口，需要先定 buff 类型和数值范围；否则只能做无 buff 的三角色展示。 |

**三个方向的「先做谁」利弊**：

- **C 奇遇系统**
  - 利：与既有战斗/装备/心法代码耦合最低；可以先把 `encounters.yaml` 与 `data/events/<id>.yaml` 的 id 联结规范立起来。
  - 弊：与 DeepSeek 文案端协同最重；若 `events/<id>.yaml` 未同步，强校验策略会影响开发节奏。
  - ⚠ 待人类决策：#6 机缘值累积规则、文案缺失时是 fail-fast 还是 Demo 白名单兜底。

- **D 师徒系统**
  - 利：Demo 量最小，只有祖师 + 大弟子 + 二弟子 3 个角色；玩家感知强，能补足项目特色。
  - 弊：#10/#11 两个决策都偏规则核心，没定就容易返工；飞升机制 Demo 不做，师徒在 Demo 中如何呈现要先讲清楚。
  - ⚠ 待人类决策：遗物传递规则、祖师 buff 是否进入 Demo、是否先做无 buff 角色展示。

- **E 武学领悟**
  - 利：最贴合「替代抽卡」卖点；能直接扩展心法/招式获得路径。
  - 弊：与已实现 `TechniqueLearningService`、`CultivationService`、`skills.yaml`、心法 UI 耦合最深，扩展成本未评估。
  - ⚠ 待人类决策：#6 机缘值规则，以及「领悟」与现有领悟点学习是否并行、替代或合并。

**建议的人类决策顺序**：

1. 先收口 #5：确认 Week 3 闭关公式是否算已决，避免 Week 4 讨论时把已实现内容重新打开。
2. 再选 Week 4 主方向：C / D / E 只选一个先拆，避免同时牵动三个未决系统。
3. 若选 C 或 E，立刻先定 #6；这是触发与结算核心，不定会直接返工。
4. 若选 D，先定 #10，再定 #11；遗物传递影响数据结构，buff 可以稍后作为接口或占位。

**如果今晚先做哪一个最不容易返工**：

推荐只在「人类接受先定 #6 的最小版本」后起手 **C 奇遇系统**。理由：C 与现有代码耦合最低，先做 `EncounterDef`、`encounters.yaml` schema、id 联结校验和只读 UI 入口，返工面相对小；D 的师承遗物规则和 E 的心法学习路径都更容易牵动已实现系统。  
⚠ 待人类决策：若 #6 今晚不能定，不建议开 C/E 服务层实现；最多继续做文档或 schema 草案。

### §起手 issue 清单（C/D/E 三方向各自展开）

#### C. 奇遇系统

Issue C-1：机缘基础属性与机缘值是否同一套资源
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：`lib/data/models/attributes.dart` 已有 `Attributes.fortune`，注释写明影响奇遇触发率；但没有“机缘值”累计模型。需要决定奇遇直接读基础属性，还是新增可累计/消耗的 fortune value。

Issue C-2：奇遇真实 GDD 锚点是否补成独立章节
- 阻塞：否（影响 Week 4 spec 与 PR 描述口径）
- 关联 §12 决策项：#6
- 建议回答方式：翻 GDD 找答案
- 备注：当前草案已修正为散见 §4.1 / §6.1 / §7.2 / §8.4 / §9.1 / §10.1 / §11.2；若 GDD 后续补独立“奇遇系统”章节，schema 文档和任务锚点要同步。

Issue C-3：`encounters.yaml` ↔ `events/<id>.yaml` 联结缺失时是否 fail-fast
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：跟 DeepSeek 端协调
- 备注：AGENTS §8.1 要求 id 严格相等且任一端缺失直接抛错；但当前 `data/events/` 已有 26 个文案文件，`data/encounters.yaml` 未创建。起手时要决定先按 events 反建触发条件，还是让 DeepSeek 等 Mac 端 id 清单。

Issue C-4：奇遇触发源是否接主线、爬塔、闭关三条入口
- 阻塞：否（影响服务 hook 拆分顺序）
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：现有可接点包括主线胜利、爬塔胜利、闭关收功；若三处同时接，测试面变大。可先定 Demo 第一版只接一处，剩余入口留 schema 字段。

Issue C-5：奇遇奖励是否允许给高阶装备/心法但暂不可用
- 阻塞：否（影响 reward schema 校验）
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：AGENTS §5.3 已明确高于当前境界的物品可获得、可携带、可观摩，但不可装备/修炼；EncounterService 需要只发放，不绕过 `canEquip` / `canPractice`。

Issue C-6：Demo 20-30 个奇遇的最小可验收粒度
- 阻塞：否（影响 T 任务验收）
- 关联 §12 决策项：#6
- 建议回答方式：跟 DeepSeek 端协调
- 备注：若 Week 4 只做系统骨架，可先放 3-5 个 fixture；若要对齐 Demo 目标，需要 Mac `encounters.yaml` 与 DeepSeek `events/` 同步到 20-30 个 id。

#### D. 师徒系统

Issue D-1：飞升 Demo 不做时，师徒系统在 Demo 如何呈现
- 阻塞：是
- 关联 §12 决策项：#10 / #11
- 建议回答方式：人类决策
- 备注：GDD §7.1 把传位、祖师 buff 与飞升绑定，但 Demo §12 不做飞升。需要决定 Week 4 是做三角色展示/上阵，还是做“未来接口 + 无飞升占位”。

Issue D-2：师承遗物传递规则
- 阻塞：是
- 关联 §12 决策项：#10
- 建议回答方式：人类决策
- 备注：已确定师承遗物受三系锁死；仍需定传递时机、继承人、多徒弟归属、buff 是否累代叠加、同部位已有装备时如何处理。

Issue D-3：祖师爷门派 buff 内容与数值范围
- 阻塞：是（若做 buff）；否（若只做角色展示）
- 关联 §12 决策项：#11
- 建议回答方式：人类决策
- 备注：`numbers.yaml` 目前 `founder_ancestor_buff.enabled_when_alive: false`、`sect_wide_buff: null`。如果 Week 4 要留接口，需决定 buff key、目标属性、数值上限与是否进入 Demo。

Issue D-4：3 个师徒角色属性来源
- 阻塞：是
- 关联 §12 决策项：#2 / #10
- 建议回答方式：人类决策
- 备注：`Character` 已有 `lineageRole`、`masterId`、`discipleIds`、`isFounder` 字段，但没有 `masters.yaml`。需要决定祖师/大弟子/二弟子是固定模板、按 CharacterGenerator roll，还是由剧情/种子创建。

Issue D-5：师徒角色是否进入 3v3 active team
- 阻塞：否（影响 UI 与 StageBattleSetup）
- 关联 §12 决策项：#10
- 建议回答方式：试做后再说
- 备注：当前 `StageBattleSetup` 从 `SaveData.activeCharacterIds` 拉玩家队伍，最多 3 人正好能承载师徒；但 UI 尚无换人/排阵入口。

Issue D-6：师徒数据 schema 放 `masters.yaml` 还是复用 Character seed
- 阻塞：否（影响数据边界）
- 关联 §12 决策项：#10 / #11
- 建议回答方式：人类决策
- 备注：草案写 `data/masters.yaml`，但现有 Isar `Character` 已能表达师徒关系。需要决定 yaml 只是初始模板，还是长期角色定义数据源。

#### E. 武学领悟

Issue E-1：与现有 TechniqueLearningService 的边界
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：`TechniqueLearningService` 当前用领悟点学习心法，服务只构造 `Technique`，不写 Isar。武学领悟要决定是解锁 `SkillDef`、解锁 `TechniqueDef`，还是给学习折扣/资格。

Issue E-2：机缘值累积规则与 C 方向共享
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：E 的 `fortune_value_required` 与 C 的奇遇触发都依赖 #6；若两个方向都要用，需要同一套 `InsightProgress` / fortune value 模型，避免重复计数。

Issue E-3：30-50 招式与 20-30 触发条件的数据组织方式
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：当前 `data/skills.yaml` 只有 18 招，且全部挂在 6 本心法下；`SkillDef.parentTechniqueDefId` 注释已允许为空表示独立领悟产出。需要决定新招直接扩 `skills.yaml`，触发条件放 `insights.yaml`，还是按流派拆文件。

Issue E-4：领悟叙事联结走 events 还是 narratives/techniques/insights
- 阻塞：否（影响 DeepSeek 协作）
- 关联 §12 决策项：#6
- 建议回答方式：跟 DeepSeek 端协调
- 备注：当前 `data/narratives/techniques/insights/` 已有 35 个文案文件；草案允许 `data/events/<id>.yaml` 或 narratives 子目录。需要统一 id 命名与加载策略。

Issue E-5：触发条件是否复用战斗 skillUsageCount
- 阻塞：否（影响实现路径）
- 关联 §12 决策项：#6
- 建议回答方式：试做后再说
- 备注：`Technique.skillUsageCount` 已记录招式使用次数，可支撑 `skill_usage_threshold`；但击杀数、天气、biome、retreat_map_type 等条件尚无统一统计模型。

Issue E-6：已领悟招式如何进入战斗可用列表
- 阻塞：是
- 关联 §12 决策项：#6
- 建议回答方式：人类决策
- 备注：`Character.learnedSkillIds` 字段已存在，但 BattleCharacter 当前主要从心法 `skillIds` 装配技能。需要决定独立领悟招式是直接加入可用技能，还是必须绑定到主修/辅修心法。

⚠ 待人类决策：上述 issue 只列阻塞点与协作点，不代表 Week 4 方向已拍板。

---

## Phase 3 Week 4 任务清单（D 师徒系统）

> **方向已选** D 师徒（2026-05-13），D-1/D-2/D-3 三决策点全部按推荐方案 A。
> 详细论证 + 不做清单 + 决策落地见 `docs/handoff/week4_d_minimal_spec_2026-05-13.md`。
> C 奇遇 / E 武学领悟仍在 §Week 4 候选 spec 草案 节保留，等 §12 #6 拍板后再排先后。

### Week 4 入场前置

- 起手前 base：main = 9bb799c，495/495 测试，analyze 0 issues
- §12 #5 已收口（2026-05-13），3 维度扩展挂账 #30
- §12 #10/#11 在 Demo 范围内全部推迟到 1.0 飞升机制，本 Week 不碰
- 与挂账 #25 P1 fixture 缺主修协调：T54 seed 改造一并修；与 #26 闭关入口硬编码 characterId=1 同源，T54 顺手清

---

### T53 · masters.yaml schema + MasterDef + GameRepository 加载 + 红线校验

- **预估时长**：0.5 天
- **依赖任务**：— （起手）
- **涉及文件**：`data/masters.yaml`（新）、`lib/data/defs/master_def.dart`（新）、`lib/data/game_repository.dart`（加 `masters` + `loadMasters` + `_enforceMasterRedLines`）、`test/master_def_test.dart`（新）

**任务内容**：

1. **新建 `data/masters.yaml`**（3 条，camelCase）：
   - `id`：`founder` / `firstDisciple` / `secondDisciple`
   - `lineageRole`：对齐 `enum LineageRole`（founder / firstDisciple / secondDisciple，已存在）
   - `slotIndex`：0 / 1 / 2
   - `defaultRealm`：宗师 / 绝顶 / 一流（递减一阶，全部 < 武圣，不触碰飞升锚点）
   - `defaultLayer`：每阶第 1 层（`qiMeng` 对齐 RealmStratum）
   - `attributeProfile`：4 项 `{strength, agility, fortune, enlightenment}` 固定模板，总和 16-24（GDD §4.1）。建议祖师 22 / 大弟子 19 / 二弟子 17
   - `startingTechniqueIds`：1 主修 + 1 辅修，id 须在 `techniques.yaml` 存在
   - `startingEquipmentIds`：3 件，id 须在 `equipment.yaml` 存在；**祖师 starting 至少含 1 件 `isLineageHeritage: true`**（与 T55 协调）
   - `enabledInDemo`：true

2. **新建 `lib/data/defs/master_def.dart`**：
   - 不可变值对象 + `fromYaml` 工厂（参照 `equipment_def.dart` 体例）
   - 内嵌 `AttributeProfile` 子类型 `{strength, agility, fortune, enlightenment}`

3. **`GameRepository` 接入**：
   - 加字段 `final List<MasterDef> masters`
   - 加方法 `Future<List<MasterDef>> _loadMasters()`，从 `data/masters.yaml` 解析
   - `_enforceMasterRedLines()`：
     - 必须正好 3 条；slotIndex 必须 0/1/2 各一不重不漏
     - lineageRole 必须三选一不重复
     - **defaultRealm 不允许 `wuSheng`**（飞升锚点）
     - startingTechniqueIds / startingEquipmentIds 全部 id 必须能在 techniques/equipment def 表中找到
     - **祖师 startingEquipmentIds 必须含至少 1 件 `EquipmentDef.isLineageHeritage == true`** —— 此校验需 T55 完成后才能生效，T53 spec 先留 TODO 注释
     - attributeProfile 4 项总和 ∈ [16, 24]

4. **单测 ≥ 6**（`test/master_def_test.dart`）：
   - fromYaml 3 角色正常加载
   - slotIndex 缺失/重复 fail-fast
   - lineageRole 重复 fail-fast
   - defaultRealm=wuSheng fail-fast
   - 任意 startingTechniqueId 不存在 fail-fast
   - attributeProfile 总和越界 fail-fast

**验收标准**：
- [ ] 单测 ≥ 6 全绿
- [ ] `flutter analyze` 0 issues
- [ ] 累计测试 495 → ≥ 501

**可能的坑**：
- pubspec.yaml 是否已声明 `data/masters.yaml` 为 asset：现有 `data/*.yaml` 是 glob 还是逐文件声明？若逐文件，T53 需加一行
- AttributeProfile 与现有 `lib/data/models/attributes.dart` 的关系：是否复用 Attributes，还是 def 层独立？建议**def 层独立**，避免 Isar `@embedded` 污染纯 Dart def
- 祖师遗物校验 TODO：T55 完成后回 T53 启用，commit 时连带补单测

---

### T54 · seedMasterDisciple service + Demo 入口接入 + 清挂账 #25/#26

- **预估时长**：0.5-1 天
- **依赖任务**：T53
- **涉及文件**：`lib/services/phase2_seed_service.dart`（加 `seedMasterDisciple` 或独立服务）、`lib/services/save_data_service.dart`（如有）、`lib/ui/debug/phase2_test_menu.dart`（加调试入口）、`lib/ui/main_menu.dart`（清挂账 #26 硬编码）、`test/master_disciple_seed_test.dart`（新）

**任务内容**：

1. **seed 服务**：
   - 接受 `MasterDef` 列表，按 slotIndex 顺序：
     - **祖师 slot 0**：**复用既有玩家 Character**（按当前 saveDataId 找 characterId=1 或 SaveData.activeCharacterIds 首位），追加 `isFounder = true / lineageRole = founder`；不另建 founder Character（决策点 1 落地）
     - **大/二弟子**：新建 2 个 Character，各按 def.defaultRealm/Layer/attributeProfile 写入；`masterId = founderId`
   - 写关系：祖师 `discipleIds = [大弟子id, 二弟子id]`
   - 学心法：调既有 `TechniqueLearningService.learn`（或类似 API）按 def.startingTechniqueIds 装上；主修 + 辅修
   - 装装备：调 `EquipmentFactory.generate` 按 def.startingEquipmentIds 生成 Equipment 实例，写入 InventoryItem 然后 equip（祖师含 1 件 isLineageHeritage）
   - **SaveData.activeCharacterIds**：写入 [founderId, 大弟子id, 二弟子id]，默认 3 师徒同阵
   - **幂等**：若已 seed（discipleIds 已非空）则跳过

2. **Demo 入口**：
   - `phase2_test_menu.dart` 增第 5 个按钮 "P5 师徒种子"，onTap 调 seedMasterDisciple
   - **可选**：与挂账 #25 协调 —— seedP1 改造为「装备+材料+心法主修+师徒种子」一站式，主菜单 P1 后可直接进主线/爬塔/闭关战斗，不再 fail-fast

3. **清挂账 #26**：
   - `main_menu.dart:77-78` 硬编码 `characterId=1 / RealmTier.xueTu` 改为从 `SaveData.activeCharacterIds` 首位读 + Character.currentRealmTier
   - 闭关入口随存档真实角色境界判定地图解锁

4. **单测 ≥ 5**：
   - seed 一次后 Character 表正确生成 3 条（祖师复用 + 2 弟子新建）
   - 师徒关系字段双向正确（祖师 discipleIds、弟子 masterId）
   - 幂等：连续调 2 次只 seed 1 次
   - activeCharacterIds = 3 个 id
   - 祖师装备里至少 1 件 isLineageHeritage

**验收标准**：
- [ ] 单测 ≥ 5 全绿；累计 ≥ 506
- [ ] `flutter analyze` 0 issues
- [ ] **挂账 #25 销账**：P1 → 主线战斗不再 fail-fast（service-level test 验证）
- [ ] **挂账 #26 销账**：闭关地图按存档真实境界判定（service-level test 验证）

**可能的坑**：
- "复用既有玩家 Character" 的 saveData 上下文：若没有 SaveData/Character 入口（Demo 首次启动尚未 P1 种子时），seed 应 fail-fast 提示「请先 P1 种子」**或**自动先调 seedP1。建议前者，保持入口契约清晰
- EquipmentFactory 现有签名是否支持指定 def + 强制生成（不抽包）：T54 起手前确认；若不支持，需要为种子场景加旁路 API
- 与挂账 #23 widget test 不接真 Isar 的协调：单测走 service-level，不写 widget test

---

### T55 · EquipmentDef.isLineageHeritage 字段 + equipment.yaml fixture 标记

- **预估时长**：0.3 天
- **依赖任务**：T53（schema）、与 T54 并行可
- **涉及文件**：`lib/data/defs/equipment_def.dart`、`data/equipment.yaml`、`lib/services/equipment_factory.dart`（透传字段）、`test/equipment_def_test.dart`、`test/equipment_factory_test.dart`

**任务内容**：

1. `EquipmentDef` 加 `final bool isLineageHeritage`（缺省 false），`fromYaml` 读 `isLineageHeritage` key（不存在则 false）
2. `equipment.yaml` 选 2-3 件**祖师可装备阶**（宗师阶或更低，对齐 T53 祖师 defaultRealm=宗师）的装备，加 `isLineageHeritage: true`
3. `EquipmentFactory.generate` 把 `def.isLineageHeritage` 透传到 `Equipment.isLineageHeritage`
4. **回 T53 启用祖师遗物红线校验**：补 `_enforceMasterRedLines` 的 TODO + 配套单测
5. 单测 ≥ 3：fromYaml 字段读 true / 缺省 false / EquipmentFactory 生成后 Equipment.isLineageHeritage 正确

**验收标准**：
- [ ] 单测 ≥ 3 全绿；累计 ≥ 509
- [ ] `flutter analyze` 0 issues
- [ ] equipment.yaml 至少 2 件标记，与祖师 starting 至少 1 件对齐

**可能的坑**：
- 标记的 2-3 件遗物**不要**改动既有平衡参数（attack/health/speed/tier），只加 `isLineageHeritage: true` 一行；避免影响 Phase 1/2 战斗测试期望
- numbers.yaml `lineage_heritage.internal_force_max_bonus: 0.05` 的应用点：当前 BattleCharacter 装配是否消费？若未，**本 T 不做**，列为新挂账（buff 效果落地另起一 T 或挂 Phase 4）

---

### T56 · 角色页签「师承」段 UI + 师徒展示

- **预估时长**：0.5-1 天
- **依赖任务**：T54
- **涉及文件**：`lib/ui/character/character_panel_screen.dart`（或既有角色面板）、`lib/ui/strings.dart`（占位字符串）、widget test

**任务内容**：

1. 在角色面板加「师承」段：
   - 「师父：XX（境界 · 层）」/「徒弟：[大弟子（境界·层）, 二弟子（境界·层）]」
   - 祖师页签显示「开派祖师」标识 + 「[传记待补]」占位（决策点 3 落地，DeepSeek 文案到位后自然替换）
2. 主菜单加「师徒」入口 **或** 角色面板平铺 3 角色切换 —— 建议**后者**，复用既有 character_panel_screen，最小改动
3. widget test：rootBundle 加载 masters.yaml + 3 角色卡片可见 + 师徒关系字段渲染正确
4. **不做**：换人 UI、收徒 UI、传位动作

**验收标准**：
- [ ] widget test ≥ 3
- [ ] `flutter analyze` 0 issues；累计 ≥ 512
- [ ] 截图：祖师视角、大弟子视角各 1 张（T58 一并验收）

**可能的坑**：
- 既有 character_panel_screen 是按 characterId=1 硬编码的（与挂账 #26 同源）；T54 清完应该已经支持切换 active 角色，但要复核

---

### T57 · 3v3 默认入阵 + 战斗集成测试

- **预估时长**：0.5 天
- **依赖任务**：T54
- **涉及文件**：`lib/services/battle_engine.dart` 或 `lib/services/stage_battle_setup.dart`（核对 activeCharacterIds 读取链）、`test/master_disciple_battle_test.dart`（新）

**任务内容**：

1. T54 已把 3 个 id 写进 `SaveData.activeCharacterIds` —— 复核 `StageBattleSetup` / `BattleCharacter` 装配链能否正确装配 3 师徒（境界/装备/心法/属性都到位）
2. service-level 集成测试：seed 师徒 → 跑 stage_01_01 → battle 结束有 victory log → 3 师徒各自属性/技能正确进入战斗
3. **不做**：换人 UI、阵型摆位、师徒协同 buff

**验收标准**：
- [ ] 集成测试 ≥ 2（victory case + defeat case）
- [ ] `flutter analyze` 0 issues；累计 ≥ 514

**可能的坑**：
- 大弟子/二弟子境界（绝顶/一流）vs 主线 stage_01_01 敌人境界差很大 → 境界差异修正会让战斗一边倒。T57 是「装配正确性」测试，**不验平衡**；平衡问题挂 Phase 5

---

### T58 · 全量 test + analyze 双绿 + Pen 视觉验收 + tag v0.3.0-w4

- **预估时长**：0.5 天
- **依赖任务**：T53-T57
- **涉及文件**：`docs/screenshots/phase3_w4/`、`phase3_summary.md`（追加 Week 4 段）、`PROGRESS.md`

**任务内容**：

1. Mac 端预演：test + analyze 双绿，累计 ≥ 514
2. 派 Pen 端：
   - 拉新 main + `flutter build windows --release` + 跑游戏
   - 清开发态存档（`%APPDATA%\com.example.wuxia_idle`，schema 升版 0.4.0 → 0.5.0 必清）
   - 走流程：P5 师徒种子 → 角色面板查 3 师徒卡片 → 进主线 stage_01_01 → 看 3 师徒同阵 victory
3. 截图归档 ≥ 3 张到 `docs/screenshots/phase3_w4/`：
   - 01 P5 种子按钮已加入
   - 02 角色面板「师承」段（祖师 + 2 弟子可见）
   - 03 主线战斗 3 师徒同阵
4. `phase3_summary.md` 追加 Week 4 段（T53-T58 + 测试数 + 截图链接 + 挂账 #25/#26 销账）
5. `PROGRESS.md` 更新
6. tag `v0.3.0-w4`，push origin

**验收标准**：
- [ ] ≥ 3 截图归档
- [ ] phase3_summary.md Week 4 段完
- [ ] tag v0.3.0-w4 已 push
- [ ] Pen 验收无大 bug
- [ ] 挂账 #25 / #26 PROGRESS 标销

**可能的坑**：
- Isar schema 升版（祖师 isFounder / discipleIds 字段已存在，本 Week 不升 schema，**但** activeCharacterIds 增到 3 个可能触发 SaveData 字段长度差异 → 测一下旧存档兼容）
- 大弟子/二弟子境界过高，stage_01_01 可能秒杀 boss，截图战斗看着可能很扯；可以接受，截图说明清楚即可

