# 离线结算闭环（体检 P0-3）设计 spec

**日期**:2026-07-07 · **分支**:`worktree-offline-settlement-loop` · **基点**:main `e8f99d28`
**来源**:`docs/audit/full_project_bughunt_2026-07-07.md` P0-3 · 用户拍板方案 B（聚焦结算 + 前台心跳 + 统一基准写入 controller）

## 1. 病根（现码核实,file:line 本会话 grep）

被动离线结算唯一入口 = HomeFeed 首帧一次（`home_feed_screen.dart:44` → `offline_recap_gate.dart:95`）;生命周期侧 `main.dart:68-78` onHide/onInactive/onDetach 只 `touchOnlineNow` 重置基准**不结算**。后果:

- **丢失**:挂后台 8h → 重新聚焦继续玩 → 该窗口永不结算,下次失焦基准又被推前,收益静默清零。违 §5.5（关游戏 8h 该有的收益,挂后台 8h 没有）。
- **双吃**:退出时 onDetach fire-and-forget 写不进 → 基准停在更早时刻 → 下次启动把实际在线游玩时段按离线补发。
- **边角（顺带修）**:有 active 闭关时（范围 A）基准整段不更新,收功后残留 stale 基准 → 下次被动结算把闭关时段再吃一遍。

## 2. 设计（方案 B）

### 2.1 新组件 `OnlinePresenceController`

`lib/features/seclusion/application/online_presence_controller.dart`,经 keepAlive provider `onlinePresenceControllerProvider` 暴露（main.dart 与 gate 共享同一实例,测试可 override）。**基准（`SaveData.lastOnlineAt`）的生命周期侧写入全部收进本类**,`IsarSetup.touchOnlineNow` 保持为底层原语。

状态:`_heartbeat Timer?`、`_startupSettleDone bool`、`_busy bool`（settle/touch 串行守卫）。

| 入口 | 行为 |
|---|---|
| `onAppFocused()`（onShow/onResume） | `_startupSettleDone==false` → 整体 no-op（首启结算归 gate,防心跳提前刷新基准毁掉离线窗口）。否则:静默结算聚焦前窗口（§2.2）→ 起心跳。已在前台重复触发 = 幂等 no-op。 |
| `onAppBlurred()`（onHide/onInactive/onDetach） | 停心跳 + 终 touch（best-effort,catch 兜底）。 |
| 心跳 tick（前台每 60s） | `touchOnlineNow`;`_busy` 时跳过本拍。 |
| `markStartupSettleDone()` | gate 首启路径完成后调;置位 + 起心跳。 |
| `dispose()` | 取消 timer。 |

心跳间隔为**纯防御工程参数**（只影响双吃上界,不影响任何收益数值）,以 `static const` 留在代码,不进 numbers.yaml;若未来要调平衡再迁。

### 2.2 静默结算（聚焦路径）

从 `offline_recap_gate.dart` 范围 B 抽共享核心 `settlePassiveWindow({required DateTime now})`（active 闭关查询直查 Isar RetreatSession,与 provider 同源,controller 不依赖 UI ref）:

1. Isar 未 init / 无存档 → null（no-op）。
2. **有 active 闭关 → 只 touch 不 settle**（互斥语义不变;touch 即修掉收功 stale 基准边角）。
3. 旧档首启（`lastOnlineAt == createdAt`）→ touch 不结算（既有分支,保留在共享核心）。
4. `awayHours ≤ 0` → no-op（时钟回拨防御,现状保留）。
5. 否则 `OfflinePassiveService.settle`（内部 txn 末重置基准,现状不动）。

gate 保留:弹卡逻辑（仅启动路径,阈值 minRecapHours 不变）+ 范围 A 收功引导,末尾调 `markStartupSettleDone()`。**聚焦结算不弹卡**（可能发生在任意屏,含战斗中,弹卡打断爽感;收益静默入包与「已静默入包不弹卡」现状语义一致）。

聚焦结算后 invalidate 结算触及的 provider（character/inventory 相关,参照 `stage_entry_flow.dart:374-380` 正确写法;Stream-based 的自刷新不必列）——防止本修复自己新增一例「结算了 UI 不刷新」（体检 P0-5 同类）。

### 2.3 main.dart 接线

`_WuxiaAppState`:AppLifecycleListener 增 `onShow`/`onResume` → `controller.onAppFocused()`;onHide/onInactive/onDetach 改为 → `controller.onAppBlurred()`;dispose 链 controller。原 `_recordOnline` 逻辑并入 controller。

## 3. 不变量与红线

- **§5.5 在线=离线**:正向修复(挂后台=关游戏);无任何加速/在线 buff。
- **零 schema 变更**:不加 SaveData 字段,不 bump saveVer,复用 `lastOnlineAt`。
- **零数值变更**:不动 numbers.yaml、compute 公式、cap/min_recap 语义。
- 弹卡 UX 不变(仅启动);互斥语义不变(active 闭关期间被动不结)。
- 不碰战斗/结算公式;聚焦静默 settle 与战后写档同为增量 txn,无共享内存状态。

## 4. 测试计划

纯 test()（Isar widget-test 死锁,memory 已记):

- R1 聚焦结算:基准 T0,focus(now=T0+8h) → 产量按 8h 入包、基准=now。
- R2 心跳压双吃:focus 后推进若干心跳 tick → 基准 ≈ 最后一拍;模拟无 blur 写的退出 → 重启 gate 结算窗口 ≤ 心跳间隔。
- R3 首启去重:`markStartupSettleDone` 前 `onAppFocused` 完全 no-op(不结算不起心跳);之后才起。
- R4 互斥:active 闭关时 focus → 只 touch,被动 0 入包。
- R5 无存档/未 init:全入口 no-op 不抛。
- R6 幂等/串行:前台重复 focus no-op;`_busy` 期间心跳跳拍。
- R7 既有 gate 测零回归(`offline_passive_gate_test`/`offline_recap_gate_test`)。
- R8 聚焦结算后 provider 刷新(container 测,characterById/inventory 读到新值)。
- 接线冒烟:widget 测经 `WidgetsBinding.handleAppLifecycleStateChanged` 驱动 listener,controller 注入 fake(不碰 Isar)。

## 5. 交付验证

analyze lib/ test/ 0 → seclusion + main 接线 targeted → **批末全量 `flutter test --no-pub`**(跨切面:触结算路径)→ 合 main 前 `git status -sb` 查分支漂移 → --no-ff 合入 → 主 checkout 复验 targeted → push + CI。

## 6. 已知不做(登记)

- 有 active 闭关且离线超 cap 后的「闭关外时段」被动不补(互斥 by design,动它=改收益语义,需另拍板)。
- 弹卡不在聚焦路径出现(体验取舍,如需「归来卡」再议)。
- P0-5/P1-6/8/11 等 invalidate 全面收口归体检批 3,本批只保证自己不新增此类。
