# P2-M0 性能与测试基线地图(2026-08-23)

> 任务:`P2-M0-QODER-BASELINE` · 只读盘点,0 改生产代码。
> 执行端:Qoder CLI + `Qwen3.8-Max`。
> 分支:`codex/phase2-m0-qoder-baseline-20260823` · 起点 HEAD:`e292d3a0`(收口主线群怪爽感与实机布局)。
> 判定口径:本文严格区分【已验证事实】(本会话用只读工具亲验)/【历史记录】(出自既有文档,未在本会话重跑)/【待测项】(需运行命令才能确认)。

---

## 0. 摘要

- 项目已具备**同核战斗内核 + headless runner + 玩家 bot + 帧/内存 Profile 探针 + 双平台物理机 Gate 脚本**的完整性能基线基建,且已在 2026-08-23 Route C Gate 中以实机证据收口(历史记录,数字见 §2)。
- **测试资产**:651 个 `*_test.dart`(已验证);最近一次全量 4244/4244(历史记录)。
- **主要缺口**:无高密度实时群战压测场景、无战斗耗时回归守卫、无独立内存长跑测、`balance_simulator_test` 已随旧 3v3 退役但文档仍引用、桌面无 FPS overlay、`integration_test`/benchmark 依赖缺失。
- **Qoder 执行端限制**:该 CLI 会话对 `flutter`/Bash/仓外文件无交互授权通道,因此动态项按待测登记。Codex 集成主审已读取桌面方案，并在隔离整合态完成九模块 77/77 targeted、18 文件 analyze 0 及补齐生成/子包依赖后的全仓 analyze 0；性能实机采样仍待跑。

---

## 1. 已验证事实(本会话只读亲验)

### 1.1 Phase 0A 同核内核与 headless

