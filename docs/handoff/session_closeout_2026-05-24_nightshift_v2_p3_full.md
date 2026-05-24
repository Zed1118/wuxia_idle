# 会话 closeout · 2026-05-24 nightshift v2 工具 + 1.0 P3 全推

> Milestone 性质放宽 ≤100 行(单会话 ~6h 推 1.0 整体 ~55% → ~75% · 15 commit · 4 nightshift batch + 1 audit)
> 范围:从 nightshift v2 P1 工具收尾(e4c4ff2)起至本会话末(9831780)· 接续上次 v2 首跑闭环(9fa98eb)
> main HEAD `9831780` · 1357 pass / 0 analyze · GDD v1.15 · ROADMAP_1_0.md v1.2

## TL;DR

单会话 4 波 nightshift opus --print 真生产 + 1 次 1.0 全谱 milestone 审查 + 桌面工作树彻底清理。**1.0 整体 65%→75%** · P3.3 PVP / P3.4 sect_event 双 100% 完整闭环 · v2 工具 C1 §6 真生产二次触发(T13+T16 fail_verify with commit 都救回)· memory sink A6+A7 反向声明 / ERE alternation 双 blind spot。

## 1. Commit 时间线(15 commit · `e4c4ff2 → 9831780`)

| 时段 | commit | 内容 |
|---|---|---|
| 下午 | `e4c4ff2` | nightshift v2 通用工作流落库(27 文件 + .gitignore SUMMARY/bak)|
| 下午 | `004cc37` | v2 P1 工具 B3 per-task BRANCH + C1 morning §6 + T01 A1 红线 |
| 下午 | `3a9720d` | PROGRESS 顶段 v2 工具收尾 |
| 晚 | `9733f2e` | T11 P3.3 PVP Phase 2 schema(PvpRecord/PvpSnapshot + StageType.pvp + numbers.yaml §13)|
| 晚 | `efc7604` | T12 P3.4 sect_event Batch 2.1 schema(Sect/SectEvent + composite index + numbers.yaml §14)|
| 晚 | `ecbca1e` | PROGRESS 顶段 T11+T12 |
| 晚 | `665a4d9` | T13 P3.3 Phase 3 logic(PvpStrategy + PvpService + NoopPvpSync + 17 测)|
| 晚 | `8c001b3` | T14 P3.4 Batch 2.2 service(SectEventService + decay + monthly_tick + 12 测)|
| 晚 | `4843bf1` + `0ac60a8` | PROGRESS T13+T14 + 砍回 100 |
| 晚 | `ff43d15` + `6673444` | **1.0 全谱 milestone 审查**(stage_audit doc 111 行) + 砍 PROGRESS 回 100 |
| 晚 | `41f89af` | T15 P3.3 Phase 4 UI + Phase 5 narrative stub + closeout |
| 晚 | `6229906` | T16 P3.4 Batch 2.3 战斗联动 + 2.4 UI/narrative + 2.5 R5 + closeout |
| 晚 | `61cf111` | main_menu_test InkWell 15→16 fix(T15+T16 双加合并)|
| 晚 | `9831780` | PROGRESS 顶段 T15+T16 收尾 · 1.0 跳 65→75% |

## 2. 1.0 跳档(全 phase 状态)

| Phase | 会话前 | 会话末 | 增量 |
|---|---|---|---|
| **P3.3 PVP 异步** | Phase 1 spec only | **100% 完整闭环** | +95% |
| **P3.4 sect_event** | Phase 1 spec only | **100% 完整闭环** | +95% |
| **1.0 整体** | ~55%(audit 前推 ~65%)| **~75%** | +20% |
| **核心可玩深度** | ~80% | **~90%** | +10% |

## 3. 工作流速度数据点(nightshift opus --print 实测)

| Batch | 类型 | spec 估 | nightshift wall | ratio |
|---|---|---|---|---|
| T11+T12 schema | greenfield Collection + yaml + R5 红线测 | 2.5h | 14min | ×0.09 |
| T13+T14 logic+service | strategy + service + sync mock + R5 | 4.5h | 18min | ×0.07 |
| T15+T16 UI+narrative+closeout 综合收尾 | UI 4 widget + narrative stub + R5 + closeout | 8h | 26min | ×0.05 |

