# P1 #42 Phase 2 · §10 新手引导骨架 P1.x spec

> 2026-05-18,Mac + Opus 4.7 xhigh,起草于 P1 #42 Phase 1 4 子系统(§9 主屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type 写入)全收口 + nightshift widget test 加固 100% 收口之后。范围 B 中型(Q3 拍板):tutorialStep 业务读写 + MainMenu 灰显 + NarrativeContent.mandatory + DeepSeek 主线 Ch1 师父教学剧情包装强制引导。**不含 _BubbleHint 组件**(留 P1.y 另起 spec)。

## 1. 背景

GDD §10「新手引导节奏」是 Demo 阶段最后未实装的玩家体验环节。§10.1 八档时间锚点(0-15min / 15-30min / ... / 5-8h)对应 8 个系统解锁里程碑;§10.2 三方式(剧情包装强制引导 / 上下文气泡提示 / 江湖见闻录百科)。本批 P1.x 范围 B 落地剧情包装 + 灯显两方式,不动气泡提示组件(P1.y 另起)。

**P1 #42 Phase 1 已就位**:
- `SaveData.tutorialStep` int 字段 @ `lib/core/domain/save_data.dart:46`,schema 0.10.0,**0 业务读写**(死字段留接口)
- GameEventService 7 type 写入 hook 已就位 + 6 caller 接入(Phase 2 一并落地)
- HomeFeedScreen / BaikeScreen / 延续典故 hook / `_LoreSection` 显化均已收口

**§10 P1.x 范围 B 实装清单**:
- ① tutorialStep 业务读写层(TutorialService + recordVictory hook 递增)
- ② MainMenu 3 按钮灰显门槛(闭关 / 心法 / 江湖见闻录 可选)
- ③ NarrativeContent.mandatory 字段 + yaml schema + NarrativeReaderScreen Skip 条件渲染
- ④ DeepSeek 派单:`stage_01_01~05_opening` 5 yaml 加 `mandatory: true` + 师父教学剧情包装扩段

## 2. Phase 0 reality check 摘要

完成于 2026-05-18 Explore 子代理 5 项调研,详见对话历史。关键结论:

| 调研项 | 现状 | 差距 |
|---|---|---|
| **tutorialStep** | `lib/core/domain/save_data.dart:46` int = 0,schema 0.10.0,**0 业务 caller**(仅 `save_data.g.dart` codegen 引用) | **0→1**:全新 service 层 |
| **MainMenu disabled 灰显** | `lib/features/main_menu/presentation/main_menu.dart:240-291` `_MenuButton.disabled` 参数已就位(Opacity 0.4 + InkWell onTap null)。唯一现用 caller = `_SeclusionMenuButton` 走 `loading` 灰显(`main_menu.dart:182,193`) | **扩展**:复用 `_MenuButton.disabled`,补 tutorialStep 门槛 |
| **NarrativeReader API** | `NarrativeContent` 4 字段(id/title/paragraphs/isPlaceholder)@ `lib/data/narrative_loader.dart:19-51`;Skip 按钮 = `NarrativeReaderScreen` AppBar actions @ `lib/features/narrative/presentation/narrative_reader_screen.dart:91-99`,无条件渲染 | **扩展**:加 `mandatory: bool` 字段 + `fromYaml` 解析 + Skip 按钮条件渲染 |
| **8 档时间锚点** | GDD §10.1 8 档跨全游戏生命周期;Ch1 现 5 关(stage_01_01~05),非"时间累计"概念 | **决议**:本批拍板 step 0→5 对应 5 关 cleared,后 3 档留 P1.y / 1.0 |
| **DeepSeek 派单** | 体例成熟(W18-A3 范例)。Ch1 5 stage 各有 opening + victory(stage_01_04+05 加 defeat),共 12 yaml 文件 | **派单**:5 个 opening yaml 加 mandatory + 扩段(师父教学剧情包装) |

**核心缺口**:GDD §10.1 8 档是「时间档」,游戏现无总在线/挂机累计时长概念。本批采用 **关卡进度递增** 替代(Q1 拍板理由:与 MainlineProgress + GameEventService 现有 hook 复用度高 + 不引入新 schema)。后 3 档(师徒 / 奇遇 / 装备开锋)留 P1.y / Ch2 实装。

## 3. 决议(Q1-Q4 拍板归档)

### Q1 tutorialStep 递增触发(关卡进度递增)

