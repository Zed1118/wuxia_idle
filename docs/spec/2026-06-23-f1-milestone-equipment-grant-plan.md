# F1 里程碑装备授予 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 实装 3 件 special 装备的里程碑授予通道，使其从「永远拿不到」变为首通对应里程碑必得（无名剑←飞升 / 心魔珠←降服心魔 / 百战甲←群战全清），并让 dropSourceTags 成为 live 消费字段。

**Architecture:** 新建 `MilestoneEquipmentGrantService.grantForTag(tag)`，按 `dropSourceTags` 筛装备授予进背包，用 `SaveData.grantedMilestoneEquipmentIds` 防重幂等。群战/心魔走 post-victory hook（镜像 `runDiscipleJoinHookAfterVictory`），飞升走 `performAscend` 内直调。

**Tech Stack:** Dart / Flutter / Riverpod 3 / Isar(isar_community) / YAML 配置 / TDD。

**前置 reality（本会话实测）：** saveVer 现 `0.27.0`(isar_setup.dart:136)；clearedStageIds 写入统一走 `MainlineProgressService.recordVictory`(:108)；post-victory 编排在 `stage_entry_flow.dart:308`(`runDiscipleJoinHookAfterVictory`)；装备入背包 = `EquipmentFactory.fromDef(...,ownerCharacterId:null)` + `isar.equipments.put`；`GameRepository.instance.equipmentDefs` 是 `Map<String,EquipmentDef>`；SaveData 单例 id=0。

**通用约束：** 改 .dart 后若动 Isar collection 字段须 `dart run build_runner build --delete-conflicting-outputs`(.g.dart gitignored)。每 task 末 commit。全程不调 3 件装备数值/lore/美术。

---

### Task 1: SaveData 新字段 + saveVer bump 0.27.0→0.28.0

**Files:**
- Modify: `lib/core/domain/save_data.dart`(在 triggeredDiscipleJoinStageIds:85 后加字段)
- Modify: `lib/data/isar_setup.dart:136`
- Modify(断言同步): `test/features/sect/sect_isar_persistence_test.dart:45-48` / `test/data/isar_setup_test.dart:63,97-98,108-109` / `test/data/isar_setup_migration_lineage_test.dart:139-140` / `test/data/save_migration_021_test.dart:72,137,178` / `test/data/passive_idle_migration_test.dart:33-35`
- Test: `test/features/equipment/milestone_grant_migration_test.dart`(新建)

- [ ] **Step 1: 写迁移失败测**

新建 `test/features/equipment/milestone_grant_migration_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';

void main() {
  test('SaveData.grantedMilestoneEquipmentIds 默认空集', () {
    final s = SaveData();
    expect(s.grantedMilestoneEquipmentIds, isEmpty);
  });
}
```

- [ ] **Step 2: 跑测验证 fail**

Run: `flutter test test/features/equipment/milestone_grant_migration_test.dart`
Expected: 编译失败 `grantedMilestoneEquipmentIds isn't defined`。

- [ ] **Step 3: 加字段 + bump saveVer**

`save_data.dart` 在 :85 `triggeredDiscipleJoinStageIds = [];` 之后加：
```dart
  /// 已授予的里程碑装备 defId（F1 · 一次性防重）。
  ///
  /// 沿 [triggeredDiscipleJoinStageIds] 体例：MilestoneEquipmentGrantService
  /// 授予后 add 本字段，重打/重飞升不重发。新字段，旧档读默认空。
  List<String> grantedMilestoneEquipmentIds = [];
```
`isar_setup.dart:136`：`static const _currentSaveVersion = '0.28.0';`
（无需新迁移块：新 List 字段 Isar 默认空；版本号在 _migrateSaveData 末尾统一升到 current。）

- [ ] **Step 4: build_runner 重生 .g.dart**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: SUCCESS（save_data.g.dart 含新字段）。

- [ ] **Step 5: 同步全部 9 处 saveVer 断言 0.27.0→0.28.0**

