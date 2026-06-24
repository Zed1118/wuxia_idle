# B1 门派事件 + 声望衰减接通 game loop · 设计

> 全系统审计（`docs/audit/full_system_audit_2026-06-24.md` §B1）「系统建好未接 game loop」第二项。
> 2026-06-24 brainstorm 拍板：① 真实日历月锚 ② 仅 tournament。
> 子系统：全系统审计 B 组（A1+B2 已闭环，本项 B1）。

## 1. 问题（亲核确认）

门派事件死链三段，生产 **0 caller**：
- `MonthlyTickCoordinator.tick()`（`lib/core/game_loop/monthly_tick.dart:20`）— 文件头自承「最简 infra stub · Phase 4 wire」
- `SectEventService.checkAndTrigger()`（`sect_event_service.dart:29`）
- `SectReputationDecayService.computeDecay()`（`sect_reputation_decay.dart:21`）

后果：`activeSectEventsProvider` 恒空 → `sect_screen.dart` 完整的「active 事件列表 + 应战 CTA」UI **永不出现待结算事件**；声望永不衰减。

**下游已 100% 建好**（只缺上游喂数据）：`resolveSectEventProvider`（win/loss/expired 三态 Isar 落库）、`SectEventDialog`（CTA→结算，读 `data/lore/sect_event/{narrativeId}.yaml`）、10 个叙事文件、`systemClockProvider`、数值配置齐全（触发率 0.30 / cooldown 30 天 / trigger_realm_min yiLiu / expire 7 天 / decay 5/月 / active 上限 3）。

## 2. 设计目标 / 非目标

**目标**：让已建好的 tournament 比武事件循环在真实日历月锚上真正运转——触发 pending 事件、过期回收、声望衰减，端到端可见。

**非目标**：
- mission/crisis 事件（叙事文件留底，1.1+）；`event.type = tournament` 硬编码保留（当前 scope 正确，非 bug）。
- 应战真战斗 wire（`SectEventDialog` 现 `Random` 50/50 是 Demo 既有挂账，不在 B1 scope）。
- 改任何战斗数值 / 红线（本批 0 碰 §5.4）。

## 3. 架构

app open（HomeFeed 首帧，与 `maybeShowOfflineRecap` 并列）→ 月度 tick 编排。复用已建好的 `MonthlyTickCoordinator` 作 fire 原语（接通审计点名的第 3 个死符号）。重逻辑抽**纯函数** `SectMonthlyTickService`（不碰 Isar，可 `test()` 单测，沿现有 sect service「pure-ish」体例避 Isar autoIncrement 撞测，memory `feedback_isar_autoincrement_test_id_collision`）。

### 组件

1. **`Sect.lastTickAt`（新 nullable `DateTime?` 字段）** — 月度 tick 独立锚点，区别于 `lastEventAt`（cooldown/decay 锚=最后结算时刻）。**必要**：否则无法记录「已消费的月」，同日再开 app 会重复触发。Isar 对 nullable 新增字段向后兼容（旧记录读 null），需 build_runner 重生 `sect.g.dart`。saveVer 是否 bump 在 plan 阶段核（SaveData 未变，倾向不动）。

2. **`SectMonthlyTickService`（新 · `lib/features/sect/application/sect_monthly_tick_service.dart`）** — 纯函数：
   ```
   SectTickResult compute({
     required Sect sect,                  // 原地不 mutate，返新值在 result
     required List<SectEvent> activeEvents,
     required RealmTier playerRealm,
     required DateTime now,
     required Random rng,
     required SectEventService eventSvc,      // 复用 checkAndTrigger
     required SectReputationDecayService decaySvc,  // 复用 computeDecay
     required SectEventDef cfg,
   })
   ```
   `SectTickResult { List<SectEvent> newEvents, List<SectEvent> expiredEvents, int newReputation, int newSectLevel, DateTime newLastTickAt, DateTime? newLastEventAt }`。
   逻辑：
   - **过期扫描（每次都跑，不绑月界）**：activeEvents 中 `now.difference(triggeredAt).inDays >= cfg.tournament.expireDays(7)` → 该 event 标 expired，reputation += lossDelta（clamp ≥min）。解 active_events_max=3 占满死锁。
   - **月度 pass（≥1 完整月才跑）**：`elapsedMonths = (now.difference(lastTickAt ?? sect.createdAt).inDays / 30).floor()`。逐月迭代（≤elapsedMonths）：
     - 当前 active（含本 tick 已生成的）未达 cap → 调 `eventSvc.checkAndTrigger(... pickedNarrativeId = cfg.tournament.narrativeIds[rng pick])`；非 null → 加入 newEvents。
     - 调 `decaySvc.computeDecay(sect, now)` → reputation 累加（idle ≥30 天 → −decayPerMonthIdle/月）。
   - `newLastTickAt = (lastTickAt ?? createdAt).add(Duration(days: elapsedMonths * 30))`（保留 <30 天余数）；elapsedMonths==0 时不变。

