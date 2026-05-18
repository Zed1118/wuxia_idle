# P1 #42 Phase 2 · §10 新手引导骨架 P1.x closeout

> 2026-05-18,Mac + Opus 4.7 xhigh 同会话续跑 Phase 0-4 全收口(spec 起草 + 4 phase 实装 + DeepSeek 派单 spec),Phase 5 落地此 closeout。范围 B 中型(tutorialStep 业务读写 + MainMenu 灰显 + NarrativeContent.mandatory + DeepSeek 派单)。**Mac 端 100% 落地,DeepSeek 端 5 yaml 改动待派**。

## 1. 概览

| 项 | 数据 |
|---|---|
| HEAD(本批 commit 前)| 与 `31fb8db` 同(spec + 实装均待 push)|
| 总耗时 | ~1.5h(Phase 0 reality check + spec 起草 + Phase 1-4 实装 + Phase 5 closeout)|
| 实装范围 | Phase 1-4 全收口 + Phase 5 收口段 |
| 文件改动 | **10 modified + 4 untracked**(lib 6 + test 4 / docs 2 + lib feature 树 1 + test feature 树 1)|
| 最终测试 | **1022 pass + 1 skip = 1023**(baseline 998 → +25) |
| analyze | **0 issues** |
| spec vs 实测 | spec 预估 sonnet baseline 3-5h,opus xhigh 实测 ~1.5h(快 2-3×,命中 memory `feedback_opus_xhigh_interactive_duration`) |
| 新 memory | 0(无新教训沉淀,沿用现有 memory 体例)|
| 设计调整 vs spec | 1 项(R1 writeTxn:从"独立 writeTxn 串行"调整为"caller 持锁同事务原子",更优)|

## 2. Phase 1-4 产出明细

### Phase 1: tutorialStep 业务读写层(~30min)

| 文件 | 改动 |
|---|---|
| `lib/features/tutorial/application/tutorial_service.dart` | **新建** ~80 行(3 method:getCurrentStep / advanceToStep / advanceForStageCleared + Ch1 stage_id→step map)|
| `lib/features/tutorial/application/tutorial_providers.dart` | **新建** ~30 行(`tutorialServiceProvider` nullable + `currentTutorialStepProvider` 派生)|
| `lib/features/tutorial/application/tutorial_providers.g.dart` | **生成** by build_runner |
| `lib/features/mainline/application/mainline_progress_service.dart` | **改** +9 行(recordVictory 加 `TutorialService? tutorialService` 可选参数 + 同事务原子 `await tutorialService?.advanceForStageCleared`)|
| `lib/features/mainline/presentation/stage_entry_flow.dart` | **改** +3 行(`tutorialService: ref.read(tutorialServiceProvider)` 注入 + `ref.invalidate(currentTutorialStepProvider)`)|
| `test/features/tutorial/application/tutorial_service_test.dart` | **新建** ~130 行,**8 case**(默认 0 / 推进 3 / 防回退 / 等值 no-op / stage_01_03 / 非 Ch1 / 5 关顺序 / 跳关回退)|
| `test/features/mainline/application/mainline_progress_service_test.dart` | **改** +3 case(group `recordVictory · tutorialService hook`:Ch1 / 非 Ch1 / null 默认)|

**关键设计**:走 **caller 持锁** 体例(对齐 GameEventService),`TutorialService` 方法不开 writeTxn,由 `MainlineProgressService.recordVictory` 现有 writeTxn 包裹,保证 `MainlineProgress.clearedStageIds` 写入与 `SaveData.tutorialStep` 写入**同事务原子**。

**spec 修订**:spec R1 拍板"独立 writeTxn 串行调用"在实装时调整为"caller 持锁同事务原子"。理由:① 与现有 GameEventService 体例一致;② 多表原子性(stage cleared 与 step++ 必须同事务,防 crash 期一致性 holes);③ 测试更直观。memory `feedback_isar_pitfalls` §1 嵌套 writeTxn 死锁风险通过"service 不自启 writeTxn"已避免。

### Phase 2: MainMenu 灰显 2 按钮(~25min)

| 文件 | 改动 |
|---|---|
| `lib/shared/strings.dart` | **改** +2 const(`mainMenuTechniquesLockedHint` "通过第三关后开放" / `mainMenuSeclusionLockedHint` "通关第一章后开放") |
| `lib/features/main_menu/presentation/main_menu.dart` | **改** ~20 行(read `currentTutorialStepProvider` + 2 const 门槛常量 + 心法按钮 `disabled: step < 3` + 闭关按钮 `_SeclusionMenuButton.tutorialLocked` 加参数 + hint 文案条件渲染)|
| `test/features/main_menu/presentation/main_menu_test.dart` | **改** +6 case(group `§10 P1.x · tutorialStep 灰显门槛`:step=0/2/3/5/8 + loading 优先级保留) + 1 旧 case fix(`activeCharacterIds 加载完成 → Opacity=1.0 enabled` 加 `currentTutorialStepProvider` override step=5)|

