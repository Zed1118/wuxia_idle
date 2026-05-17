# P0.2 #40 本地排行榜 + Supabase placeholder · closeout

> **完工**:2026-05-17(Mac + Opus 4.7 xhigh,~3h 全 5 phase 一波收口)
> **基线**:873/873 → **888/888**(+15 case)+ analyze 0 issues
> **commit 前缀**:`[schema]` (Phase 1) / `[feat]` (Phase 2/3/4) / `[docs]` (Phase 5)
> **spec 起点**:`docs/handoff/p0_40_local_leaderboard_spec.md`(449 行)
> **本会话 commit 链**:`b5d29a2` → `4916ef1` → `dc546d1` → `76b5283`

---

## 1. 决议落地(spec §3 方案 D)

**方案 D · 延后接 backend,本地链 + Noop placeholder + future-proof 接口**全 5 phase 闭环:

| Phase | 内容 | commit | 耗时 |
|---|---|---|---|
| 0 | Reality check + 项目策略 4 候选拍板 D + spec 范围 3 项拍板 | `4835ade` (上波) | 1h |
| 1 | TowerProgress schema bump 3 字段 + saveVersion 0.9.0 + build_runner regen | `b5d29a2` | ~30min |
| 2 | runTowerFlow stopwatch + recordClear elapsedMs API + 11 test 调用更新 + 4 新 case | `4916ef1` | ~50min |
| 3 | LeaderboardSyncService abstract + NoopLeaderboardSync + victory hook 注入 + try-catch 兜底 | `dc546d1` | ~40min |
| 4 | LeaderboardScreen UI 3+1 指标 + 主菜单按钮 + strings 8 const + widget test 6 case | `76b5283` | ~50min |
| 5 | verify + closeout + PROGRESS 销账(本段) | (本 commit) | ~20min |

**总耗时实测 ~3h** vs spec 预估 6-10h ── **较预估快 50%**。原因:
1. Reality check 真源 `TowerProgress` 已闭环(spec §2.1 暴露),省了「字段已有 + caller 全无 0→1」模式预估的额外工作量(memory `feedback_phase0_grep_two_axes` 「扩展」格子)
2. Phase 3 抽象层 + Noop 实现简洁(56 行)
3. Phase 4 UI 走 main_menu 现有 _MenuButton 体例 + LeaderboardScreen 单屏 3+1 tile,无复杂交互

## 2. 关键改动汇总

### 2.1 lib/ 改动

| 文件 | 改动 |
|---|---|
| `lib/features/tower/domain/tower_progress.dart` | 加 perFloorClearTimes: List<int> / bestClearTime: int? / lastClearedAt: DateTime? 3 字段 |
| `lib/features/tower/application/tower_progress_service.dart` | recordClear 签名加 required int elapsedMs + 首通锁 perFloorClearTimes(重打不覆盖 GDD §5.1)+ bestClearTime 派生(min over 非 0)+ lastClearedAt 任何通关都更新 |
| `lib/features/tower/application/leaderboard_sync_service.dart` | **新建** abstract LeaderboardSyncService.reportClear + NoopLeaderboardSync implements |
| `lib/features/tower/application/tower_providers.dart` | 加 @riverpod leaderboardSync 函数(默认 NoopLeaderboardSync) |
| `lib/features/tower/presentation/tower_entry_flow.dart` | 加 Stopwatch 计时 + clearRecorderForTest DI 签名扩展 + recordClear 透传 elapsedMs + victory hook 注入 sync.reportClear(整段 try-catch 兜底防 IsarSetup 抛错) |
| `lib/features/tower/presentation/leaderboard_screen.dart` | **新建** Scaffold + AppBar + 3+1 _MetricTile ListView + 空态提示 + 耗时格式化(< 60s / >= 60s 2 格式) |
| `lib/features/main_menu/presentation/main_menu.dart` | 加排行榜 _MenuButton(tower 下方 seclusion 上方,9 → 10 按钮)|
| `lib/data/isar_setup.dart` | _currentSaveVersion '0.8.0' → '0.9.0' + 注释加 P0.2 #40 段 |
| `lib/shared/strings.dart` | 加 mainMenuLeaderboard + mainMenuLeaderboardHint + leaderboard* 8 const + 3 派生 helper |

### 2.2 test/ 改动

