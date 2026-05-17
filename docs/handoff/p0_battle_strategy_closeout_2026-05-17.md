# P0 battle_engine 抽 strategy 层重构 · closeout

> **作者**:Mac + Opus 4.7 · 2026-05-17 晚续
> **spec 起点**:`docs/handoff/p0_battle_strategy_spec.md`(433 行,9 段,2 batch × 5 phase)
> **实测时长**:Batch 1 ~1.5h + Batch 2 ~30min = **~2h**(vs spec 预估 6-12h **快 3-5×**)
> **commit 链(本会话 4 commit,全 push origin/main)**:`6748582` → `456349b` → `14d62b1` → `68a6365`
> **test 基线**:888 → **943**(+55 case 净增,P0.2 #40 销账后 → P0 strategy 重构后)

## 1. 总览:Phase 1-5 全过

| Phase | 任务 | commit | 实测 | 结果 |
|---|---|---|---|---|
| 1 | BattleStrategy abstract + DefaultGroundStrategy 实装(11 method 搬迁) | `6748582` [arch] | ~45min | ✅ analyze 0 issues |
| 2 | BattleEngine 改 facade(467 → 50 行) | `456349b` [refactor] | ~10min | ✅ 888/888 全过(facade 等价兜底) |
| 3 | BattleNotifier 接 strategy injection | `14d62b1` [refactor] | ~15min | ✅ 888/888 全过(生产路径切 _strategy 等价) |
| 4 | e2e 全场景红线压测(55 case) | `68a6365` [test] | ~20min | ✅ 943/943 全过,e2e 单文件 ~3s |
| 5 | closeout + PROGRESS 销账 + ROADMAP v1.2 | (本文档 + 文档 commit 待跟进) | ~30min | 进行中 |

**Batch 1**(Phase 1-3,~1.5h)+ **Batch 2**(Phase 4-5,~30min)合计 ~2h,远低 spec 预估 6-12h。

## 2. 关键产出

### 2.1 strategy 抽象层(新增 2 文件)

- **`lib/features/battle/domain/strategy/battle_strategy.dart`**(55 行)
  - 3 method abstract:`tick` / `runToEnd` / `requestUltimate`
  - 粗粒度对齐 P3 §12.3 三战斗形态扩展需要(memory `feedback_avoid_over_engineer_abstraction` Q2 拍板)
  - P3 期挂 LightFootStrategy / MassBattleStrategy / PvpStrategy 即可 plug-in

- **`lib/features/battle/domain/strategy/default_ground_strategy.dart`**(477 行)
  - 地面 3v3 半横版唯一实装(Demo 阶段)
  - cp battle_engine.dart 整体复制(memory `feedback_layered_bugs` R3 对策:cp 整体 + 改 class 名 + static→instance,降漏迁风险)
  - 11 method 全搬迁:tick / runToEnd / requestUltimate / _advanceTick / _actorOrder / _findById / _resolveAction / _replaceById / _calculateInBattle / _formatAction / _fmt
  - 公式语义零变化(GDD §5.3-§5.6 + §12.1 #7 v1.4 阴柔内伤 dot / 刚猛震伤)
  - **不持任何 mutable instance state**:所有 method 接 BattleState 入参输出新 state(e2e test 中 5 case 等价回归实证)
  - `const` ctor 单例,Dart 编译时 canonicalize(e2e test `identical(a, b)` 实证)

### 2.2 facade 兜底(改 1 文件)

- **`lib/features/battle/domain/battle_engine.dart`**(467 → 50 行,-417)
  - 整体替换为 facade,委派给 `const DefaultGroundStrategy()` 单例
  - 静态 `tick / runToEnd / requestUltimate` 签名不变,test/combat/* 25+ 处直调 0 改动
  - P3 三战斗形态扩展时,生产路径走 BattleNotifier strategy injection 不通过 facade

### 2.3 strategy injection(改 1 文件)

- **`lib/core/application/battle_providers.dart`**(+21 -7)
  - BattleNotifier 加 `BattleStrategy _strategy = const DefaultGroundStrategy();` instance field
  - startBattle 加可选 `BattleStrategy? strategy` 参数,nullable 默认 DefaultGroundStrategy
  - requestUltimate / advance 改走 _strategy 委派
  - 4 生产 callsite 不必改:stage_entry_flow / tower_entry_flow / battle_test_menu / battle_demo
  - 删 battle_engine.dart import(BattleNotifier 不再直调,但 facade 保留供 test/combat/* 沿用)

### 2.4 e2e 红线压测(新增 1 文件)

- **`test/balance/battle_strategy_e2e_test.dart`**(333 行)
  - 主线 15 关 e2e(stage_01_01 → stage_03_05 全过)
  - 爬塔 30 层 e2e(floor 1-30 全过,buildTeamsForTower 路径)
  - 心法相生 5 组合 e2e(VC18-A1 fixture 切 activeCharacterIds 各 1)
  - backwards compat 5 case(facade ↔ strategy 行为等价 + const 单例 + 无 mutable state)
  - 红线断言语义(memory `feedback_red_line_test_semantics`):写约束(runToEnd 不抛 / result 有解 / tick ≤ 1000)不写瞬时事实

## 3. 文件清单实测

| 文件 | 状态 | 行数 |
|---|---|---|
| `lib/features/battle/domain/strategy/battle_strategy.dart` | ✨ 新增 | 55 |
| `lib/features/battle/domain/strategy/default_ground_strategy.dart` | ✨ 新增 | 477 |
| `lib/features/battle/domain/battle_engine.dart` | 🔄 重写 | 467 → 50 (-417) |
| `lib/core/application/battle_providers.dart` | 🔄 改动 | +21 / -7 |
| `test/balance/battle_strategy_e2e_test.dart` | ✨ 新增 | 333 |

总:增 2 / 改 2 / test 增 1 = 5 文件改动。

## 4. e2e 红线矩阵实测

执行时间:**~3s 单文件**(spec §6 R5 风险条担忧 30s+ 不撞)。

| 测试组 | case 数 | 执行结果 |
|---|---|---|
| 主线 15 关 e2e | 15 | ✅ 全过(runToEnd 不抛 + result 有解 + tick ≤ 1000) |
| 爬塔 30 层 e2e | 30 | ✅ 全过(同上) |
| 心法相生 5 组合 e2e | 5 | ✅ 全过(VC18-A1 fixture 5 角色 5 synergy 单独命中) |
| backwards compat | 5 | ✅ 全过(facade 等价 + const 单例 + 无 mutable state) |
| **合计** | **55** | ✅ 全过 |

**全 test 套件**:888 → **943**(+55 净增),analyze 0 issues 不退步。

## 5. commit 链(本会话本 spec 后,4 commit 全 push origin/main)

```
68a6365 [test] Phase 4 battle strategy e2e 全场景红线压测(55 case)
14d62b1 [refactor] Phase 3 BattleNotifier 接 strategy injection
456349b [refactor] Phase 2 BattleEngine 改 facade 委派 DefaultGroundStrategy
6748582 [arch] Phase 1 BattleStrategy abstract + DefaultGroundStrategy 实装
```

(spec 起草 commit `6862e48` 不计入本批实装链。)

## 6. 风险落地(spec §6 6 风险条)

| # | 风险 | 实测落地 |
|---|---|---|
| R1 | 公式语义漏迁(高) | ✅ cp 整体复制路径 + Phase 2 facade 兜底 + e2e backwards compat 5 case 实证 0 漂移 |
| R2 | 实测时长爆 12h 上限(中) | ✅ 实测 ~2h 远低 6-12h 预估,**spec §6 R2 对策"Batch 1 完成后 push"已执行** |
| R3 | 上层 fail 掩盖下层(中,memory `feedback_layered_bugs`) | ✅ DefaultGroundStrategy `const` 单例 + 无 mutable state,e2e "跨调用不持 mutable state" case 实证 |
| R4 | BattleNotifier `_strategy` race(低) | ✅ Demo 单线程读写 ok,P3 PVP 异步时再设计(spec §6 R4 已记录) |
| R5 | e2e 45 场景执行慢(低) | ✅ 单文件 ~3s 远低 30s 担忧,无需拆主线/爬塔双文件 |
| R6 | P3 三形态预留接口不足(低) | ⏸ 留 P3 期遇真痛点时再加 hook(memory `feedback_avoid_over_engineer_abstraction` 不预先抽象) |

## 7. memory 引用实战

| memory | 引用位置 |
|---|---|
| `feedback_model_selection` | opus xhigh 升档(跨模块战斗引擎重构) |
| `feedback_phase0_grep_two_axes` | Reality check 二度自审两维 grep(spec §2 + Phase 0 起草段) |
| `feedback_avoid_over_engineer_abstraction` | Q2 粗粒度 3 method 抽象拍板(P3 三形态真痛点在主循环不在 hook) |
| `feedback_layered_bugs` | DefaultGroundStrategy 无 mutable state 设计 + cp 整体复制路径 |
| `feedback_red_line_test_semantics` | e2e 红线断言写约束不写瞬时事实(runToEnd 不抛 / result 有解 / tick ≤ 1000) |
| `feedback_session_close_prompt_on_demand` | 收尾 1 行清理建议 + 默认不主动输出新会话提示词 |
| `feedback_closeout_numbers_grep` | 本 closeout 行数 / commit 数 / case 数全 grep 实测后落地 |

## 8. P0 阶段全销账状态

W18 Demo 主战场全收口后 P0 4 项实测推进:

| # | 项目 | 状态 |
|---|---|---|
| P0.1 | #38 base maxHp 数值平衡 | ✅ 2026-05-17 销账(方案 D 多 lever 重平衡) |
| P0.2 | #40 Supabase 排行榜 0→1 | ✅ 2026-05-17 销账(方案 D 本地链 + Noop placeholder) |
| P0.3 | #41 MSIX + itch.io 发包链路 | ✅ 2026-05-17 决议归档方案 C(砍归档推 P5.4b) |
| (新)P0 | battle_engine 抽 strategy 层重构 | ✅ **2026-05-17 销账**(本 closeout) |

**P0 阶段 4 项 100% 收口**。1.0 路线图进 P1(系统纵深 + 美术 PoC),sonnet 4-6h 可选 #42 §9 上线第一屏 + §10 引导骨架(剩 1 项 P1 可选)。

## 9. 下一步

- **P1 候选 1**:#42 §9 上线第一屏 + §10 引导骨架(sonnet 4-6h)
- **P1 候选 2**:美术 PoC(AI 出图测试,水墨 LoRA 训练,与 Demo 内容字数对齐)
- **P2 候选**:从挂账 P1 #37 6 events orphan / #43 高阶占位补齐 / GDD §12.4 节日活动系统级 1.0 框架

P0 strategy 重构本身**不阻塞 P3 §12.3 三战斗形态扩展**:LightFootStrategy / MassBattleStrategy / PvpStrategy 三类实装时,直接 implements `BattleStrategy` + `startBattle(left, right, strategy: LightFootStrategy())` 即可 plug-in,生产 4 callsite 不必改。

## 10. 决策日志(沿 spec §9 拍板对齐)

| 决策 | 实测结果 | 反思 |
|---|---|---|
| 分 batch B (2 batch) | ✅ Batch 1+2 总 ~2h 同会话续跑 | 实测时长远低预估,本可考虑 1 batch 一波,但 2 batch 节奏稳健 |
| 抽象粒度 粗粒度 | ✅ 3 method 抽象够用 | P3 三形态真痛点未来再加 hook 不预先抽象,memory `feedback_avoid_over_engineer_abstraction` 实战锚点 |
| e2e 全场景一波 A | ✅ 单文件 55 case 3s 全过 | spec §6 R5 拆双文件方案未执行(单文件够快) |
| DamageCalculator/BattleAI 不进 B | ✅ strategy 边界清晰 | P3 期若三形态选招逻辑共用,留 BattleAI 在 domain/ |
| applySynergy 排除 | ✅ view 层 setup 不感知 strategy | W18-A1 注入路径未受影响 |
| Facade 保留 | ✅ test/combat 25+ 处 0 改动 | 显著降迁移成本,值得 |
| `_strategy` instance field | ✅ Demo 单线程 ok | P3 PVP 异步时改 passed-with-state 设计 |
| commit 前缀 `[arch]`/`[refactor]`/`[test]`/`[docs]` | ✅ 4 commit 全对齐 | 可读性强 |

---

**P0 battle_engine 抽 strategy 层重构 100% 收口。Demo 阶段无视觉差异 / 数值零变化 / 943 test 全过 / P3 三形态预留接口稳。**