| 事实 | 位置 |
|---|---|
| 战斗结算唯一入口为纯 Dart reducer | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart`(`reducePhase0aTick` + `Phase0aDamageResolver`) |
| 流程封装,在线视觉与 headless 共用 | `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart`(`Phase0aWaveBattleFlow.advance`) |
| headless runner 已生产接线,零 Flutter 依赖 | `phase0a_headless_runner.dart`(`runToEnd` 同步 / `runToEndAsync` 按 `yieldEveryTicks` 让出;返回 `Phase0aHeadlessResult`,含 ticks/events/`timedOut`) |
| 生产装配显式注入 rng | `phase0a_production_flow_assembler.dart`(`Phase0aProductionFlowAssembler.assemble`) |
| 玩家 bot 为生产消费(扫荡/远征/断魂庄),经同一输入适配器进 reducer | `phase0a_player_bot_adapter.dart`(`commandFor`) |

### 1.2 战斗时长预算(生产配置)

- `data/numbers.yaml` `phase0a_arena.simulation`:`fixed_delta_seconds: 0.1`,`max_battle_seconds: 300.0`(即 3000 tick 预算;超时返回显式 `timedOut`)。
- 消费符号:`lib/data/numbers_config.dart` `Phase0aArenaConfig.maxSimulationTicks` / `fixedDeltaSeconds`。
- 观测 harness:`test/support/phase0a_profile_harness.dart` 逐场记录 ticks/seconds/伤害分位(仅观测,**无性能基线断言**)。

### 1.3 确定性机制

- 全局 `rngProvider`:`lib/shared/utils/rng_provider.dart`(生产为无种子 `DefaultRng`);战斗内核不走 provider,装配时显式注入(远征 `newMathRandom(seed: nodeSeed)`,`lib/shared/utils/math_random.dart`)。
- 确定性测试代表(文件存在已亲验):`test/shared/utils/rng_test.dart`、`test/shared/utils/rng_provider_wiring_contract_test.dart`、`test/features/battle/application/phase0a/phase0a_headless_kernel_test.dart`(同初态两次运行全等)、`test/features/expedition/expedition_seed_test.dart`、`test/support/phase0a_ch1_founder_profile.dart`(seed 参数化)。

### 1.4 生产路由与路由口径

- **无 GoRouter、无 routes 表**:`lib/main.dart` `MaterialApp(home: SplashScreen())`,全库命令式 `Navigator.push`。
- 「路由」口径 = `VisualRoute` 枚举:**77 个枚举值,含聚合入口 `hub`**(`lib/features/debug/application/visual_route.dart`,亲数)。
- 「65 路由」是**历史口径**:指旧 3v3 删除范围中的 137 条中 65 条(`docs/audit/legacy_3v3_removal_scope_2026-08-18.md`),与当前 77 不可直接对比。
- 路由清单工具:`tool/visual_acceptance.dart`(`routes|checklist|dry-run` 命令,`--suite smoke|battle|full`)。

### 1.5 帧性能与内存诊断基建

- 核心探针:`lib/features/debug/application/battle_frame_profile.dart` ——
  - 帧预算 `_frameBudget=16.6ms`、严重帧 `_severeFrame=33.3ms`;
  - 基于 `SchedulerBinding.addTimingsCallback` + `FrameTiming`,输出 `frames.jsonl` / `summary.json`(p99 build/raster/totalSpan、连续超帧);
  - 内存:`ProcessInfo.currentRss` 每秒采样 → `memory_gc.jsonl`,summary 含 `rss_start/peak/end_bytes`;vm_service GC 事件遥测。
- 接线:`lib/main.dart:40` `BattleFrameProfileProbe.configureFromArgs(args)`(非 release);窗口尺寸经 `--battle-profile-viewport=WxH` 或 `VISUAL_WINDOW_W/H` 锁定;负载路由 = `--visual-route=phase0a_battle_profile`(bot 循环负载 + 自动重开)。
- Gate 脚本(亲验存在):`tools/route_c_gate/run_route_c_macos_profile.sh`(及 `*_matrix.sh` / Windows `.ps1` 对应件)。macOS 单轮复合门(`jq`):`sampled_frames>=3000 && p99_total_span_ms<16.6 && max_consecutive_severe_frames<=1 && frame_streak_gate_passes && gc_telemetry_status=="GC_TELEMETRY_COLLECTED" && 逻辑视口精确 && rss_end<=rss_start*1.10+64MB`。
- 脚本硬前置:要求 worktree 干净 + 指定期望 commit + 期望 `data/phase0a_debug_battle.yaml` fixture SHA-256。
- 探针自测:`test/features/debug/application/battle_frame_profile_test.dart`。
- **无 FPS overlay/常驻 HUD;无独立内存泄漏测试、无 memory-pressure 监听。**

### 1.6 生产 fixture

- `data/phase0a_debug_battle.yaml`:视觉验收专用(头注明示「Never use as production balance data」),`seed: 20260816`,2 波敌人(2 + 3 只),**非高密度场景**。

### 1.7 双视口

- 生产窗口预设(`lib/features/settings/domain/display_settings.dart`):hd720=1280×720、**hd900=1600×900(默认)**、hd1080=1920×1080,经 `WindowManagerController.apply` → `windowManager.setSize` 生产接线(`main.dart:60-65`)。
- Gate 双视口口径:1280×720 与 **1440×900**(`run_route_c_macos_profile.sh` `case` 白名单)。
- ⚠️ 差异点:生产默认预设 1600×900 不在 Gate 白名单内(1440×900 是 Gate 视口),两套口径并存,基线时需明示采用哪套。

### 1.8 群战 / 高密度

- 旧制群战守城:`lib/features/mass_battle/`(`MassBattleService`),`data/stages.yaml` 5 关(玩家 3 vs 敌 5–7/波,2–4 波),回合制旧体例。
- 实时群怪:Phase 0A 主线群怪由 `data/numbers.yaml` `mainline_wave` 展开(**普通关 2/3/4 三波、Boss 关 2/3 铺垫 +1 Boss**,亲验原文);`stages.yaml` 主线每关只留 1 个模板敌人。
- `Phase0aWave` 敌人列表不可修改副本(`lib/features/battle/domain/phase0a/phase0a_wave.dart`)。
- **未找到实时怪海敌数量上限/密度参数旋钮;无高密度压测 fixture。**

### 1.9 测试资产盘点

- `test/*_test.dart` 共 **651** 个(亲数)。
- `test/support/`(18 文件):`phase0a_profile_harness.dart`、`phase0a_ch1_founder_profile.dart`、`combatant_snapshot_fixture.dart`、`isar_test_support.dart`、`test_data.dart` 等。
- `test/tools/`(24 文件):`stress_test.dart`(D 段性能稳定压测,覆盖 GameEvent 无界累积 + 极端时长结算;注释声明连续战斗压测由已退役的 `balance_simulator_test` 1000 场覆盖)、`phase0a_full_content_balance_diagnostic_test.dart` 等 5 个 0A 诊断测、`coverage_ratchet_test.dart`、`ci_workflow_contract_test.dart`、`macos_release_gate_contract_test.dart`、四项审计器(中文直写/桌面语义/资产/美术色调)。
- `test/fixtures/`:4 个 allowlist txt。`test/route_c/`:4 文件。**无 golden 目录、无 `matchesGoldenFile`。**
- pubspec dev_dependencies:`flutter_test`/`analyzer`/`lints`/`build_runner`/`riverpod_generator` 等;**无 `integration_test`、无 benchmark 包,无 `integration_test/` 目录。**
- 环境现状:本 worktree `lib/*.g.dart` = **0**(gitignore 生成物缺失)、`libisar.dylib` **不在库内**(CLAUDE §9.1 明示 fresh worktree 需从主仓拷贝)。

### 1.10 既有审计报告(存在性亲验,数字属历史记录)

`docs/audit/route_c_gate_closeout_2026-08-23.md`、`route_c_mac_gate_2026-08-22.md`、`phase0a-production-wiring-audit-2026-08-16.md`、`phase0a-batch8-vfx-anchor-audit-2026-08-16.md`、`phase0a-presentation-gap-audit-2026-08-16.md`、`battle_repaint_rainbow_probe_2026-07-05.md`;性能 spec:`docs/spec/m15_d_performance_spec_2026-05-29.md`(D1-D6 中 D1 FPS 基线/D2 memory/D3 Isar IO/D5 8h 长跑**均未落自动化**;`tools/perf_profile.dart`、`isar_io_stress_test.dart`、`tools/idle_long_run.dart` 均不存在)。

---

## 2. 历史记录(出自古文档,本会话未重跑)

| 记录 | 数字 | 出处 |
|---|---|---|
| Route C 双平台 Gate 裁决 | PASS,Gate commit `597a243b` | `docs/audit/route_c_gate_closeout_2026-08-23.md` |
| Gate 时全量测试 | 4218/4218,analyze 0 | 同上 |
| 最新全量 | 4244/4244,analyze 0 | `PROGRESS.md` 顶条(2026-08-23) |
| Mac 实机 p99(3 轮/视口) | 720p 5.579/5.349/5.535ms;900p 5.371/5.649/5.754ms | closeout §Mac |
| Windows 实机 p99 | 720p 3.416/3.499/3.514ms;900p 3.573/3.539/3.471ms | closeout §Windows |
| 双视口严重慢帧 | 六轮均 0,样本帧 8624–8648 | closeout |
| 早期双视口基线 | 720p p99 6.258–9.099ms、900p 8.023–8.105ms、最大帧 ≤12.730ms、超预算帧 0(2026-08-16,`phase0a_replay` Profile) | `phase0a-presentation-gap-audit-2026-08-16.md` |
| 切片帧预算基线 | p99 ≤9.1ms,反馈池 136/160 | `phase0a-batch8-vfx-anchor-audit-2026-08-16.md` |
| 并发全量耗时 | `flutter test --no-pub` 10 核 2m34s(3587 pass,2026-07-03);`-j1` 9m42s | CLAUDE.md v1.29 |
| 串行参考 | 11:16,4792(2026-08-01) | `docs/spec/2026-08-01-battle-ui-sample-fidelity-95-repair-report.md` |
| 测试数演进 | 3587(07-03)→4802(08-02)→4903(08-07)→5142(08-17,四段跑)→4218(08-23,3v3 删除)→4244 | `PROGRESS.md` |
| 内存 | **无任何运行期内存数字入档**(仅构建体积 169–174MB);rss 数据只存在 Gate 证据包 `summary.json` 中 | 亲验 `PROGRESS.md` 无命中 |

---

## 3. 待测项(本会话无法执行,命令见 §5)

1. **Qoder 未跑动态探针**:`flutter` 与全部 Bash 命令被其执行环境权限拦截；Codex 已补九模块联合测试与静态分析，`rng_test`、性能/压力/全量仍未执行。
2. 全量测试当前耗时与通过数(651 文件/4244 口径)。
3. `stress_test` 实跑输出(`test/tools/output/`)。
4. 0A 诊断测的战斗耗时/胜率分位实测(`phase0a_profile_harness` 观测值)。
5. 当前 commit(`e292d3a0`,含主线群怪批)下双视口帧采样 —— 历史实机数字绑定的是 `597a243b`,**不可沿用到新 commit**。
6. 当前 `data/phase0a_debug_battle.yaml` SHA-256(Gate 脚本参数,运行时取)。
7. `dart run build_runner build` 与 `libisar.dylib` 拷贝后的环境可跑性验证(本 worktree 0 个 `.g.dart`、无 dylib)。

---

## 4. 缺口清单

| # | 缺口 | 影响 |
|---|---|---|
| G1 | Qoder 端无法读取仓外二阶段方案 | Codex 主审已读取并完成范围对照,已解除 |
| G2 | Qoder 端无法执行动态命令 | Codex 已补 77/77 targeted 与 analyze；性能/压力/全量按 §5 补 |
| G3 | fresh worktree 缺 `.g.dart` 与 `libisar.dylib` | build runner 已在整合态补 `.g.dart`;需 Isar 测试时再从主仓复制 dylib |
| G4 | 无高密度实时群战压测场景:debug fixture 最多单波 3 敌,`mainline_wave` 上限单波 4,mass_battle 是旧回合制 | 群战高密度无基线 |
| G5 | 战斗耗时无回归守卫:300s 是超时预算非基线断言,harness 只观测 | 数值改动可静默拖长战斗 |
| G6 | 无内存长跑测/泄漏锚点;内存数字未入任何文档基线 | m15 D2 从未落地 |
| G7 | `balance_simulator_test` 已退役,但 `stress_test.dart` 注释与 CLAUDE.md §5.4 仍引用(文档漂移) | 误导后续任务 |
| G8 | 无 `integration_test`/benchmark 依赖、无 golden 测 | 性能自动化只能靠 Profile 探针 |
| G9 | 生产默认预设 1600×900 不在 Gate 双视口白名单(1280×720/1440×900) | 视口口径需拍板 |
| G10 | Isar IO 压测(m15 D3 `isar_io_stress_test.dart`)从未实装 | 大背包/多角色写入无锚点 |

---

## 5. 四小时批执行建议(精确命令 + 资源锁顺序)

**资源锁分级**(从弱到强,按序获取,持强锁时不得并行跑后续等级):
- `L0` 只读静态(文件系统)——无锁,任何时候可跑;
- `L1` flutter 工具锁 + pub 缓存 —— 同一时刻只允许 1 个 flutter 命令;
- `L2` CPU 满载(约 10 核)—— analyze/全量测试独占,期间不跑其它编译;
- `L3` `build/macos` 构建目录 —— `flutter build macos --profile` 独占;
- `L4` 显示/窗口锁 —— 帧采样开真实窗口 + `caffeinate`,**前台独占、单视口串行**,期间禁跑任何视觉验收/截图。

**顺序即下表,持 L4 前必须已提交文档使 `git status --porcelain` 干净(Gate 脚本硬前置):**

| 批 | 锁 | 命令 | 预算 |
|---|---|---|---|
| B0 环境预检 | L1 | 根目录 `flutter pub get && dart run build_runner build`;`cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib ./libisar.dylib`;`(cd tools/phase0minus_probe && flutter pub get)`;`flutter --version` | 20min |
| B1 确定性目标测 | L1 | `flutter test test/shared/utils/rng_test.dart --no-pub`;`flutter test test/features/battle/application/phase0a/phase0a_headless_kernel_test.dart --no-pub` | 15min |
| B2 战斗时长/headless 诊断 | L2 | `flutter test test/tools/phase0a_full_content_balance_diagnostic_test.dart test/tools/phase0a_production_migration_preflight_diagnostic_test.dart --no-pub` | 30min |
| B3 压测与门禁 | L2 | `flutter test test/tools/stress_test.dart --no-pub`;`dart run tool/route_c_gate_preflight.dart`(如支持单测模式按 `--help`) | 25min |
| B4 静态门禁 | L2 | `flutter analyze --no-pub lib test tool`;`git diff --check` | 10min |
| B5 Profile 构建 | L3 | `flutter build macos --profile` | 30min |
| B6 双视口帧采样 | L4 | `FIX=$(shasum -a 256 data/phase0a_debug_battle.yaml \| awk '{print $1}')`;`COMMIT=$(git rev-parse HEAD)`;`ROUTE_C_SKIP_BUILD=true tools/route_c_gate/run_route_c_macos_profile.sh 1280x720 3 "$COMMIT" "$FIX"`;完成后同式串行跑 `1440x900` | 45min |
| B7 批末全量 | L2 | `flutter test --no-pub`(默认并发) | 15min |
| B8 归档 | L0 | 汇总 frames/summary jsonl → 基线数字回填本文 §2/§3,更新计划文件恢复点 | 20min |

合计约 3.5h,留 0.5h 缓冲。若 B6 失败,只回退该批,不影响已归档的 B1–B4 基线。

---

## 6. 范围与红线声明

- 本任务 0 改 `lib/`、`data/`、`test/`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`;仅新增本文与计划文件。
- 未跑全量测试、未启动视觉窗口、未升级依赖、未删除文件、未 push/合并。
- 已否任务清单(`docs/spec/rejected_task_registry.md`)已读:本盘点不触碰任何已否方向;性能基线属新增度量,不引入玩法/数值变更。
