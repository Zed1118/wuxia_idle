# P3.4 §12.1 sect_event 全收口(Batch 2.3 + 2.4 + 2.5 + closeout)

> 日期:2026-05-24 nightshift T16(Mac + Opus 4.7)
> 上游:P3.4 spec(2026-05-24)+ Batch 2.1 schema(`efc7604`)+ Batch 2.2 service(`8c001b3`)
> 范围:`nightshift/T16` branch · git worktree 独立 base 自 main

## TL;DR

- SectScreen 顶 name/level/reputation 进度条 + active list + history tab + SectEventDialog 弹 narrative + 应战/拒绝 + resolve 路径 全实装。
- main_menu 14→15 入口插 Sect(MassBattle 后 / Leaderboard 前)+ UiStrings `mainMenuSect/Hint`。
- sect_providers Riverpod wire:service Provider 2 个 + SectStateNotifier 内存 state(Demo)+ 单 sect 单玩家路径。
- R4 widget 测 4 + R1 应战 e2e 整链测 5 + Decay/Service wire 测 2 = 11 新测全绿;`test/features/sect/` 22/22 全绿。
- 0 改 lib/features/battle/strategy/* / 0 改 numbers_config.dart 强类型 / 0 改 data/numbers.yaml(Batch 2.2 已落 `sect_event:` 段)。

## 改动总览

| 文件 | 类型 | 行数 | 备注 |
|---|---|---|---|
| `lib/shared/strings.dart` | edit | +5 | `mainMenuSect / Hint` 2 静态串 |
| `lib/features/main_menu/presentation/main_menu.dart` | edit | +6 | SectScreen import + `_MenuButton` 插序 |
| `lib/features/sect/application/sect_providers.dart` | new | ~110 | service Provider 2 + SectStateNotifier(Notifier 3.x API)+ SectState immutable |
| `lib/features/sect/presentation/sect_screen.dart` | new | ~300 | DefaultTabController 2-tab · `_SectHeader / _ActiveEventList / _HistoricalEventList` |
| `lib/features/sect/presentation/widgets/sect_event_dialog.dart` | new | ~165 | FutureBuilder 弹 narrative `loadYaml` + 应战/拒绝 + resolve |
| `data/lore/sect_event/tournament_01.yaml` | new | 9 | 群英会 stub |
| `data/lore/sect_event/tournament_02.yaml` | new | 10 | 春秋赛事 stub |
| `test/features/main_menu/.../main_menu_test.dart` | edit | +6 | 14→15 InkWell + 顺序断言 |
| `test/features/sect/sect_screen_test.dart` | new | ~99 | R4.1-R4.4 widget 测 |
| `test/features/sect/sect_battle_integration_test.dart` | new | ~160 | R1.5-R1.9 service + provider wire e2e |

## R 测族销账

- **R1** 应战 e2e 整链(spec §7):新增 5 测(R1.5/R1.6/R1.7/R1.8/R1.9 走 `numbersConfigProvider.overrideWithValue` + NumbersConfigStub)
- **R2/R3** service + decay:Batch 2.2 已覆盖 13 测(`sect_event_service_test` + `sect_reputation_decay_test`)
- **R4** widget UI(spec §7):4 测(`sect_screen_test`)
- **R5** schema:Batch 2.1 已覆盖 4 测(`sect_schema_test`)
- **总计**:22/22 全绿 in `test/features/sect/`

## 决策点

- **应战路径模拟战斗**:Demo 走 `Random.nextBool()` 决定 win/loss(spec §4 「default ground strategy 不引入新数值轴」意图保留 · 数值红线零碰)。真 BattleScreen wire(StageBattleSetup + buildMirrorEnemyTeam 同境界镜像 + push BattleScreen 等结算)留挂账下波。
- **真持久化 wire**:`SectSchema` / `SectEventSchema` 尚未加 `IsarSetup._allSchemas` · Demo 走 `SectStateNotifier` 内存 state · Phase 4 wire 真 Isar 时:① schema 加 _allSchemas 升 saveVersion 0.13.0;② StreamProvider 切 Isar collection 读;③ `SectStateNotifier.resolve` 内 `await isar.writeTxn(() async { ... })`。
- **Notifier 3.x API**:flutter_riverpod 3.x `StateNotifierProvider` 已 deprecated · 用 `Notifier<State>` + `NotifierProvider<N, S>(N.new)` 体例(沿 P1.1 `recruitmentNotifier` 同 API)。

## 挂账

| # | 项 | 落处 |
|---|---|---|
| 1 | tournament_03..08 narrative 完整 5-8 条(春秋赛事 ✓ 群英会 ✓ · 余 6 主题:比武大会 / 华山论剑 / 门派友谊赛 / 正邪辩武 / 武林大会 / 江南论剑)| 下波文案 batch |
| 2 | sect_screen 真持久化 wire writeTxn 验收(SectSchema/SectEventSchema 加 _allSchemas + saveVersion 0.13.0 + StreamProvider 切 Isar collection)| Phase 4 真持久化 batch |
| 3 | monthly_tick 真接 Riverpod tick(`lib/core/game_loop/monthly_tick.dart` 新建 · 调 `SectEventService.checkAndTrigger` + `SectReputationDecayService.computeDecay`)| Phase 4 game_loop batch |
| 4 | SectEventDialog 真 BattleScreen wire(StageBattleSetup + buildMirrorEnemyTeam 镜像同境界 enemy team + push BattleScreen + Completer 等结算 outcome)| Phase 4 战斗联动 batch |
| 5 | sect_screen_test R4.4 `UncontrolledProviderScope` + 真 Isar inMemory 验 writeTxn 持久化 | Phase 4 真持久化 batch 同期 |

## 工作量复盘

- 估时:nightshift ~25-35min(spec §8 第 3+4+5 行 ~4h xhigh 压缩)
- 实测:reality check + service review(~10min) → UiStrings + main_menu(~5min) → sect_providers + SectScreen + SectEventDialog(~25min) → narrative + tests(~15min) → analyzer fix(Notifier 3.x + override 方法名) + closeout + commit(~10min)
- 一次 analyzer 失败修复:`StateNotifier` → `Notifier` API 切换 + `overrideWith` → `overrideWithValue`;无运行时 fail。
- 决策点保留 spec §4 「default ground strategy 不引入新数值轴」精神 · 不实施 BattleScreen e2e wire(留挂账)· §5.4 数值红线零碰。

---

**P3.4 §12.1 sect_event 主链路 100% 完整闭环 ✅**(schema · service · UI · narrative stub · 测族 · Riverpod wire)· 余 4 挂账走 Phase 4 真持久化 + 战斗联动 batch 落。
