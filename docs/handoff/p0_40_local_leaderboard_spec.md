# P0.2 #40 本地排行榜 + Supabase placeholder · 完整 spec

> **任务级别**:P0 阶段第二波(1.0 路线图 ROADMAP_1_0.md P0.2 / 挂账 #40)
> **预估**:opus xhigh **6-10h**(5 phase,跨 schema bump + service + UI + test)
> **开工模型**:必须 **opus xhigh**(跨 schema + service + UI + test 跨模块大改,memory `feedback_model_selection` 实战锚点)
> **commit 前缀**:`[feat]`(schema 改动 commit 用 `[schema]`)
> **作者**:Mac + Opus 4.7 · 2026-05-17 起草

---

## 1. 背景

外部审查(2026-05-17)发现 GDD §8.2「通关层数决定排行榜位置(Supabase 同步)」当前未闭环 — 仓库 0 supabase 包 / 0 client / 0 leaderboard service / 0 排行榜 UI,只有:

- `data/numbers.yaml line 1054-1058` `leaderboard.sync_to_supabase: true` + 3 字段配置(死配置,0 读取)
- `lib/core/domain/save_data.dart:42` `towerLeaderboardSyncedAt: DateTime?`(死字段,0 业务读写)
- `lib/core/domain/save_data.dart:40` `highestTowerLayer: int = 0`(死字段,0 业务读写)

**项目策略拍板**(Phase 0 reality check 后 2026-05-17):**方案 D · 延后接 backend,先做本地链 + itch.io 公开**(详 §3 决议)。

**根治目标**:Demo 阶段提供完整本地排行榜功能(读 `TowerProgress` 真源)+ 预留 Supabase placeholder 接口(future-proof);itch.io 公开后看玩家量级再决定是否升 Pro plan($25/月)接真 backend。

## 2. Reality check 现状盘点

### 2.1 真源已闭环(`TowerProgress` 实体)

`lib/features/tower/domain/tower_progress.dart`(已实装):

| 字段 | 当前状态 | Demo 排行榜价值 |
|---|---|---|
| `highestClearedFloor` | ✅ recordClear 已维护(单调递增) | 主指标 |
| `totalAttempts` | ✅ recordClear/recordDefeat 已增 | 次指标 |
| `totalDefeats` | ✅ recordDefeat 已增 | 派生指标(可显胜率) |
| `highestClearedAt` | ✅ 首通时间已记 | 时间锚 |
| `createdAt` | ✅ getOrCreate 已记 | 玩家入坑时间 |
| **`bestClearTime`** | ❌ **缺**(本 spec Phase 1 新加) | 第 3 指标 |
| **`perFloorClearTimes`** | ❌ **缺**(本 spec Phase 1 新加) | bestClearTime 派生源 |
| **`lastClearedAt`** | ❌ **缺**(本 spec Phase 1 新加) | 最近活跃锚 |

### 2.2 死字段保留(用户决议)

| 字段 | 决议 |
|---|---|
| `SaveData.highestTowerLayer` (line 40) | 保留不动 |
| `SaveData.towerLeaderboardSyncedAt` (line 42) | 保留不动 |

**理由**:Demo 期未发包无玩家存档冲击,但 schema 不改保守。未来 backend 接入时这两个字段可能复活(highestTowerLayer 作 SaveData 层 cache 副本,towerLeaderboardSyncedAt 作上次同步时间锚)。本 spec 不动这两个字段。

### 2.3 numbers.yaml 配置

`data/numbers.yaml:1054-1058`:

```yaml
leaderboard:
  sync_to_supabase: true                   # 通关后同步到 Supabase
  sync_throttle_seconds: 60                # 节流:每 60 秒最多同步一次
  track_metrics: ["highest_layer", "best_clear_time", "total_attempts"]
```

**本 spec 处理**:配置保留不改(本会话 placeholder 实现读取后 noop,sync_to_supabase: true 在 NoopSync 下不触发任何网络调用,等同 false 行为但保配置语义)。

### 2.4 Supabase 项目盘点(2026-05-17 实测)

org `odrdinciulqlhiubaxre`(Zed1118's Org,仅 1 org),3 projects:Saibandao(INACTIVE)/ LifeTimeApp(ACTIVE)/ SalesCRM(ACTIVE)。**org 内 2 active 已满**(免费版限 2),与 memory `feedback_supabase_freetier_quota` 一致。

**结论**:Demo 阶段不动 Supabase 项目(本 spec D 方案)。未来若升 Pro plan 接真 backend,新建独立 wuxia_idle project 替换 placeholder(无配额冲击)。

## 3. 决议

### 3.1 方案 D · 延后接 backend(2026-05-17 拍板)

| 子项 | 决议 |
|---|---|
| Demo 期 Supabase 接入 | **不接**(0 supabase 包 / 0 network call) |
| 本地排行榜真源 | 直接读 `TowerProgress` 实体 |
| Supabase service 抽象层 | **做** placeholder(LeaderboardSyncService abstract + NoopLeaderboardSync 实现) |
| 死字段(SaveData) | **保留**(0 schema bump 涉及死字段) |
| best_clear_time schema 字段 | **加**(TowerProgress Phase 1 schema bump,本 spec 落地) |

### 3.2 范围拆解(5 Phase)

| Phase | 内容 | 估时 |
|---|---|---|
| 0 | Reality check + Supabase 项目策略选型(本会话完成) | 0.5h(已完成) |
| 1 | TowerProgress schema bump + Isar migration + g.dart 重生 + 红线 test | 1.5-2h |
| 2 | runTowerFlow 接计时 + recordClear API 扩展(elapsedMs)+ TowerProgressService test 更新 | 1-2h |
| 3 | LeaderboardSyncService 抽象 + NoopLeaderboardSync 实现 + victory hook 注入 + service test | 1-2h |
| 4 | LeaderboardScreen UI + 主菜单按钮 + strings.dart 文案 + Phase2TestMenu 视觉验收按钮 + widget test | 1.5-2.5h |
| 5 | verify(test 全过 + analyze 0 issues)+ closeout + PROGRESS 销账 #40 | 0.5-1h |

**Phase 1+2 可串行(schema + service 紧耦合)**,Phase 3+4 紧接,Phase 5 收尾。**单会话 opus xhigh 6-10h 一波收口**(memory `feedback_claude_print_task_duration` 估时锚:大型 spec 落地 6-10h 现实)。

## 4. 实装细节

### 4.1 Phase 1 · TowerProgress schema bump

**改动文件**:

| 文件 | 操作 |
|---|---|
| `lib/features/tower/domain/tower_progress.dart` | 加 3 字段:`bestClearTime: int?`(ms)/ `perFloorClearTimes: List<int> = []`(ms,index = floorIndex-1)/ `lastClearedAt: DateTime?` |
| `lib/features/tower/domain/tower_progress.g.dart` | `dart run build_runner build --delete-conflicting-outputs` 重生 |

**Field 语义**:

```dart
/// 各层首通耗时(ms),index = floorIndex - 1
/// 第 N 层首通后写 perFloorClearTimes[N-1] = elapsedMs;
/// 重打不覆盖(锁首通耗时,防玩家强化后刷新数据)
List<int> perFloorClearTimes = [];

/// 全塔最佳通关耗时(ms,即 perFloorClearTimes 非空时的 min)
/// 派生字段,recordClear 时同步计算
/// 0 = 无通关数据
int? bestClearTime;

/// 最近一次通关时间(任何层 + 首通/重打都更新)
/// 与 highestClearedAt(只锁首通最高层) 区分
DateTime? lastClearedAt;
```

**Migration**:Isar 自动加新字段默认值(`bestClearTime = null` / `perFloorClearTimes = []` / `lastClearedAt = null`),旧存档无 migration 风险。**Phase 2 reality check**:跑 `flutter test` 看 g.dart 重生后 query API 是否破坏现有 test。

### 4.2 Phase 2 · runTowerFlow 接计时

**改动文件**:

| 文件 | 操作 |
|---|---|
| `lib/features/tower/presentation/tower_entry_flow.dart` | `_runTowerBattle` 加 stopwatch,完成时计算 elapsedMs |
| `lib/features/tower/application/tower_progress_service.dart` | `recordClear(floorIndex, now, elapsedMs)` 签名扩展 + 写 perFloorClearTimes / 重算 bestClearTime / 更新 lastClearedAt |

**runTowerFlow 改动**(line 50-188 内):

```dart
// _runTowerBattle 内 stopwatch
final stopwatch = Stopwatch()..start();
// ... 战斗等待 ...
stopwatch.stop();
final elapsedMs = stopwatch.elapsedMilliseconds;

// recordClear 调用扩展
clearResult = await svc.recordClear(
  floorIndex: floor.floorIndex,
  now: DateTime.now(),
  elapsedMs: elapsedMs,
);
```

**recordClear 改动**:

```dart
Future<TowerClearResult> recordClear({
  required int floorIndex,
  required DateTime now,
  required int elapsedMs,  // 新增
}) async {
  // ... 现有逻辑(单调递增 highestClearedFloor)...
  
  // 新增:perFloorClearTimes / bestClearTime / lastClearedAt 更新
  await isar.writeTxn(() async {
    // 首通锁首通时间(重打不覆盖)
    if (progress.perFloorClearTimes.length < floorIndex) {
      // pad with 0 to floorIndex - 1 then set
      final padded = List<int>.from(progress.perFloorClearTimes);
      while (padded.length < floorIndex - 1) padded.add(0);
      padded.add(elapsedMs);
      progress.perFloorClearTimes = padded;
    } else if (progress.perFloorClearTimes[floorIndex - 1] == 0) {
      // 历史空位补首通
      final patched = List<int>.from(progress.perFloorClearTimes);
      patched[floorIndex - 1] = elapsedMs;
      progress.perFloorClearTimes = patched;
    }
    // 重打不写 perFloorClearTimes(对应 GDD §5.1 反主流防刷)
    
    // 重算 bestClearTime(派生)
    final nonZero = progress.perFloorClearTimes.where((t) => t > 0);
    progress.bestClearTime = nonZero.isEmpty ? null : nonZero.reduce((a, b) => a < b ? a : b);
    
    progress.lastClearedAt = now;
    
    await isar.towerProgress.put(progress);
  });
  
  return (isFirstClear: ..., highestAfter: progress.highestClearedFloor);
}
```

**测试更新**:

| 文件 | 改动 |
|---|---|
| `test/features/tower/application/tower_progress_service_test.dart` | recordClear 调用全部加 elapsedMs 参数 + 新 case:首通写 perFloorClearTimes / 重打不覆盖 / bestClearTime 派生正确 / lastClearedAt 更新 |
| `test/features/tower/presentation/tower_entry_flow_test.dart` | clearRecorderForTest 签名扩展(if exists),不破坏现有 DI |

### 4.3 Phase 3 · LeaderboardSyncService 抽象

**新建文件**:

```
lib/features/tower/application/leaderboard_sync_service.dart
```

**Abstract interface + Noop 实现**:

```dart
/// 排行榜同步抽象(P0.2 D 方案 placeholder,1.0 上线 Pro plan 后接真 Supabase)
abstract class LeaderboardSyncService {
  /// 上报一次通关(victory hook 内调用)
  /// 实现端负责节流(numbers.yaml leaderboard.sync_throttle_seconds=60)
  Future<void> reportClear({
    required int highestFloor,
    required int? bestClearTimeMs,
    required int totalAttempts,
    required DateTime clearedAt,
  });
}

/// Noop 实现(D 方案下默认注入,0 network call)
/// 未来接 Supabase 时新建 SupabaseLeaderboardSync 实现并替换 provider 注入
class NoopLeaderboardSync implements LeaderboardSyncService {
  const NoopLeaderboardSync();
  
  @override
  Future<void> reportClear({
    required int highestFloor,
    required int? bestClearTimeMs,
    required int totalAttempts,
    required DateTime clearedAt,
  }) async {
    // intentionally noop
  }
}
```

**Provider 注入**(`lib/features/tower/application/tower_providers.dart`):

```dart
@riverpod
LeaderboardSyncService leaderboardSync(Ref ref) {
  // 1.0 Pro plan 接入时改返回 SupabaseLeaderboardSync(ref.read(supabaseClient))
  return const NoopLeaderboardSync();
}
```

**victory hook 注入**(`tower_entry_flow.dart` line 142 附近,drops 持久化后):

```dart
// 排行榜同步(D 方案下 Noop,future-proof 接口)
if (clearResult.isFirstClear) {
  final sync = ref.read(leaderboardSyncProvider);
  final progress = await TowerProgressService(isar: IsarSetup.instance)
      .getOrCreate(saveDataId: IsarSetup.currentSlotId);
  unawaited(sync.reportClear(
    highestFloor: progress.highestClearedFloor,
    bestClearTimeMs: progress.bestClearTime,
    totalAttempts: progress.totalAttempts,
    clearedAt: progress.lastClearedAt ?? DateTime.now(),
  ).catchError((e, st) {
    debugPrint('leaderboard sync failed: $e\n$st');
  }));
}
```

**测试新建**:

| 文件 | case |
|---|---|
| `test/features/tower/application/leaderboard_sync_service_test.dart` | NoopLeaderboardSync.reportClear 不抛 / 0 副作用 / 接口契约 3 字段(highest/best/attempts) |
| `tower_entry_flow_test.dart` 扩展 | victory 时调 sync.reportClear(可用 fake LeaderboardSync 注入,验证 highestFloor 传值正确) |

### 4.4 Phase 4 · LeaderboardScreen UI

**新建文件**:

```
lib/features/tower/presentation/leaderboard_screen.dart
```

**3 指标展示**:

```dart
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(towerProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(UiStrings.leaderboardTitle)),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SelectableText('$e')),
        data: (progress) => _buildContent(progress),
      ),
    );
  }
  
  Widget _buildContent(TowerProgress p) {
    if (p.highestClearedFloor == 0) {
      return const Center(child: Text(UiStrings.leaderboardEmpty));
    }
    return ListView(
      children: [
        _MetricTile(
          label: UiStrings.leaderboardHighestLayer,
          value: '${p.highestClearedFloor} ${UiStrings.leaderboardLayerSuffix}',
        ),
        _MetricTile(
          label: UiStrings.leaderboardBestClearTime,
          value: p.bestClearTime == null
              ? UiStrings.leaderboardNoData
              : _formatDuration(p.bestClearTime!),
        ),
        _MetricTile(
          label: UiStrings.leaderboardTotalAttempts,
          value: '${p.totalAttempts}',
        ),
        if (p.totalDefeats > 0)
          _MetricTile(
            label: UiStrings.leaderboardWinRate,
            value: _formatWinRate(p),
          ),
      ],
    );
  }
}

String _formatDuration(int ms) {
  final seconds = (ms / 1000).round();
  if (seconds < 60) return '$seconds 秒';
  return '${seconds ~/ 60} 分 ${seconds % 60} 秒';
}

String _formatWinRate(TowerProgress p) {
  if (p.totalAttempts == 0) return '0%';
  final wins = p.totalAttempts - p.totalDefeats;
  final pct = (wins * 100 / p.totalAttempts).round();
  return '$pct%';
}
```

**主菜单按钮**(`lib/features/main_menu/presentation/main_menu_screen.dart` 或同等位置):加「排行榜」按钮 push LeaderboardScreen。

**strings.dart 扩展**(`lib/shared/strings.dart`):

```dart
// 排行榜(P0.2 #40)
static const String leaderboardTitle = '排行榜';
static const String leaderboardEmpty = '尚未通关任何爬塔层';
static const String leaderboardHighestLayer = '最高通关层';
static const String leaderboardLayerSuffix = '层';
static const String leaderboardBestClearTime = '最佳通关耗时';
static const String leaderboardTotalAttempts = '累计挑战次数';
static const String leaderboardWinRate = '胜率';
static const String leaderboardNoData = '—';
```

**Phase2TestMenu 视觉验收按钮**(`lib/features/debug/presentation/phase2_test_menu.dart`):加 14th 按钮 VC-LEADERBOARD,seed 一些 TowerProgress 数据(e.g. 通过 5 层,perFloorClearTimes 模拟值)+ push LeaderboardScreen。

**widget test**:

| 文件 | case |
|---|---|
| `test/features/tower/presentation/leaderboard_screen_test.dart` | 空态 / 通 5 层 3 指标渲染 / bestClearTime null 显示 — / winRate 派生正确 |
| `test/features/main_menu/main_menu_screen_test.dart`(if exists) | 按钮数 +1 + push LeaderboardScreen 测试 |
| `test/features/debug/phase2_test_menu_test.dart` | 按钮数 13 → 14(对齐 W18-A1 VC18-A1 模式)|

### 4.5 Phase 5 · verify + closeout

**verify**:

```bash
flutter test  # 全过(873 + Phase 1-4 新增 case)
flutter analyze  # 0 issues
```

**closeout**:`docs/handoff/p0_40_local_leaderboard_closeout_2026-05-17.md`(对齐 #38 closeout 体例)

**PROGRESS 销账**:#40 标 ✅,下波切 P0.3 itch.io 发包(#41)

## 5. 验收红线

| 红线 | 验收方法 |
|---|---|
| TowerProgress schema bump 不破坏旧存档 | Phase2 seed 旧存档(0 perFloorClearTimes)load 后 bestClearTime = null 不抛 |
| 重打不覆盖首通耗时(GDD §5.1 反主流) | tower_progress_service_test.dart 显式 case |
| bestClearTime 派生公式正确(min over 非零) | tower_progress_service_test.dart 显式 case |
| LeaderboardSyncService 接口 future-proof | 抽象类 + Noop 实装契约,新增 Supabase 实现时 0 victory hook 改动 |
| numbers.yaml leaderboard.sync_to_supabase 配置保语义 | Noop 实现下 sync_to_supabase=true 等同 sync_to_supabase=false 行为(0 network call) |
| 主菜单 + LeaderboardScreen 0 raw defId 暴露 | widget test 渲染断言 |
| Phase2TestMenu 按钮数对齐(13 → 14) | phase2_test_menu_test.dart 按钮数 + 顺序断言 |
| flutter test 全过 + analyze 0 issues | Phase 5 verify |

## 6. 风险

| # | 风险 | 应对 |
|---|---|---|
| R1 | Isar @collection schema bump 破坏旧存档 | Phase 1 Migration 验证旧存档 load 后新字段默认值 OK(Isar 自动加,memory `feedback_isar_pitfalls` 引用) |
| R2 | List<int> @embedded fixed-length 问题(memory `feedback_isar_pitfalls`) | recordClear 内必须 `List.from(progress.perFloorClearTimes)` 转 growable 再写,与 W13 skillUsageCount fix 同套路 |
| R3 | victory hook stopwatch 计时不准(BattleScreen push/pop 动画时间也算进去) | Phase 2 计时起点定位:战斗 startBattle 后第一帧(BattleScreen build 完),终点定位 onVictory/onDefeat 回调触发;不算 push/pop 动画 |
| R4 | 主菜单按钮位置冲突(已有 9 按钮 W17 lineage 后) | Phase 4 grep main_menu_screen.dart 现有按钮顺序,排行榜按钮插入位置(建议爬塔按钮下方) |
| R5 | LeaderboardSyncService provider 注入位置可能与现有 ref.read 体例冲突 | Phase 3 用 @riverpod 函数式 provider(对齐 lib/features/tower/application/tower_providers.dart 体例) |
| R6 | placeholder 抽象未来 Supabase 接入时接口可能不够 | Phase 3 接口设计 review:reportClear 4 字段是否够 Supabase RPC?GDD §8.2 只要 highest_layer + best_clear_time + total_attempts,4 字段够 |

## 7. 测试矩阵

| Phase | 测试文件 | case 增量 |
|---|---|---|
| 1 | tower_progress_test.dart(可能新建) | 3 字段默认值 / migration 不破 |
| 2 | tower_progress_service_test.dart | recordClear elapsedMs 4 case(首通写/重打不覆盖/bestClearTime 派生/lastClearedAt 更新) |
| 2 | tower_entry_flow_test.dart | clearRecorderForTest elapsedMs DI 适配(if exists)|
| 3 | leaderboard_sync_service_test.dart(新建) | 3 case(Noop 不抛 / 0 副作用 / 接口契约)|
| 3 | tower_entry_flow_test.dart 扩展 | 1 case fake LeaderboardSync 注入验证 reportClear 调用 |
| 4 | leaderboard_screen_test.dart(新建) | 4-5 case(空态/3 指标渲染/bestClearTime null/winRate 派生/总计数显示) |
| 4 | main_menu_screen_test.dart | +1 case(if exists,按钮数 + push) |
| 4 | phase2_test_menu_test.dart | 按钮数 13 → 14 + VC-LEADERBOARD 顺序 |

**总增量**:**~15-20 case**,873 → ~890+。

## 8. 相关 memory(实战引用)

| memory | 引用场景 |
|---|---|
| `feedback_supabase_freetier_quota` | §2.4 Supabase 项目盘点策略;§3.1 D 方案理由 |
| `feedback_proxy` | 未来 Phase 6 Pro plan 接 Supabase 时 supabase CLI / mcp call 自动清 proxy |
| `feedback_isar_pitfalls` | §6 R2 List<int> 转 growable;Phase 1 Migration |
| `feedback_model_selection` | 估时 6-10h 必 opus xhigh |
| `feedback_claude_print_task_duration` | 大型 spec 落地 6-10h 现实校准 |
| `feedback_red_line_test_semantics` | §5 验收红线写法(约束语义不写瞬时事实) |
| `feedback_layered_bugs` | Phase 1-4 同会话推进时,修上层 schema 后下层公式 bug 可能浮现 |
| `feedback_riverpod_codegen_provider_split` | §4.3 Provider 设计对齐已有 tower_providers.dart 体例 |
| `feedback_riverpod_lint_plugin_enable` | LeaderboardSyncService 抽象类不强制 @Dependencies(0 scope 依赖) |

## 9. 决策日志

| 时间 | 决策点 | 选择 | 备注 |
|---|---|---|---|
| 2026-05-17 | Supabase 项目策略 | D 方案延后接 backend | 0 付费 / Demo 先看玩家量级 / 1.0 16 月预算 $400 待数据验证 |
| 2026-05-17 | best_clear_time schema | 加(Phase 1 schema bump) | numbers.yaml track_metrics 3 项全接;backend 接入时 0 schema 军改 |
| 2026-05-17 | SaveData 死字段处理 | 保留不动 | 0 schema bump 风险;未来 backend 接入时复活作 cache 副本 |
| 2026-05-17 | Supabase placeholder | 做 abstract + Noop | 0 backend 依赖 + 接口预留,接入 Supabase 时 0 victory hook 改动 |

---

**起草完成**(本会话 Mac + Opus 4.7 Phase 0 reality check + spec 起草 ~1h)。

**下波实装**:opus xhigh 6-10h 新会话,从 Phase 1 schema bump 起步,5 phase 一波收口 + closeout + PROGRESS 销账 #40。
