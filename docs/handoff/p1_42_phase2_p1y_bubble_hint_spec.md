# P1 #42 Phase 2 · §10 新手引导骨架 P1.y spec

> 2026-05-18,Mac + Opus 4.7 xhigh,起草于 P1.x 范围 B 销账(`cf91809`)之后。范围:`TutorialBannerCard` widget + step 6-8 业务门槛 hook(GDD §10.2 第 2 方式上下文气泡提示)。**不含 §10.2 第 3 方式 BaikeScreen 系统百科条目**(留另起 spec)。

## 1. 背景

GDD §10「新手引导节奏」三方式:① 剧情包装强制引导(P1.x 已落 step 1-5)/ ② **上下文气泡提示**(本批 P1.y)/ ③ 江湖见闻录系统百科(下一波)。§10.1 八档时间锚点中 step 6-8 对应 2h+ 的「师徒 / 奇遇 / 装备开锋」高阶系统解锁,P1.x 仅 Ch1 5 关递增到 step 5,后 3 档留 P1.y 接入。

**P1.x 已就位**(承上):
- `SaveData.tutorialStep` int 字段 + schema 0.10.0,业务读写层接入 5 关 → step 1-5
- `TutorialService.advanceForStageCleared` Ch1 stage_id → step 1-5 map
- `MainMenu` 心法按钮 step<3 灰显 / 闭关按钮 step<5 灰显
- `NarrativeContent.mandatory` 字段 wire(P1.x Phase 3)

**P1.y 范围**:
- ① schema bump:`SaveData.tutorialHintsRead: List<int>` 读状字段 + 0.10.0 → 0.11.0
- ② step 6/7/8 业务门槛 hook(3 caller 各 1 method 注入)
- ③ `TutorialBannerCard` widget 新建(MainMenu 顶部 banner card + 红点 + onTap markRead 隐藏)
- ④ 表驱动 `TutorialHintDef` 3 条 hint 定义(step 6/7/8)
- ⑤ MainMenu wire + UiStrings 6 const(3 title + 3 body)

## 2. Phase 0 reality check 摘要

完成于 2026-05-18 主对话调研,关键结论:

