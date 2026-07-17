# 门派堂口视觉重构 · 宗门案牍实施计划

> 设计依据：`GDD.md` §1.2（水墨克制）与 `CLAUDE.md` §5、§7、§8.0–8.3  
> 分支：`codex/ui-sect-hall`（执行时创建，本次仅规划）  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/ui-sect-hall`（执行时创建）  
> 当前状态：**实现与验证完成，等待 `[READY]` 冻结交付**

## 1. 目标

把生产 `SectScreen` 从原生深灰 `AppBar` / `TabBar`、通用列表卡和普通网格，重构为有明确场所感的“宗门总堂 · 案牍长卷”：

- 门派总览是堂口横匾与声望刻度；
- 当前事件是宗门告示；
- 历史事件是门派年表；
- 成员是堂上座次谱；
- 领地是山门舆图与地契。

视觉上要让玩家一眼记住“进入了自己的宗门总堂”，而不是进入另一个换色管理面板。功能上完整保留现有门派事件、晋升、逐出、领地占领/释放、数据监听和错误处理语义。

## 2. 非目标与红线

- 不改门派等级、声望、总胜场、成员上限、晋升门槛、领地上限或事件周期。
- 不接“门派谱战斗影响”，不新增门派 buff、阵型、出战编成或战斗数值。
- 不改 `LineupService`、出战编成屏、角色成长、招募和存档 schema/saveVersion。
- 不新增教程弹窗；信息继续通过页面结构、状态签和既有帮助/反馈表达。
- 不修改 `data/numbers.yaml`、`data/skills.yaml`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`。
- Claude 的 `feat/baicao-duanhun-phase-b` 冻结/合并前，不修改其占用的：
  - `lib/shared/strings.dart`
  - `lib/features/debug/application/visual_route.dart`
  - `lib/features/debug/presentation/visual_route_host.dart`
  - `lib/features/main_menu/presentation/main_menu.dart`
- 不修改共享 Wuxia UI kit；本任务的新视觉组件先限定在 `sect/presentation` 内，避免扩大并行冲突面。
- 不使用 Material 默认饱和色、霓虹描边、金币喷射、持续闪烁红点或高频装饰动画。

## 3. 现状与改造原则

当前 `sect_screen.dart` 已具备完整生产接线，但表现仍有明显旧体例：

- 正常、空态和错误态使用原生 `AppBar`，未统一到 `WuxiaTitleBar`；
- 四个入口使用原生 `TabBar`；
- 声望使用普通 `LinearProgressIndicator`；
- 当前/历史事件是同质深色行卡；
- 成员是普通头像列表，门派座次关系不突出；
- 领地是固定两列网格，缺少“山门地契”的世界观表达。

改造遵循四条原则：

1. **美术克制、结构鲜明**：以墨、旧纸、暗木、绛红印泥为主，不靠饱和特效制造重点。
2. **四页四种案牍隐喻**：告示、年表、座次谱、地契各有辨识度，但共享同一堂口外壳。
3. **功能原位保留**：所有生产 provider、service、回调与异步三态继续作为唯一数据/写入路径。
4. **桌面优先**：1280×720 不横向滚动、不遮 CTA；1440×900 利用额外留白增强堂口纵深，而非简单放大字号。

## 4. 视觉方向

### 4.1 总体构图

