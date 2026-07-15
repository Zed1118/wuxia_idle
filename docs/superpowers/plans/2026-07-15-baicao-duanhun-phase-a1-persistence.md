# 百草岭／断魂庄 Phase A1 实施计划 — 持久化基础与占用契约

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 冻结百草岭／断魂庄两套系统共享的持久化与占用契约——`SaveData` 永久进度字段、`ExpeditionRun`／`BossGauntletRun` 两个 active 会话 collection、`saveVersion` 0.36.0→0.37.0 可加性迁移、以及统一的 `CharacterOccupancyService` + 保留 DTO——使装备批、Phase B、Phase C 能在冻结接口上独立推进。

**Architecture:** 纯持久化 + 领域服务，**无任何玩法屏、无 numbers 调整、无战斗逻辑**。新增两个 Isar collection（照 `RetreatSession` active-session 体例）+ 一个 `@embedded` 成员快照；占用查询新建薄 `lib/features/activity/`，聚合闭关（既有 `Character.currentRetreatSessionId` 字段路径，零重做）+ 两个新会话，返回统一 `ActivityOccupancy` DTO。装备服务消费的 `reservedEquipmentIds` 类型（`Set<int>`）与装备 plan `isCandidateEligible` 签名对齐。

**Tech Stack:** Flutter Desktop · Isar（`isar_community` 3.x，`@collection`/`@embedded`/`build_runner`）· Riverpod 3.x · Dart。

**依赖：** 批1 冻结拍板（Q3 `SaveData` 加字段、Q5 保留 DTO）。**下游：** Phase A2、B、C 与装备批消费本计划冻结的 collection／DTO／schema。

**源规格：** `docs/superpowers/specs/2026-07-15-baicao-expedition-duanhun-gauntlet-design.md`（§8.1 占用查询／§8.3 持久化＋永久进度）＋ companion §3.3／§3.5／§4.1／§4.7。

---

## 前置（每个执行者开工先跑一次）

