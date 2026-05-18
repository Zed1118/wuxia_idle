# P1 #42 Phase 2 · §10 P1.z 江湖见闻录·机制百科 closeout

> 2026-05-18,Mac + Opus 4.7 xhigh 同会话续跑 Phase 0 reality check + Q1-Q6 拍板 + spec 起草 + 方案 B 调整 + Phase 1-2 实装 + Phase 3 DeepSeek 派单 spec + Phase 4 收口。GDD §10.2 第 3 方式「永久可查,每条 200-500 字,详细机制说明」首批 8 条机制百科条目落地。**Mac 端 100% 落地,1076 pass + 1 skip + 0 issues**。

## 1. 概览

| 项 | 数据 |
|---|---|
| HEAD(本批 commit 前)| `5bcc6ab`(P1.z spec §12 方案 B 调整)|
| 总耗时 | ~2h(Phase 0 reality check + spec + 方案 B 发现/调整 + Phase 1-2 实装 + Phase 3 派单 + Phase 4 收口)|
| 实装范围 | Phase 1-4 全收口 + DeepSeek P3 派单 spec 就位 |
| 文件改动 | **lib 4 new + 2 modified + 2 .g.dart 重生成** / **test 3 new + 1 modified** / docs 2 new(spec 起草 + 调整 / 派单 spec / closeout)|
| 最终测试 | **1076 pass + 1 skip = 1077**(baseline 1057 → +19 增量)|
| analyze | **0 issues** |
| spec vs 实测 | spec sonnet baseline 3.5-5h vs opus xhigh 实测 ~2h(快 1.7-2.5×)|
| 新教训沉淀 | 1 项实战印证 `feedback_phase0_grep_two_axes`(Phase 0 漏看 `data/narratives/codex/` 18 md,补救后方案 B 撤销 yaml schema 改 md 复用)|

## 2. Phase 1-2 产出明细

### Phase 1: 数据层 + 领域层(~25min)

| 文件 | 改动 |
|---|---|
| `lib/features/codex/domain/codex_category.dart` | **新建** `CodexCategory` enum 8 值 + `step` extension(combat=1, enhancement=2, ..., advanced=8)|
| `lib/features/codex/domain/codex_index.dart` | **新建** `CodexIndex.entries`(8 条 `CodexIndexEntry` const list:realm/resonance/techniques_and_styles/three_styles_detail/retreat/master_disciple/encounter_system/combat_advanced)+ `byId(String)` 反查 |
| `lib/features/codex/domain/codex_entry.dart` | **新建** `CodexEntry`(id/step/title/category/paragraphs)+ `totalChars` getter + `fromMd(id, raw)`(首行 `# 标题` + 段间 `\n\s*\n` 切段)|
| `lib/data/codex_loader.dart` | **新建** `CodexLoader.loadAll()` 扫 `CodexIndex.entries` 8 条 id,graceful 跳过缺失/解析失败 |
| `lib/data/game_repository.dart` | 加 `Map<String, CodexEntry> codexEntries` 字段 + 构造参数 + `loadAllDefs` 调 `CodexLoader.loadAll` + `_enforceCodexRedLines`(id 登记 / step ∈ [1,8] / step 唯一 / paragraphs 非空 / 字数 [200,550])|
| **test +12 case** | codex_entry_test +8(单段/多段/未登记/缺标题/空标题/空 body/totalChars/8 档映射)+ codex_loader_test +4(8 全提供/档 8 缺/全缺/单条解析失败 graceful)|

### Phase 2: Application 层 + UI 层(~50min)

