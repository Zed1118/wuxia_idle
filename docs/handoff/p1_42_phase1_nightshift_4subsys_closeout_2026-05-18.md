# P1 #42 Phase 1 nightshift 4 子系统 widget test 加固 closeout

> 2026-05-18 凌晨 sonnet `claude --print` 8 task 串行 2h 5m 自动跑 + 早上 Mac Opus 4.7 收编(Phase A/B/C ~10min)+ deep review 7 文件 + 3 项优化(2 成 1 翻车)+ 教训沉淀 + push origin/main。

## 1. 概览

| 项 | 数据 |
|---|---|
| HEAD(完工) | `970dc0f` |
| 总耗时 | 凌晨 nightshift 2h 5m + 早上收编 ~10min + 优化 ~25min |
| nightshift 8 task | 6 completed + 2 skipped(verify `--fatal-infos` info lint) |
| 早上 Phase A 合 7 branch | T01-T07 各 1 merge commit |
| Phase B 修 lint | T04 5 lint(brace×4 + underscore×1) + T06 2 lint(const×2),1min 微改 |
| Phase C push | 18 commit(1 chore + 7 test + 2 fix + 7 merge + 1 progress) |
| 早上优化 | 3 文件,T05/T06 成功;T02 死锁回滚 + 沉淀 memory |
| 最终测试 | **998 / 998**(997 pass + 1 skip)持平 baseline |
| analyze | **0 issues** |
| 覆盖度增量 | 971 → 997(+26 new test,1 skip = T07 `recordLineageInherited` Phase 5+ 预期) |

## 2. nightshift 8 task 产出

| Task | 主题 | 状态 | 耗时 | 产出文件 | 新 test 数 |
|---|---|---|---|---|---|
| T01 | HomeFeedScreen 相对时间 4 档 | ✅ | 4m 56s | `test/features/home_feed/presentation/home_feed_screen_time_format_test.dart` | +4 testWidgets |
| T02 | HomeFeedScreen 快速领取按钮行为 | ✅ | 11m 50s | `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart` | +3 testWidgets |
| T03 | markAllFeedRead 边界 | ✅ | 2m 41s | `test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart` | +3 test |
| T04 | BaikeScreen 典故 tab 7 阶分组 + 段数 | ⚠️ skipped | 15m 49s | `test/features/baike/presentation/baike_screen_tier_group_test.dart` | +4 testWidgets(早上修后合) |
| T05 | BaikeScreen 导航 + 时间 override | ✅ | 10m 58s | `test/features/baike/presentation/baike_screen_navigation_test.dart` | +3 testWidgets |
| **T06** | **EquipmentDetailScreen `_LoreSection` 0→1【最高价值】** | ⚠️ skipped | 4m 58s | `test/features/inventory/presentation/equipment_detail_screen_lore_section_test.dart` | **+5 testWidgets**(早上修后合) |
| T07 | GameEventService #4 接口 + #9 路由 | ✅ | 5m 28s | `test/features/event/application/game_event_service_lineage_routing_edge_test.dart` | +4 test + 1 skip |
| T08 | SUMMARY 生成 | ✅ | ~5m | `.nightshift/SUMMARY.md`(T08 branch,未合) | — |

## 3. 早上 Phase A/B/C 收编

### Phase A:合并 7 branch(每个 --no-ff 独立 commit)

`6fad3b7` T01 → `8837db3` T02 → `6e2193a` T03 → `4e7600b` T04 → `72323fd` T05 → `df65d2d` T06 → `f1be6c6` T07

### Phase B:修 T04 / T06 lint(1min 微改各)

- T04 `7b9c651` fix:`baike_screen_tier_group_test.dart:102,120,136` `${t}${s}` → `$t$s`(brace×4) + `_goToLoreTab` → `goToLoreTab`(underscore×1)
- T06 `1314312` fix:`equipment_detail_screen_lore_section_test.dart:190,191` `LoreSegment(...)` → `const LoreSegment(...)`(const×2)

### Phase C:验证 + push + 清理 + PROGRESS

- 主 worktree `flutter analyze` 0 issues + `flutter test` 997 pass + 1 skip = 998 total
- `git push origin main`(17 nightshift commit + 1 PROGRESS commit `1b422b8`)
- 8 worktree(`../wuxia-idle-T0[1-8]`)+ 8 nightshift/T0X branch 全清
- PROGRESS.md 加 nightshift 销账段(98 行 < 100 红线)

## 4. 早上 deep review 7 test 文件评分

