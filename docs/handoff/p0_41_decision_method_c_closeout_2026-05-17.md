# P0.3 #41 决议方案 C 砍发包链路推 P5.4b · 决策归档

> **日期**:2026-05-17 晚续
> **会话**:Mac + Opus 4.7,~30min
> **commit**:`d7aafee` `[docs] P0.3 #41 决议方案 C 砍发包链路推 P5.4b + ROADMAP v1.1`
> **0 代码改动 / 0 yaml 改动 / 0 test 改动**(纯文档层 + 全局规则修订)

## 1. 决策概要

外部审查 + W18 全收口后留下的 P0 三个挂账(#38 / #40 / #41):
- #38 base maxHp 重平衡 → P0.1 已销账(opus xhigh ~2h)
- #40 本地排行榜 + Supabase placeholder → P0.2 已销账(opus xhigh ~3h,方案 D)
- #41 MSIX + itch.io 发包链路 → **本批方案 C 决议砍归档推 P5.4b**

**用户「聚焦游戏本身」原则触发**:reality check 后用户明确「现在需要聚焦游戏本身,这些东西是否可以推到后期或者下一个版本」。5 项分析(MSIX 工具链 / itch.io 账号 / Sentry release / Pen SSH 派单 / itch.io 商品页)其中 **3/5 是第三方平台 + 后端配置**(itch.io / Sentry / Google 表单),与游戏本身工作量无关。**P0.3 整段推 P5.4b**:
- MSIX 打包工具链 → 在 P5.4 C5 Steam 集成内同期落地(Steam 工具链通用)
- itch.io 中间发布 → **直接砍**,买断制游戏走 Steam Demo 版即可,无 itch.io 中间态价值
- Sentry release 监控 → 推 P5.4b(Flutter Desktop Sentry 支持有限,Demo 阶段 ROI 低)
- Google 表单反馈 → 推 P5.4b closed beta 同期落地
- Pen SSH 派单 → 不再需要(P5 期 Steam Demo 版打包直接走 Steam 工具链)

**R6「数值打磨需外部反馈」对策改写**:从「P0.3 itch.io 公开免费版」改「P5.4b closed beta(~10 人 + Google 表单结构化反馈) + Steam Demo 版」。P0/P1/P2 期内部 dogfood + 数值红线测试 + Phase 0 reality check 兜底。

## 2. 产出清单

### 2.1 `docs/ROADMAP_1_0.md` v1.0 → v1.1(7 处修订)

| # | 段落 | 改动 |
|---|---|---|
| 1 | 时间线表 P0 行 | 交付物移除 itch.io Demo + Demo 公开收反馈 |
| 2 | 关键决策记录表 | 删「itch.io Demo 公开纳入 P0 末交付」+ 加「itch.io 中间发布砍」 |
| 3 | §P0 段 | 整段 P0.3 itch.io Demo 公开免费版(5 行子段)改为 1 行归档行 |
| 4 | §P5 段 | 加 P5.4b「closed beta + Google 表单 + Steam Demo 版」新段(MSIX + Sentry 接入移到此) |
| 5 | 关键依赖图 | `P0.3 itch.io ──→ P5 C2` 改 `P5.4b closed beta + Steam Demo ──→ P5.2 C2` |
| 6 | §风险列表 R6 | 对策从「P0.3 itch.io 公开」改「P5.4b closed beta + Steam Demo」 |
| 7 | 修订记录 | 加 v1.1 条目 |

### 2.2 `PROGRESS.md` 4 处修订

| # | 段落 | 改动 |
|---|---|---|
| 1 | 当前阶段段顶 | 加「P0.3 #41 决议方案 C 砍掉」新段 |
| 2 | 已知偏差 #41 行 | 从「未闭环」改归档行(✅ 决议) |
| 3 | 销账条目列表 | 加 #40 + #41 归档备注(剩余 P0 项改 strategy 重构) |
| 4 | 下一步段 | 改「P0 battle_engine 抽 strategy 层重构」 |

### 2.3 全局 `~/.claude/CLAUDE.md`「任务收尾会话清理判断」段重写

用户补规则:**任务收尾默认只输出 1 行会话清理建议,不自动追加新会话提示词 fenced code block,等用户明确通知后再输出**。

改动:
- 头部说明从「追加 2 行固定信息」改「追加 1 行会话清理建议」
- 删除原「输出格式范例」嵌套 fence 范例段
- 加「### 新会话提示词按需输出(2026-05-17 用户补规则)」段
- 反例段更新:加「未通知就自动追加长篇代码块」反例 + 「给提示词时只甩 PROGRESS 链接」反例
- 文件总行数 124 → 118

### 2.4 新增 memory(`~/.claude/projects/-Users-a10506/memory/`)

- `feedback_session_close_prompt_on_demand.md`:任务收尾只输 1 行建议,新会话提示词等用户通知再输出,沿原体例产出
- `MEMORY.md` 索引加 1 行(紧邻 [[clear-session-timing]])

## 3. 决策动机回顾(5 项 reality check)

| 项 | 后端依赖? | P0.3 时方案 | 推迟原因 |
|---|---|---|---|
| 1. MSIX 打包工具链 | ❌ 本地工具 | `msix` 包(pubspec)+ msix.json | 与 Steam 集成同期更经济(P5.4 C5) |
| 2. itch.io 账号 | ✅ 第三方平台 | 注册 + product page | 买断制游戏走 Steam,itch.io 中间态价值低 |
| 3. Sentry release 监控 | ✅ SaaS 后端 | sentry_flutter + DSN + release | Flutter Desktop 支持有限 + Demo 阶段 ROI 低 |
| 4. Pen SSH 派单 | ❌ 本地工具 | 末段一波 Pen 跑 build msix | 不再需要(走 Steam 工具链) |
| 5. itch.io 商品页 + Google 表单 | ✅ 双第三方平台 | Public + Pay What You Want + 双反馈 | 推 P5.4b closed beta 同期落地 |

**5 项中 3 项(2/3/5)是第三方平台/后端配置,与游戏本身无关**。剩 2 项(1/4 工具链)在 P5 期与 Steam 集成同期更经济。

## 4. 下波建议:P0 battle_engine 抽 strategy 层重构

**P0 真正剩余 1 项**(原 ROADMAP P0.2 升回 P0):

- **估时**:opus xhigh 6-12h(R4 风险条,实测可能更长,Phase 0 reality check 决定是否分 2-3 batch 渐进迁移)
- **跨链路**:damage_calculator / battle_state / battle_runner 全链路改 strategy injection
- **产物**:
  - `BattleStrategy` 抽象基类 + `DefaultGroundStrategy`(地面 3v3 实装)
  - e2e test 全战斗场景全过(15 主线关 + 30 爬塔层 + 5 闭关地图 + 心法相生 5 组合)
- **阻塞**:P3 §12.3 轻功对决 / 群战守城 / PVP 三种战斗形态扩展
- **执行建议**:**新会话升 opus xhigh** 走完整 Phase 0 reality check + spec 起草

## 5. 关联文件

- commit `d7aafee` [docs] P0.3 #41 决议方案 C 砍发包链路推 P5.4b + ROADMAP v1.1
- `docs/ROADMAP_1_0.md` v1.0 → v1.1
- `PROGRESS.md` 当前阶段 #41 决议段
- `docs/handoff/p0_40_local_leaderboard_closeout_2026-05-17.md`(前一波 P0.2 销账)
- `~/.claude/CLAUDE.md`「任务收尾会话清理判断」段(全局规则)
- `~/.claude/projects/-Users-a10506/memory/feedback_session_close_prompt_on_demand.md`(新增 memory)

## 6. memory 影响

新增:
- `feedback_session_close_prompt_on_demand`:任务收尾按需输提示词

无销账 memory(本批属新规则补全,与既有 [[clear-session-timing]] 兼容)。