- **step 0**:初始,玩家未通任何 stage
- **step 1**:stage_01_01 cleared(战斗 + 境界 + 装备掉落已落)
- **step 2**:stage_01_02 cleared(装备强化 + 共鸣已被动展示)
- **step 3**:stage_01_03 cleared(心法主修已可见)
- **step 4**:stage_01_04 cleared(三流派克制已实战)
- **step 5**:stage_01_05 cleared(Ch1 通关,闭关 + 师徒等高阶系统解锁)

**理由(Q1 选项 1 拍板)**:与 MainlineProgress + GameEventService 现有 hook 复用度高,不引入新 schema(避免 SaveData.totalPlayMinutes Stopwatch wire),Demo 阶段单机 + 反主流(GDD §5.5 在线=离线)与"挂机时长"概念矛盾。后 3 档(step 6-8)留 P1.y 另起。

### Q2 强制引导剧情机制(yaml mandatory 字段)

- **NarrativeContent**:加 `final bool mandatory`(默认 false)
- **fromYaml**:解析 `mandatory: true` 字段,缺省 false 兼容现有 yaml
- **NarrativeReaderScreen**:Skip 按钮按 `widget.content.mandatory` 条件渲染(true → 隐藏,false → 显示)
- **DeepSeek 端**:Ch1 5 opening yaml 加 `mandatory: true`

**理由(Q2 选项 1 拍板)**:不硬编码中文 / mandatory 标注权归 DeepSeek,符合 CLAUDE.md §5.6 文案数据隔离原则 + Mac 端 0 硬编码。NarrativeReader Screen / Loader API 已稳定,加字段最小改动。

### Q3 范围(B 中型)

**含**:tutorialStep 业务读写 + MainMenu 灰显 + NarrativeContent.mandatory + DeepSeek 派单。

**不含**:`_BubbleHint` 组件(GDD §10.2 上下文气泡提示,留 P1.y 另起 spec)、江湖见闻录系统百科条目(GDD §10.2 第 3 方式,留 P1.y 与 DeepSeek 协作)、§10.3 「第一小时所有战斗轻松取胜」数值调校(留 P3 数值 polish)。

**理由(Q3 选项 1 拍板)**:Mac opus xhigh 预估 2-3h,DeepSeek 1-2h,总 3-5h 一波收口可控。三方式 1 + 2 + 3 联合实装范围 C 4-6h + 3-5h 跨端协作复杂度高,拆 P1.x / P1.y 滚动落地。

### Q4 DeepSeek 文案目录(复用 narratives/stages)

- **DeepSeek 派单交付**:`data/narratives/stages/stage_01_01_opening.yaml` ~ `stage_01_05_opening.yaml` 5 文件,各加 `mandatory: true` 字段 + 扩段(师父教学剧情包装,3-5 段 → 6-8 段)
- **Mac 端 NarrativeLoader**:无需新增 scan path,沿用 `lib/data/narrative_loader.dart:65-68` 现有 `_scanPaths`
- **Mac 端 stage_entry_flow**:无需改 narrativeOpeningId 拼装,沿用现有 stages.yaml `narrative_opening_id: stage_01_01_opening` 现有联结

**理由(Q4 选项 1 拍板)**:0 新建子目录,跨端最小改动,NarrativeLoader scan path 不动,测试 fixture 不动。

## 4. 5 phase 实装拆解

### Phase 1: tutorialStep 业务读写层(预估 sonnet baseline 1-1.5h / opus xhigh ~25-40min)

#### 文件改动

1. **`lib/features/tutorial/application/tutorial_service.dart`** [新建] ~80 行
   - `class TutorialService`(无状态,持 `Isar`)
   - `Future<int> getCurrentStep()` 读 SaveData.tutorialStep
   - `Future<void> advanceToStep(int targetStep)` 若 currentStep < targetStep 写入,否则 no-op(防回退 + 幂等)
   - `Future<void> recordStageCleared(String stageId)` 内部调 stage_01_0X → targetStep X 映射 + advanceToStep
   - **不持 ref**(memory `feedback_riverpod_closure_ref_disposed` 避免 closure 持 ref disposed)

2. **`lib/features/tutorial/application/tutorial_providers.dart`** [新建] ~50 行
   - `@riverpod TutorialService tutorialService(TutorialServiceRef ref)` 依赖 isarProvider
   - `@riverpod Future<int> currentTutorialStep(CurrentTutorialStepRef ref)` 派生 step,供 MainMenu 监听

3. **`lib/features/mainline/application/mainline_progress_service.dart`** [改] +6 行
   - `recordVictory` writeTxn 内追加:若 `stageId.startsWith('stage_01_')` → 调用 `TutorialService.recordStageCleared(stageId)`(在同 writeTxn 外或独立 service 调用,避免嵌套 writeTxn,memory `feedback_isar_pitfalls` §1)