| Task | 断言语义 | fixture | 覆盖度 | 可维护性 | prompt 对齐 | 综合 |
|---|---|---|---|---|---|---|
| T01 时间 4 档 | 5 | 4 | 4 | 4 | 5 | 4.4 |
| T02 快速领取(原版) | 3 | 4 | 3 | 3 | 3 | 3.2 ⚠️ |
| T03 markAllFeedRead | 5 | 5 | 5 | 5 | 5 | **5.0** |
| T04 7 阶 + 段数 | 5 | 4 | 5 | 3 | 5 | 4.4 |
| T05 导航 + 时间(原版) | 4 | 4 | 4 | 3 | 4 | 3.8 ⚠️ |
| T06 `_LoreSection`(原版) | 5 | 4 | 5 | 4 | 5 | 4.6 |
| T07 #9 路由 | 5 | 5 | 5 | 5 | 5 | **5.0** |

**原批平均 4.34 / 5**。亮点:0 硬编码瞬时事实 / `tester.getTopLeft(...).dy` 顺序谓词 / `WuxiaColors.internalForce` 颜色常量 / `expect(eventType, isNot(...))` 反向断言 / T07 主动加 grandDisciple 第三枚举值兜底。

## 5. 优化(3 项,2 成 1 翻车)

### ✅ T05 A 简化(成功)

发现 `main_menu_test.dart` 已有「11 个菜单按钮 label 全部可见且顺序正确」完整覆盖 11 按钮 + 顺序。T05 A 的 InkWell≥11 是冗余 + 不严谨(InkWell 数 ≠ button 数)。

改为单点 sanity check「江湖见闻录」按钮可见 + 注释说明指向 main_menu_test 已覆盖全集。

### ✅ T06 A/C 解耦生产 id(成功)

原版用 `GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian')` 真实装备 — 以后 rename / 删除会断 test。

改为本地 `testDef('test_preset_only', presetLoreIds: const ['p_a','p_b','p_c'])` 工厂函数(沿 emptyDef 风格扩展可注入 presetLoreIds)。完全解耦,不依赖任何生产装备 id。

### ❌ T02 B 真 Isar spy(翻车回滚)

**意图**:原 T02 B "verify markAllFeedRead 被调用" 实际只验不抛 + Navigator,没真 spy。想加 `IsarSetup.init + writeTxn(unread) + tap → 查 isReadEqualTo(false).isEmpty` 真验证副作用。

**结果**:**widget test 死锁 10min timeout fail**。`tap` 触发 markAllFeedRead 内部第 2 次 `writeTxn` 与 testWidgets fake event loop 互相等待 cross-isolate deadlock。

**回滚 + 加注释**:回到原版 "isar=null no-op" 体例,注释说明指向 `home_feed_providers_mark_all_edge_test.dart`(T03 普通 test 不是 testWidgets)已用真 Isar + writeTxn 完整覆盖 3 case markAllFeedRead 副作用。

**memory 沉淀**:`feedback_isar_widget_test_deadlock`(testWidgets 内 writeTxn 死锁,真 Isar 副作用必须用 `test()` 单测)。

## 6. 新增 memory(本批 2 条)

1. **`feedback_nightshift_verify_lint_severity`**:nightshift verify.sh 用 `--fatal-infos` 让代码正确 task 被标 skipped(T04/T06 中招),下次改 `--fatal-errors` 或 prompt 内加 lint 自查步骤
2. **`feedback_isar_widget_test_deadlock`**(本批新):testWidgets 内 `isar.writeTxn` 与 Flutter event loop 死锁 10min,真 Isar 副作用必须用 `test()` 不 `testWidgets()`;widget test 端测 UI 时 isarProvider 默认 null 或同步注入 mock

## 7. 实测教训对锚点

| memory 锚点 | 本批实测 | 偏差 |
|---|---|---|
| `feedback_claude_print_task_duration` test 类 8-15min | T03 2m 41s / T07 5m 28s / T04 15m 49s | 范围内,T03 偏快 T04 偏慢 |
| nightshift 8 task ≈ 2-3h | 实测 2h 5m | 命中 |
| `feedback_red_line_test_semantics` 约束语义 | 全 7 task 0 硬编码 | 100% 守住 |
| `feedback_isar_pitfalls` Isar 易踩坑 | T02 优化撞 widget test 死锁新坑 | 补完整体系 |
| `feedback_layered_bugs` 修上层后下层暴露 | T02 spy 优化暴露 widget test + Isar 死锁 | 二次确认 |

## 8. 18+1 commit 一览(本批 push)