| 文件 | 改动 |
|---|---|
| `lib/features/codex/application/codex_providers.dart` | **新建** `@riverpod codexListItems` 返回 `List<CodexListItem>`(按 CodexIndex.entries 顺序,entry null = md 缺失)+ `@riverpod unlockedCodexCount` 派生 |
| `lib/features/codex/presentation/codex_tab.dart` | **新建** `CodexTab` widget:`ListView.separated` 渲染 header「已解锁 N / 8」+ 8 行 `_CodexListTile`,未达 step / 未加载 → 灰显 + `Icons.lock_outline` + 「待解锁」文案;已解锁 InkWell push detail |
| `lib/features/codex/presentation/codex_entry_detail.dart` | **新建** detail screen(AppBar title + ListView 渲染 paragraphs)|
| `lib/features/baike/presentation/baike_screen.dart` | 2 tab → 3 tab:`DefaultTabController(length: 3)` + TabBar 加 `Tab(text: UiStrings.baikeTabCodex)` + TabBarView 加 `CodexTab()` |
| `lib/shared/strings.dart` | +5 const(`baikeTabCodex='机制'` / `baikeCodexEmpty` / `codexLockedTitle='待解锁'` / `codexLockedBody='修行未至,机缘未到。'` / `codexUnlockedHint` 函数式)|
| **test +7 case** | codex_tab_test +5(全锁 step=0 / 部分解锁 step=5 / 全解锁 step=8 仅档 8 灰 / 点击 push detail / chip 渲染)+ codex_entry_detail_test +2(title / 多段渲染)+ baike_screen_test 改既存 1(2 tab → 3 tab)|

### Phase 3: DeepSeek 派单 spec(~15min)

| 文件 | 改动 |
|---|---|
| `docs/handoff/deepseek_p1_42_phase2_p1z_codex_dispatch_2026-05-18.md` | **新建** 派单 spec ~180 行 9 段:必读 / 任务一句话 / 文件要求 / 3 锚点(开锋+结晶+相生)/ 文学红线 / 范例 / 自审 / 交付流程 / 反例。**仅派 1 篇 md(combat_advanced.md)~30min** |

### Phase 4: 收口(~15min)

本 closeout + PROGRESS 顶段销账 + commit + push。

## 3. 测试增量分布(baseline 1057 → 1076, +19)

| Phase | 文件 | 新增 case | 累计 |
|---|---|---|---|
| 1 | `codex_entry_test.dart`(新建)| +8 | 1065 |
| 1 | `codex_loader_test.dart`(新建)| +4 | 1069 |
| 2 | `codex_tab_test.dart`(新建)| +5 | 1074 |
| 2 | `codex_entry_detail_test.dart`(新建)| +2 | 1076 |
| 2 | `baike_screen_test.dart`(改既存)| +0 改 1 | 1076 |
| **合计** | — | **+19** | — |

spec 方案 B 预估 +12-15,实际 +19 = spec +4(顺手补 `totalChars` getter test + `CodexCategory.step` 8 档全映射 + chip 渲染独立 case + detail title 渲染独立 case)。

## 4. 验收红线 R1-R12 ✅

| # | 红线 | 实测点 | 状态 |
|---|---|---|---|
| R1 | 8 yaml/md 全部加载到 ≥7 条(允许档 8 缺)| flutter test setUpAll 加载真实 md 7/8 OK | ✅ |
| R2 | step ∈ [1,8] 唯一 | `_enforceCodexRedLines` 抛 StateError 测覆盖间接验证 | ✅ |
| R3 | paragraphs 总字数 ∈ [200,550] | 18 md 现实字数 317-543 全过(`_enforceCodexRedLines` 范围校验)| ✅ |
| R4 | id 与文件名一致 | `CodexLoader.loadAll` 直接以 id 拼路径加载 | ✅ |
| R5 | category 与 step 映射一致 | `CodexCategory.step` extension test +1 case 全 8 档覆盖 | ✅ |
| R6 | 未达 step 灰显 + 锁图标 | codex_tab_test +3 case 覆盖 step=0/5/8 锁图标计数精确 | ✅ |
| R7 | 已解锁条目可 push detail | codex_tab_test 点击 push 测 | ✅ |
| R8 | provider 不返回 closure 持 ref | `codexListItems` / `unlockedCodexCount` 均顶级 @riverpod 函数(memory `feedback_riverpod_closure_ref_disposed`)| ✅ |
| R9 | 0 中文 literal | lib/features/codex/ 全树 grep 0 中文 literal(走 UiStrings)| ✅ |
| R10 | 1057 pass + 0 issues 不退步 | 1057 → 1076 pass + 1 skip + 0 issues | ✅ |
| R11 | BaikeScreen 3 tab AppBar / TabBar 渲染 | baike_screen_test 改既存 AppBar 标题 + 3 tab 渲染 | ✅ |
| R12 | MainMenu 永久可见(无解锁条件)| 既存 main_menu_test 0 改动 | ✅ |

