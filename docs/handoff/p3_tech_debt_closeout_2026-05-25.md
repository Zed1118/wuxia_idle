# P3 技术债 3 合一收口 · nightshift T19b (2026-05-25)

闭包 `stage_audit_1_0_overall_2026-05-24.md` §7.2-7.4 挂账的 3 项技术债。
0 行为变化 · 纯重构 · `flutter analyze` 0 issue · 1429 tests pass。

## 已闭包项

### 7.2 PvpDef + SectEventDef 强类型(NumbersConfig)

- `lib/data/numbers_config.dart` 加 `PvpDef` + `SectEventDef` 两个 def 类
  (沿 `JianghuConfig` + `HeritageItems` 体例,empty 兜底)。
  - `PvpDef`:elo / matchRange / sync / history / unlockRequiresStage
  - `SectEventDef`:tournament / reputation / sectLevel / activeEventsMax
- `pvp_service.dart` 删 `pvpCfgFor(NumbersConfig)` raw map 取值,改 `numbers.pvp.elo.kFactor` 直接读。
- `sect_event_service.dart` 删 `numbers.raw['sect_event']` map cast,改 `numbers.sectEvent.tournament.cooldownDays` 直接读。
- `sect_reputation_decay.dart` 删 raw map 取值。
- `pvp_providers.dart` 同步切到 `numbers.pvp.elo.initial`。

### 7.3 Sect / SectEvent / PvpRecord / PvpSnapshot Isar 持久化

- `lib/data/isar_setup.dart` `_allSchemas` 加 4 schema:`SectSchema` /
  `SectEventSchema` / `PvpRecordSchema` / `PvpSnapshotSchema`。
- `_currentSaveVersion` 0.12.0 → **0.13.0**(合并 P1.2 ReputationSchema/NpcRelationSchema 已加 + T19b 4 schema 加)。
- `sect_providers.dart` 删 `SectStateNotifier` 内存 state,改:
  - `currentSectProvider` StreamProvider 读 `isar.sects.watchObject(1)`(Isar 未 init 兜底返默认 sect)
  - `activeSectEventsProvider` / `historicalSectEventsProvider`
    走 `filter().statusEqualTo(...).watch()`
  - `resolveSectEventProvider`(AsyncNotifier)`isar.writeTxn` 落 sect + event
  - `seedSectEventProvider`(AsyncNotifier)月度 tick 写 pending event
- `sect_screen.dart` 切 `AsyncValue.when` 三态(data/loading/error + null sect 兜底文案)。
- `sect_event_dialog.dart` 加 `sect` 必传参,调 `resolveSectEventProvider.notifier.resolve(sect, event, outcome)`。

### 7.4 systemClock Riverpod provider

- 新 `lib/core/application/system_clock_provider.dart`(`SystemClock` +
  `systemClockProvider`,测试可 override 注 FakeClock)。
- Scope 留窄:只切 `pvp_service.dart`(`PvpRecord.timestamp` / `_newMatchId`)
  + `sect_providers.dart`(default sect createdAt)+ `resolveSectEvent.resolve`(now)。
- 其他模块的 `DateTime.now()` 留旧路径(避无谓 diff,sect/pvp 是先头部队)。

## R5 baseline

```
flutter analyze --no-fatal-warnings   → No issues found
flutter test (full suite)              → +1429 ~1: All tests passed
```

4 新测族:
- `test/data/numbers_config_pvp_def_test.dart` 5 测(R1.1-R1.5 全字段 + 4 路兜底)
- `test/data/numbers_config_sect_event_def_test.dart` 5 测(R2.1-R2.5)
- `test/core/application/system_clock_provider_test.dart` 2 测(R3.1-R3.2)
- `test/features/sect/sect_isar_persistence_test.dart` 5 测(R4.1-R4.5,real Isar
  open/writeTxn/close/reopen 走完整 round-trip)

更新现有测族:
- `test/data/isar_setup_test.dart` saveVersion 0.12.0 → 0.13.0
- `test/features/pvp/pvp_service_test.dart` R3.8 切强类型 `numbersCfg.pvp.elo.kFactor`
- `test/features/sect/sect_screen_test.dart` StreamProvider override 体例
  (替原 `seedActiveEvent` 内存 state mutation),加 R4.5 sect=null 兜底
- `test/features/sect/sect_battle_integration_test.dart` 删 R1.5-R1.7 内存
  state e2e(语义迁 sect_event_service_test.dart 已有测 + 新 sect_isar_persistence)
- `test/features/sect/sect_event_service_test.dart` /
  `sect_reputation_decay_test.dart` NumbersConfigStub 加 `sectEvent` + `pvp`
  getter(覆盖 noSuchMethod 缺槽)

## 不变量

- §5.4 红线 0 碰(纯解析层重构,无新数值)
- pvp/sect service 行为 0 变化(强类型读 = 原 raw map 读相同值)
- saveVersion 升级仅扩 schema,无字段语义变化(老存档可直读)

## 挂账归档

- `stage_audit_1_0_overall_2026-05-24.md` §7.2 / §7.3 / §7.4 三条全部销账
- `numbers_config.dart` 顶部「raw map 取值,后续阶段按需逐步强类型化」一句仍保留,
  剩余强类型化范围是 equipment / techniques 等(独立挂账,本 task 不动)。
