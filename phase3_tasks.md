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

## Week 2-3：待 Week 1 跑通后再拆

候选方向（GDD §7-§8 + CLAUDE §7）：

- **爬塔 30 层**：3 小 Boss [5/15/25] + 3 大 Boss [10/20/30]，新 TowerProgress collection + 闯关流程 UI
- **闭关地图 5 张**：兵器/心法/属性/共鸣/... 偏向不同（CLAUDE §12 #5 待决：每小时产出公式）
- **奇遇 20-30**：encounters.yaml 触发条件（Mac）+ events/ 文案（DeepSeek），机缘值累积规则待决（§12 #6）
- **师徒传承**：祖师+大弟子+二弟子 数据 model + 遗物三系锁死校验，§12 #10/#11 待决
- **武学领悟 30-50 招**：插槽机制 + 触发条件，§12 #6 机缘值累积待决

Week 1 收尾时跟用户讨论 Week 2 切法，重新走「kickoff §四 → 拆任务 → 落档」流程。

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