→ nightshift opus 锚点稳定:**schema ×0.09 · logic ×0.07 · 收尾综合类 ×0.05** (远快于主对话 xhigh ×0.30-0.67)。**1h 窗实装类塞 4-6 task / 收尾综合类 4-6 task / schema 类 6-8 task**。

## 4. v2 工具 ROI 真生产兑现

- **C1 §6「失败但有产出」**:T13(attackPowerMultiplier 反向声明误抓)+ T16(ERE `\|` literal 误判)双 fail_verify 都成功 surface 候选,5min 人工 review cherry-pick 救回 ~1700 行真产出
- **idempotent claude-skip** + **B3 override** + **A1-A5 verify P0 修补**:首跑 P0 修补持续生效,4 task 0 重跑成本
- **morning.sh 自动战报** + **dry-run 自检**:0 launch 事故,4 batch wall ~75min 总
- **cherry-pick conflict 处理体例**:numbers.yaml 末位撞(T11+T12)/ main_menu.dart + strings.dart + main_menu_test 4 处撞(T15+T16)/ PROGRESS conflict 处理(`--ours` discard worktree 视图)— 经验固化,每次 ~5-10min

## 5. Memory sink 新增

- **A6 反向声明 blind spot**(`feedback_nightshift_v2_first_run_lessons`):全文 grep keyword 抓「0 引入 / 不引入」类注释假阳性(T13 实战)
- **A7 ERE alternation escape blind spot**(同 memory):`grep -qE "A\|B"` 在 ERE 中是 literal,`\|` 应在 BRE 用(T16 实战)
- 两条同根:**verify 字符串 grep 兜底语义级检查是 blind spot**,更根本是 R5 测族 explicit assertion

## 6. 桌面清理(挂账 #3 销账)

- 删 5 个 v2 首跑 worktree(wuxia-idle-T01..T05)+ 5 个 nightshift/T0X 分支
- 删 2 个 v2 schema worktree(wuxia-idle-T11/T12)+ 分支
- 删 2 个 v2 logic worktree(wuxia-idle-T13/T14)+ 分支
- 删 2 个 v2 UI worktree(wuxia-idle-T15/T16)+ 分支
- 删 nightshift-test-repo + nightshift-test-repo-T01(测试残留)
- 移 codex-overnight-workflow-v1.md → `~/scripts/codex-overnight/`(与 `~/scripts/nightshift-tpl/` 同级归档)
- **残余**:主 cwd + `wuxia_idle-p12-spec`(PR #6 OPEN 关联保留)

## 7. 关键挂账(下波考虑)

| # | 项 | 严重度 | 估时 |
|---|---|---|---|
| 1 | **PR #6 P1.2 spec merge → P1.2 Phase 2-5 全实装**(解 P1 100%)| ★★★ | ~45min nightshift |
| 2 | numbers_config 升 PvpDef/SectEventDef 强类型(还本日 raw map 技术债)| ★★ | ~30min 主对话 |
| 3 | **跨系统数值红线压测 audit**(P2.2 镜像 × P3.1 terrain × P3.2 阵型 × P3.3 ELO × P3.4 sect_level)| ★★ | ~2-3h |
| 4 | inner_demon 7 主题 enemy 立绘异步 MJ 出图(T03 prompt 已起)| ★ | 异步 |
| 5 | P4.1 §12.2 帮派门派 spec 起草(最大未启 1.0 模块)| ★ | ~1h spec |
| 6 | P3.3 narrative 完整 8-12 条(初战/连胜/晋级/降段)| ★ | ~1h 体力 |
| 7 | P3.4 tournament narrative 完整 5-8 条 | ★ | ~1h 体力 |
| 8 | sect_screen 真持久化 wire writeTxn(本会话 service pure-ish + provider 内做 mutation 假签)| ★ | ~30min |
| 9 | monthly_tick 真接 Riverpod 系统时间锚 | ★ | ~30min |

## 8. 不变量沿用

详 `docs/handoff/stage_audit_1_0_overall_2026-05-24.md`(本会话 milestone audit 全谱)+ ROADMAP_1_0.md v1.2 + GDD v1.15 § 12 决议表 12 项纳入 1.0。数值红线 §5.4(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备 ≤2000)持续未破。