把上列 5 个测试文件中所有 `'0.27.0'` 改 `'0.28.0'`（grep `0\.27\.0` test/ 核对无遗漏，禁 `| head` 截断）。reason 文案里的「兵器谱」描述保留，仅改版本号。

- [ ] **Step 6: 跑测验证全绿**

Run: `flutter test test/features/equipment/milestone_grant_migration_test.dart test/data/isar_setup_test.dart test/data/passive_idle_migration_test.dart test/data/save_migration_021_test.dart test/data/isar_setup_migration_lineage_test.dart test/features/sect/sect_isar_persistence_test.dart`
Expected: 全 PASS。

- [ ] **Step 7: Commit**

```bash
git add lib/core/domain/save_data.dart lib/data/isar_setup.dart test/
git commit -m "feat: SaveData 加 grantedMilestoneEquipmentIds + saveVer 0.28.0(F1 Task1)"
```

---

### Task 2: numbers.yaml 里程碑映射 + NumbersConfig 解析

**Files:**
- Modify: `data/numbers.yaml`(顶层加 milestone_equipment_grants)
- Modify: `lib/data/numbers_config.dart`(NumbersConfig 加字段 + fromYaml:277 解析)
- Test: `test/data/milestone_grants_config_test.dart`(新建)

- [ ] **Step 1: 写解析失败测**

新建 `test/data/milestone_grants_config_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('milestoneEquipmentGrants 解析 stageId→tag', () {
    final cfg = NumbersConfig.fromYaml({
      ...minimalNumbersStub(),
      'milestone_equipment_grants': {
        'stage_mass_battle_05': 'mass_battle_merit',
        'stage_inner_demon_07': 'inner_demon_reward',
      },
    });
    expect(cfg.milestoneEquipmentGrants['stage_mass_battle_05'],
        'mass_battle_merit');
    expect(cfg.milestoneEquipmentGrants['stage_inner_demon_07'],
        'inner_demon_reward');
  });
}
```
（`minimalNumbersStub()` 若不存在：从既有 numbers_config 测试复制其构造 stub，或直接 load 真 yaml 后断言两 key。实装者按现有该文件测试体例二选一。）

- [ ] **Step 2: 跑测验证 fail**

Run: `flutter test test/data/milestone_grants_config_test.dart`
Expected: fail（`milestoneEquipmentGrants` getter 未定义）。

- [ ] **Step 3: numbers.yaml 加映射**

`data/numbers.yaml` 顶层加：
```yaml
# F1 里程碑装备授予：stageId → dropSourceTags tag。
# 首通该关 → MilestoneEquipmentGrantService.grantForTag(tag)。飞升 tag
# (ascension_reward)是终局事件非关卡，在 performAscend 内直调不入本表。
milestone_equipment_grants:
  stage_mass_battle_05: mass_battle_merit
  stage_inner_demon_07: inner_demon_reward
```

- [ ] **Step 4: NumbersConfig 解析**

`numbers_config.dart` class 加 `final Map<String, String> milestoneEquipmentGrants;`，构造函数 required，`fromYaml`(:277) 内：
```dart
      milestoneEquipmentGrants: ((y['milestone_equipment_grants'] as Map?) ??
              const {})
          .map((k, v) => MapEntry(k as String, v as String)),
```

- [ ] **Step 5: 跑测验证 PASS**

Run: `flutter test test/data/milestone_grants_config_test.dart`
Expected: PASS。

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/milestone_grants_config_test.dart
git commit -m "feat: numbers.yaml milestone_equipment_grants 映射 + 解析(F1 Task2)"
```

---

### Task 3: UiStrings 3 条 obtainedFrom 来历串

**Files:**
- Modify: `lib/shared/strings.dart`(UiStrings 加 3 const)

- [ ] **Step 1: 加 3 条来历串**

`lib/shared/strings.dart` UiStrings 内（沿 dropSourceStageDefault 体例，搜该 const 定位附近）加：
```dart
  /// F1 里程碑装备来历（obtainedFrom）。
  static const String dropSourceMassBattleMerit = '群战军功';
  static const String dropSourceInnerDemonReward = '降服心魔';
  static const String dropSourceAscensionReward = '飞升所得';