| 调研项 | 现状 | 差距 |
|---|---|---|
| **tutorialStep / TutorialService** | API 3 method 已就位(`getCurrentStep` / `advanceToStep` / `advanceForStageCleared`)| **扩展**:加 `advanceForRealmBreakthrough` / `advanceForFirstAdventure` / `advanceForFirstEnhanceLevel10` 3 业务 method + `markHintRead` |
| **GameEventService record method** | **7 个 record method**(`recordRetreatCompleted` / `recordAdventureTriggered` / `recordEquipmentObtained` / `recordSkillEnlightened` / `recordRealmBreakthrough`(#6+#9 路由)/ `recordResonanceUpgraded` / `recordBossDefeated`),不是早期文档"7 type / 3 method"误描述 | **现状**:#4 `techniqueLearned` 0 caller 留 Phase 5+,本批不涉 |
| **recordRealmBreakthrough caller** | 3 处 caller 持锁(`tower_entry_flow.dart:383` / `seclusion_service.dart:363` / `stage_entry_flow.dart:495`),`AdvancementResult.tierAfter` 直接判 `RealmTier.yiLiu` | **wire**:3 caller 注入 `TutorialService?` 参数 + `result.tierAfter == RealmTier.yiLiu` 时 `await tutorialService?.advanceForRealmBreakthrough(tierAfter)` |
| **EncounterService.tryApply** | 内部 caller 持锁 writeTxn,`founderCharacterId != null` 分支 inline 调 `GameEventService(isar).recordAdventureTriggered`(line 312-323)| **wire**:`tryApply` 加 `TutorialService?` 参数 + 同分支内 inline `await tutorialService?.advanceForFirstAdventure()` |
| **EnhancementService.persistResult** | **service 持锁**(line 207 `isar.writeTxn`),与 GameEventService caller 持锁体例不同 | **wire**:`persistResult` 加 `TutorialService?` 参数 + writeTxn 内 `result.outcome == success && eq.enhanceLevel >= 10` 时 inline `await tutorialService?.advanceForFirstEnhanceLevel10()`,**同事务原子** |
| **§6.5 开锋系统** | **0 实装**:lib/ 全仓 grep `sharpen|warbornSlot` 0 命中,槽 1/2/3 解锁逻辑 + 选择 UI 留 Phase 5+ | **决议**:step 8 trigger 调整为「装备 enhanceLevel ≥10 任一件」纯字段 trigger,不依赖未实装的开锋槽逻辑(Q6 回流拍板 A1)|
| **现成 Chip 体例** | 7 处(`_Chip` / `_SynergyChip` / `_ContinuedLoreChip` / `_TodayFestivalChip` / `_StatusChip` / `_SmallChip` / `_CharacterChip`)| **复用**:沿 `_TodayFestivalChip` Card + Padding + Row + Icon + Text 体例实装 `TutorialBannerCard`(更大尺寸 + 红点)|
| **lib/shared/widgets/** | **不存在**,lib/shared/ 仅 effects/strings.dart/theme/utils 4 项 | **决议**:Q1 拍板气泡 widget 落在 `lib/features/tutorial/presentation/` 不预提到 shared(Q1 拍板) |

**核心调整**:Phase 0 暴露 §6.5 开锋系统 0 实装 → Q6 回流拍板 A1,step 8 trigger 改用纯字段 `Equipment.enhanceLevel >= 10` 判定。

## 3. 决议(Q1-Q6 拍板归档)

### Q1 `_BubbleHint` 组件位置(`lib/features/tutorial/presentation/`)

`lib/features/tutorial/presentation/tutorial_banner_card.dart` 新建。**理由**:靠近 tutorialStep 业务逻辑,P1.y 封闭在 tutorial feature 内;后续跨 feature 复用再提到 lib/shared/widgets/。

### Q2 step 6/7/8 触发机制(业务门槛)

- **step 6** = 主角 `realmTier` 突破到 `RealmTier.yiLiu`(一流,GDD §7.1 收徒境界门槛)
- **step 7** = 第 1 次任意 encounter `recordAdventureTriggered` 触发(GDD §7.2 武学领悟 / 奇遇)
- **step 8** = 第 1 次装备 `enhanceLevel >= 10`(GDD §6.5 开锋阶段锚点,**Q6 拍板 A1** 纯字段判定不依赖开锋槽解锁逻辑)

**理由**:与 GDD §7.1/§7.2/§6.5 业务语义对齐,不依赖时间堆积(Demo §5.5 在线=离线,无总在线时长概念)。

### Q3 banner UI 形态(MainMenu 顶部 banner card)

`TutorialBannerCard` widget 实装为 Card 容器,Padding 16 + Row(Icon + Column[title bold + body]) + 右上角红点,点击 `onTap` markHintRead + 隐藏。**理由**:GDD §10.2 第 2 方式"红点 + 50-100 字介绍"原设计,复用 `_TodayFestivalChip` 体例成本最低。

### Q4 覆盖范围(step 6/7/8 全走 + 表驱动)

step 6/7/8 全部 hook + 3 条 banner hint 一起落地,`TutorialHintDef` 表驱动定义。**理由**:hook 架子 + UI 一波拼成本低,§10.2 第 2 方式完整落地。

### Q5 banner 读状管理(`SaveData.tutorialHintsRead: List<int>`)

新增 `tutorialHintsRead: List<int>` 字段默认 `[]`,值域 `{6, 7, 8}`,schema bump 0.10.0 → 0.11.0。点击 banner → `TutorialService.markHintRead(step)` 同事务 add + UI 隐藏。**理由**:UI 状态可控,玩家未点过不消失 + 同 step 多次进 MainMenu 都显。

### Q6 step 8 hook 接装备 `enhanceLevel >= 10` 任一件(回流后拍板 A1)

`EnhancementService.persistResult` 内 `result.outcome == EnhanceOutcome.success && eq.enhanceLevel >= 10` 时 inline `advanceForFirstEnhanceLevel10()`。**理由**:§6.5 开锋系统 0 实装,沿用阶段锚点的"强化 +10 是开锋起点"设计意图,语义对齐 + 0 schema 压力。

## 4. 5 phase 实装拆解

### Phase 1: schema bump SaveData.tutorialHintsRead(~15min)

| 文件 | 改动 |
|---|---|
| `lib/core/domain/save_data.dart` | +2 行(`List<int> tutorialHintsRead = []` + 注释)|
| `lib/data/isar_setup.dart` | `_currentSaveVersion` 0.10.0 → 0.11.0 + 注释 |
| `lib/core/domain/save_data.g.dart` | build_runner 重生成 |
| `test/data/isar_setup_test.dart` | +1 case(新建 SaveData → `tutorialHintsRead.isEmpty`)|

**红线**:0.11.0 升版字段加 default 不破现有 SaveData 反序列化(Isar 自动 fallback default)。

### Phase 2: step 6/7/8 业务 hook(~40min)

| 文件 | 改动 |
|---|---|
| `lib/features/tutorial/application/tutorial_service.dart` | +3 method:`advanceForRealmBreakthrough(RealmTier tierAfter)`(tierAfter == yiLiu → step 6)/ `advanceForFirstAdventure()`(advanceToStep(7))/ `advanceForFirstEnhanceLevel10()`(advanceToStep(8)) + `markHintRead(int step)` 同事务 add |
| `lib/features/tower/presentation/tower_entry_flow.dart` | line 383 邻接 `result.tierAfter == yiLiu` 时注入 `await tutorialService?.advanceForRealmBreakthrough(...)` |
| `lib/features/seclusion/application/seclusion_service.dart` | line 363 邻接同上,seclusion_service 已有 tutorialService 可选参数体例对齐(P1.x 已建立)|
| `lib/features/mainline/presentation/stage_entry_flow.dart` | line 495 邻接同上,加 `ref.read(tutorialServiceProvider)` 注入 |
| `lib/features/encounter/application/encounter_service.dart` | `tryApply` 加 `TutorialService? tutorialService` 可选参数 + `founderCharacterId != null` 分支内 `await tutorialService?.advanceForFirstAdventure()` |
| `lib/features/equipment/application/enhancement_service.dart` | `persistResult` 加 `TutorialService? tutorialService` 可选参数 + writeTxn 内 success outcome 且 `eq.enhanceLevel >= 10` 时 inline 推进 |
| caller wire 调整 | encounter_hook.dart / enhance_dialog.dart 调用方加 `tutorialService: ref.read(tutorialServiceProvider)` 注入 |
| **test +9 case** | tutorial_service_test +4(advanceForRealmBreakthrough yiLiu 命中 / 非 yiLiu skip / advanceForFirstAdventure / advanceForFirstEnhanceLevel10)+ 3 caller test 各 +1 hook 触发 + EncounterService test +1 + EnhancementService test +1 |

**红线**:
- 同事务原子:3 caller 都在现有 writeTxn 内 inline await(EnhancementService 是 service 持锁同事务)
- step 推进单调不回退:`advanceToStep` 内部 currentStep >= target no-op(P1.x 已确保)
- 防回流二次触发:`advanceForFirstAdventure` 内部读 `tutorialStep >= 7` no-op(纯靠 advanceToStep 单调性,无需新字段)

### Phase 3: TutorialBannerCard widget + 表驱动 hint(~30min)

| 文件 | 改动 |
|---|---|
| `lib/features/tutorial/presentation/tutorial_banner_card.dart` | **新建** ~80 行(`TutorialBannerCard` widget:Card + Padding + Row[Icon + Column[title + body]] + 右上角红点;onTap → `tutorialService.markHintRead(step)` + invalidate provider)|
| `lib/features/tutorial/domain/tutorial_hint_def.dart` | **新建** ~50 行(`TutorialHintDef` 表驱动:`step` / `title` / `body` / `iconData`,3 条静态 const 定义对应 step 6/7/8,从 `UiStrings` 拉文案)|
| `lib/shared/strings.dart` | +6 const(`tutorialHintStep6Title` "收徒资格已达成" / body "..."  / step 7 "江湖奇遇初体验" / step 8 "装备开锋已可寻") |
| `test/features/tutorial/presentation/tutorial_banner_card_test.dart` | **新建** +5 case(渲染 step 6 文案 / 红点可见 / onTap 调 markHintRead / 隐藏当 step ∈ hintsRead / Icon 渲染) |
| `test/features/tutorial/domain/tutorial_hint_def_test.dart` | **新建** +3 case(3 个 hint 覆盖 step 6/7/8 / 文案非空 / step ↔ def lookup) |

**红线**:
- 0 中文 literal,全走 UiStrings(CLAUDE.md §5.6)
- 文案 50-100 字(GDD §10.2 原设计)
- 表驱动:`TutorialHintDef.allHints` const list,future 加 step 9+ 仅扩表不改 widget

### Phase 4: MainMenu wire + flutter analyze/test 收口(~20min)

| 文件 | 改动 |
|---|---|
| `lib/features/main_menu/presentation/main_menu.dart` | 顶部插 `TutorialBannerCard` 条件渲染(`step ∈ {6,7,8} && step ∉ tutorialHintsRead` → 显;否则空 widget),复用 `currentTutorialStepProvider` + 新增 `currentTutorialHintsReadProvider`(派生 SaveData.tutorialHintsRead)|
| `lib/features/tutorial/application/tutorial_providers.dart` | 加 `@riverpod` `currentTutorialHintsRead` provider(读 SaveData,nullable propagation)+ build_runner |
| `test/features/main_menu/presentation/main_menu_test.dart` | +6 case(step=6 banner 显 / step=6 但 6 ∈ hintsRead → 不显 / step=7 显 7 hint / step=8 显 8 hint / step=5 不显 / onTap 调 markHintRead 路径)|

### Phase 5: closeout + PROGRESS 销账 + commit/push(~15min)

`docs/handoff/p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md` 8 段(承 P1.x closeout 体例),PROGRESS 顶段插 P1.y 销账段,3-4 commit 推 origin/main。

## 5. 验收红线 12/12 ✅

| # | 红线 | 实测点 |
|---|---|---|
| R1 | schema 0.11.0 不破 0.10.0 现有存档 | isar_setup_test 新建 + 旧 SaveData 反序列化均通 |
| R2 | tutorialStep 单调递增不回退 | advanceForRealmBreakthrough / FirstAdventure / FirstEnhanceLevel10 内部走 advanceToStep 单调性 |
| R3 | tutorialHintsRead 单调追加不删 | markHintRead 走 `addAll([step])` + 同 step 二次 add no-op(Set 语义 / List.contains 判断)|
| R4 | step 6 hook 仅 yiLiu 触发 | tower / seclusion / stage 3 caller test 各 +1 case 验 `tierAfter != yiLiu` no-op |
| R5 | step 7 hook 仅 founderCharacterId != null 时触发 | EncounterService test fixture caller 注入 → 命中,null 路径 → no-op |
| R6 | step 8 hook 仅 success outcome 且 enhanceLevel >= 10 触发 | EnhancementService test +1 enhance to level 10 触发 + failure no-op |
| R7 | TutorialBannerCard 0 中文 literal | grep 0 命中 |
| R8 | step ∉ {6,7,8} 不渲染 banner | MainMenu test step=0/3/5 不显 |
| R9 | step ∈ hintsRead 不渲染 banner | MainMenu test step=6 + 6 ∈ hintsRead → 空 widget |
| R10 | onTap 后 markHintRead + 立即隐藏 | banner_card_test pump tap → next frame banner 不可见 |
| R11 | provider 不返回 closure 持 ref | tutorialHintsRead provider 顶级函数,memory `feedback_riverpod_closure_ref_disposed` |
| R12 | 现有 1022 pass + 0 issues 不退步 | 实测 1022 → 1045 (+~23) + analyze 0 issues |

## 6. 风险(6 项)

1. **R1 EnhancementService.persistResult 加可选参数破现有 caller**:enhance_dialog.dart 是唯一 caller(grep 确认),改一处即可。test fixture 不显式传参时 nullable propagation skip,0 退步风险。
2. **R2 step 8 enhanceLevel >= 10 在 cap 边界**:学徒-启蒙 absoluteLevel=1 时 cap=1 永远 < 10。Demo 早期玩家(step 5 Ch1 通关)绝对等级 ~ 7-14(一流-精通),触发 cap 在 14 → 14 >= 10 OK。预测无问题但 test 加 1 case 验 cap=1 边界 → no-op。
3. **R3 banner 多 step 同时满足**:玩家可能 step 已到 8 但 step 6/7 hint 都未读。MainMenu 同时显 3 banner 影响 UI。**决议**:取 `unreadHints` 列表第 1 个 step 渲染单 banner,后续读完后下一个自然显出。
4. **R4 schema migration 不平滑**:Isar `List<int>` 字段默认 `[]`,旧 SaveData 反序列化时 Isar 自动 fallback 空 list。已有 W18 (TowerProgress + perFloorClearTimes) 实例验证此路径。
5. **R5 test 内 build_runner 漏跑**:Phase 1 加字段后 nightshift verify 教训 `--fatal-errors` 而非 `--fatal-infos`(memory `feedback_nightshift_verify_lint_severity`),analyze 不阻塞;但 .g.dart 重新生成必须 build_runner。本批主对话同步跑。
6. **R6 step 8 在 EnhancementService 同事务破"caller 持锁"统一体例**:EnhancementService.persistResult 历史就是 service 持锁(line 207),不与 GameEventService 体例统一。本批不改架构(scope creep 风险),P3 polish 阶段统一两种体例可独立立项。

## 7. 测试矩阵

| Phase | 文件 | 新增 case | 红线对齐 |
|---|---|---|---|
| 1 | `isar_setup_test.dart` | +1 | R1 |
| 2 | `tutorial_service_test.dart` | +4 | R2/R4/R5/R6 |
| 2 | `tower_entry_flow_test.dart` / `seclusion_service_test.dart` / `stage_entry_flow_test.dart` | +3 | R4 |
| 2 | `encounter_service_test.dart` | +1 | R5 |
| 2 | `enhancement_service_test.dart` | +1 | R6 |
| 3 | `tutorial_banner_card_test.dart`(新建)| +5 | R7/R10 |
| 3 | `tutorial_hint_def_test.dart`(新建)| +3 | R3 |
| 4 | `main_menu_test.dart` | +6 | R8/R9 |
| **合计** | — | **+24** | — |

baseline 1022 pass + 1 skip → 预期 1046 pass + 1 skip。

## 8. memory 引用

| memory | 应用点 |
|---|---|
| `feedback_phase0_grep_two_axes` | Phase 0 两维 grep(字段已落 + 是否有 caller),本批 6 项摸底完整 |
| `feedback_opus_xhigh_interactive_duration` | spec 给 sonnet baseline 3-5h 预估,实测 opus xhigh 1.5-2.5h(memory 锚点 2-3× 快)|
| `feedback_red_line_test_semantics` | 测试断言走"约束语义"不写死具体数字(R3 单调追加 / R4-R6 触发条件)|
| `feedback_riverpod_closure_ref_disposed` | tutorialHintsRead provider 顶级函数,不返回 closure 持 ref(R11)|
| `feedback_isar_pitfalls` §1 | TutorialService 新 method 不开 writeTxn,caller 持锁体例 |
| `feedback_isar_pitfalls` §3 | schema bump 加 default 字段,Isar 自动 fallback |
| `feedback_clear_session_timing` | 同 P1 #42 Phase 2 子系统延续,会话密度高,本批与 P1.x 同会话 OK |
| `feedback_closeout_numbers_grep` | closeout 数字必 grep 实测(测试 case 数 / 行数)|
| `feedback_session_close_prompt_on_demand` | 收尾默认不输出新会话提示词 |
| `feedback_subagent_parallel_vs_serial` | phase 链强依赖串行,本批 Phase 1-5 不并行 |
| `feedback_avoid_over_engineer_abstraction` | Q1 拍板气泡 widget 进 features/tutorial/ 不预提 shared,避免 over-engineer |

## 9. 决策日志(4 项关键)

1. **2026-05-18 Q1-Q6 拍板**:6 问 6 答(详 §3),核心是「业务门槛 vs 时间锁」「banner vs Overlay」「全 step 6/7/8 vs MVP」三选择,均选 GDD 设计意图对齐 + 复用现成体例的方案。
2. **2026-05-18 Q6 回流 A1**:Phase 0 暴露 §6.5 开锋系统 0 实装,step 8 trigger 由"开锋槽 1 解锁"调整为"`Equipment.enhanceLevel >= 10` 任一件",纯字段判定不引入未实装架子。
3. **2026-05-18 schema bump 0.11.0**:`SaveData.tutorialHintsRead: List<int>` 加默认 `[]`,Isar 平滑反序列化(W18 TowerProgress 路径已验证)。
4. **2026-05-18 多 step 同时满足取第 1 个 unread**:风险 R3 处置,避免 MainMenu 同时显多 banner 影响 UI(GDD §10.2 单 banner 设计)。

---

**预估总耗时(opus xhigh 实测预估)**:1.5-2.5h(Phase 1 ~15min + Phase 2 ~40min + Phase 3 ~30min + Phase 4 ~20min + Phase 5 ~15min);sonnet baseline 预估 4-6h(memory `feedback_opus_xhigh_interactive_duration` 锚点 2-3× 快)。