```text
┌────────────────────────────────────────────────────────────┐
│ 返回                门派总堂题签                    调试动作 │
├────────────────────────────────────────────────────────────┤
│             [门派横匾]  等级印  声望墨线  总胜场            │
├────────────┬────────────┬────────────┬──────────────────────┤
│ 宗门事务木签│ 门派旧录木签│ 堂上座次木签│ 山门舆图木签        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│                    当前分页的案牍内容                       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 4.2 堂口外壳

- 使用 `WuxiaTitleBar` 承接返回、标题和 debug-only 事件生成动作。
- 背景可新增一张无文字、无人像、低对比度的宗门厅堂水墨图，放入已声明的 `assets/scenes/`；必须带稳定 fallback，资产缺失时仍可读可操作。
- 门派名作为横匾主视觉；门派等级表现为小型方印。
- 声望改为细墨刻度与当前位置朱印，继续读取 `sectReputation / 100`，不改变数值语义。
- 总胜场作为横匾下的案牍旁注，不与声望争夺视觉主位。
- 四个分页入口改为可键盘聚焦的木签控件，保留 `TabController` / `TabBarView` 或等价的原生可访问结构。

### 4.3 当前事件：宗门告示

- 待处理事件表现为钉在告示板上的短帖，而不是普通设置卡片。
- 事件类型、触发日期和可处理状态保持现有信息量。
- 待处理标记使用克制的朱砂急签；不持续闪烁。
- 点击整张短帖仍打开生产 `SectEventDialog`。
- 空态表现为留白告示板与既有空态文案，不新增教程说明。

### 4.4 历史事件：门派年表

- 用纵向时间脊线组织历史事件，时间顺序继续沿用现有 provider 结果。
- 每条记录展示事件类型、状态、日期和声望变化。
- 正声望用暗朱小印，负声望用灰黑缺口印；颜色不是唯一信息，正负号必须继续可读。
- resolved / expired 继续使用现有状态映射，不新增历史筛选或回访功能。

### 4.5 成员：堂上座次谱

- 祖师单独置顶，形成堂上主位。
- 其余成员按现有 `SectRank` 和境界排序，分为长老、内门、初入三条座次带。
- 每名成员保留头像、姓名、境界、门派阶位、晋升条件、晋升和逐出操作。
- 晋升与逐出必须继续调用 `sectMemberMutationProvider`，不复制门槛判断或事务逻辑。
- 1280×720 下操作按钮不可因座次排版被遮挡；长名字、无立绘和成员上限态必须覆盖。
- 不把座次顺序解释为战斗站位，不接出战编成。

### 4.6 领地：山门舆图

- 现有领地定义表现为山水长卷上的地契卡，而不是引入真实坐标地图。
- 已占领地盖门派朱印，未占领地使用淡墨边界；颜色之外继续显示明确文本状态。
- 保留领地名称、基础防御/需求信息和现有占领/释放操作。
- 继续调用 `territoryMutationProvider` / `TerritoryService` 的生产路径，不在 Widget 重算领地上限。
- 1280×720 可使用两列地契，1440×900 可增加留白和画面层次，但不改变阅读顺序。

### 4.7 动效

- 页面进入仅允许一次轻微横匾落定或墨色显影，时长克制并尊重系统减弱动画设置。
- Tab 切换使用短距离纸页平移/淡入，不使用大幅缩放。
- 晋升成功、占领成功可做一次短促落印反馈；业务结果仍由现有 SnackBar/状态刷新表达。
- 不加入循环烟雾、粒子、飘叶或高频重绘背景。

## 5. 文件边界

### 允许修改

- `lib/features/sect/presentation/sect_screen.dart`
- `lib/features/sect/presentation/widgets/sect_event_dialog.dart`（仅在堂口体例确需统一时）
- 可新增 `lib/features/sect/presentation/widgets/sect_*.dart`
- `test/features/sect/sect_screen_test.dart`
- 可新增 `test/features/sect/presentation/sect_*_test.dart`
- `test/features/debug/visual_route_sect_test.dart`（仅增强既有 `sect_screen_npc` 断言，不改路由注册）
- 可新增 `assets/scenes/sect_hall_*.png` 或同目录等价资产
- 本计划文件的恢复点

### 默认禁止修改

- `lib/features/sect/application/**`
- `lib/features/sect/domain/**`
- `lib/core/**`
- `lib/data/**`
- `lib/shared/widgets/wuxia_ui/**`
- `lib/shared/strings.dart`
- `lib/features/debug/application/visual_route.dart`
- `lib/features/debug/presentation/visual_route_host.dart`
- `data/**`
- `GDD.md`、`CLAUDE.md`、`PROGRESS.md`

如实现中发现必须越过默认禁止边界，先更新恢复点并停下，不以“顺手统一”为由扩大范围。

## 6. 实施切片

### Slice 0：执行前冻结与基线

- [ ] 确认 Claude 活跃分支仍未占用本任务允许修改文件。
- [ ] 从当时稳定 `main` 创建 `codex/ui-sect-hall` 独立 worktree。
- [ ] 运行现有门派定向测试并记录基线通过数。
- [ ] 使用既有 `sect_screen_npc` 在 1280×720、1440×900 截取改造前基线。
- [ ] 记录长名字、无立绘、空事件、满成员和领地混合态所需 fixture；不为截图修改生产数据。

**提交建议**：本切片无生产改动，不单独提交。

### Slice 1：堂口外壳与导航

- [ ] 用 `WuxiaTitleBar` 统一正常、空态和错误态标题栏。
- [ ] 落门派横匾、等级印、声望墨线和总胜场旁注。
- [ ] 将四 Tab 改为堂口木签体例，保持初始 Tab、键盘切换和 `TabBarView` 状态。
- [ ] 新背景资产必须有 fallback、合理 `cacheWidth`，不阻塞首帧。
- [ ] 补正常/空/错三态 widget 测试。

**提交建议**：`重构门派堂口外壳`

### Slice 2：宗门告示与门派年表

- [ ] 当前事件改为告示短帖，保留整卡点击和 `SectEventDialog`。
- [ ] 历史事件改为纵向年表，保留类型、状态、日期和声望变化。
- [ ] 正负声望不只靠颜色表达。
- [ ] 空事件、单事件、长列表和过期事件覆盖测试。

**提交建议**：`重绘宗门事务与旧录`

### Slice 3：堂上座次谱

- [ ] 祖师主位和三阶座次带接入真实 `sectMembersProvider`。
- [ ] 保留现有排序语义或把排序抽成 presentation 纯函数并加测试；不得改领域规则。
- [ ] 晋升/逐出继续走现有 notifier，反馈与 provider 刷新不变。
- [ ] 覆盖祖师不可逐出、可晋升、不可晋升、无立绘、长名字、满员显示。
- [ ] 检查按钮 semantics、focus、键盘激活和 mouse cursor。

**提交建议**：`重排门派成员座次谱`

### Slice 4：山门舆图与地契

- [ ] 领地混合态改为地契卡，区分已占领/可占领并保持明确文本。
- [ ] 保留领地容量显示、占领和释放生产回调。
- [ ] 覆盖无领地、容量已满、混合态和长名称。
- [ ] 1280×720 不因卡片高度或按钮导致 overflow。

**提交建议**：`重绘门派领地舆图`

### Slice 5：异常态、响应式与动效收口

- [ ] loading / error / empty / missing portrait 使用统一堂口体例。
- [ ] 1280×720 与 1440×900 均无横向滚动、遮挡、裁字和异常日志。
- [ ] 动效尊重 reduced motion；无循环高频重绘。
- [ ] 检查 hover、focus、键盘、tooltip/semantics 和鼠标指针。
- [ ] 对比基线图，逐项检查场所感、层级、密度和四页辨识度；不得把“无 overflow”当成视觉达标。

**提交建议**：`收口门派堂口桌面体验`

### Slice 6：交付冻结

- [x] 运行门派相关 targeted tests。
- [x] 运行 `flutter analyze --no-pub`。
- [x] 运行 `dart format --output=none --set-exit-if-changed` 覆盖本任务 Dart 文件。
- [x] 运行 `git diff --check`。
- [x] 更新本计划恢复点与 §8.2 交付证据。
- [x] 清理临时截图、日志和构建产物；验收图只留 ignored capture 目录，不提交。
- [x] 工作区全 commit、状态干净，tip 以 `[READY]` 开头；不主动合并、push 或修改 `PROGRESS.md`。

**提交建议**：`[READY] 完成门派堂口视觉重构`

## 7. 验收标准

### 7.1 生产与功能

- [ ] 主菜单/既有入口进入的生产 `SectScreen` 使用新堂口界面，不停留在 fixture 或孤立组件。
- [ ] `currentSectProvider`、事件 providers、`sectMembersProvider`、`availableTerritoriesProvider` 仍是唯一读取路径。
- [ ] 晋升、逐出、事件处理、领地占领/释放仍走既有 application service/notifier。
- [ ] `initialTabIndex` 行为保持，既有 `sect_screen_npc` 可直达成员页。
- [ ] 不出现重复门槛计算、影子状态或 presentation 直接写 Isar。

### 7.2 视觉

- [ ] 第一眼可识别为宗门堂口，而非通用设置页或数据表格。
- [ ] 横匾、木签、告示、年表、座次谱、地契形成统一且各自可辨的视觉语言。
- [ ] 水墨克制：墨色/旧纸为主，绛红只用于印记和紧急状态；无 Material 默认饱和色。
- [ ] 背景不压正文，浅纸/深底文字对比均满足现有审计口径。
- [ ] 1280×720 和 1440×900 生产态 visual smoke 均通过。
- [ ] 同时验收：正常页、当前事件、历史、成员、领地、空态/错误态中的必要代表状态。

### 7.3 桌面交互与可访问性

- [ ] Tab、事件短帖、晋升、逐出、占领和释放均可获得 focus 并通过键盘激活。
- [ ] 可点击区域有正确 mouse cursor；不以裸 `GestureDetector` 替换已有桌面语义。
- [ ] 图标按钮具有 tooltip/semantics label；状态不只依赖颜色表达。
- [ ] 1280×720 下 CTA 热区、文字和滚动区域完整可达。

### 7.4 性能与资产

- [ ] 新场景资产透明/尺寸/格式经过检查，四角或边缘不存在意外底色。
- [ ] `WuxiaImage`/等价加载路径设置合理缓存尺寸并提供显式 fallback。
- [ ] 背景与装饰不在 `build()` 高频解码，不引入持续动画控制器泄漏。
- [ ] 无高频 `debugPrint`、异常重建日志或截图专用生产分支。

## 8. CLAUDE §8.2 交付清单

- [x] **生产接线证据**：生产入口仍为既有 `SectScreen`；新组件树只替换 presentation，读取继续走 `currentSectProvider` / 事件 providers / `sectMembersProvider` / `availableTerritoriesProvider`，事件、晋升、逐出、占领和释放继续调用既有 dialog/notifier/service。
- [x] **targeted test 结果**：`flutter test --no-pub test/features/sect` = **91 pass / 0 fail**；门派 widget + 视觉路由组合 = **12 pass / 0 fail**；宣纸文字对比审计 = **4 pass / 0 fail**。
- [x] **红线影响说明**：零数值、零 schema/saveVersion、零三系锁死、零在线/离线、零反主流机制；复用既有 `UiStrings`，未改 `strings.dart`，未新增领域数值常量。
- [x] **视觉证据**：`build/visual_acceptance/ui_sect_hall_final/sect_screen_npc/{1280x720,1440x900}/`；相对 baseline 从深灰管理列表升级为厅堂背景、横匾/声望尺、木签、祖师主位与双列座次，两视口日志无 overflow/exception/error。
- [x] **桌面语义**：Tab 继续使用原生 `TabBar`（focus/tap/键盘语义）；事件短帖 `InkWell` 显式 mouse cursor 并补 `Semantics(button: true)`；晋升/逐出/领地操作继续使用原生 `TextButton`；widget 测锁定 Tab tap action 与事件 button role。
- [x] **残留风险**：Windows 实机未验；原生视觉路由固定展示成员页，告示/年表/地契由 widget 与生产接线覆盖但未逐页原生截图；厅堂背景为 1672×941 WebP 内容、约 120 KiB，已由最终真机截图证实可解码。
- [x] **清洁度**：未提交 `.g.dart`、capture、日志或构建产物；未改 GDD/CLAUDE/PROGRESS、共享 strings/视觉路由/主菜单；提交信息为中文动宾结构。
- [x] **就绪信号**：最终恢复点提交使用 `[READY]`，提交后检查 worktree 干净；Claude 按 §8.2 Gate 审核，不直接接触 WIP。

## 9. 建议验证命令

执行时按项目当前测试数量和文件名复核后使用：

```bash
flutter test --no-pub test/features/sect/sect_screen_test.dart
flutter test --no-pub test/features/debug/visual_route_sect_test.dart
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed \
  lib/features/sect/presentation \
  test/features/sect \
  test/features/debug/visual_route_sect_test.dart
git diff --check
```

本任务是单 feature 表现层改动，默认不单独跑全量测试；在 Claude 合并审核后的 UI 批末统一跑 `flutter test --no-pub`。

## 10. 当前恢复点

- **状态**：实现与验证完成；本次恢复点提交后冻结为 `[READY]`，等待 Claude 按 §8.2 Gate 审核/合并。
- **最后完成**：生产 `SectScreen` 已接入宗门厅堂背景、宣纸标题栏、门派横匾、等级印、声望墨线、四枚木签 Tab、宗门告示、门派年表、祖师主位/三阶座次谱和山门地契；所有读取与写入继续走既有 provider/service。新增 `assets/scenes/sect_hall_main_v1.png`，由内置 imagegen 生成 1672×941 无人物厅堂图后转 WebP 内容、保留项目既有 `.png` 引用惯例，体积约 120 KiB。
- **下一步**：Claude 审核此 `[READY]` 分支；通过后由主窗口合并并在 UI 批末统一跑全量测试。本分支不主动 push、开 PR、合并或修改 `PROGRESS.md`。
- **已跑验证**：fresh worktree 经 build_runner 重生 124 outputs；最终组合验证 **98/98**（门派全目录 + 视觉路由 + 宣纸文字对比审计）；门派 widget + 视觉路由单独验证 **12/12**；`flutter analyze --no-pub` **0 issue**；`git diff --check` 通过。最终 `sect_screen_npc` 1280×720、1440×900 双视口截图位于 `build/visual_acceptance/ui_sect_hall_final/`，两份日志均无 overflow/exception/error。
- **阻塞项**：无。已知残留仅为 Windows 未实机、告示/年表/地契未逐页做原生截图；功能路径与响应式由 widget/业务测试覆盖。Claude `feat/baicao-duanhun-phase-b` 与本任务文件零重叠；本分支未碰 `shared/strings.dart`、视觉路由注册、`main_menu.dart`、数值、schema/saveVersion、GDD/CLAUDE/PROGRESS。