```

- [ ] **Step 2: analyze 验证无错**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues。

- [ ] **Step 3: Commit**

```bash
git add lib/shared/strings.dart
git commit -m "feat: UiStrings 加 3 条里程碑装备来历串(F1 Task3)"
```

---

### Task 4: MilestoneEquipmentGrantService

**Files:**
- Create: `lib/features/equipment/application/milestone_equipment_grant_service.dart`
- Test: `test/features/equipment/milestone_equipment_grant_service_test.dart`

- [ ] **Step 1: 写 service 失败测**

新建测试（沿 DropService/EquipmentFactory 测试体例，用真 GameRepository.load 或 fixture；实装者参考 `test/features/equipment/` 既有测如何起 isar + load repo）：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/equipment/application/milestone_equipment_grant_service.dart';
// + isar 初始化 / GameRepository.load 的既有测试 helper import

void main() {
  late Isar isar;
  setUp(() async { /* 起测试 isar + 写 SaveData()..id=0 + GameRepository.load */ });
  tearDown(() async { await isar.close(deleteFromDisk: true); });

  test('grantForTag 首次授予百战甲进背包(owner=null)', () async {
    final svc = MilestoneEquipmentGrantService(isar: isar);
    final granted = await svc.grantForTag('mass_battle_merit',
        obtainedFrom: '群战军功');
    expect(granted, contains('armor_special_bai_zhan_jia'));
    final all = await isar.equipments.where().findAll();
    final bzj = all.firstWhere((e) => e.defId == 'armor_special_bai_zhan_jia');
    expect(bzj.ownerCharacterId, isNull);
    final save = await isar.saveDatas.get(0);
    expect(save!.grantedMilestoneEquipmentIds,
        contains('armor_special_bai_zhan_jia'));
  });

  test('grantForTag 二次调用幂等 no-op', () async {
    final svc = MilestoneEquipmentGrantService(isar: isar);
    await svc.grantForTag('mass_battle_merit', obtainedFrom: '群战军功');
    final second = await svc.grantForTag('mass_battle_merit',
        obtainedFrom: '群战军功');
    expect(second, isEmpty);
    final all = await isar.equipments
        .filter()
        .defIdEqualTo('armor_special_bai_zhan_jia')
        .findAll();
    expect(all.length, 1);
  });

  test('未知 tag → 空', () async {
    final svc = MilestoneEquipmentGrantService(isar: isar);
    expect(await svc.grantForTag('nope', obtainedFrom: 'x'), isEmpty);
  });
}
```

- [ ] **Step 2: 跑测验证 fail**

Run: `flutter test test/features/equipment/milestone_equipment_grant_service_test.dart`
Expected: fail（service 未定义）。

- [ ] **Step 3: 实装 service**

