# P1 #42 Phase 2 · §10 新手引导骨架 P1.y closeout

> 2026-05-18,Mac + Opus 4.7 xhigh 同会话续跑 spec 起草 + 4 phase 实装 + Phase 5 收口。GDD §10.2 第 2 方式(上下文气泡提示)+ §7.1/§7.2/§6.5 业务门槛 hook 全收口。**Mac 端 100% 落地,1057/1057 + 1 skip + analyze 0 issues**。

## 1. 概览

| 项 | 数据 |
|---|---|
| HEAD(本批 commit 前)| 与 `cf91809` 同(P1.x 之后)|
| 总耗时 | ~2h(Phase 0 reality check + spec 起草 + 4 phase 实装 + closeout)|
| 实装范围 | Phase 1-4 全收口 + Phase 5 收口段 |
| 文件改动 | **lib 8 modified + 3 new + 2 .g.dart 重生成** / **test 5 modified + 2 new** / docs 2 new(spec + closeout)|
| 最终测试 | **1057 pass + 1 skip = 1058**(baseline 1022 → +35 增量)|
| analyze | **0 issues** |
| spec vs 实测 | spec 预估 sonnet baseline 4-6h,opus xhigh 实测 ~2h(快 2-3×,命中 memory `feedback_opus_xhigh_interactive_duration` 锚点)|
| 新教训沉淀 | 1 项实战印证 `feedback_isar_widget_test_deadlock`(banner_card_test onTap 端到端 hung 2:23,改 service 层 markHintRead 5 case 覆盖)|

## 2. Phase 1-4 产出明细

### Phase 1: schema bump SaveData.tutorialHintsRead(~15min)

| 文件 | 改动 |
|---|---|
| `lib/core/domain/save_data.dart` | +2 行(`List<int> tutorialHintsRead = []` + 注释)|
| `lib/data/isar_setup.dart` | `_currentSaveVersion` 0.10.0 → 0.11.0 + 注释 |
| `lib/core/domain/save_data.g.dart` | build_runner 重生成(28 outputs)|
| `test/data/isar_setup_test.dart` | +1 case(P1.y `tutorialHintsRead` 写入 [6,7] → close → reopen 读出 [6,7])+ saveVersion 断言改 0.11.0 + tutorialHintsRead 默认空验证 |

### Phase 2: step 6/7/8 业务 hook(~40min)

| 文件 | 改动 |
|---|---|
| `lib/features/tutorial/application/tutorial_service.dart` | +4 method:`advanceForRealmBreakthrough(RealmTier tierAfter)` / `advanceForFirstAdventure()` / `advanceForFirstEnhanceLevel10()` / `markHintRead(int step)` + `getHintsRead()` |
| `lib/features/mainline/presentation/stage_entry_flow.dart` | line 488 邻接 `events.recordRealmBreakthrough` 后 inline `TutorialService(isar).advanceForRealmBreakthrough(...)`(仅 founder)|
| `lib/features/tower/presentation/tower_entry_flow.dart` | line 377 邻接同上 |
| `lib/features/seclusion/application/seclusion_service.dart` | line 362 邻接同上 + `LineageRole.founder` 守卫(disciple 升层不推 step 6)|
| `lib/features/encounter/application/encounter_service.dart` | `applyOutcome` 内 `founderCharacterId != null` 分支 inline `TutorialService(isar).advanceForFirstAdventure()` |
| `lib/features/equipment/application/enhancement_service.dart` | `persistResult` 内 success outcome 且 `eq.enhanceLevel >= 10` 时 inline `TutorialService(isar).advanceForFirstEnhanceLevel10()`,**同 service 持锁 writeTxn 内原子**|
| **test +16 case** | tutorial_service_test +10(4 advanceForXxx 全路径 + 5 markHintRead 单调追加/越界/二次/未 seed/getHintsRead)+ enhancement_persist_test +2(+10 触发 / +9 不触发)+ encounter_service_test +2(founderId 路径 / null 路径)+ seclusion_service_test +2(founder/disciple)|