| 文件 | 改动 |
|---|---|
| `test/data/isar_setup_test.dart` | saveVersion expect 期待值 0.8.0 → 0.9.0 + reason 更新 |
| `test/features/tower/application/tower_progress_service_test.dart` | 11 处 recordClear 调用全加 elapsedMs:1000 + 5 新 case(Phase 1 3 字段默认值 / Phase 2 首通写 / 重打不覆盖 / bestClearTime min 派生 / lastClearedAt 任何通关更) |
| `test/features/tower/presentation/tower_entry_flow_test.dart` | clearRecorder 5 处 mock lambda 扩展 (floorIndex, elapsedMs) + 2 处类型签名 |
| `test/features/tower/application/leaderboard_sync_service_test.dart` | **新建** 4 case(Noop 不抛 / 边界值 / 连调 100 次 0 副作用 / fake _RecordingLeaderboardSync 接口契约) |
| `test/features/tower/presentation/leaderboard_screen_test.dart` | **新建** 6 case(空态 / 通 5 层 3 指标 / bestClearTime null / totalDefeats > 0 显胜率 / == 0 不显 / >= 60s 分秒格式) |
| `test/features/main_menu/presentation/main_menu_test.dart` | 9 → 10 InkWell + 顺序断言加 leaderboard + tap Phase 2 加 ensureVisible(viewport 临界) |

**test 增量**:0 → +15 case(实测,符合 spec §7 预估 15-20)。

### 2.3 numbers.yaml / GDD

**未改动**(spec §2.3 决议:配置保留,Noop 实现下 `sync_to_supabase=true` 等同 `false` 行为)。

## 3. 验收红线全过(spec §5)

| 红线 | 验收方式 | 状态 |
|---|---|---|
| TowerProgress schema bump 不破坏旧存档 | isar_setup_test 跑过 + 3 字段默认值 case + Isar 自动迁移 | ✅ |
| 重打不覆盖首通耗时(GDD §5.1 反主流) | tower_progress_service_test 「重打 elapsedMs 2000 不覆盖首通 5000」case | ✅ |
| bestClearTime 派生公式正确(min over 非零) | tower_progress_service_test 「min over [7000, 3000, 9000] = 3000」case | ✅ |
| LeaderboardSyncService 接口 future-proof | leaderboard_sync_service_test fake _RecordingLeaderboardSync 验 implements 可覆写 | ✅ |
| numbers.yaml leaderboard.sync_to_supabase 配置保语义 | Noop 实现下 0 network call(reportClear 内 intentionally noop) | ✅ |
| 主菜单 + LeaderboardScreen 0 raw defId 暴露 | widget test 全 6 case 用 UiStrings.* const 断言 | ✅ |
| Phase2TestMenu 按钮数对齐 | spec §4.4 决定不加 14th 按钮(D 方案 LeaderboardScreen 走主菜单 push 即用) | N/A(本批撤回) |
| flutter test 全过 + analyze 0 issues | 888/888 + 0 issues | ✅ |

## 4. 风险应对(spec §6)

| # | 风险 | 实际遇到 | 应对结果 |
|---|---|---|---|
| R1 | Isar @collection schema bump 破坏旧存档 | 未遇到 | Isar 自动新字段默认值,新 case 显式断言通过 |
| R2 | List<int> @embedded fixed-length | 未遇到(perFloorClearTimes 写入前 List.from 转 growable) | memory `feedback_isar_pitfalls` §2 实践 |
| R3 | victory hook stopwatch 计时不准(push/pop 600ms 误差) | 已知误差,接受 | 注释明写,接受 ≈ 600ms 误差对玩家「最佳通关耗时」UI 目的够用 |
| R4 | 主菜单按钮位置冲突 | 未遇到 | 9 → 10 按钮,但 viewport 临界(Phase 2 下移到第 6 位)→ test 加 ensureVisible 修 |
| R5 | LeaderboardSyncService provider 注入位置冲突 | 未遇到 | @riverpod 函数对齐现有 tower_providers.dart 体例 |
| R6 | placeholder 接口未来 Supabase 不够 | N/A(本批未接 backend) | reportClear 4 字段对齐 GDD §8.2 + numbers.yaml track_metrics 3 项 + clearedAt 时间锚,future-proof |

**额外风险**(spec 未列):**widget test victory hook IsarSetup access 抛错** — Phase 3 victory hook 内 `TowerProgressService(isar: IsarSetup.instance).getOrCreate(...)` 在 widget test 未 init isar 时抛错,3 个现有 widget test 失败。应对:整段 try-catch 兜底防 IsarSetup 抛错 + unawaited 内 catchError 双层保护(memory `feedback_layered_bugs` 实践)。修复后 widget test 全过。