## 5. spec vs 实测对锚

| memory 锚点 | 本批实测 | 偏差 |
|---|---|---|
| `feedback_opus_xhigh_interactive_duration` opus xhigh 比 sonnet baseline 快 3-5× | spec sonnet 3.5-5h vs 实测 ~2h | 命中(1.7-2.5× 快,偏保守端因 Phase 0 漏看返工)|
| `feedback_phase0_grep_two_axes` 两维 grep | **暴露漏看**:Phase 0 第 1 轮没扫 data/narratives/codex/,起完 spec 后跑第 2 轮才发现 18 md 存在 → 方案 B 调整 | 实战印证,补救成功 |
| `feedback_red_line_test_semantics` 约束语义 | 全 19 case 0 硬编码瞬时事实(锁图标计数随 step 派生) | 100% 守住 |
| `feedback_riverpod_closure_ref_disposed` provider 不持 ref | `codexListItemsProvider` / `unlockedCodexCountProvider` 顶级 @riverpod | 100% 守住 |
| `feedback_clear_session_timing` 同子系统不清理 | 本批与 P1.x DeepSeek 销账同会话连开,密度高 OK | 不需要清理 |
| `feedback_closeout_numbers_grep` 数字 grep | 本 closeout 19 case 增量 grep 实测(代码:`grep -c "test\(\|testWidgets\(" test/features/codex test/data/codex_loader_test.dart`)| 100% |
| `feedback_subagent_parallel_vs_serial` phase 链串行 | Phase 1-4 主对话串行,Phase 0 reality check 并行 grep(2 维) | 命中 |
| `feedback_avoid_over_engineer_abstraction` 抽 widget 不预提 shared | CodexTab / CodexEntryDetail 落 features/codex/presentation/,不预提 shared | 命中 |
| `feedback_session_close_prompt_on_demand` 收尾按需输出提示词 | 默认不输出 fenced code block,等用户通知 | 100% |

## 6. 设计调整 vs spec(1 大项 + 2 小项)

### 调整 1(大):方案 B 撤销 yaml schema → 复用 18 现成 md

**spec 原案**(spec §1-§11):建 `data/codex/` 顶层目录,新 yaml schema(id/step/title/category/paragraphs),DeepSeek 派单 3-5h 写 8 yaml。

**实装调整**(spec §12 方案 B):Phase 0 reality check 第 2 轮发现 `data/narratives/codex/` 已存 18 md(2026-05-10 早期 Phase 1 落,字数 317-543 字完美对齐 §10.2 200-500 字范围,7/8 档现成内容已有)。改用:
- 数据载体:复用 `data/narratives/codex/` 18 md
- 解析体例:首行 `# 标题` + 段间空行切段(`CodexEntry.fromMd`)
- DeepSeek 工作量:3-5h → ~30min(仅补 1 篇档 8)
- Mac 端工作量:1h50min → ~1h40min(数据层略简化)

**理由**:Phase 0 漏看的代价立即补救,避免双端 6-12h 重复劳动浪费 18 现成 md。memory `feedback_phase0_grep_two_axes` 实战印证一例。

### 调整 2(小):档 2 强化+共鸣 → 复用 `resonance.md`

**spec 原案**(§12.1 Q5b 拍板):strengthening.md(329 字)+ resonance.md(423 字)二选一 / 合并。