3. **`sectMonthlyTickProvider`（新 Provider 持 `MonthlyTickCoordinator`）** — 构造时 `register` 一个调 `_runSectTick(ref, now)` 的 callback。keepAlive 普通 Provider 的 ref 可安全捕获（非 autoDispose / widget 瞬时 ref，不踩 `feedback_riverpod_closure_ref_disposed`）。

4. **`_runSectTick(Ref ref, DateTime now)`** — 经 `ref.read` 取 isar / 当前 sect / activeEvents / playerRealm / numbers / rng → 调 service.compute → `isar.writeTxn`：put newEvents、put expiredEvents、put 更新后的 sect（reputation + sectLevel + lastTickAt + lastEventAt）。Isar null（widget test）→ 提前 return no-op（沿 offline-recap 体例）；currentSect null（lazy-init race）→ skip。

5. **`maybeRunSectMonthlyTick(WidgetRef ref, {DateTime? now})`（新 · 同 offline_recap_gate 体例的顶层函数）** — HomeFeed 首帧调。内部 `ref.read(sectMonthlyTickProvider).tick(now ?? clock.now())`。

6. **numbers.yaml** `sect_event.tournament.narrative_ids: [tournament_01, tournament_02, tournament_03, tournament_04, tournament_05]`；`SectTournamentDef` 加 `List<String> narrativeIds`（fromYaml 解析，空兜底 `const []`）。tick 触发时 rng 选一个——配置驱动，不硬编码 id 进 dart（守 §5.6）。`narrativeIds` 为空时 checkAndTrigger 不调（防空 pick 崩）。

7. **HomeFeed 首帧**（`home_feed_screen.dart` initState `addPostFrameCallback`）加 `maybeRunSectMonthlyTick(ref)` 与 `maybeShowOfflineRecap` 并列。

8. **dev 调试触发** — sect_screen 顶部 dev-gated（`kDebugMode`）按钮，立即 fire 一次 tick（`now = clock.now()` 但强制 elapsedMonths≥1 走一遍），便于真实 30 天节奏下验收。位置/形态 plan 阶段定。

## 4. 数据流（每次 app open）

```
HomeFeed 首帧
  → maybeRunSectMonthlyTick(ref)
    → coordinator.tick(now)
      → _runSectTick(ref, now)
        → gather: isar / sect / activeEvents / playerRealm / numbers / rng
        → SectMonthlyTickService.compute(...)
            ├ 过期扫描：pending 超 7 天 → expired (rep −5)
            └ 月度 pass：floor(elapsedDays/30) 月，逐月 checkAndTrigger + computeDecay
        → writeTxn: put newEvents + expiredEvents + sect(rep/level/lastTickAt/lastEventAt)
  → StreamProvider watch 自动刷新 sect_screen
```

## 5. 错误处理 / 不变量

- Isar null / currentSect null → no-op skip。
- coordinator callback 异常被 `MonthlyTickCoordinator.tick` 吞掉隔离（既有行为）。
- 不变量：`reputation ∈ [min,max]=[0,100]`、`sectLevel ≤ 7`、newEvents 数 + 现 active ≤ active_events_max(3)。

## 6. 测试

- **纯 service 测**（`test()` 非 testWidgets · FakeClock + 种子 Random + 手搭 Sect/SectEvent）：
  - 月数 catch-up：0 月 no-op / 1 月 / 多月 / cap clamp（active 满不再生成）
  - 过期扫描：triggeredAt 6 天不过期、8 天过期 + rep −5
  - decay：idle ≥30 天扣、<30 不扣、多月累扣
  - rng 触发门控：概率 0 不触发、概率 1 触发
  - 不变量断言：rep clamp [0,100]、level ≤7
- **provider 落库路径**：沿现有 `sect_providers` 测体例（real Isar test 实例或 nullable 退化 no-op）。
- **无新战斗数值** → 不碰红线；不变量断言兜底。

## 7. 变更清单（预估）

| 文件 | 改动 |
|---|---|
| `lib/features/sect/domain/sect.dart` + `.g.dart` | 加 `lastTickAt` nullable 字段 + build_runner 重生 |
| `lib/features/sect/application/sect_monthly_tick_service.dart` | 新建纯函数 service + SectTickResult |
| `lib/features/sect/application/sect_providers.dart` | 加 `sectMonthlyTickProvider` + `_runSectTick` |
| `lib/features/sect/application/sect_monthly_tick_gate.dart` | 新建 `maybeRunSectMonthlyTick` 顶层函数（或并入 providers）|
| `lib/features/home_feed/presentation/home_feed_screen.dart` | 首帧加 tick 调用 |
| `lib/features/sect/presentation/sect_screen.dart` | dev-gated 调试触发按钮 |
| `data/numbers.yaml` + `lib/data/numbers_config.dart` | `narrative_ids` 配置 + `SectTournamentDef.narrativeIds` 解析 |
| `test/...` | 纯 service 测 + provider 测 |

零 saveVer（待 plan 核）/ 零产出数值变更 / 0 碰 §5.4 红线。