**关键设计调整**(vs spec):沿 `GameEventService(isar)` inline 构造体例,所有 caller 都 `TutorialService(isar)` inline 构造(0 通过 provider 注入),0 caller 改 signature。

### Phase 3: TutorialBannerCard widget + 表驱动 hint(~30min)

| 文件 | 改动 |
|---|---|
| `lib/features/tutorial/domain/tutorial_hint_def.dart` | **新建** ~70 行(`TutorialHintDef` const-canonical 表 + step6/7/8 3 静态实例 + `all` list + `byStep` lookup)|
| `lib/features/tutorial/presentation/tutorial_banner_card.dart` | **新建** ~95 行(Material + InkWell + Stack[Container 卡片 + Positioned 红点],onTap → `TutorialService.markHintRead` + invalidate provider)|
| `lib/features/tutorial/application/tutorial_providers.dart` | +`@riverpod` `currentTutorialHintsRead` provider |
| `lib/shared/strings.dart` | +6 const(`tutorialHintStep6/7/8Title/Body`,文案 50-100 字 GDD §10.2)|
| **test +11 case** | tutorial_hint_def_test +6(覆盖 step 6/7/8 / 非空 / 长度 / byStep 命中 / 越界 null / const-canonical)+ tutorial_banner_card_test +5(3 step 渲染 + 红点 + InkWell 存在)|

**memory `feedback_isar_widget_test_deadlock` 实战印证**:banner_card_test 原计划加 1 个 onTap 端到端 case 走真 Isar(testWidgets 内 `isar.writeTxn`),实跑 hung 2:23 复刻死锁场景。处置:删该 case,markHintRead 业务路径由 tutorial_service_test 5 个 `test()` 单元 case 覆盖,banner_card_test 只验渲染 + InkWell 存在(onTap 路径在 main_menu_test 由 fake provider override 覆盖)。

### Phase 4: MainMenu wire(~25min)

| 文件 | 改动 |
|---|---|
| `lib/features/main_menu/presentation/main_menu.dart` | 加 2 import(TutorialHintDef / TutorialBannerCard)+ build() 读 `currentTutorialHintsReadProvider` + 派生 `_firstUnreadHint(step, hintsRead)`(R3 风险处置:取最早 step unread)+ 顶部条件渲染 `TutorialBannerCard` |
| **test +7 case** | main_menu_test +7(step=0 不显 / step=5 不显 / step=6 显 step6 / step=6+[6] 不显 / step=8 显 step6 / step=8+[6,7] 显 step8 / step=8+[6,7,8] 不显)|

## 3. 测试增量分布(baseline 1022 → 1057, +35)

| Phase | 文件 | 新增 case | 累计 |
|---|---|---|---|
| 1 | `isar_setup_test.dart` | +1 | 1023 |
| 2 | `tutorial_service_test.dart` | +10 | 1033 |
| 2 | `enhancement_persist_test.dart` | +2 | 1035 |
| 2 | `encounter_service_test.dart` | +2 | 1037 |
| 2 | `seclusion_service_test.dart` | +2 | 1039 |
| 3 | `tutorial_hint_def_test.dart`(新建)| +6 | 1045 |
| 3 | `tutorial_banner_card_test.dart`(新建)| +5 | 1050 |
| 4 | `main_menu_test.dart` | +7 | 1057 |
| **合计** | — | **+35** | — |

spec 预估 +24,实际 +35 = spec +11(边界 case 顺手补:advanceForRealmBreakthrough yiLiu 及以上各 tier 覆盖 / advanceForFirstAdventure 2 次 no-op / markHintRead 越界 5/9/0 / hint_def const-canonical 单例 / banner 渲染 3 step 全验 + 红点 / main_menu step=8 hintsRead 部分各 case)。

