# P1 #42 Phase 2 §10 P1.z + P2 同日会话 · 工作流反思

> 2026-05-18,Mac + Opus 4.7。**触发**:P2 扩段后期用户反馈"工作速度变慢"。复盘后定位非任务复杂亦非模型慢,而是 3 个工作流杠杆没用好。本文留 repo 可追溯;跨会话/跨项目复用见 memory `feedback_workflow_speed_levers`。

## 1. 实测数据

| 项 | 值 |
|---|---|
| 任务 | P1.z P2 扩段(CodexCategory.lore + entries 8→19 + UI 分段) |
| 复杂度 | 非复杂任务(非算法/schema/RLS/并发) |
| 模型 | opus 4.7 主对话 |
| 总时长 | ~55min(spec 1.5-2.25h 快 ~2×,memory 第 8 次锚点) |
| 浪费占比 | **~20min / 55min = ~36%** |

## 2. 3 个工作流 lever 浪费分布

### Lever 1 · 全量 flutter test 跑勤(浪费 ~6min)

跑了 4 次全量 ~2min/次:
- git pull 后验 baseline ✅ 必要
- Phase 1+2 后看 break 量 ❌ 多余(局部 ~10s 够)
- Phase 3 后验全绿 ✅ 必要
- build_runner 后再验 ❌ 多余(codegen 没改函数签名)

**纪律**:feature-local 改动先跑局部 `flutter test test/features/X/`,最后 1 次全量验集成。

### Lever 2 · spec Phase 0 漏分布矩阵(浪费 ~5min)

P1.z P2 spec 写 `_enforceCodexRedLines` "step ≤ 2/档(1 首批 + 1 补充阅读)",未数 A 组 4 条挂的 step 分布:
- combat(档 1)挂 1 条 ✅
- **enhancement(档 2)挂 2 条**(strengthening + weapon_forging)→ + P1.z resonance = 3 条 ❌
- techniques(档 3)挂 1 条 ✅

setUpAll 抛 StateError → 227 cascade fail → spec 改红线设计返工。Phase 0 多 1 分钟数分布即可避免。

**纪律**:reality check 维度 D = 分布矩阵(每分类实际条目数),A/B/C 三维之后必加(memory `feedback_phase0_grep_two_axes` 升级)。

### Lever 3 · closeout 体量超扩段配额(浪费 ~10min)

P1.z 主 closeout §10 初稿 76 行(7 子段含 hardcode 自检 / 详细产出明细 / 改动表展开 / 19 条归属表),后压缩到 46 行(6 子段,-40%)。

**纪律**:closeout 体量按里程碑分级:
- **大里程碑**(P1.x 主线 / P0 重平衡)→ 150-200 行,含验收红线 / 闭环里程碑
- **扩段/补丁**(P2 / 子主题滚动)→ 30-50 行内,核心改动 + 数字 + 教训 + 下波

## 3. vs spec 2 项设计调整(代码层教训,已留 §10.4)

| # | spec 写 | 实测改 | 根因 |
|---|---|---|---|
| 1 | 红线 step ≤ 2/档 | step 唯一性废除 | Phase 0 漏分布(Lever 2) |
| 2 | chip 分子 max 12 > 分母 8 | 改"档数" `step.clamp(0,8)` | spec 起草偷懒未做数学验证,玩家视角缺位 |

## 4. 沉淀产出

| 产出 | 位置 |
|---|---|
| 代码层教训(2 项) | 本主 closeout §10.4 |
| 工作流 3 lever(detect + apply + 反例) | memory `feedback_workflow_speed_levers` |
| 量化浪费占比 | 本文 §1-§2 + memory 锚点段 |

## 5. 下次同类任务用法

**用户说"为什么慢" / "卡在哪" / "速度变了"时**,自查清单:
1. 全量 test 跑了几次?>1 次都该问"局部能跑吗"
2. 实装阶段有 spec 漏笔返工?说明 Phase 0 维度缺
3. closeout 是否超过任务里程碑配额?扩段不该 >50 行

不要先归因"任务复杂"或"opus 慢" —— 这些是常见但错误的归因。
