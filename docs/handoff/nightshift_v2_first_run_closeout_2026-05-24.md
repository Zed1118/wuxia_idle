# Nightshift v2 通用工作流首跑 closeout(2026-05-24)

> 主 cwd HEAD `676be95`(本会话 4 commit `a38b84c → 676be95` 全 push origin/main)
> feat/p1_2_spec HEAD `a443905`(PR #6 自动更新)
> 模板源 `~/scripts/nightshift-tpl/` 同步 v2 verify 修补

## TL;DR

v2 通用挂机工作流首次在 wuxia_idle 生产试跑 5 task(T01-T05 spec/实装/MJ-prompt 混合)。**首跑 0/5 verify 通过(产出实际全 OK,verify 我写错)** → P0 修补 5 项后 **重跑 4/4 verify pass(0 API cost,走 idempotent 路径)**。产出已 push:T01 进 PR #6 + T02-T05 4 commit 进 main。

## 5 commit 产出

| # | task | commit | 内容 |
|---|---|---|---|
| T01 | spec PR #6 reviewer 4 项 fix | `a443905` (feat/p1_2_spec) | §3 数值阈值梯度 / §1 OUT 心魔引用 / §7 R5.6 schema 断言 / §2 composite index |
| T02 | BreakthroughBlocker 集成 character_panel | `a38b84c` (main) | 78 行 widget,wuSheng 阶心魔关未过拦升层,analyze 0 + 1302/1302 test pass |
| T03 | inner_demon 7 主题 enemy MJ v7 prompt | `d9f2a04` (main) | 138 行 doc,7 主题(贪/嗔/痴/慢/疑/空/真)+ MJ prompt + 沿 M4 #46 体例 |
| T04 | P3.4 门派事件 Phase 1 spec | `711caa3` (main) | 160 行,9 节体例沿 P1.2 spec,Q1-Q5 默认决议版 |
| T05 | P3.3 PVP Phase 1 spec | `676be95` (main) | 160 行,9 节,异步 PVP + 离线快照,留同步/大群战给 P5+ |

## v2 首跑成绩(两轮)

| 维度 | 首跑 | 第 1 轮重跑 | 第 2 轮重跑 |
|---|---|---|---|
| verify 通过 | 0/5 | 2/4(T02+T04) | **4/4 ✓** |
| 实跑时长 | 32min(含 5 task claude) | 5min(idempotent + 新 verify) | 5min |
| API cost | ~$5-10 | $0 | $0 |
| 饱满度(3h 窗) | **18%**(opus 实测 ×0.18 远快于 memory 锚点 ×0.3-0.5) | — | — |

## P0 修补 5 项(v2 模板 + wuxia_idle 双向同步)

| # | bug | 修法 |
|---|---|---|
| A1 | Claude 跳 worktree(T01 真因) | PROMPT 模板加 🚨 红线:严禁 cd 出 dispatcher 创建的 worktree |
| A2 | verify 路径写死必错(T02 character_panel_screen.dart 路径) | 新增 `verify_diff_contains` helper,verify 不写死路径改查 diff 命中 keyword |
| A3 | blacklist 误抓 `--no legendary` 防护段(T03) | `verify_blacklist_words` 跳 `--no/--`/`黑名单/blacklist/防护` 元描述行;MJ doc 性质特殊默认砍 blacklist 检查 |
| A4 | 节标记 grep `§N` 死写(T04) | 新增 `verify_section_titles` helper,查节标题文字不查符号 |
| A5 | 同 A4(T05) + spec 节体例差异(T05 用 `R5 测族` 不是 `测试`) | 同 A4 helper + 接受各 spec 自有体例 keyword |

## 沉淀 2 条 memory(已入 MEMORY.md index)

- `feedback_nightshift_v2_first_run_lessons.md` — 5 类 12 问题全档,下次写挂机 task 必查
- `feedback_opus_nightshift_speed_v2.md` — opus --print ×0.10-0.18 速度锚点 + 3h 窗容量算式(doc/spec 类 15-20 task / 实装类 6-8 / 混合 10-12)

## 余下挂账

**P1(下次 nightshift 前考虑)**:
- B3 `nightshift.conf` per-task `TASKS_T0X_BRANCH/WORKTREE` override(T01 类需切外部分支不撞强制隔离)
- C1 `morning.sh` 加段「fail_verify 但有 commit — 候选人工 review」(避免漏 cherry-pick)

**P2(白天挂机 / 预算可见)**:
- B2 dispatcher `--keep-alive-min N`(白天 N 小时挂机,sleep 后扫新 task)
- C2 dispatcher 解析 `cost_usd` 累计 SUMMARY(预算监控)
- B4 `nightshift-init.sh` 预检 `.nightshift/` git tracked 状态

**尾巴**:
- `.nightshift/` 在 wuxia_idle 是 git tracked,v2 init + verify 修补累积 D/M unstaged 山 → 待用户决:commit 进 main(v2 落库)vs `git rm --cached + .gitignore`(本地 dev tool)
- T01 prompt 修补:去掉外部 worktree 引用 + 加 A1 红线(避免下次再撞)

## 关键经验(刻碑)

**verify 严苛度 vs 产出质量是两件事**。5/5 产出 OK + 0/5 verify pass 是冷酷事实 — verify 是 gate 不是产出,verify 写错会让 morning.sh 漏掉真有用的 commit。**写 verify 必先 Phase 0 grep 路径 + 容忍 markdown 体例自然差异**。

**opus nightshift 比 spec 估时快 5-9×**。3h 窗 doc/spec 类塞 15-20 task 才饱满,5 task 只用 18%。

(详 `memory/feedback_nightshift_v2_first_run_lessons.md` + `memory/feedback_opus_nightshift_speed_v2.md`)