## 4. 验收红线 12/12 ✅

| # | 红线 | 实测点 | 状态 |
|---|---|---|---|
| R1 | schema 0.11.0 不破 0.10.0 现有存档 | isar_setup_test 新建 + 持久化双 case 通 | ✅ |
| R2 | tutorialStep 单调递增不回退 | tutorial_service_test advanceForXxx 全单调,advanceForFirstAdventure 2 次 no-op | ✅ |
| R3 | tutorialHintsRead 单调追加不删 | markHintRead 6/7/8 顺序 → [6,7,8] / 二次 no-op | ✅ |
| R4 | step 6 hook 仅 yiLiu 及以上触发 | yiLiu/jueDing/zongShi/wuSheng 命中 + xueTu/sanLiu/erLiu no-op | ✅ |
| R5 | step 7 hook 仅 founderCharacterId != null 时触发 | encounter_service_test founder/null 双 case | ✅ |
| R6 | step 8 hook 仅 success outcome 且 enhanceLevel >= 10 触发 | enhancement_persist_test +10 触发 / +9 不触发 | ✅ |
| R7 | TutorialBannerCard 0 中文 literal | grep 0 命中,文案全走 UiStrings | ✅ |
| R8 | step ∉ {6,7,8} 不渲染 banner | main_menu_test step=0/5 不显 | ✅ |
| R9 | step ∈ hintsRead 不渲染 banner | main_menu_test step=6 + [6] 不显 / step=8 + [6,7,8] 不显 | ✅ |
| R10 | onTap → markHintRead → 隐藏路径 | tutorial_service_test markHintRead 5 case + main_menu_test step=6 + [6] 不显 间接验隐藏 | ✅ |
| R11 | provider 不返回 closure 持 ref | `currentTutorialHintsRead` 顶级函数 ref.watch isarProvider | ✅ |
| R12 | 1022 pass + 0 issues 不退步 | 1022 → 1057 pass + 1 skip + 0 issues | ✅ |

## 5. spec vs 实测对锚

| memory 锚点 | 本批实测 | 偏差 |
|---|---|---|
| `feedback_opus_xhigh_interactive_duration` opus xhigh 比 sonnet baseline 快 3-5× | spec sonnet 4-6h vs 实测 ~2h | 命中(2-3× 快,稍偏保守端)|
| `feedback_phase0_grep_two_axes` 两维 grep | Phase 0 reality check 6 项摸底完整(暴露 §6.5 开锋 0 实装 → Q6 回流 A1)| 100% 落实 |
| `feedback_red_line_test_semantics` 约束语义 | 全 35 case 0 硬编码瞬时事实 | 100% 守住 |
| `feedback_isar_widget_test_deadlock` testWidgets 死锁 | banner_card_test onTap 端到端 hung 2:23 → 拆 service 层 5 case 覆盖 | 实战印证 1 次,处置成功 |
| `feedback_riverpod_closure_ref_disposed` provider 不持 ref | currentTutorialHintsRead 顶级函数 | 100% 守住 |
| `feedback_isar_pitfalls` §1 嵌套 writeTxn | 5 caller 全 caller 持锁 / service 持锁体例,0 嵌套 writeTxn | 100% 守住 |
| `feedback_clear_session_timing` 同子系统不清理 | 本批与 P1.x 同会话连开,密度高 OK | 不需要清理 |
| `feedback_closeout_numbers_grep` 数字 grep | 本 closeout 35 case 增量 grep 实测 | 100% |
| `feedback_subagent_parallel_vs_serial` phase 链串行 | Phase 1-5 主对话串行,Explore 调研并行(Phase 0)| 命中 |
| `feedback_avoid_over_engineer_abstraction` 抽 widget 不预提 shared | TutorialBannerCard 落 features/tutorial/presentation/ 不预提 shared/widgets/(Q1 拍板)| 命中 |

## 6. 设计调整 vs spec(2 项)