新建 `lib/features/equipment/application/milestone_equipment_grant_service.dart`：
```dart
import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../shared/utils/rng.dart';
import 'equipment_factory.dart';

/// F1 里程碑装备授予。按 dropSourceTags 筛装备，授予未授予过的进背包。
///
/// 沿 [DiscipleJoinService] 一次性防重体例：[SaveData.grantedMilestoneEquipmentIds]
/// gate，重打/重飞升幂等 no-op。dropSourceTags 由此成为 live 消费字段。
class MilestoneEquipmentGrantService {
  MilestoneEquipmentGrantService({required this.isar, DateTime Function()? now})
      : now = now ?? DateTime.now;
  final Isar isar;
  final DateTime Function() now;

  /// 授予所有 dropSourceTags 含 [tag] 且未授予过的装备进背包。
  /// 返回本次新授予的 defId 列表（已授予过 → 空）。
  Future<List<String>> grantForTag(
    String tag, {
    required String obtainedFrom,
  }) async {
    if (!GameRepository.isLoaded) return const [];
    final defs = GameRepository.instance.equipmentDefs.values
        .where((d) => d.dropSourceTags.contains(tag))
        .toList();
    if (defs.isEmpty) return const [];

    final granted = <String>[];
    await isar.writeTxn(() async {
      final save = await isar.saveDatas.get(0);
      if (save == null) return;
      final already = save.grantedMilestoneEquipmentIds.toSet();
      final rng = DefaultRng();
      final newly = <String>[];
      for (final def in defs) {
        if (already.contains(def.id)) continue;
        final eq = EquipmentFactory.fromDef(
          def,
          rng: rng,
          obtainedAt: now(),
          obtainedFrom: obtainedFrom,
        );
        await isar.equipments.put(eq);
        newly.add(def.id);
      }
      if (newly.isEmpty) return;
      save.grantedMilestoneEquipmentIds = [
        ...save.grantedMilestoneEquipmentIds,
        ...newly,
      ];
      await isar.saveDatas.put(save);
      granted.addAll(newly);
    });
    return granted;
  }
}
```

- [ ] **Step 4: 跑测验证 PASS**

Run: `flutter test test/features/equipment/milestone_equipment_grant_service_test.dart`
Expected: 3 PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/features/equipment/application/milestone_equipment_grant_service.dart test/features/equipment/milestone_equipment_grant_service_test.dart
git commit -m "feat: MilestoneEquipmentGrantService 按 dropSourceTags 授予(F1 Task4)"
```

---

### Task 5: post-victory hook + 接线 stage_entry_flow（群战/心魔）

**Files:**
- Create: `lib/features/equipment/presentation/milestone_grant_hook.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`(import + :308 附近加调用)
- Test: `test/features/equipment/milestone_grant_hook_test.dart`

- [ ] **Step 1: 写 hook 失败测（service 级集成，不起 widget）**

新建 `test/features/equipment/milestone_grant_hook_test.dart`，直接测「stageId→tag→grant」映射逻辑（hook 内调 service 的纯逻辑抽到可测函数 `grantMilestoneForClearedStage`）：
```dart
import 'package:flutter_test/flutter_test.dart';
// isar + GameRepository helper import
import 'package:wuxia_idle/features/equipment/presentation/milestone_grant_hook.dart';

void main() {
  // setUp: 起 isar + SaveData()..id=0 + GameRepository.load(含 numbers milestone map)
  test('首通 stage_mass_battle_05 授百战甲', () async {
    final granted = await grantMilestoneForClearedStage(
        isar: isar, clearedStageId: 'stage_mass_battle_05');
    expect(granted, contains('armor_special_bai_zhan_jia'));
  });
  test('非里程碑关 no-op', () async {
    final granted = await grantMilestoneForClearedStage(
        isar: isar, clearedStageId: 'stage_01_01');
    expect(granted, isEmpty);
  });
  test('首通 stage_inner_demon_07 授心魔珠', () async {
    final granted = await grantMilestoneForClearedStage(
        isar: isar, clearedStageId: 'stage_inner_demon_07');
    expect(granted, contains('accessory_special_xin_mo_zhu'));
  });
}
```

- [ ] **Step 2: 跑测验证 fail**

Run: `flutter test test/features/equipment/milestone_grant_hook_test.dart`
Expected: fail（函数未定义）。

- [ ] **Step 3: 实装 hook（纯逻辑函数 + UI 包装，镜像 disciple_join_hook）**

新建 `lib/features/equipment/presentation/milestone_grant_hook.dart`：
```dart
import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../application/milestone_equipment_grant_service.dart';

