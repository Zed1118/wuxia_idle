# P1 #44 红线 case spec 起草 + 实装(默认 skip) closeout · 2026-05-19

> Mac + Opus 4.7(主对话 sonnet)续推进(2026-05-19 晚,~0.8h),起自 P1 #43 高阶占位补齐 closeout (HEAD `5d719e3`) 之后,2 commit 销账 P1 #44 Mac 端验收侧。终态 HEAD `3609851`。

## §1 起手会话状态

- HEAD `5d719e3`(P1 #43 高阶占位补齐 closeout 后)
- 测试 1117 pass + 1 skip + 0 issues / PROGRESS.md 80 行
- 用户拍板下波候选 ① Mac 端起草 35 件红线 case 验收 spec → 起草完成后续推:② 实装

## §2 2 commit 一览

| commit | 任务 | 文件改动 | +/- lines |
|---|---|---|---|
| `cb3429b` | spec 起草 + PROGRESS L10 挂回 | 2(1 新)| +146/-1 |
| `3609851` | 红线 case 实装 lore_loader_test L156- + PROGRESS L10 baseline 更新 | 2 | +134/-1 |

2 commit 全 push origin/main,工作树干净。

## §3 Phase 0 reality check

- LoreContent schema 字段名锁定:`continuedLoreObtainedPool` / `continuedLoreBossDefeatedPool`(P1 #44 Mac 端 wire 已落)
- `test/data/lore_loader_test.dart` L124 group「35 个真实 yaml 红线」已有,新红线 group 加到其后,体例对齐
- 35/35 件 yaml **0 件**当前已加 continued_lore 池(DeepSeek 端 0% 进度,grep 实测)
- 故新红线 case 默认 skip,DeepSeek 端文案落地后去 skip 启用

## §4 关键设计决策

### 5 strict + 1 soft red line 拆分

| # | 红线 | 体例 | 失败信号 |
|---|---|---|---|
| 1 | 漏件防护 | length ∈ [3, 5] | `<id>: obtained=N / bossDefeated=M` |
| 2 | 占位符白名单 | 集合 ⊆ {source, boss_name, stage_name} | `<id>/<池>/<idx>: 未约定占位符 {<var>}` |
| 3 | 占位符语义分池 | obtained 池仅 source / bossDefeated 池仅 boss_name+stage_name | `<id>/<池>/<idx>: 占位符 {<var>} 不属于此池` |
| 4 | 文案非空白 + 长度 ≤300 字 | trim 非空 + length 上限 | `<id>/<池>/<idx>: text 空白 / 超长 N 字` |
| 5 | 网游词黑名单 | 8 中文 + 2 英文 | `<id>/<池>/<idx>: 含网游词「<word>」` |
| 6 (soft) | 文风审计 warning | emoji / <10 字 / 同池重复 | `print` 不 fail |

### 实装体例:5 strict 合一 test + 1 soft 单 test

- 5 strict 合并到单一大 test() 扫一次 IO(35 件 yaml 遍历),内部 5 个约束块逐项 expect 带精确 reason(`<id> / <池名> / <条 idx>: <错因>`)
- 1 soft 单独 test() `print` warning 不 expect(`avoid_print` lint 用 `// ignore: avoid_print` 抑制)
- 两 case 默认 `skip: 'P1 #44 待 DeepSeek 35 件文案落地后启用,见 docs/handoff/p1_44_red_line_acceptance_spec.md'`

### 默认 skip 的理由 + 切换体例

- DeepSeek 端 35/35 全空状态下跑红线 1 立刻 35 fail,破 baseline
- DeepSeek 端文案到位后,Mac 端 `sed -i "/skip: 'P1 #44/d"` 一次性去 skip 即可启用(或手 Edit)
- 断言层均为**约束语义而非瞬时事实**(memory `feedback_red_line_test_semantics`),池量增减 ∈ [3,5] 不破红线;只要 DeepSeek 端不违例,池条数从 3 → 4 → 5 都安全

### `inInclusiveRange` matcher 复用既有体例

`flutter_test` 默认 matcher,本仓 3 处既有用法(damage_calculator / battle_engine / stage_battle_setup),体例对齐。

## §5 PROGRESS.md 状态变化

| 项目 | 起手 | 终态 |
|---|---|---|
| HEAD | `5d719e3` | `3609851` |
| 测试 | 1117 pass + 1 skip | **1117 pass + 3 skip(原 1 + 新 2)** |
| analyze | 0 issues | 0 issues |
| 总行数 | 80 | **80**(L10 #44 段 inline 扩文,守 ≤80 上限)|
| P1 #44 Mac 端 | wire 完成 / 红线 case 待办 | **wire + spec + 红线 case 实装全完成**(默认 skip 等 DeepSeek 落地)|
| P1 剩余 | 只 #44 | 只 #44(DeepSeek 端 35 件文案,异步)|

## §6 下波候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| ① | DeepSeek 35 件文案补齐 | DeepSeek 主导 | 3-5h | Windows 端推进,Mac 端等回收后 `sed -i` 去 skip 一键启用 |
| ② | 美术 PoC + 水墨 LoRA 调研 | **opus xhigh** + 用户主导 | 6-10h | M4 硬门槛,技术选型先讨论(SD/Flux/MJ + LoRA 数据策略 + Demo 35 装备首批节奏) |
| ③ | P1.2+ 章节扩展 / 心法相生 | opus | TBD | Phase 0 先扫 synergies.yaml 现状 + GDD §4.5 ≥ 5 组合现状 |

## §7 硬约束沿用

- GDD §5.4 数值红线 / §5.6 不硬编码 / §6.6 延续典故个性化
- Mac+Opus 不动 `data/lore/<id>.yaml` 文案(DeepSeek 领地,CLAUDE.md §8)
- DeepSeek 端不改 schema 字段名(`continued_lore_obtained` / `continued_lore_boss_defeated` 锁,改字段名 Mac wire break)
- 占位符花括号 `{var}` 形式,不识别 `{{var}}` / `<var>` / `${var}`
- 红线 case 失败信号精确到 yaml id + 池名 + 条 idx,便于 DeepSeek 端定位修
- 测试用 `test()` 不 `testWidgets()`(本批纯 yaml 解析层,无 Isar 副作用,memory `feedback_isar_widget_test_deadlock`)
- ListView widget test ≥ 7-8 行扩 viewport(本批无 widget test,但 memory `feedback_listview_widget_test_viewport` 沿用)
- closeout 数字必 grep 实测(本批 35/35 件 0 池实测 / `inInclusiveRange` 3 处既有 grep 实测,memory `feedback_closeout_numbers_grep`)
- Mac git 走代理需 `HTTP_PROXY=""` 前缀(hook 自动清)

## §8 closeout

本会话定位:**P1 #44 Mac 端验收侧二阶段** — spec 起草(0.3h)+ 红线 case 实装(0.5h)。2 commit 同子系统(test/data/lore_loader_test.dart + docs/handoff/spec)连贯推进,无技术债遗留。

Phase 0 三维 grep 实测:LoreContent schema / lore_loader_test L124 group / 35 件 yaml 0 池现状,memory `feedback_phase0_grep_two_axes` 实战再印证。`inInclusiveRange` matcher 既有 3 处用法,体例对齐零摩擦。memory `feedback_opus_xhigh_interactive_duration` 再添一例:主对话同 context 实测 ~0.8h vs 初估 1-2h(快 1.5×)。

**P1 #44 Mac 端全完成**,剩 DeepSeek 端 35 件文案是异步动作(Windows 端推进 3-5h),回收后 Mac 端 1 行 sed 去 skip 即启用红线 case 验收。剩余 P1 挂账归零(只 #44 DeepSeek 端文案,#44 Mac 端已闭环)。

下波 ① DeepSeek 派单 / ② 美术 PoC / ③ P1.2 章节扩展均跨子系统或新会话起点,**建议清理会话**;候选 ② 技术选型须先讨论且要升 opus xhigh,跨会话切入更合适。