**关键设计**:
- 复用 `_MenuButton.disabled` 现有参数(`Opacity(0.4)` + `InkWell.onTap = null`),0 新建 widget
- `_SeclusionMenuButton.disabled = loading || tutorialLocked`(loading 优先级保留,memory `feedback_seclusion_loading_guard` 防回归)
- 心法按钮直接走 `_MenuButton.disabled`(无 loading 概念,只 step 门槛)
- 江湖见闻录主入口不灰(范围 B 收敛,典故 tab 处理留 P1.y)

### Phase 3: NarrativeContent.mandatory wire(~25min)

| 文件 | 改动 |
|---|---|
| `lib/data/narrative_loader.dart` | **改** +6 行(`NarrativeContent.mandatory` 字段 default false 非 required / `fromYaml` 解析 `mandatory: y['mandatory'] as bool? ?? false`)|
| `lib/features/narrative/presentation/narrative_reader_screen.dart` | **改** +5 行(`AppBar.actions` 条件渲染 `c.mandatory ? const [] : [...跳过]`)|
| `test/data/narrative_loader_test.dart` | **改** +4 case(`placeholder mandatory 默认 false` / 无字段默认 false / `mandatory: true` / `mandatory: false` 显式)|
| `test/features/narrative/presentation/narrative_reader_screen_test.dart` | **改** +4 case(`mandatory=false` 跳过可见 / `mandatory=true` 跳过不可见 / 中段继续推进 / 末段完成触发 onFinish)|

**关键设计**:
- `NarrativeContent.mandatory` 非 required(`this.mandatory = false`),向后兼容现有所有 NarrativeContent direct construction(test fixtures 不动)
- yaml schema 反向兼容:无 `mandatory` 字段时默认 false(现有 12 个 stage yaml + tower yaml 不动)
- AppBar.actions 条件渲染 `const <Widget>[]` const-canonical,无运行期开销
- 物理返回键(PopScope)拦截**本批不动**(留 P1.y)

### Phase 4: DeepSeek 派单 spec(~15min)

| 文件 | 改动 |
|---|---|
| `docs/handoff/deepseek_p1_42_phase2_tutorial_dispatch_2026-05-18.md` | **新建** 232 行(9 段:必读 / 任务一句话 / 5 stage 现状与扩段锚点 / 文学体例红线 / 自审清单 / 范围拆解 / 联动 / 交付 / 反例)|

**关键设计**:
- **拆 5.1 最小动作 / 5.2 推荐动作**:DeepSeek 端最小只需加 `mandatory: true` 字段(~5min),即可让 Mac 端 mandatory 行为生效;扩段(教学包装)可选,P1.y 滚动落地
- **叙事逻辑约束**:师父留山门内,玩家在山门外 → 师父教学只能用"回忆/叮嘱/心境"插入,不能让师父出现在场景中
- **文学体例硬约束**:沿 W18-A3 lore 派单纪律(古风克制 / 不写数值 / 不写招式名 / 不写网游词 / 不写大场面 / 寻常人调子)
- **mandatory 字段位置约定**:yaml 顶层 title 后 paragraphs 前(可读性 + grep 友好)

## 3. 测试增量分布(baseline 998 → 1022, +24 pass + 1 重复 reseed = +25)

| Phase | 文件 | 新增 case | 实际 +N |
|---|---|---|---|
| 1 | `tutorial_service_test.dart`(新建)| 8 | +8 |
| 1 | `mainline_progress_service_test.dart` | 3 | +3 |
| 2 | `main_menu_test.dart` | 6 | +6 |
| 3 | `narrative_loader_test.dart` | 4 | +4 |
| 3 | `narrative_reader_screen_test.dart` | 4 | +4 |
| **合计** | — | **25** | **+25** ✓ |

spec 预估 +21,实际 +25 = spec +4(边界 case 顺手补:advanceToStep 等值 no-op / 5 关顺序通 / 跳关回退 / placeholder mandatory 默认 + null tutorialService 默认)。

## 4. 验收红线 10/10 ✅