/// tag → 来历串。新增里程碑装备时在此补一行。
String _obtainedFromForTag(String tag) {
  switch (tag) {
    case 'mass_battle_merit':
      return UiStrings.dropSourceMassBattleMerit;
    case 'inner_demon_reward':
      return UiStrings.dropSourceInnerDemonReward;
    case 'ascension_reward':
      return UiStrings.dropSourceAscensionReward;
    default:
      return UiStrings.dropSourceStageDefault;
  }
}

/// 纯逻辑：若 [clearedStageId] 是里程碑触发关，按映射 tag 授予装备。
/// 返回新授予 defId（非里程碑关 / 已授予过 → 空）。可单测。
Future<List<String>> grantMilestoneForClearedStage({
  required Isar isar,
  required String clearedStageId,
}) async {
  if (!GameRepository.isLoaded) return const [];
  final map = GameRepository.instance.numbers.milestoneEquipmentGrants;
  final tag = map[clearedStageId];
  if (tag == null) return const [];
  final svc = MilestoneEquipmentGrantService(isar: isar);
  return svc.grantForTag(tag, obtainedFrom: _obtainedFromForTag(tag));
}

/// post-victory hook（镜像 runDiscipleJoinHookAfterVictory）。
/// Isar 未 ready → no-op 不阻塞胜利流。F1 范围内静默入袋，无授予特效。
Future<void> runMilestoneGrantHookAfterVictory({
  required String stageId,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  await grantMilestoneForClearedStage(isar: isar, clearedStageId: stageId);
}
```

- [ ] **Step 4: 跑测验证 PASS**

Run: `flutter test test/features/equipment/milestone_grant_hook_test.dart`
Expected: 3 PASS。

- [ ] **Step 5: 接线 stage_entry_flow**

`stage_entry_flow.dart` 顶部 import 段加：
```dart
import '../../equipment/presentation/milestone_grant_hook.dart';
```
在 :308 `await runDiscipleJoinHookAfterVictory(` 调用**之后**（同一 post-victory async 块内，确保在 recordVictory 写 clearedStageIds 之后）加：
```dart
    await runMilestoneGrantHookAfterVictory(stageId: stageId);
```
（hook 内幂等，重打不重发；非里程碑关 no-op。stageId 变量名以 :308 上下文实际为准。）

- [ ] **Step 6: 全项目 analyze**

Run: `flutter analyze`
Expected: No issues found（守 feedback_subagent_implementer_full_analyze：跑全项目非单文件）。

- [ ] **Step 7: Commit**

```bash
git add lib/features/equipment/presentation/milestone_grant_hook.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/equipment/milestone_grant_hook_test.dart
git commit -m "feat: 群战/心魔里程碑装备 post-victory hook(F1 Task5)"
```

---

### Task 6: 飞升授予无名剑（performAscend）

**Files:**
- Modify: `lib/features/ascension/application/ascend_service.dart`(performAscend:178 内)
- Test: `test/features/ascension/ascend_milestone_grant_test.dart`(或扩既有 ascend 测)

- [ ] **Step 1: 写飞升授予失败测**

新建 `test/features/ascension/ascend_milestone_grant_test.dart`（沿既有 ascend_service 测体例起 isar + repo + 满足飞升条件的角色）：
```dart
test('performAscend 授无名剑进背包', () async {
  // arrange: 满飞升条件的 founder + SaveData()..id=0
  await svc.performAscend(/* 既有测试入参 */);
  final all = await isar.equipments.where().findAll();
  expect(all.any((e) => e.defId == 'weapon_special_wu_ming_jian'), isTrue);
});
test('二次飞升不重发无名剑(幂等)', () async {
  await svc.performAscend(/* ... */);
  // 二次调用（若测试可构造）→ 无名剑仍只 1 件
  final all = await isar.equipments
      .filter().defIdEqualTo('weapon_special_wu_ming_jian').findAll();
  expect(all.length, 1);
});
```
（若既有 ascend 测已有满条件 fixture，复用之；幂等测若飞升为一次性终局难二次构造，可改为直接二次调 service.grantForTag 验幂等。）

- [ ] **Step 2: 跑测验证 fail**

Run: `flutter test test/features/ascension/ascend_milestone_grant_test.dart`
Expected: fail（无名剑未授予）。

- [ ] **Step 3: performAscend 内授予**

`ascend_service.dart` import 段加：
```dart
import '../../../shared/strings.dart';
import '../../equipment/application/milestone_equipment_grant_service.dart';
```
在 `performAscend`(:178) 主 writeTxn **之后**（避免嵌套 writeTxn，service 自开事务；caller 持锁语义见 :22 注释——若 performAscend 全程在外层 writeTxn 内，则改为在 performAscend 返回前、锁释放后由 caller 调，或把授予逻辑内联进同一 txn 用 save 直接 put）。**实装者先读 :178-294 确认事务边界**，二选一：
- (a) performAscend 不自开 txn（caller 持锁）→ 在授予处内联：筛 dropSourceTags 含 'ascension_reward' 的 def，未在 grantedMilestoneEquipmentIds 则 fromDef+put+加集合（复用 Task4 逻辑，同一 txn）。
- (b) performAscend 自开 txn 且已结束 → txn 后调 `MilestoneEquipmentGrantService(isar: isar).grantForTag('ascension_reward', obtainedFrom: UiStrings.dropSourceAscensionReward)`。

优先 (b)（复用 service、不重复逻辑）；仅当事务边界冲突（嵌套 writeTxn 报错）才用 (a)。

- [ ] **Step 4: 跑测验证 PASS**

Run: `flutter test test/features/ascension/ascend_milestone_grant_test.dart`
Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/features/ascension/application/ascend_service.dart test/features/ascension/ascend_milestone_grant_test.dart
git commit -m "feat: 飞升授予无名剑(F1 Task6)"
```

---

### Task 7: 全量回归 + audit/PROGRESS 收尾

**Files:**
- Modify: `docs/audit/drop_consistency_2026-06-23.md`(F1/F6 标 resolved)
- Modify: `PROGRESS.md`(顶段加续条)

- [ ] **Step 1: 全项目 analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 2: 全量测**

Run: `flutter test`
Expected: All tests passed（基线本会话实测 2826+1skip；本计划新增 ~10 测，断言改 9 处；零回归，数字以实跑为准不转抄）。

- [ ] **Step 3: 标记 audit F1/F6 resolved + PROGRESS 续条**

`docs/audit/drop_consistency_2026-06-23.md` 在 F1、F6 条目加 `✅ 已修(2026-06-23 续XX)`。`PROGRESS.md` 顶段加一条续记（F1 实装摘要 + commit 区间 + 实测 analyze/test 数）。

- [ ] **Step 4: Commit**

```bash
git add docs/ PROGRESS.md
git commit -m "docs: F1 里程碑装备授予闭环 + audit/PROGRESS 收尾(F1 Task7)"
```

---

## 自查（spec 覆盖 / 一致性）

- **spec ① 架构**(service+dropSourceTags live+SaveData 字段+saveVer) → Task1/Task4 ✅
- **spec ② 三触发点**(群战05/心魔07/飞升) → Task5(群战/心魔)+Task6(飞升) ✅
- **spec ③ 配置**(numbers.yaml 映射) → Task2 ✅
- **spec ④ 持久化迁移**(saveVer0.28+9 断言同步) → Task1 ✅
- **spec ⑤ 测试**(service单测/迁移/集成) → Task1/4/5/6 ✅
- **spec ⑥ 范围边界**(不碰 F2-F8/不调数值/无授予特效) → 全程遵守 ✅
- **F6 死字段**(dropSourceTags 变 live) → Task4 service 消费 ✅
- 类型一致：`grantForTag(tag,{obtainedFrom})` / `grantMilestoneForClearedStage({isar,clearedStageId})` / `grantedMilestoneEquipmentIds` / `milestoneEquipmentGrants` 全 task 命名统一 ✅