4. **`lib/features/mainline/application/mainline_providers.dart`** [改] +2 行
   - 注入 TutorialService 参数 / provider 依赖

#### 测试

5. **`test/features/tutorial/application/tutorial_service_test.dart`** [新建] ~80 行,6 case
   - `getCurrentStep` 默认 0
   - `advanceToStep(3)` 从 0 写入 3
   - `advanceToStep(2)` 已在 step=3 时 no-op(幂等 + 防回退)
   - `recordStageCleared('stage_01_03')` → step 3
   - `recordStageCleared('stage_02_01')` → no-op(非 Ch1)
   - `recordStageCleared` 重复 cleared 已 step ≥ 3 → no-op

6. **`test/features/mainline/application/mainline_progress_service_test.dart`** [改] +2 case
   - 通 stage_01_01 → tutorialStep 1
   - 通 stage_02_01 → tutorialStep 不变(0)

### Phase 2: MainMenu 灰显 3 按钮(预估 sonnet baseline 45-60min / opus xhigh ~15-25min)

#### 文件改动

1. **`lib/features/main_menu/presentation/main_menu.dart`** [改] ~30 行
   - 在 `build` 顶部读 `currentTutorialStepProvider` 派生 step
   - **闭关按钮** `_SeclusionMenuButton` 改:`disabled: loading || step < 5`(注意:loading 也保留,避免引入 widget test 回归)
   - **心法面板按钮** 第 11 个 `_MenuButton` 改:`disabled: step < 3` + `onTap: step < 3 ? null : () => _push(...)`
   - **江湖见闻录按钮(可选)** 第 9 个 `_MenuButton`:Phase 1 已落地不灰显(BaikeScreen 见闻录 tab 永久可见),典故 tab step < 5 隐藏 → 留 Phase 2 子项内 BaikeScreen 内部处理 / 或本批不动只灰主入口
   - **拍板**:本批 Mac 端做 **闭关 + 心法** 2 按钮灰显,江湖见闻录主入口不灰(BaikeScreen 内典故 tab step < 5 隐藏走 P1.y / 不动)

2. **`lib/shared/strings.dart`** [改] +2 const
   - `mainMenuSeclusionLockedHint`(闭关 step < 5 时的弱提示文案 "通关第一章后开放")
   - `mainMenuTechniquesLockedHint`(心法 step < 3 时的弱提示文案 "通过第三关后开放")
   - **不硬编码中文**:走 UiStrings 集中管理(沿现有 strings.dart 体例)

#### 测试

3. **`test/features/main_menu/presentation/main_menu_test.dart`** [改] +6 case
   - step=0 → 闭关 disabled + 心法 disabled
   - step=2 → 闭关 disabled + 心法 disabled
   - step=3 → 心法 enabled + 闭关 disabled
   - step=5 → 心法 enabled + 闭关 enabled
   - step=8(未来值) → 全 enabled(向上兼容)
   - 闭关 step=5 时 + character loading → disabled(loading 优先级保留)

### Phase 3: NarrativeContent.mandatory wire(预估 sonnet baseline 1-1.5h / opus xhigh ~25-40min)

#### 文件改动

1. **`lib/data/narrative_loader.dart`** [改] +4 行
   - `NarrativeContent` 加 `final bool mandatory` 字段
   - constructor 加 `required this.mandatory` + `placeholder` factory 传 `mandatory: false`
   - `fromYaml` 加 `mandatory: y['mandatory'] as bool? ?? false`(向后兼容,缺省 false)

2. **`lib/features/narrative/presentation/narrative_reader_screen.dart`** [改] +6 行
   - AppBar `actions` 改为 `actions: c.mandatory ? [] : [TextButton(...跳过)]`
   - 物理返回键(WillPopScope / PopScope)按 mandatory 拦截(可选,本批不动避免范围扩张)

#### 测试

3. **`test/data/narrative_loader_test.dart`** [改] +3 case
   - 现有 yaml 无 mandatory 字段 → mandatory=false 默认
   - yaml `mandatory: true` → mandatory=true
   - placeholder → mandatory=false

4. **`test/features/narrative/presentation/narrative_reader_screen_test.dart`** [改] +4 case
   - mandatory=false → "跳过" 按钮可见
   - mandatory=true → "跳过" 按钮不可见
   - mandatory=true + 最后段 "完成" 按钮仍可点
   - mandatory=true + 中段 "继续" 仍可点

### Phase 4: DeepSeek 派单 spec(预估 ~15-20min,内容由 DeepSeek 写)