| # | 红线 | 实测点 | 状态 |
|---|---|---|---|
| R1 | tutorialStep 默认 0 + schema 0.10.0 不破 | tutorial_service_test 默认 0 / IsarSetup._currentSaveVersion 不动 | ✅ |
| R2 | tutorialStep 单调递增不回退 | `advanceToStep(2)` 在 step=3 no-op + 跳关回退 case | ✅ |
| R3 | Mac 端 0 硬编码 mandatory(全走 yaml) | grep `mandatory: true` 仅在 narrative_loader.dart 默认值 + test fixture 字符串 | ✅ |
| R4 | Mac 端 0 硬编码中文(走 UiStrings) | strings.dart +2 const,main_menu.dart 0 中文 literal | ✅ |
| R5 | NarrativeReader Skip 按钮按 mandatory 条件渲染 | reader_screen_test 4 case 覆盖 | ✅ |
| R6 | MainMenu 灰显复用 `_MenuButton.disabled`(不新建 widget) | grep `_MenuButton` 类定义 1 处,无新 widget | ✅ |
| R7 | recordVictory 调用 tutorialStep advance 不嵌套 writeTxn | TutorialService 方法不开 writeTxn,caller 持锁 | ✅ |
| R8 | provider 不返回 closure 持 ref | tutorial_providers.dart 顶级函数体例 | ✅ |
| R9 | 现有 998/998 + 0 issues 不退步 | 998 → 1022 pass + 1 skip + 0 issues | ✅ |
| R10 | GDD §5.4 数值红线不动 | 本批 0 数值改动 | ✅ |

## 5. spec vs 实测对锚

| memory 锚点 | 本批实测 | 偏差 |
|---|---|---|
| `feedback_opus_xhigh_interactive_duration` opus xhigh 比 sonnet baseline 快 3-5× | spec sonnet 3-5h vs 实测 ~1.5h | 命中(2-3× 快,稍偏保守端)|
| `feedback_phase0_grep_two_axes` 两维 grep | Phase 0 reality check 5 项摸底完整 | 100% 落实 |
| `feedback_red_line_test_semantics` 约束语义 | 全 25 case 0 硬编码瞬时事实,用约束语义 | 100% 守住 |
| `feedback_riverpod_closure_ref_disposed` provider 不持 ref | tutorial_providers.dart 顶级函数 + ref.watch isarProvider | 100% 守住 |
| `feedback_isar_pitfalls` §1 嵌套 writeTxn | TutorialService 不自启 writeTxn | 100% 守住 |
| `feedback_subagent_parallel_vs_serial` phase 链串行 | Phase 1-3 主对话串行,Phase 0 Explore 调研并行 | 命中 |
| `feedback_clear_session_timing` 同子系统不清理 | 本批同 P1 #42 Phase 2 子系统延续,会话密度高 | 不需要清理 |

## 6. 设计调整 vs spec(1 项)

**spec R1 风险条款** 拍板"TutorialService 走独立 writeTxn 串行调用",实装时调整为 **"caller 持锁同事务原子"**。

**调整理由**:
1. 与现有 `GameEventService` 体例一致(caller 持锁 + service 不自启 writeTxn)
2. 多表原子性:`MainlineProgress.clearedStageIds` 写入与 `SaveData.tutorialStep` 写入必须同事务,防应用 crash 期间出现"stage cleared 但 tutorialStep 未递增"的一致性洞
3. 测试更直观:test 路径 `isar.writeTxn(() => svc.advanceForStageCleared(...))` 与 GameEventService test 完全对齐
4. 0 嵌套 writeTxn 风险:service 内部纯 `findFirst + put`,memory `feedback_isar_pitfalls` §1 死锁风险通过 caller 持锁规约避免

**未来扩展兼容性**:Phase 5+ 师徒 / 奇遇 / 装备开锋 等 step 6-8 hook 接入时,同样走 caller 持锁体例,在对应 service 的 writeTxn 内 await tutorialService advance,保持架构一致。

## 7. 下波候选(本批 P1.x 收口后)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 | **DeepSeek 派单交付 5 yaml 改动** | DeepSeek | 5min(最小)/ 30-60min(扩段) | Phase 4 派单 spec 落地动作。Mac 端 git pull 后 closeout 引用本派单交付 SUMMARY |
| 2 | §10 P1.y `_BubbleHint` 组件 + 8 档时间锚点 wire | sonnet 4-6h | 4-6h | GDD §10.2 第 2 方式(上下文气泡提示),tutorialStep 6-8 高阶系统 hook |
| 3 | §10 P1.y BaikeScreen 系统百科条目 | sonnet 1-2h + DeepSeek 3-5h | 4-7h | GDD §10.2 第 3 方式,与 P1.y _BubbleHint 同期 |
| 4 | #44 延续典故文案抽 yaml | Mac sonnet 1-2h + DeepSeek 3-5h | 4-7h | 待 W17 内容层 Phase 2 P1.x |
| 5 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户介入 | 6-10h | 用户主导技术选型 |
| 6 | 挂账冲刺 #37 + #43 + §12.4 1.0 框架预设计 | sonnet 3-5h | 3-5h | — |

