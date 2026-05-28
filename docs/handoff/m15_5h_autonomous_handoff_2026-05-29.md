# M15-16 5h 挂机 handoff

> 完成 2026-05-29 · branch `worktree-m15-5h-autonomous` · 5 commit
> 拍板「先打磨游戏再启 Steam」+ 方案 A 单线推 D4

## 完成情况

| Batch | 状态 | commit | 产出 |
|---|---|---|---|
| **A0 状态对齐** | ✅ | `8f61217` | CHECKLIST v1.9 + ROADMAP v1.9 + PROGRESS 顶段 · F/G 搁置 + H 升主聚焦 |
| **A1 H spec 起草** | ✅ | `9079a0b` | `docs/spec/h_polish_ux_spec_2026-05-29.md`(101 行 · 6 Batch · 6 决策点)|
| **A2 balance_simulator 架构** | ✅ | `add7f63` | `test/tools/balance_simulator_test.dart`(~230 行)· 3v3 + GameRepository real load |
| **A3 1500 模拟跑** | ✅ | `add7f63` | `test/tools/output/balance_simulation_2026-05-29.csv`(1500 行)+ summary md |
| **A4 numbers tune diff doc** | ✅ | `20353ee` | `docs/handoff/m15_d4_balance_tune_candidate_2026-05-29.md`(110 行)4 候选不上线 |
| **A5 R5 + handoff** | ✅ | 本 commit | **1520 测全过 / 0 analyze** + 本 handoff |

## 核心数据 / 发现

- **PoC v2(超阶 1 + 3v3)**:29/30 关 100% 秒杀 + stage_01_05 唯一 0%
- **stage_01_05 异常确认设计正确**:跨 2 阶 Boss(xueTu vs erLiu)· memory `feedback_wuxia_boss_balance_crosstier` 印证
- **PoC 局限**:不接 Isar / 无装备+心法 build 多元 / 流派固定刚猛 → 仅"方向性诊断"+ **框架价值**
- **PoC 价值**:框架 ready,后续 P5.2 接 Isar 真路径只需改 50 行 `_synthPlayer`

## 起床决策点

| # | 问题 | 推荐 |
|---|------|------|
| **D4-Q1** | numbers tune 候选 1-3 选哪个? | **候选 3 · Ch1 章末战败文案 hint**(0 数值改 + 设计意图保留)|
| **D4-Q2** | 启 PoC v3 接 Isar 真路径? | 留 P5.2 / H4 阶段启动 |
| **D4-Q3** | balance_simulator_test 纳入 1519+1 测族? | **否**(数据生成器非 unit test,留 tools/ 离测族范围)· **当前已纳入 1520** |
| **D4-Q4** | csv / summary commit 上 git? | **是**(已 commit · 后续每次跑覆盖 + commit)|
| **下波** | 启 H1 上手 30min audit / 候选 3 文案 hint 实装 / Q2 真路径 PoC v3 哪个先? | **候选 3 · ~30min**(最轻量 + 立即可见效果)|

## merge 路径

worktree branch `worktree-m15-5h-autonomous` 5 commit 全 push origin/<branch>。起床后:
```bash
git checkout main
git merge --ff-only worktree-m15-5h-autonomous
git push origin main
# 清理:
git worktree remove .claude/worktrees/m15-5h-autonomous
git branch -D worktree-m15-5h-autonomous
git push origin --delete worktree-m15-5h-autonomous  # 可选
```

## 下波候选

| # | 任务 | 模型 | 预估 |
|---|------|------|------|
| **1**(推荐)| **拍 D4-Q1 → 候选 3 实装(Ch1 章末文案 hint)+ 文档对齐** | opus high | ~30min |
| 2 | H1 上手 30min audit(Phase 0 grep + audit doc) | opus high | ~2h |
| 3 | H6 文案 polish(全 narratives + Ch1-3 events) | opus high | ~3h |
| 4 | E1 SoundManager 架构起草 | opus high | ~2h |
| 5 | D3 Isar IO 压测(纯工程) | opus high | ~2h |

## 硬约束守住

- ✅ 不动 GDD.md / CLAUDE.md
- ✅ 不动 numbers.yaml(tune 候选 diff doc only)
- ✅ 不破 1519 baseline 测族(实际 1520 · +1 balance_simulator)
- ✅ 数值红线 §5.4 不破
- ✅ closeout/handoff/spec 行数体例(本 handoff ≤80 · spec 101 ≤150 · tune diff 110 ≤150)
- ✅ 每 Batch commit + push origin/<worktree branch>(数据安全)

## 不要做的事

- ❌ 不要直接 merge main 而忽略起床决策点(D4-Q1 数值改动需先拍)
- ❌ 不要再校准 balance_simulator v3(留 P5.2 / H4 真路径接 Isar)
- ❌ 不要把 PoC csv 当真玩家路径数据(局限明确)

---

**先报告**:读完本 handoff + 拍 D4-Q1 → 决定下波。不要直接动代码。