#### 文件改动

1. **`docs/handoff/deepseek_p1_42_phase2_tutorial_dispatch_2026-05-18.md`** [新建] ~150 行派单 spec
   - **任务**:`data/narratives/stages/stage_01_0{1..5}_opening.yaml` 5 个文件,各加 `mandatory: true` 字段 + 扩段(现 3-5 段 → 6-8 段)
   - **文学体例**:沿现有 chapter1 5 opening 范例(已落地,本批不动文学风格,只扩师父视角教学包装)
   - **教学包装锚点**:
     - stage_01_01_opening:战斗 + 装备掉落 引导(师父讲解"剑要握紧,胜负看招式倍率")
     - stage_01_02_opening:装备强化 + 共鸣 引导(师父讲"磨剑石可助器物精进")
     - stage_01_03_opening:心法主修 引导(师父讲"今日教你第一道运气法门")
     - stage_01_04_opening:三流派克制 引导(师父讲"刚猛克灵巧,灵巧克阴柔,阴柔克刚猛")
     - stage_01_05_opening:闭关 + 师徒 高阶系统预告(师父讲"通此关后,你便要开始闭关静修了")
   - **自审清单**:① yaml 加 mandatory + 顺序不动 ② 段数 6-8 范围 ③ 字数 50-80 字/段 ④ 文学气质对齐现有 5 opening ⑤ 不引入数值 / 招式名 / 网游词

### Phase 5: 收口 + closeout + push(预估 ~15-20min)

- `flutter analyze` 0 issues
- `flutter test` 全跑(预估 998 → 1015 左右,+17 case:Phase 1 +8 / Phase 2 +6 / Phase 3 +7,扣除重复)
- 写 `docs/handoff/p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md`
- PROGRESS.md 销账(顶段段落)
- `git push origin main`
- 任务 list 全 completed

## 5. 验收红线

| # | 红线 | 实测点 |
|---|---|---|
| R1 | tutorialStep 默认 0 + schema 0.10.0 不破 | TutorialService.getCurrentStep / IsarSetup._currentSaveVersion |
| R2 | tutorialStep 单调递增不回退 | `advanceToStep(2)` 在 step=3 时 no-op |
| R3 | Mac 端 0 硬编码 mandatory(全走 yaml) | grep `mandatory: true` 仅在 `data/narratives/stages/*.yaml` 出现 |
| R4 | Mac 端 0 硬编码中文(走 UiStrings) | grep `'通关'`、`'开放'` 等 → 不在 lib/ 出现 |
| R5 | NarrativeReader Skip 按钮按 mandatory 条件渲染 | mandatory=true → actions=[] |
| R6 | MainMenu 灰显复用 `_MenuButton.disabled`(不新建 widget) | grep `Opacity(opacity: 0.4` 仅在 `main_menu.dart` 现有位置 |
| R7 | recordVictory 调用 tutorialStep advance 不嵌套 writeTxn | grep `writeTxn` 嵌套 = 0(memory `feedback_isar_pitfalls` §1) |
| R8 | provider 不返回 closure 持 ref | `tutorial_providers.dart` 不出现闭包 ref(memory `feedback_riverpod_closure_ref_disposed`) |
| R9 | 现有 998/998 + 0 issues 不退步 | Phase 5 全跑 + 0 issues |
| R10 | GDD §5.4 数值红线不动 | 本批 0 数值改动 |

## 6. 风险

1. **R1 风险**:recordVictory writeTxn 内嵌套调 TutorialService.advance(若内部 writeTxn)→ Isar 死锁(memory `feedback_isar_pitfalls` §1)。**对策**:TutorialService.advance 接受 Isar 但不自启 writeTxn,由 caller(mainline_progress_service)外层 writeTxn 一次写完;或者 TutorialService.recordStageCleared 走独立 writeTxn(同 isar instance 串行 OK)+ mainline_progress_service 在 recordVictory writeTxn 完成 **后** 调 TutorialService。**拍板**:走独立 writeTxn 串行调用模式(简单 + 测试性好)。
2. **R2 风险**:NarrativeContent constructor 加 `required this.mandatory` 是 breaking change,会触发所有 NarrativeContent direct construction callsite 编译失败。**对策**:`mandatory` 默认 false → 改 `this.mandatory = false` 不 required,向后兼容。
3. **R3 风险**:Phase 4 DeepSeek 派单后,5 yaml 文件 mandatory: true 但 DeepSeek 未交付前 NarrativeReader 仍可 skip(false)。**对策**:Phase 4 先派单不阻塞 Mac 端 Phase 1-3 实装,Phase 5 收口前 DeepSeek 端落地 + Mac 端 git pull --rebase --autostash 同步即可。
4. **R4 风险**:MainMenu 灰显 step < 3 心法可能让从 Ch2 开始的 NewGame+ 玩家不便。**对策**:Demo 阶段无 NewGame+,P1.y / 1.0 实装时再加 SaveData.isOnboardingCompleted 跳过引导(GDD §10.4 快速开局)。
5. **R5 风险**:NarrativeReader 物理返回键(PopScope)未处理,玩家强引导剧情仍可 swipe back / Android back 跳过。**对策**:本批不动,P1.y 加 PopScope canPop=mandatory ? false : true。
6. **R6 风险**:Ch1 5 stage 5 step 后,step 6-8 高阶系统(师徒 / 奇遇 / 装备开锋)灰显门槛缺失,玩家通 Ch1 后 step=5 后续无引导。**对策**:本批接受残缺,P1.y 加 Ch2 / hook 触发 step 6-8 递增。