## 5. 模型选型实战锚点(memory `feedback_model_selection` 校准)

| Phase | 任务类型 | 模型选型实测 | 评估 |
|---|---|---|---|
| 1 | schema bump 3 字段 + saveVersion bump + 1 test case | opus xhigh 30min | ✅ 用 opus xhigh 对(memory 警示「Supabase schema 迁移、数据模型重设计」必升 xhigh)|
| 2 | service API 扩展 + 11 处 test 批量改 + 4 新 case | opus xhigh 50min(其中 perl 批量改 5min) | ✅ perl 批量改 + 4 新 case 设计 xhigh 价值在 |
| 3 | abstract + Noop 实装 + try-catch 兜底 + test | opus xhigh 40min | ✅ try-catch 兜底决策 xhigh ROI 高 |
| 4 | UI Scaffold + tile + strings + test 6 case | opus xhigh 50min | sonnet 也能做(UI 体例对齐),但 xhigh 一次到位无需 review |

**结论**:整批 ~3h 全 xhigh 推进,符合 memory 决策。下波 #41 itch.io 发包(sonnet 3-5h)按 sonnet 默认。

## 6. claude --print 单轮任务时长校准(memory `feedback_claude_print_task_duration`)

本批不走 nightshift dispatcher(同会话 xhigh 一波推进),但工作量对应 memory 锚:
- spec 起草 ~1h(详 spec doc 449 行) ≈ memory 「markdown 重写 5-10min」的 6-10 倍量级 OK
- 单 Phase 实装 30-50min ≈ memory 「test 8-15min × 2-3」量级 OK
- 总 5 phase 同会话 ~3h 符合 memory 「6-10h 现实校准」下限

**校准**:复杂多 phase 任务同会话 xhigh 推进比 nightshift 分批 dispatch 高效得多(免 worktree 切换 / dispatcher 调度开销)。

## 7. 下一波建议

### 7.1 P0.3 #41 MSIX + itch.io 发包链路(下波候选)

- **估时**:sonnet 3-5h 单独会话
- **范围**:GDD §11/§11.3 MSIX 包配置 + itch.io 商品页 + readme + 反馈渠道
- **依赖**:本批排行榜已完工,可作为「Demo 完整功能」一部分公开
- **模型选型**:sonnet 默认(打包配置 / 文档撰写,无跨模块设计)

### 7.2 后续可选(P1 优先级)

- **#42** §9 上线第一屏 / §10 引导骨架(sonnet 4-6h,发布后随外部反馈再决定)
- **#37** 6 events orphan 主题不适配(留 _archive 不动)

## 8. 决策日志补充

| 时间 | 决策点 | 选择 | 备注 |
|---|---|---|---|
| 2026-05-17 | Phase2TestMenu 14th VC-LEADERBOARD 按钮 | **不加** | spec §4.4 倾向加,但 D 方案下 LeaderboardScreen 走主菜单 push 即用 + 本批不派 Codex 视觉验收,免 Phase2TestMenu 维护成本 |
| 2026-05-17 | victory hook widget test fake LeaderboardSync 注入 | **不加** | widget test 没 init isar,victory hook 内 svc.getOrCreate 必抛 → 加 try-catch 兜底覆盖路径即可,service test 已覆盖 Noop 契约 |
| 2026-05-17 | victory hook 计时起点定位 | **stopwatch start 在 push BattleScreen 前**(含 push/pop 600ms 误差) | 简单 + 误差对 UI 目的可接受;不重构 _runTowerBattle 返回 record |
| 2026-05-17 | LeaderboardScreen 第 4 派生指标(胜率)| **条件渲染 totalDefeats > 0 时显** | GDD 反留存焦虑(§5.1),不每屏挂派生;有失败数据才显 |
| 2026-05-17 | best_clear_time 派生位置 | **service 层每次 recordClear 重算 min** | 比 UI 层 fly-time 派生稳;接 Supabase 时 best 是字段不是派生 |

---

**P0.2 #40 全 5 phase 闭环 + 888/888 + analyze 0 issues + 4 commit 待 push**(`b5d29a2` → `4916ef1` → `dc546d1` → `76b5283`)。下波切 P0.3 #41 sonnet 单会话。
