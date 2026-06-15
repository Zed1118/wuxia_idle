# M2 范围 B — 通用被动离线挂机 + 累计总额 · 设计 spec

> 2026-06-15 立项（opus xhigh）。范围 A（闭关归来卡）已合 main（`7efb82c8`）。
> 本 spec = 范围 B「真·通用被动离线挂机」，单独立项。设计经用户逐点拍板（§2）。
> Phase 0 现状见 §1，红线复评见 §6。

## §1 Phase 0 现状（关键事实）

1. **被动挂机当前不存在**：不开闭关直接退游戏 → 回来 0 奖励。唯一离线产出路径 = 闭关（`SeclusionService.completeRetreat` 按真实时长结算）。
2. **`SaveData.lastOnlineAt` 是死字段**：注释写「玩家关游戏时写入」，但实际仅 `isar_setup.dart:144` 创建存档时写一次（= `createdAt`，见 `isar_setup_test.dart:120`），**无任何更新点**。范围 B 必须补真写入点才能算离线时长。
3. **资源 = 经验 / 磨剑石 / 心血结晶 / insightPoints**；无金币概念。
4. `saveVersion = '0.23.0'`，迁移走 `_migrateSaveData` 分段追加。
5. 范围 A 已有：`OfflineRecapService.buildRecap`（纯函数）+ `maybeShowOfflineRecap` gate（`home_feed_screen.dart:34` 首帧调一次）+ `OfflineRecapCard`。

## §2 设计决策（用户拍板）

| # | 决策点 | 拍板 |
|---|--------|------|
| 1 | 定位 | **闭关增强版**——被动涓流保底，闭关高产仍最优解 |
| 2 | 未闭关退游戏是否产出 | **算**（兑现 GDD §5.5「关 8h = 挂 8h」承诺） |
| 3 | 产出资源 | **经验 + 磨剑石**（常规消耗品；稀缺资源——心血结晶/insightPoints/共鸣——不走零操作管道，守 §5.1） |
| 4 | 强度 | **≈ 闭关同时长的 25%**（设计意图，实装跑 `balance_simulator` 校准） |
| 5 | cap | **72h**（复用闭关锚点 §5.2） |
| 6 | 产率基准 | 固定 `passive_base` × **当前出战主角境界** scale(1.3/阶)，不绑特定地图 |
| 7 | 发放 | **自动入包 + 归来卡仅告知**（无「领取」按钮，避 §5.1 登录奖励化） |
| 8 | 累计字段 | **仅汇总卡展示**（YAGNI，不为未立项的 M15 看板多存维度） |
| 9 | 闭关 vs 被动 | **互斥不叠加**——被动仅在「无 active 闭关」时生效，闭关期间离线归闭关结算 |

## §3 架构与数据流

```
[app lifecycle: detached/hidden]  →  写 SaveData.lastOnlineAt = now   ← 新增(范围B前置)
                                          ↓ (玩家关游戏)
[重开 → HomeFeed 首帧 gate]
   ├─ 有 active 闭关？ ── 是 ──→ 范围A 卡(已实装,引导收功,不叠加被动)
   └─────────────────── 否 ──→ 范围B 被动结算:
                                  awayHours = clamp(now - lastOnlineAt, 0, 72h)
                                  yield = OfflinePassiveService.compute(awayHours, 主角境界)
                                  → 同事务: 入包(角色经验 + 磨剑石仓库) + 累计字段 +=
                                            + lastOnlineAt = now (重置基准, 防重复结算)
                                  → awayHours ≥ 1h: 弹归来卡「被动变体·仅告知」
```

**互斥实现**（§2 #9）：gate 先查 `activeRetreatSessionProvider`。非 null → 走范围 A 分支（return，不结算被动）；null → 走范围 B 结算。

## §4 组件（隔离边界）

| 组件 | 职责 | 依赖 | 可测 |
|---|---|---|---|
| `OfflinePassiveService.compute()` | **纯函数** `(awayHours, realmTier, config) → (mojianshi, exp)`，锚定 `computeOutputs` × 0.25 | numbers config | ✅ 单测 |
| 发放编排（扩 gate） | 启动分流 + 同事务入包/累计/重置 lastOnlineAt（幂等） | Isar / service | ✅ 持久化测 |
| `AppLifecycleObserver`（新） | lifecycle detached/hidden → 写 lastOnlineAt | 平台 hook | 隔离副作用 |
| 归来卡「被动」变体 | 复用 `OfflineRecapCard` 文案变体「闭关外·被动精进 N 磨剑石+M 经验·已入囊」 | — | ✅ widget |

**发放点**：经验入角色（复用现有升级/加经验入口）、磨剑石入仓库（复用现有磨剑石加法入口）——实装阶段 grep 定位真相源，不另起一套加法。

## §5 数据模型迁移

`SaveData` 加 2 字段（YAGNI）：`totalPassiveMojianshi: int = 0` / `totalPassiveExperience: int = 0`。`lastOnlineAt` 复用（补真写入点，§4）。

`saveVersion 0.23.0 → 0.24.0`，`_migrateSaveData` 追加段：
- 两累计字段旧档默认 0；
- **旧档首启不回溯**：旧档 `lastOnlineAt == createdAt`（基准未建立）时，首次启动**不结算被动**、仅置 `lastOnlineAt = now` 建立基准。避免老玩家一上线吃一笔巨额回溯产出。

`.g.dart` gitignored，迁移后接收方 checkout 须重跑 `build_runner`（memory `feedback_wuxia_pen_build_runner`）。

## §6 数值与红线

`numbers.yaml` 新增 `passive_idle` 段：
- `base_mojianshi_per_hour` / `base_exp_per_hour`（锚定 `computeOutputs` 同境界产率 × **0.25**）
- `realm_scale_per_tier: 1.3`（复用）· `cap_hours: 72`（复用）· `min_recap_hours: 1.0`（告知阈值，与范围 A 一致）
- 走 schema 校验，不硬编码（§5.6）。

**红线复评（硬约束 · 实装必做）**：新增零操作产出管道，实装阶段**必跑 `balance_simulator`**，确认 ① 全周目产出曲线不被被动管道破坏 ② 不触 §5.4 红线（被动只产经验/磨剑石，不直接进伤害公式，但放大养成速度需验产出曲线）。25% 为设计意图，simulator 实测校准 base 值。

**§5.1 守线**：自动入包 · 归来卡纯告知 · 无「领取」按钮 · 无每日刷新 · 无留存通知——不构成登录奖励/留存诱饵。

**§5.5 兑现**：在线=离线，被动产出按真实离线时长线性结算（cap 72h），无加速券/在线 buff。

## §7 测试策略（TDD）

1. `compute()` 纯函数边界：0h / <1h / cap 72h / 各境界 scale / 25% 锚定 `computeOutputs`。
2. 发放幂等 + `lastOnlineAt` 重置（结算后再启动不重复发）。
3. 分流：有 active 闭关 → 走范围 A、不发被动；无闭关 → 范围 B 结算入包。
4. 旧档首启不回溯（`lastOnlineAt == createdAt` → 不结算、建基准）。
5. 累计字段同事务 += 正确。
6. 红线：`balance_simulator` 加被动管道后产出曲线 + 不进红线。

## §8 YAGNI / 不做

- 不做 M15 统计看板（仅留两累计字段，不多存分资源/分来源维度）。
- 不做「领取」交互、每日刷新、离线 buff、加速券。
- 不做精确 lastOnlineAt 的多点写入（仅 lifecycle detached/hidden 一处够用；闭关分支不依赖它）。