### 调整 1:caller 注入方式 — `TutorialService(isar)` inline 构造,不通过 provider

**spec 原案**:5 caller 加 `TutorialService? tutorialService` 可选参数 + caller 端 `ref.read(tutorialServiceProvider)` 注入。

**实装调整**:沿 `GameEventService(isar)` inline 体例,所有 caller 内部 `final tutorialSvc = TutorialService(isar);` 直接构造。

**理由**:
1. service 是无状态纯函数式 wrapper(纯 Isar query/write,0 mutable state),inline 构造无副作用
2. 0 改 caller signature(test fixture 不动)
3. 与 GameEventService caller 体例完全一致,降低代码风格碎片化
4. encounter_service.dart / enhancement_service.dart 不依赖 Riverpod ref(纯 service 层),inline 更干净

### 调整 2:step 8 trigger 改"装备 enhanceLevel ≥10 任一件"(Q6 回流 A1)

**spec 原案**:step 8 = 第 1 次开锋槽 1 解锁(GDD §6.5 强化 +10 解锁开锋一)。

**实装调整**:Phase 0 reality check 暴露 §6.5 开锋系统 0 实装(lib/ 全仓 grep `sharpen|warbornSlot` 0 命中),Q6 回流拍板 A1 改用"`Equipment.enhanceLevel >= 10`"纯字段判定。

**理由**:沿用 GDD §6.5 阶段锚点的"强化 +10 是开锋起点"设计意图,语义对齐 + 0 schema 压力 + 不引入未实装的开锋槽架子。

## 7. 下波候选(本批 P1.y 收口后)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 | **DeepSeek 派单交付 P1.x 5 yaml** | DeepSeek | 5min(最小)/ 30-60min(扩段) | 仍挂账,可同会话续做最小动作 |
| 2 | §10 P1.z BaikeScreen 系统百科条目(GDD §10.2 第 3 方式)| sonnet 1-2h + DeepSeek 3-5h | 4-7h | §10 第 3 方式收口,与本批 P1.y 同 GDD §10 闭环 |
| 3 | #44 延续典故文案抽 yaml | Mac sonnet 1-2h + DeepSeek 3-5h | 4-7h | 待 W17 内容层 |
| 4 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户介入 | 6-10h | 用户主导技术选型 |
| 5 | 挂账冲刺 #37 + #43 + §12.4 1.0 框架预设计 | sonnet 3-5h | 3-5h | — |

## 8. 硬约束沿用

- GDD §5.4 数值红线(本批 0 数值改动)
- 不硬编码数值 / 中文文案 / test 断言不写死具体数字(memory `feedback_red_line_test_semantics`)
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Riverpod provider 不返回 closure 持 ref(memory `feedback_riverpod_closure_ref_disposed`)
- Isar @collection / @embedded 实体含 late 字段 → test/seed 必走 Xxx.create 工厂方法(memory `feedback_isar_pitfalls` §6)
- **`isar.writeTxn` 测试必须用 `test()` 不 `testWidgets()`**(memory `feedback_isar_widget_test_deadlock`,**本批 banner_card onTap 端到端实战印证**)
- service 多表原子写入 → caller 持锁体例;无状态 wrapper service 沿 GameEventService inline `new Service(isar)` 体例(本批 5 caller 全用)
- 复杂任务开工前升档 opus xhigh(memory `feedback_model_selection`)
- spec 时长按 sonnet baseline 给,opus xhigh 实测 vs spec 快 3-5×(memory `feedback_opus_xhigh_interactive_duration` · 本批 P1.y 实测 ~2h vs spec 4-6h 命中 2-3× 快)
- closeout 数字必 grep 实测(memory `feedback_closeout_numbers_grep`)
- Phase 0 reality check 两维 grep(memory `feedback_phase0_grep_two_axes` · 本批暴露 §6.5 开锋 0 实装 → Q6 回流改 trigger)