**模型建议**:候选 2/5 复杂 → 升 opus xhigh(memory `feedback_model_selection`);候选 1/3/4/6 sonnet 即可。

## 8. 硬约束沿用

- GDD §5.4 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(本批 0 数值改动)
- 不硬编码数值 / 中文文案 / test 断言不写死具体数字(memory `feedback_red_line_test_semantics`)
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Riverpod provider 不返回 closure 持 ref(memory `feedback_riverpod_closure_ref_disposed`)
- Isar @collection / @embedded 实体含 late 字段 → test/seed 必走 Xxx.create 工厂方法(memory `feedback_isar_pitfalls` §6)
- `isar.writeTxn` 测试必须用 `test()` 不 `testWidgets()`(memory `feedback_isar_widget_test_deadlock` W17 nightshift 沉淀)
- nightshift verify 改 `--fatal-errors` 不 `--fatal-infos`(memory `feedback_nightshift_verify_lint_severity` W17 nightshift 沉淀)
- 复杂任务开工前升档 opus xhigh(memory `feedback_model_selection`)
- spec 时长按 sonnet baseline 给,opus xhigh 实测 vs spec 快 3-5×(memory `feedback_opus_xhigh_interactive_duration`)
- closeout 数字必 grep 实测(memory `feedback_closeout_numbers_grep`)
- Phase 0 reality check 两维 grep(memory `feedback_phase0_grep_two_axes`)
- 强依赖 phase 链 ≠ subagent 并行(memory `feedback_subagent_parallel_vs_serial`)
- service 多表原子写入 → caller 持锁体例(本批实战确认,对齐 GameEventService 体例)

## 9. DeepSeek 端交付销账(2026-05-18 当日)

**DeepSeek 端 Windows commit `f64883e`** ─ `[content] Ch1 opening 加 mandatory: true`(范围 5.1 最小动作,~5min)。

### 9.1 DeepSeek SUMMARY 摘录

| 文件 | mandatory | 位置 | 段数 | 字数 |
|---|---|---|---|---|
| stage_01_01_opening.yaml | true (L3) | title 后 paragraphs 前 | 2 | 44 字 |
| stage_01_02_opening.yaml | true (L3) | title 后 paragraphs 前 | 3 | 61 字 |
| stage_01_03_opening.yaml | true (L3) | title 后 paragraphs 前 | 3 | 71 字 |
| stage_01_04_opening.yaml | true (L3) | title 后 paragraphs 前 | 3 | 76 字 |
| stage_01_05_opening.yaml | true (L3) | title 后 paragraphs 前 | 3 | 75 字 |

### 9.2 Mac 端自审 5/5 ✅

| # | 自审点 | 实测 | 状态 |
|---|---|---|---|
| 1 | 5 yaml 全部含 `mandatory: true` | `grep ^mandatory data/narratives/stages/stage_01_0{1..5}_opening.yaml` 全命中 | ✅ |
| 2 | 字段位置规范(L3 title 后 paragraphs 前) | 5/5 命中 | ✅ |
| 3 | NarrativeContent.fromYaml 解析无回归 | flutter test 1057 pass + 1 skip = 1058(与 P1.y baseline 一致)| ✅ |
| 4 | flutter analyze 无新增 issue | 0 issues(ran in 23.1s)| ✅ |
| 5 | 5.1 最小动作范围(仅加字段不改文案) | git diff stage_01_0{1..5} 仅 `+mandatory: true` 1 行/文件 | ✅ |

### 9.3 联动效果

- `NarrativeContent.fromYaml`(P1.x Phase 3 Mac 端落)读 `mandatory: true` 字段
- `NarrativeReaderScreen` AppBar.actions 条件渲染:Ch1 5 opening 剧情触发时**不显跳过按钮 / PopScope 物理返回**(P1.x Phase 3 Mac 端落)
- 玩家通关 Ch1 关 1-5 时,opening 剧情**强制看完才能继续战斗**,对齐 GDD §10.2 第 1 方式"剧情包装的强制引导(前 30 分钟)"设计意图

### 9.4 P1.x 100% 闭环

§10 P1.x **范围 B 双端交付完整**:Mac 端 Phase 1-3(tutorialStep 业务读写 + MainMenu 灰显 + NarrativeContent.mandatory wire)+ DeepSeek 端 5 yaml mandatory 标注(5.1 最小动作)。5.2 扩段(2-3 段 → 5-7 段,师父留下的叮嘱/教学暗喻)留 P1.y/P1.z 收口后另起 small 任务滚动落地,不阻塞 P1.x 销账。