```
970dc0f test(nightshift 优化): T02/T05/T06 review 后 3 点改进
1b422b8 docs(progress): nightshift 4 子系统 widget test 加固 销账 + 教训沉淀
f1be6c6 merge(nightshift T07): #4 接口 + #9 路由 edge (+4 pass, +1 skip)
df65d2d merge(nightshift T06): _LoreSection 延续典故渲染 edge (0→1, +5)
72323fd merge(nightshift T05): BaikeScreen 导航 + 时间 override edge (+3)
4e7600b merge(nightshift T04): BaikeScreen 7 阶分组 + 段数 edge (+4)
6e2193a merge(nightshift T03): markAllFeedRead 边界 edge (+3)
8837db3 merge(nightshift T02): HomeFeedScreen 快速领取行为 edge (+3)
6fad3b7 merge(nightshift T01): HomeFeedScreen 时间 4 档 edge (+4)
1314312 fix(nightshift T06): dart analyze 2 info lint(const constructor×2)
7b9c651 fix(nightshift T04): dart analyze 5 info lint(brace×4 + underscore×1)
e447a53 test(nightshift T07): #4 接口 + #9 路由 edge
6235cf0 test(nightshift T06): _LoreSection 延续典故渲染 edge(0→1)
6be64ac test(nightshift T05): BaikeScreen MainMenu 导航 + 时间 override edge
7949121 test(nightshift T04): BaikeScreen 7 阶分组 + 段数 edge
b263610 test(nightshift T03): markAllFeedRead 边界 edge
a10ed9e test(nightshift T02): HomeFeedScreen 快速领取行为 edge
aed0717 test(nightshift T01): HomeFeedScreen 相对时间 4 档 edge
c0369da chore(nightshift): 2026-05-18 P1 #42 Phase 1 4 子系统 widget test 加固 8 task
```

## 9. 下波候选(同步 PROGRESS「下一步」段)

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 | §10 引导骨架 P1.x | sonnet 4-6h + DeepSeek 2-3h | 6-9h | SaveData.tutorialStep 接业务读写 / MainMenu disabled 灰显 / 剧情包装强制引导(DeepSeek 主线 Ch1)+ `_BubbleHint` 组件 + 8 档时间锚点 wire |
| 2 | #44 延续典故文案抽 yaml | Mac sonnet 1-2h + DeepSeek 3-5h | 4-7h | DeepSeek 端 `data/lore/<id>.yaml` 加 `continued_lore_pool` 字段池 + `LoreLoader.loadContinuedPool` 扩 + `GameEventService` 改读 yaml random pick |
| 3 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户介入 | 6-10h | AI 出图工具链(SD/Flux/Midjourney)+ 水墨 LoRA 训练数据集 + Mac 端拼图工具链;**用户主导技术选型讨论** |
| 4 | 挂账冲刺 #37 + #43 + §12.4 1.0 框架预设计 | sonnet | 3-5h | #37 6 orphan 决议补 / #43 高阶占位 / §12.4 节日系统级 1.0 框架前置 spec 起步 |

**模型建议**:候选 1/3 复杂 → 开工前升 opus xhigh(`feedback_model_selection`);候选 2/4 sonnet 即可。spec 时长按 sonnet baseline 给,opus 实测 3-5× 快(`feedback_opus_xhigh_interactive_duration`)。

## 10. 硬约束沿用

- GDD §5.4 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(不退步)
- 不硬编码数值 / 中文文案 / test 断言不写死具体数字(`feedback_red_line_test_semantics`)
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Riverpod provider 不返回 closure 持 ref(`feedback_riverpod_closure_ref_disposed`)
- Isar @collection / @embedded 实体含 late 字段 → test/seed 必走 Xxx.create 工厂方法(`feedback_isar_pitfalls` §6)
- **新**:`isar.writeTxn` 测试必须用 `test()` 不 `testWidgets()`(`feedback_isar_widget_test_deadlock` 本批新沉淀)
- nightshift verify 改 `--fatal-errors` 不 `--fatal-infos`(`feedback_nightshift_verify_lint_severity` 本批新沉淀,下次 nightshift 落实)
- 强依赖 phase 链 ≠ subagent 并行(`feedback_subagent_parallel_vs_serial`)
- 复杂任务开工前升档 opus xhigh(`feedback_model_selection`)
- closeout 数字必 grep 实测(`feedback_closeout_numbers_grep`)
- 旧 SUMMARY 数据 baseline 必重测(本批早上"修 55 fail"错推荐就是没校准 baseline 的活样本)