## 7. 测试矩阵

| Phase | 文件 | case 数 | 类型 |
|---|---|---|---|
| 1 | `tutorial_service_test.dart` | 6 | unit test |
| 1 | `mainline_progress_service_test.dart` | +2 | unit test |
| 2 | `main_menu_test.dart` | +6 | widget test |
| 3 | `narrative_loader_test.dart` | +3 | unit test |
| 3 | `narrative_reader_screen_test.dart` | +4 | widget test |
| **合计** | — | **+21 case** | — |

baseline 998 → 预估 ~1019(扣去重复 ~1015)+ 0 skip 增量。

## 8. memory 引用

| memory | 应用点 |
|---|---|
| `feedback_phase0_grep_two_axes` | Phase 0 reality check 已落实"字段已落 + 是否有 caller"两维 grep |
| `feedback_riverpod_closure_ref_disposed` | TutorialService 不返回 closure 持 ref,Provider 体例对齐 P1 #42 Phase 1 `markAllFeedRead` 顶级函数模式 |
| `feedback_isar_pitfalls` §1 | TutorialService.advance 不嵌套 writeTxn,由 caller 串行调用 |
| `feedback_red_line_test_semantics` | test 断言不写死 step 具体值,改用约束语义(`step >= 3` / `step != 0` / clamp 范围) |
| `feedback_model_selection` | 复杂任务 opus xhigh,spec 起草 ~30min(实测 vs sonnet baseline 3-5×快) |
| `feedback_opus_xhigh_interactive_duration` | spec 预估按 sonnet baseline 给(总 3-5h),opus xhigh 实测可 1.5-2.5h |
| `feedback_subagent_parallel_vs_serial` | Phase 1-5 强依赖串行,Phase 4 DeepSeek 派单可与 Mac 端 Phase 1-3 并行 |
| `feedback_clear_session_timing` | 同 P1 #42 Phase 2 子系统延续,本批不需要清理会话 |
| `feedback_session_close_prompt_on_demand` | 收尾建议按需输出新会话提示词 |
| `feedback_closeout_numbers_grep` | Phase 5 closeout 数字必 grep 实测,baseline 998 重测 |

## 9. 决策日志

| Q | 选项 | 拍板理由 |
|---|---|---|
| Q1 tutorialStep 递增 | 关卡进度递增(step 0→5 对应 Ch1 5 关) | 与 MainlineProgress + GameEventService hook 复用度高,无新 schema |
| Q2 mandatory 机制 | yaml 加 mandatory 字段 | 不硬编码,DeepSeek 控制权,NarrativeReader 最小改动 |
| Q3 范围 | B 中型(剧情包装 + 灯显两方式) | _BubbleHint 留 P1.y,GDD §10.2 三方式滚动落地 |
| Q4 DeepSeek 目录 | 复用 narratives/stages | 0 新建子目录,NarrativeLoader scan path 不动 |
| 自决 R1 writeTxn 嵌套 | TutorialService 走独立 writeTxn 串行 | 防 Isar 死锁(memory `feedback_isar_pitfalls` §1) |
| 自决 R2 NarrativeContent 字段默认 | `this.mandatory = false` 非 required | 向后兼容,避免 breaking change |
| 自决 江湖见闻录灰显 | 主入口不灰,典故 tab 不动 | 范围 B 收敛,典故 tab 处理留 P1.y |
| 自决 PopScope 物理返回拦截 | 本批不动 | 范围 B 收敛,留 P1.y |

---

**spec 落地完毕,等用户审 + 拍板进 Phase 1 实装**。