**实装调整**:CodexIndex.entries 收 resonance(共鸣度·人剑合一,423 字最贴 200-500 范围)收档 2;strengthening 留 P2 扩段。

### 调整 3(小):CodexIndexEntry 数据类替代 Record 元组

**spec 原案**(§12.4 预览):`List<({String id, int step, CodexCategory category})>` Dart 3 record。

**实装调整**:`class CodexIndexEntry`(id + category,step 由 category.step 派生)。

**理由**:派生 step 一处定义(CodexCategory.step extension)避免 record 中 step/category 数据冗余风险;`byId(String) → CodexIndexEntry?` API 比 record 反查更易读。

## 7. 下波候选(本批 P1.z 收口后)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 | **DeepSeek P1.z 派单交付**(combat_advanced.md 档 8 补)| DeepSeek | ~30min | 收口 §10.1 8 档 100% |
| 2 | P1.z P2 扩段(strengthening / equipment_tiers / weapon_forging 等 10 现成 md 入库,扩展 codex 条目超 §10.1 8 档)| Mac sonnet 1-2h + DeepSeek 0 | 1-2h | 拓宽机制百科,P2 滚动 |
| 3 | #44 延续典故文案抽 yaml | Mac sonnet 1-2h + DeepSeek 3-5h | 4-7h | 待 W17 内容层 |
| 4 | §10 P1.x 5.2 扩段(stage_01_0{1..5} opening 2-3 段 → 5-7 段)| DeepSeek 30-60min | 30-60min | P1.x P2 滚动 |
| 5 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户介入 6-10h | 6-10h | 用户主导技术选型 |
| 6 | 挂账冲刺 #37 + #43 + §12.4 1.0 框架预设计 | sonnet 3-5h | 3-5h | — |

**模型建议**:候选 5 复杂 → 升 opus xhigh;候选 1/2/3/4/6 sonnet 即可。

## 8. 硬约束沿用

- GDD §5.4 数值红线(本批 0 数值改动)
- 不硬编码数值 / 中文文案 / test 断言不写死具体数字(memory `feedback_red_line_test_semantics`)
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md
- Riverpod provider 不返回 closure 持 ref(memory `feedback_riverpod_closure_ref_disposed`)
- service 多 caller inline `new XxxService(isar)` 体例(本批 0 service,纯 loader + domain)
- Isar 测试用 test() 不 testWidgets()(本批 0 Isar 写入,N/A)
- ListView widget test 需 `tester.binding.setSurfaceSize(Size(800, 2000))` 扩 viewport(本批新沉淀,后续 ≥ 8 行 list widget test 体例)
- closeout 数字必 grep 实测(memory `feedback_closeout_numbers_grep`)
- Phase 0 reality check 两维 grep(memory `feedback_phase0_grep_two_axes` · **本批 Phase 0 实战漏看 + 第 2 轮补救印证**)
- 复杂任务开工前升档 opus xhigh(已升)
- spec 时长按 sonnet baseline 给,opus xhigh 实测 vs spec 快 3-5×(memory `feedback_opus_xhigh_interactive_duration` · 本批第 7 次实战锚点 ~2h vs 3.5-5h)

## 9. §10 闭环里程碑

**§10 三种引导方式全闭环(2026-05-18 当日)**:

| 方式 | 实装 | closeout |
|---|---|---|
| 1️⃣ 剧情包装的强制引导 | P1.x Mac Phase 1-3 + DeepSeek 5 yaml mandatory | `p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md` §9 |
| 2️⃣ 上下文气泡提示 | P1.y TutorialBannerCard + step 6-8 hook + tutorialHintsRead | `p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md` |
| 3️⃣ 江湖见闻录百科 | P1.z CodexTab + 8 条 md(7 现成 + 1 待派) | 本 closeout |

**P1 #42 100% 销账**(Phase 1 §9 主屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type + Phase 2 P1.x/y/z 三种引导方式)。剩余 §10 收口动作:DeepSeek 补 combat_advanced.md(~30min)→ 8/8 满收口。