`.g.dart` 走 gitignore（fresh worktree 无生成代码）。本计划新增 `@collection`／`@embedded`／新 SaveData 字段均需 codegen：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Isar 测试需完整 `libisar.dylib`（fresh worktree 可能截断，见 memory `feedback_fresh_worktree_libisar_dylib`）。测试体例统一沿 `test/data/inner_force_qi_migration_test.dart`（`IsarSetup.init(directory: tempDir, inspector: false)` → 写 → `close` → 重 `init` 触发迁移 → 断言）。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/core/domain/save_data.dart` | 永久玩法进度唯一真相源（6 新字段） | Modify（§40/§92 体例后追加） |
| `lib/features/expedition/domain/expedition_run.dart` | 百草岭 active 会话 collection | Create |
| `lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart` | 断魂庄 active 会话 collection | Create |
| `lib/features/activity/domain/activity_member_snapshot.dart` | 两会话共享的成员快照 `@embedded` | Create |
| `lib/features/activity/domain/activity_occupancy.dart` | 占用/保留统一 DTO | Create |
| `lib/features/activity/application/character_occupancy_service.dart` | 唯一对外占用查询口 | Create |
| `lib/data/isar_setup.dart` | schema 注册 + 版本 + 迁移段 | Modify（`:82` `_allSchemas` / `:161` 版本 / `:368` 后加段7） |
| `test/**` | 各任务 TDD | Create |

> 命名边界：`ActivityMemberSnapshot` / `ActivityOccupancy` / `ActivityOccupancyEntry` / `ActivityKind` / `CharacterOccupancyService`（跨功能薄层，落 `lib/features/activity/`）；`ExpeditionRun` / `ExpeditionPolicy`；`BossGauntletRun` / `GauntletPhase`。这些名字被 Phase A2/B/C 与装备批引用，后续任务不得改名。

---

## Task 1: SaveData 永久进度字段（Q3）

**Files:**
- Modify: `lib/core/domain/save_data.dart`（在 `:92 grantedMilestoneEquipmentIds` 同区块后追加）
- Test: `test/core/domain/save_data_journey_progress_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/domain/save_data_journey_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('新 SaveData 的江湖远行永久进度字段取安全默认', () {
    final save = SaveData();
    expect(save.jianghuJourneyUnlocked, isFalse);
    expect(save.baicaoMaxDepth, 0);
    expect(save.expeditionRunSerial, 0);
    expect(save.clearedGauntletIds, isEmpty);
    expect(save.duanhunFirstClearedAt, isNull);
    expect(save.grantedTicketMilestoneIds, isEmpty);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/core/domain/save_data_journey_progress_test.dart`
Expected: 编译失败（`jianghuJourneyUnlocked` 等 getter 未定义）。

- [ ] **Step 3: 加字段**

在 `lib/core/domain/save_data.dart` 的 `grantedMilestoneEquipmentIds`（`:92`）之后、类闭合之前追加：

```dart
  // --- 江湖远行永久进度（0.37；companion Q3/§8.3，非 active 会话可承载）---

  /// 任一角色首达 Lv100 后永久解锁「江湖远行」；离队/传承/境界变化不回锁。
  bool jianghuJourneyUnlocked = false;

  /// 百草岭历史最深节点（展示用，§3.3）。
  int baicaoMaxDepth = 0;

  /// 远征序号；每次派遣自增，进稳定随机种子（§4.7）。
  int expeditionRunSerial = 0;

  /// 断魂庄首通 gauntlet id 集合（一次性防重，仿 [grantedMilestoneEquipmentIds]）。
  List<String> clearedGauntletIds = [];

  /// 断魂庄首通时间（展示用，§3.3；DateTime? 沿 [islandLastSettledAt] 体例）。
  DateTime? duanhunFirstClearedAt;

  /// 问鼎江湖第 10/20/30 层断魂帖·旧档补发防重（§6.4，F1 里程碑同款一次性体例）。
  List<String> grantedTicketMilestoneIds = [];
```

- [ ] **Step 4: 重跑 build_runner（SaveData schema 变了）+ 测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub test/core/domain/save_data_journey_progress_test.dart
```
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/core/domain/save_data.dart lib/core/domain/save_data.g.dart test/core/domain/save_data_journey_progress_test.dart
git commit -m "feat: SaveData 加江湖远行永久进度字段"
```

---

## Task 2: ActivityMemberSnapshot（`@embedded` 成员快照）

**Files:**
- Create: `lib/features/activity/domain/activity_member_snapshot.dart`
- Test: `test/features/activity/activity_member_snapshot_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/activity/activity_member_snapshot_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';

void main() {
  test('成员快照默认值安全，保留 id 列表可写', () {
    final m = ActivityMemberSnapshot()
      ..characterId = 7
      ..reservedEquipmentIds = [11, 12]
      ..reservedTechniqueIds = [3]
      ..currentHp = 500
      ..currentQi = 40
      ..isDowned = false;
    expect(m.characterId, 7);
    expect(m.reservedEquipmentIds, [11, 12]);
    expect(m.reservedTechniqueIds, [3]);
    expect(ActivityMemberSnapshot().isDowned, isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/activity/activity_member_snapshot_test.dart`
Expected: 编译失败（找不到 `ActivityMemberSnapshot`）。

- [ ] **Step 3: 实现 `@embedded`**

```dart
// lib/features/activity/domain/activity_member_snapshot.dart
import 'package:isar_community/isar.dart';

/// 活动会话（远征/断魂庄）内单个角色的关次/节点边界快照。
///
/// 保留字段 [reservedEquipmentIds]/[reservedTechniqueIds] 是占用契约的真相来源：
/// [CharacterOccupancyService] 聚合各 active 会话成员的这两列，供装备/心法/战斗入口
/// 统一查询（companion Q5/§3.5）。生命/真气/阵亡供 Phase B/C 的跨战继承。
@embedded
class ActivityMemberSnapshot {
  int characterId = 0;

  /// 出发/入场时冻结的装备 Isar id（`Character.equipped*Id` 快照）。
  List<int> reservedEquipmentIds = [];

  /// 出发/入场时冻结的心法 Isar id（`Character.mainTechniqueId` 及装配槽快照）。
  List<int> reservedTechniqueIds = [];

  int currentHp = 0;
  int currentQi = 0;
  bool isDowned = false;
}
```

- [ ] **Step 4: build_runner + 测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub test/features/activity/activity_member_snapshot_test.dart
```
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/features/activity/domain/activity_member_snapshot.dart test/features/activity/activity_member_snapshot_test.dart
git commit -m "feat: 加活动会话成员快照 embedded 类型"
```

---

## Task 3: ExpeditionRun collection

**Files:**
- Create: `lib/features/expedition/domain/expedition_run.dart`
- Test: `test/features/expedition/expedition_run_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/expedition/expedition_run_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

void main() {
  test('ExpeditionRun 默认值与方针枚举可用', () {
    final run = ExpeditionRun()
      ..saveDataId = 1
      ..policy = ExpeditionPolicy.yanJingCaiYao
      ..seed = 12345
      ..departedAt = DateTime(2026, 7, 15)
      ..currentNode = 3;
    expect(run.currentNode, 3);
    expect(run.policy, ExpeditionPolicy.yanJingCaiYao);
    expect(run.lastSettledAt, isNull);
    expect(run.members, isEmpty);
    expect(ExpeditionPolicy.values.length, 3);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/expedition/expedition_run_test.dart`
Expected: 编译失败（找不到 `ExpeditionRun`）。

- [ ] **Step 3: 实现 collection**

```dart
// lib/features/expedition/domain/expedition_run.dart
import 'package:isar_community/isar.dart';

import '../../../core/domain/reward_entry.dart';
import '../../activity/domain/activity_member_snapshot.dart';

part 'expedition_run.g.dart';

/// 出发方针（§4.3）；只改节点权重，不改奖励公式或战斗属性。
enum ExpeditionPolicy { yanJingCaiYao, xunJiFangYou, yiZhanLiXing }

/// 百草岭远征 active 会话（每存档同类最多一条，§8.3）。照 `RetreatSession` 体例。
@collection
class ExpeditionRun {
  Id id = Isar.autoIncrement;

  /// 多存档隔离（沿 `RetreatSession.saveDataId`）。
  late int saveDataId;

  @enumerated
  late ExpeditionPolicy policy;

  /// 稳定随机种子（= 存档标识 + 远征编号派生，§4.7）。
  late int seed;

  late DateTime departedAt;
  DateTime? lastSettledAt;

  /// 已完成节点数；离线结算按 `lastSettledAt → now` 顺序推进。
  int currentNode = 0;

  /// 出发快照 + 远征生命/真气状态。
  List<ActivityMemberSnapshot> members = [];

  /// 暂存奖励（返程/召回时一次性发放，§9.1）。
  List<RewardEntry> stagedRewards = [];
}
```

- [ ] **Step 4: build_runner + 测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub test/features/expedition/expedition_run_test.dart
```
Expected: PASS（`expedition_run.g.dart` 生成）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/expedition/domain/expedition_run.dart lib/features/expedition/domain/expedition_run.g.dart test/features/expedition/expedition_run_test.dart
git commit -m "feat: 加百草岭远征会话 collection"
```

---

## Task 4: BossGauntletRun collection（含托管栏 + awaitingRewardChoice）

**Files:**
- Create: `lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart`
- Test: `test/features/boss_gauntlet/boss_gauntlet_run_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/boss_gauntlet/boss_gauntlet_run_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

void main() {
  test('BossGauntletRun 默认停在第一关·战斗态，托管三列表平行', () {
    final run = BossGauntletRun()
      ..saveDataId = 1
      ..seed = 999
      ..escrowItemDefIds = ['item_liaoshangdan', 'item_xingnang_buji']
      ..escrowLoadedQty = [2, 1]
      ..escrowUsedQty = [0, 0];
    expect(run.currentStage, 1);
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.isFirstClearPending, isFalse);
    expect(run.rewardCandidateDefIds, isEmpty);
    // 托管三列表等长（不变式，Phase C2 消费）
    expect(run.escrowLoadedQty.length, run.escrowItemDefIds.length);
    expect(run.escrowUsedQty.length, run.escrowItemDefIds.length);
  });

  test('会话阶段枚举含 awaitingRewardChoice（Q4 崩溃恢复锚点）', () {
    expect(GauntletPhase.values, contains(GauntletPhase.awaitingRewardChoice));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/boss_gauntlet/boss_gauntlet_run_test.dart`
Expected: 编译失败（找不到 `BossGauntletRun`）。

- [ ] **Step 3: 实现 collection**

```dart
// lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart
import 'package:isar_community/isar.dart';

import '../../../core/domain/reward_entry.dart';
import '../../activity/domain/activity_member_snapshot.dart';

part 'boss_gauntlet_run.g.dart';

/// 断魂庄会话阶段（§9.2）。`awaitingRewardChoice` = Boss 已胜、待玩家三选一，
/// 崩溃/关闭重进强制恢复到奖励选择页，不再战斗或重抽候选（Q4）。
enum GauntletPhase { inBattle, interlude, awaitingRewardChoice, settled }

/// 断魂庄三连战 active 会话（每存档最多一条，§8.3）。检查点粒度 = 关次边界 + 整备页
/// （v1 不序列化战斗内逐动作，§5.6）。
@collection
class BossGauntletRun {
  Id id = Isar.autoIncrement;

  late int saveDataId;

  /// 稳定随机种子（= 存档标识 + 会话 + 关次派生，§5.6）。
  late int seed;

  /// 当前关次 1..3（1 苏无咎 / 2 石镇岳 / 3 闻九针）。
  int currentStage = 1;

  @enumerated
  GauntletPhase sessionPhase = GauntletPhase.inBattle;

  /// 玩家队伍关次边界快照（生命/真气/阵亡；跨战继承，§5.5）。
  List<ActivityMemberSnapshot> members = [];

  // --- 补给托管栏（Q2 会话托管，三列表平行；不碰普通库存）---
  /// 托管补给 defId（疗伤丹/行囊补给，最多合计 3 份）。
  List<String> escrowItemDefIds = [];
  /// 对应装入数量。
  List<int> escrowLoadedQty = [];
  /// 对应已用数量（≤ 装入数；关闭会话时 装入−已用 原子返还普通库存）。
  List<int> escrowUsedQty = [];

  // --- 最终奖励（Q4）---
  /// 三件命名装备候选 defId；胜利时原子固化，选择前不可重抽。
  List<String> rewardCandidateDefIds = [];
  /// 首通判定快照（胜利时固化，供一次性首通奖励发放）。
  bool isFirstClearPending = false;

  /// 暂存奖励（选定后一次性发放，§9.2）。
  List<RewardEntry> stagedRewards = [];
}
```

- [ ] **Step 4: build_runner + 测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub test/features/boss_gauntlet/boss_gauntlet_run_test.dart
```
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart lib/features/boss_gauntlet/domain/boss_gauntlet_run.g.dart test/features/boss_gauntlet/boss_gauntlet_run_test.dart
git commit -m "feat: 加断魂庄会话 collection 含托管栏与奖励阶段"
```

---

## Task 5: schema 注册 + saveVersion 0.37.0 迁移

**Files:**
- Modify: `lib/data/isar_setup.dart`（`:82` `_allSchemas` / `:159-161` 版本注释与常量 / `:368` 段6 后加段7）
- Modify: `test/data/inner_force_qi_migration_test.dart:57`（`'0.36.0'` → `'0.37.0'`；其余断言此常量的测试同步）
- Test: `test/data/isar_setup_journey_migration_test.dart`

- [ ] **Step 1: 写失败测试（旧档 0.36 → 0.37 可加性迁移）**

```dart
// test/data/isar_setup_journey_migration_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_journey_migration_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('0.36 旧档迁到 0.37：新进度字段取默认、无 active 会话、旧数据不动', () async {
    // 伪造旧档：手写 0.36.0 版本号
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.currentSaveData())!..saveVersion = '0.36.0';
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();

    // 重开触发迁移
    await IsarSetup.init(directory: tempDir, inspector: false);
    final migrated = (await IsarSetup.currentSaveData())!;

    expect(migrated.saveVersion, '0.37.0');
    expect(migrated.jianghuJourneyUnlocked, isFalse);
    expect(migrated.baicaoMaxDepth, 0);
    expect(migrated.grantedTicketMilestoneIds, isEmpty);
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/data/isar_setup_journey_migration_test.dart`
Expected: 失败——`_allSchemas` 未含两新 collection（无 `.expeditionRuns` 访问器）/ 版本仍 `0.36.0`。

- [ ] **Step 3a: 注册 schema**

`lib/data/isar_setup.dart:82` `_allSchemas` 列表加两项（保持既有顺序，追加到末尾前）：

```dart
    ExpeditionRunSchema,
    BossGauntletRunSchema,
```

并在文件头补 import：

```dart
import '../features/expedition/domain/expedition_run.dart';
import '../features/boss_gauntlet/domain/boss_gauntlet_run.dart';
```

- [ ] **Step 3b: 升版本 + 加迁移段**

`lib/data/isar_setup.dart:161` 版本常量：

```dart
  static const _currentSaveVersion = '0.37.0';
```

在 `:159-161` 版本历史注释区补一行：

```dart
  // 0.37.0 江湖远行:SaveData +6 永久进度字段(默认空/false)+ ExpeditionRun/
  //   BossGauntletRun 两个空会话 collection(可加性迁移,旧档零 active 记录)。
```

在 `_migrateSaveData` 的段6（`:368` `if (_compareVersion(fromVersion, '0.36.0') < 0)` 块）之后、尾部 `save.saveVersion = _currentSaveVersion;`（`:385`）之前插入段7：

```dart
      // --- 段 7(0.37.0 江湖远行)---
      // SaveData 新字段为可加性(List/bool/DateTime? 均有默认),旧档 load 时 Isar
      // 自动取 Dart 字段初值,无需显式回填;两新 collection 旧档初始为空。此段仅作
      // 幂等占位与版本文档锚,真正落版本号由本函数尾部统一执行。
      if (_compareVersion(fromVersion, '0.37.0') < 0) {
        // 无显式迁移动作(纯可加)。
      }
```

- [ ] **Step 3c: 同步版本断言测试**

```bash
git grep -n "'0.36.0'" test/ lib/
```
把断言「当前版本」的用例（至少 `test/data/inner_force_qi_migration_test.dart:57` 的 `expect(..., '0.36.0')`）改为 `'0.37.0'`。**只改断言当前版本号的行**，历史 `fromVersion` 用 `'0.36.0'` 构造旧档的行不动。

- [ ] **Step 4: build_runner + 定向测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub test/data/isar_setup_journey_migration_test.dart test/data/inner_force_qi_migration_test.dart test/data/isar_setup_test.dart
```
Expected: 全 PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/data/isar_setup.dart lib/data/isar_setup.g.dart test/data/isar_setup_journey_migration_test.dart test/data/inner_force_qi_migration_test.dart
git commit -m "feat: 注册远征/断魂庄会话并升存档版本至0.37"
```

---

## Task 6: CharacterOccupancyService + ActivityOccupancy DTO（Q5）

**Files:**
- Create: `lib/features/activity/domain/activity_occupancy.dart`
- Create: `lib/features/activity/application/character_occupancy_service.dart`
- Test: `test/features/activity/character_occupancy_service_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/activity/character_occupancy_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/character_occupancy_service.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_occupancy_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('无任何活动时占用为空', () async {
    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds, isEmpty);
    expect(occ.reservedEquipmentIds, isEmpty);
    expect(occ.activityOf(1), isNull);
  });

  test('远征成员进占用与保留集，装备id 进 reservedEquipmentIds', () async {
    await IsarSetup.instance.writeTxn(() async {
      final run = ExpeditionRun()
        ..saveDataId = 1
        ..policy = ExpeditionPolicy.yanJingCaiYao
        ..seed = 1
        ..departedAt = DateTime(2026, 7, 15)
        ..members = [
          ActivityMemberSnapshot()
            ..characterId = 42
            ..reservedEquipmentIds = [100, 101]
            ..reservedTechniqueIds = [5],
        ];
      await IsarSetup.instance.expeditionRuns.put(run);
    });

    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds, {42});
    expect(occ.reservedEquipmentIds, {100, 101});
    expect(occ.reservedTechniqueIds, {5});
    expect(occ.activityOf(42), ActivityKind.expedition);
  });

  test('闭关角色沿 currentRetreatSessionId 进占用（仅锁角色）', () async {
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = '徒一'
        ..currentRetreatSessionId = 7;
      await IsarSetup.instance.characters.put(c);
    });
    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds.length, 1);
    expect(occ.activityOf(occ.occupiedCharacterIds.first), ActivityKind.retreat);
    // 闭关只锁角色，不保留装备
    expect(occ.reservedEquipmentIds, isEmpty);
  });
}
```

> 注：`Character` 构造若需更多必填字段，沿 `test/support/` 现有角色构造 helper（如 `test/support/test_data.dart`）补全，不要在测试内散写数值。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/activity/character_occupancy_service_test.dart`
Expected: 编译失败（找不到 `CharacterOccupancyService`/`ActivityOccupancy`）。

- [ ] **Step 3a: DTO**

```dart
// lib/features/activity/domain/activity_occupancy.dart

/// 活动种类（闭关/百草岭/断魂庄）。
enum ActivityKind { retreat, expedition, bossGauntlet }

/// 单个活动会话的占用/保留条目。
class ActivityOccupancyEntry {
  const ActivityOccupancyEntry({
    required this.kind,
    required this.runId,
    required this.characterIds,
    required this.equipmentIds,
    required this.techniqueIds,
  });

  final ActivityKind kind;

  /// 会话 Isar id；闭关无独立 run 概念时为 null。
  final int? runId;

  final Set<int> characterIds;
  final Set<int> equipmentIds;
  final Set<int> techniqueIds;
}

/// 统一活动保留上下文（companion §3.5/§8.1 Q5）。唯一对外占用查询结果，
/// 出战编成、所有战斗入口、装备强化/助炼/分解/开锋、心法研习/装配均消费此结果。
class ActivityOccupancy {
  const ActivityOccupancy(this.entries);

  final List<ActivityOccupancyEntry> entries;

  static const ActivityOccupancy empty =
      ActivityOccupancy(<ActivityOccupancyEntry>[]);

  Set<int> get occupiedCharacterIds =>
      {for (final e in entries) ...e.characterIds};

  /// 装备批 `EquipmentAidService.isCandidateEligible(reservedEquipmentIds:)` 直接消费。
  Set<int> get reservedEquipmentIds =>
      {for (final e in entries) ...e.equipmentIds};

  Set<int> get reservedTechniqueIds =>
      {for (final e in entries) ...e.techniqueIds};

  bool isCharacterOccupied(int id) => occupiedCharacterIds.contains(id);

  /// 该角色所属活动（供 UI「远征中未随行」提示）；未占用返回 null。
  ActivityKind? activityOf(int characterId) {
    for (final e in entries) {
      if (e.characterIds.contains(characterId)) return e.kind;
    }
    return null;
  }
}
```

- [ ] **Step 3b: Service**

```dart
// lib/features/activity/application/character_occupancy_service.dart
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../../expedition/domain/expedition_run.dart';
import '../domain/activity_member_snapshot.dart';
import '../domain/activity_occupancy.dart';

/// 唯一对外占用查询口（companion §3.5/§8.1 Q5）。聚合闭关（既有
/// [Character.currentRetreatSessionId] 字段路径，零重做）+ 百草岭 + 断魂庄
/// 三源，返回统一 [ActivityOccupancy]；各入口不再各自散查两套 session collection。
class CharacterOccupancyService {
  const CharacterOccupancyService(this._isar);

  final Isar _isar;

  Future<ActivityOccupancy> snapshot() async {
    final entries = <ActivityOccupancyEntry>[];

    // 闭关：沿既有字段路径判定，仅锁角色（不保留装备/心法）。
    final retreating = await _isar.characters
        .filter()
        .currentRetreatSessionIdIsNotNull()
        .findAll();
    if (retreating.isNotEmpty) {
      entries.add(ActivityOccupancyEntry(
        kind: ActivityKind.retreat,
        runId: null,
        characterIds: {for (final c in retreating) c.id},
        equipmentIds: const <int>{},
        techniqueIds: const <int>{},
      ));
    }

    for (final run in await _isar.expeditionRuns.where().findAll()) {
      entries.add(_fromMembers(ActivityKind.expedition, run.id, run.members));
    }
    for (final run in await _isar.bossGauntletRuns.where().findAll()) {
      entries.add(_fromMembers(ActivityKind.bossGauntlet, run.id, run.members));
    }

    return ActivityOccupancy(entries);
  }

  ActivityOccupancyEntry _fromMembers(
    ActivityKind kind,
    int runId,
    List<ActivityMemberSnapshot> members,
  ) {
    return ActivityOccupancyEntry(
      kind: kind,
      runId: runId,
      characterIds: {for (final m in members) m.characterId},
      equipmentIds: {for (final m in members) ...m.reservedEquipmentIds},
      techniqueIds: {for (final m in members) ...m.reservedTechniqueIds},
    );
  }
}
```

- [ ] **Step 4: 测试**

Run: `flutter test --no-pub test/features/activity/character_occupancy_service_test.dart`
Expected: PASS。

> 若 `currentRetreatSessionIdIsNotNull()` 生成器名不符，跑一次 build_runner 后按 `expedition_run.g.dart`/Isar 生成的实际 query 扩展名对齐（Isar 按字段名生成 `<field>IsNotNull()`）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/activity/ test/features/activity/character_occupancy_service_test.dart
git commit -m "feat: 加统一角色占用查询服务与保留DTO"
```

---

## Task 7: 批末验证（Phase A1 收口）

- [ ] **Step 1: analyze**

Run: `flutter analyze --no-pub lib/ test/`
Expected: 0 issue。

- [ ] **Step 2: A1 相关 targeted 全绿**

Run:
```bash
flutter test --no-pub \
  test/core/domain/save_data_journey_progress_test.dart \
  test/features/activity/ \
  test/features/expedition/ \
  test/features/boss_gauntlet/ \
  test/data/isar_setup_journey_migration_test.dart \
  test/data/inner_force_qi_migration_test.dart
```
Expected: 全 PASS。

- [ ] **Step 3: 跨切面全量（schema/saveVer 改动，按 §8.0 必跑）**

Run: `flutter test --no-pub`
Expected: 0 fail（基线较 A1 前 +新增测试）。若有失败，先 `git grep -n "0.36.0"` 复查是否有漏改的版本断言。

- [ ] **Step 4: 提交（若批末有琐碎修复）+ 更新恢复点**

在本文件「当前恢复点」记：A1 全 7 任务完成、collection/DTO/schema 已冻结、全量绿；下一步 Phase A2。

---

## 当前恢复点

- **状态：** 未开工（计划已写，待执行）。
- **最后完成：** —
- **下一步：** Task 1（SaveData 字段）。
- **已跑验证：** 计划期接口对真实代码核（`save_data.dart:92`/`isar_setup.dart:82,161,368`/`character.dart:69-112`/`retreat_session.dart` 体例/`inner_force_qi_migration_test.dart` 迁移测体例）。
- **阻塞项：** 无（批1 已冻结拍板）。

## 冻结产物（下游依赖，不得改名/改签名）

| 产物 | 消费方 |
|---|---|
| `SaveData` 6 字段 | A2（断魂帖里程碑防重）、C（首通/解锁写入） |
| `ExpeditionRun` / `BossGauntletRun` + `ActivityMemberSnapshot` | B（远征会话）、C（断魂庄会话） |
| `ActivityOccupancy` DTO（`reservedEquipmentIds: Set<int>` 等） | 装备批（`isCandidateEligible`）、编成/战斗入口、C |
| `CharacterOccupancyService.snapshot()` | 所有占用查询点 |
| `saveVersion = '0.37.0'` + 两 schema | A2、B、C 的迁移基线 |
| `GauntletPhase.awaitingRewardChoice` / 托管三列表 | C2（崩溃恢复、补给托管） |

## 自检（写完 vs 源规格）

- **Spec 覆盖：** companion §3.3（永久进度→Task1）/§3.5 Q5（占用 DTO→Task6）/§4.1 A1 四项（永久进度→T1、schema0.37+迁移→T5、活动占用/资产保留→T2/6）/§4.7（0.37 迁移旧档兼容→T5 测）。§3.4 `awaitingRewardChoice` 的**枚举/字段锚**在 T4（阶段消费逻辑属 C2）。
- **Placeholder 扫描：** 每 code step 均给完整可编译代码 + 精确路径 + 命令与期望；无 TBD/「类似上文」。
- **类型一致：** `reservedEquipmentIds`/`reservedTechniqueIds` 全程 `Set<int>`（DTO getter）/ `List<int>`（快照存储），与装备 plan `isCandidateEligible(required Set<int> reservedEquipmentIds)` 对齐。
