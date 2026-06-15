# M2 范围 B 通用被动离线挂机 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 不开闭关直接退游戏，重开也按真实离线时长结算少量被动产出（经验+磨剑石，≈闭关 25%），自动入包+归来卡仅告知；兑现 GDD §5.5「在线=离线」。

**Architecture:** 纯函数 `OfflinePassiveService.compute()` 算产量（可单测）+ `settle()` 副作用入库（fake Isar 测）。`lastOnlineAt` 补真写入点（`AppLifecycleListener`）。启动 gate 分流：有 active 闭关→走已有范围 A 卡、不发被动；无闭关→范围 B 结算。被动与闭关互斥不叠加。

**Tech Stack:** Flutter Desktop · Riverpod 3.x · Isar(isar_community) · YAML 数值配置 · TDD(flutter_test)

**Spec:** `docs/spec/2026-06-15-m2-offline-passive-idle-design.md`

**前置环境备忘（worktree）：** 真 Isar 测试首跑若报 `libisar.dylib` 截断，从主仓拷完整 dylib（memory `feedback_fresh_worktree_libisar_dylib`）。schema 改动后 `.g.dart` gitignored，须 `dart run build_runner build --delete-conflicting-outputs`（memory `feedback_wuxia_pen_build_runner`）。

---

## File Structure

| 文件 | 责任 | 新建/改 |
|---|---|---|
| `data/numbers.yaml` | `passive_idle` 段数值 | 改 |
| `lib/data/numbers_config.dart` | `PassiveIdleConfig` 解析 + 挂 `NumbersConfig.passiveIdle` | 改 |
| `lib/features/seclusion/application/offline_passive_service.dart` | `compute()` 纯函数 + `settle()` 入库 | 新建 |
| `lib/core/domain/save_data.dart` | 2 累计字段 | 改 |
| `lib/data/isar_setup.dart` | saveVer 0.24.0 + 迁移段 + 旧档基准 | 改 |
| `lib/main.dart` | `AppLifecycleListener` 挂 `WuxiaApp` + `IsarSetup.touchOnlineNow` | 改 |
| `lib/features/seclusion/presentation/offline_recap_gate.dart` | 分流：无闭关→调 settle→弹被动卡 | 改 |
| `lib/features/seclusion/presentation/offline_recap_card.dart` | 被动变体（命名构造） | 改 |
| `lib/shared/strings.dart` | 被动卡文案 | 改 |

---

## Task 1: passive_idle 数值段 + PassiveIdleConfig 解析

**Files:**
- Modify: `data/numbers.yaml`（retreat 段后追加）
- Modify: `lib/data/numbers_config.dart`
- Test: `test/data/passive_idle_config_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/data/passive_idle_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('PassiveIdleConfig.fromYaml 解析字段 + realmScaleFor pow(1.3, index)', () {
    final cfg = PassiveIdleConfig.fromYaml(const {
      'base_mojianshi_per_hour': 0.25,
      'base_exp_per_hour': 25.0,
      'realm_scale_per_tier': 1.3,
      'cap_hours': 72,
      'min_recap_hours': 1.0,
    });
    expect(cfg.baseMojianshiPerHour, 0.25);
    expect(cfg.baseExpPerHour, 25.0);
    expect(cfg.capHours, 72);
    expect(cfg.minRecapHours, 1.0);
    expect(cfg.realmScaleFor(RealmTier.xueTu), 1.0); // index 0 → 1.3^0
    expect(cfg.realmScaleFor(RealmTier.sanLiu), closeTo(1.3, 1e-9)); // index 1
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/passive_idle_config_test.dart`
Expected: FAIL — `PassiveIdleConfig` 未定义。

- [ ] **Step 3: numbers.yaml 追加 passive_idle 段**

在 `data/numbers.yaml` 的 `retreat:` 段（约 886–1016 行）之后、下一个顶层 key 之前追加：

```yaml
# M2 范围 B 通用被动离线挂机(spec 2026-06-15-m2-offline-passive-idle)。
# 不开闭关退游戏也按真实离线时长涓流产出，≈闭关同时长 25%。初值取入门图
# (exp 100 / moji 1.0)×0.25，base 值待 balance_simulator 校准(见 Task 7)。
passive_idle:
  base_mojianshi_per_hour: 0.25   # ≈ 入门闭关图 1.0 × 0.25
  base_exp_per_hour: 25.0         # ≈ 入门闭关图 100 × 0.25
  realm_scale_per_tier: 1.3       # 复用闭关锚点(学徒 ×1.0，武圣 ≈4.83)
  cap_hours: 72                   # 复用闭关封顶，超出不累积
  min_recap_hours: 1.0            # 离开 ≥1h 才弹告知卡(与范围 A 一致)
```

- [ ] **Step 4: numbers_config.dart 加 PassiveIdleConfig + 挂 NumbersConfig**

在 `numbers_config.dart` 文件末尾（其他 Config 类旁）加类：

```dart
/// M2 范围 B 通用被动离线挂机配置（numbers.yaml `passive_idle`）。
class PassiveIdleConfig {
  final double baseMojianshiPerHour;
  final double baseExpPerHour;
  final double realmScalePerTier;
  final int capHours;
  final double minRecapHours;

  const PassiveIdleConfig({
    required this.baseMojianshiPerHour,
    required this.baseExpPerHour,
    required this.realmScalePerTier,
    required this.capHours,
    required this.minRecapHours,
  });

  /// 境界缩放：每升一大境界 ×realmScalePerTier。学徒(index 0)=1.0。
  double realmScaleFor(RealmTier tier) =>
      math.pow(realmScalePerTier, tier.index).toDouble();

  factory PassiveIdleConfig.fromYaml(Map<String, dynamic> y) {
    final base = (y['base_mojianshi_per_hour'] as num).toDouble();
    final exp = (y['base_exp_per_hour'] as num).toDouble();
    final scale = (y['realm_scale_per_tier'] as num).toDouble();
    final cap = (y['cap_hours'] as num).toInt();
    final minRecap = (y['min_recap_hours'] as num).toDouble();
    // schema 校验：非负 + cap 合理
    if (base < 0 || exp < 0 || scale <= 0 || cap <= 0 || minRecap < 0) {
      throw ArgumentError('passive_idle 数值非法: $y');
    }
    return PassiveIdleConfig(
      baseMojianshiPerHour: base,
      baseExpPerHour: exp,
      realmScalePerTier: scale,
      capHours: cap,
      minRecapHours: minRecap,
    );
  }
}
```

确保文件顶部已 `import 'dart:math' as math;`（若无则加）。在 `NumbersConfig` 类加字段 `final PassiveIdleConfig passiveIdle;`、构造函数加 `required this.passiveIdle,`、`fromYaml` 内加：

```dart
passiveIdle: PassiveIdleConfig.fromYaml(
  y['passive_idle'] as Map<String, dynamic>,
),
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/data/passive_idle_config_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/passive_idle_config_test.dart
git commit -m "[schema] M2范围B Task1: passive_idle 数值段 + PassiveIdleConfig 解析"
```

---

## Task 2: OfflinePassiveService.compute() 纯函数

**Files:**
- Create: `lib/features/seclusion/application/offline_passive_service.dart`
- Test: `test/features/seclusion/application/offline_passive_service_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/seclusion/application/offline_passive_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  const cfg = PassiveIdleConfig(
    baseMojianshiPerHour: 0.25,
    baseExpPerHour: 25.0,
    realmScalePerTier: 1.3,
    capHours: 72,
    minRecapHours: 1.0,
  );

  test('0h → 全 0', () {
    final y = OfflinePassiveService.compute(
      awayHours: 0, realmTier: RealmTier.xueTu, config: cfg);
    expect(y.mojianshi, 0);
    expect(y.experience, 0);
  });

  test('10h 学徒 → floor(base×10×1.0)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 10, realmTier: RealmTier.xueTu, config: cfg);
    expect(y.mojianshi, 2);   // floor(0.25×10×1.0)=2
    expect(y.experience, 250); // floor(25×10×1.0)=250
  });

  test('超 cap 按 cap 截断(100h→72h)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 100, realmTier: RealmTier.xueTu, config: cfg);
    expect(y.experience, (25.0 * 72).floor()); // 1800
  });

  test('境界 scale 生效(三流 ×1.3)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 10, realmTier: RealmTier.sanLiu, config: cfg);
    expect(y.experience, (25.0 * 10 * 1.3).floor()); // 325
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/seclusion/application/offline_passive_service_test.dart`
Expected: FAIL — `OfflinePassiveService` 未定义。

- [ ] **Step 3: 写 compute() 纯函数**

```dart
// lib/features/seclusion/application/offline_passive_service.dart
import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';

/// 被动离线挂机一次结算的产量（纯数据）。
typedef PassiveYield = ({int mojianshi, int experience});

/// M2 范围 B 通用被动离线挂机服务。
///
/// [compute] 纯函数算产量（≈闭关 25%，base 走 numbers.yaml passive_idle）。
/// 副作用入库见 [settle]（Task 4）。与闭关互斥：仅在无 active 闭关时由 gate 调用。
class OfflinePassiveService {
  OfflinePassiveService._();

  /// 按离线时长 + 主角境界算被动产量。
  /// [awayHours] 由 caller 传入（gate 已 clamp 下界 0）；内部按 cap 截上界。
  static PassiveYield compute({
    required double awayHours,
    required RealmTier realmTier,
    required PassiveIdleConfig config,
  }) {
    final capped = awayHours.clamp(0, config.capHours.toDouble());
    final scale = config.realmScaleFor(realmTier);
    final mojianshi =
        (config.baseMojianshiPerHour * capped * scale).floor().clamp(0, 999999);
    final experience =
        (config.baseExpPerHour * capped * scale).floor().clamp(0, 999999);
    return (mojianshi: mojianshi, experience: experience);
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/seclusion/application/offline_passive_service_test.dart`
Expected: PASS（4 测全过）

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/application/offline_passive_service.dart test/features/seclusion/application/offline_passive_service_test.dart
git commit -m "M2范围B Task2: OfflinePassiveService.compute 纯函数 + 边界测"
```

---

## Task 3: SaveData 累计字段 + saveVer 0.24.0 迁移

**Files:**
- Modify: `lib/core/domain/save_data.dart`
- Modify: `lib/data/isar_setup.dart:103`（版本号）+ `_migrateSaveData`
- Test: `test/data/passive_idle_migration_test.dart`

- [ ] **Step 1: SaveData 加 2 字段**

在 `save_data.dart` 的 `skillUnlockProgress` 字段后加：

```dart
  /// M2 范围 B 被动离线挂机累计总产出（仅汇总卡展示，YAGNI 不分维度）。
  int totalPassiveMojianshi = 0;
  int totalPassiveExperience = 0;
```

- [ ] **Step 2: 跑 build_runner 重生成 .g.dart**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 成功，`save_data.g.dart` 含新 2 字段。

- [ ] **Step 3: 写失败测试（旧档首启不回溯）**

```dart
// test/data/passive_idle_migration_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_mig_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async => await IsarSetup.close());

  test('新档累计字段默认 0', () async {
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 0);
    expect(save.totalPassiveExperience, 0);
  });

  test('saveVersion 标记为 0.24.0', () async {
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.saveVersion, '0.24.0');
  });
}
```

> **真名核对（Phase 0 已确认）**：`IsarSetup` 公开成员 = `init` / `close` / `instance`（`Isar` getter）/ `instanceOrNull`；SaveData 读取无 public 方法（private `_ensureSaveData`），**本 Task Step 2.5 新增 public `currentSaveData()`**。SaveData id 固定 0（每槽单例）。

- [ ] **Step 4: 跑测试确认失败**

Run: `flutter test test/data/passive_idle_migration_test.dart`
Expected: FAIL — saveVersion 仍 `0.23.0`。

- [ ] **Step 5: isar_setup.dart 加 currentSaveData getter + 升版本 + 迁移段**

在 `IsarSetup` 类加 public getter（供 Task 4/5/测试读 SaveData，复用 id=0 单例约定）：

```dart
  /// 当前槽位 SaveData（id 固定 0）。init 后必非 null；未 init 时 instance 抛错。
  static Future<SaveData?> currentSaveData() => instance.saveDatas.get(0);
```

`isar_setup.dart:103` 改：

```dart
  //   M2 范围 B 被动离线挂机:SaveData 加 totalPassiveMojianshi/totalPassiveExperience
  //   (旧档默认 0,Isar 新 int 字段自动 0)。lastOnlineAt 旧档 == createdAt 时
  //   首启不回溯被动(gate 层处理,见 Task 4)→ 0.24.0。
  static const _currentSaveVersion = '0.24.0';
```

`_migrateSaveData` 内（分段追加末尾）加：

```dart
    // 段(0.24.0):M2 范围 B 两累计字段。Isar 新增 int 字段旧档读为默认 0,
    // 无显式迁移动作;仅推进版本标记。lastOnlineAt 不在此清零(gate 层判
    // == createdAt 决定首启是否结算,见 offline_recap_gate)。
    save.saveVersion = _currentSaveVersion;
    await isar.saveDatas.put(save);
```

> 若 `_migrateSaveData` 末尾已有统一 `save.saveVersion = _currentSaveVersion; put(save)`，则不重复加，仅靠版本号常量更新即可。读现有 `_migrateSaveData` 尾部确认。

- [ ] **Step 6: 跑测试确认通过 + 全量回归**

Run: `flutter test test/data/passive_idle_migration_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/core/domain/save_data.dart lib/core/domain/save_data.g.dart lib/data/isar_setup.dart test/data/passive_idle_migration_test.dart
git commit -m "[schema] M2范围B Task3: SaveData 累计字段 + saveVer 0.24.0"
```

---

## Task 4: settle() 入库 + gate 分流 + 旧档不回溯

**Files:**
- Modify: `lib/features/seclusion/application/offline_passive_service.dart`（加 `settle`）
- Modify: `lib/features/seclusion/presentation/offline_recap_gate.dart`（分流）
- Test: `test/features/seclusion/application/offline_passive_settle_test.dart`

- [ ] **Step 1: 写失败测试（settle 发放 + 幂等 + 重置）**

```dart
// test/features/seclusion/application/offline_passive_settle_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  late Directory tempDir;
  const kCharId = 10;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_settle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch = Character.create(
      name: 'hero', realmTier: RealmTier.xueTu, realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(), rarity: RarityTier.biaoZhun)..id = kCharId;
    await IsarSetup.instance
        .writeTxn(() => IsarSetup.instance.characters.put(ch));
  });

  tearDown(() async => await IsarSetup.close());

  test('settle 发放磨剑石入包 + 经验入角色 + 累计 +=', () async {
    final result = await OfflinePassiveService.settle(
      saveDataId: 1,
      characterId: kCharId,
      awayHours: 10, // 学徒 → moji 2 / exp 250
      now: DateTime(2026, 6, 15, 12),
    );
    expect(result.mojianshi, 2);
    expect(result.experience, 250);

    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item?.quantity, 2);

    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 2);
    expect(save.totalPassiveExperience, 250);
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 12)); // 重置基准
  });
}
```

> **真名（Phase 0 确认）**：InventoryItem 有 unique 索引 `getByDefId(defId)`，字段 `firstObtainedAt`/`lastObtainedAt`（非 `acquiredAt`）。全局 isar = `IsarSetup.instance`。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/seclusion/application/offline_passive_settle_test.dart`
Expected: FAIL — `settle` 未定义。

- [ ] **Step 3: 实现 settle()（复用 completeRetreat 发放真相源）**

在 `offline_passive_service.dart` 的 `compute` 后加（参照 `seclusion_service.dart:300–393` 的入库模式）：

```dart
  /// 结算一次被动离线产出并写 Isar（同事务）：
  ///   1. 磨剑石 → InventoryItem(item_mojianshi)
  ///   2. 经验 → CharacterAdvancementService.applyExperience（含升层 + 心魔锁，
  ///      与闭关收功一致）
  ///   3. SaveData 累计 += + lastOnlineAt = now（重置基准，防重复结算）
  ///
  /// 仅由 gate 在「无 active 闭关 + 离线≥min」时调用（互斥见 spec §2 #9）。
  /// 返回本次产量供告知卡展示。
  static Future<PassiveYield> settle({
    required int saveDataId,
    required int characterId,
    required double awayHours,
    required DateTime now,
  }) async {
    final isar = IsarSetup.instance;
    final ch = await isar.characters.get(characterId);
    final realmTier = ch?.realmTier ?? RealmTier.xueTu;
    final yield_ = compute(
      awayHours: awayHours,
      realmTier: realmTier,
      config: GameRepository.instance.numbers.passiveIdle,
    );

    await isar.writeTxn(() async {
      if (yield_.mojianshi > 0) {
        // 复用闭关同款 defId + getByDefId 索引(对齐 drop 体系)。
        final existing = await isar.inventoryItems.getByDefId('item_mojianshi');
        if (existing != null) {
          existing.quantity += yield_.mojianshi;
          existing.lastObtainedAt = now;
          await isar.inventoryItems.put(existing);
        } else {
          await isar.inventoryItems.put(InventoryItem()
            ..defId = 'item_mojianshi'
            ..itemType = ItemType.moJianShi
            ..quantity = yield_.mojianshi
            ..firstObtainedAt = now
            ..lastObtainedAt = now);
        }
      }

      final c = await isar.characters.get(characterId);
      if (c != null && yield_.experience > 0) {
        final progress = await isar.mainlineProgress
            .filter().saveDataIdEqualTo(saveDataId).findFirst();
        final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
        final innerDemonDef = GameRepository.instance.numbers.innerDemon;
        CharacterAdvancementService.applyExperience(
          c,
          yield_.experience,
          realmLookup: GameRepository.instance.getRealm,
          isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
            nextTier: tier,
            nextLayer: layer,
            innerDemonDef: innerDemonDef,
            clearedStageIds: clearedSet,
          ),
        );
        await isar.characters.put(c);
      }

      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.totalPassiveMojianshi += yield_.mojianshi;
        save.totalPassiveExperience += yield_.experience;
        save.lastOnlineAt = now;
        await isar.saveDatas.put(save);
      }
    });

    return yield_;
  }
```

补 import：`data/isar_setup.dart`、`core/domain/inventory_item.dart`(InventoryItem/ItemType)、`core/domain/character.dart`、`CharacterAdvancementService` 与 `InnerDemonService`(grep 定位文件路径)、`data/game_repository.dart`。字段名已对齐 `_addInventoryItem`（seclusion_service.dart:552）：`getByDefId` 索引 + `firstObtainedAt`/`lastObtainedAt`。`mainlineProgress.filter().saveDataIdEqualTo` 沿用 completeRetreat 同款 query（seclusion_service.dart:374）。

- [ ] **Step 4: gate 分流（无闭关→settle→弹被动卡）**

`offline_recap_gate.dart` 的 `maybeShowOfflineRecap`：现有 `if (session == null) return;` 改为分流到范围 B。替换该早返回为：

```dart
  if (session != null) {
    // —— 范围 A：有 active 闭关，引导收功（现有逻辑保持不变）——
    // ...（原 buildRecap + showDialog OfflineRecapCard 引导收功代码不动）
    return;
  }

  // —— 范围 B：无 active 闭关，按 lastOnlineAt 结算被动 ——
  final save = (await IsarSetup.currentSaveData())!;
  // 旧档首启不回溯：lastOnlineAt == createdAt 视为基准未建立，置 now 不结算。
  if (save.lastOnlineAt == save.createdAt) {
    await IsarSetup.touchOnlineNow(); // Task 5 提供（写 lastOnlineAt = now）
    return;
  }
  final cfg = GameRepository.instance.numbers.passiveIdle;
  final nowDt = now ?? DateTime.now();
  final awayHours = nowDt.difference(save.lastOnlineAt).inSeconds / 3600.0;
  if (awayHours <= 0) return;

  final ids = await ref.read(activeCharacterIdsProvider.future);
  final charId = ids.isNotEmpty ? ids.first : 1;
  // settle 内部用 IsarSetup.instance：自动入包 + 累计 += + 重置 lastOnlineAt。
  final yield_ = await OfflinePassiveService.settle(
    saveDataId: save.slotId,
    characterId: charId,
    awayHours: awayHours,
    now: nowDt);

  // 离开不足阈值：已静默入包，不弹卡（小额无打扰）。
  if (awayHours < cfg.minRecapHours) return;
  if ((yield_.mojianshi == 0 && yield_.experience == 0) || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: OfflineRecapCard.passive(  // Task 6 命名构造
        mojianshi: yield_.mojianshi,
        experience: yield_.experience,
        awayHours: awayHours,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
```

> **gate import 备忘**：`offline_recap_gate.dart` 需补 `import '../../../data/isar_setup.dart';` 与 `import '../application/offline_passive_service.dart';`。`activeCharacterIdsProvider` 已在范围 A 分支用，复用。

- [ ] **Step 5: 跑 settle 测试确认通过**

Run: `flutter test test/features/seclusion/application/offline_passive_settle_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/seclusion/application/offline_passive_service.dart lib/features/seclusion/presentation/offline_recap_gate.dart test/features/seclusion/application/offline_passive_settle_test.dart
git commit -m "M2范围B Task4: settle 入库 + gate 分流 + 旧档不回溯"
```

---

## Task 5: lastOnlineAt 真写入点（AppLifecycleListener）

**Files:**
- Modify: `lib/data/isar_setup.dart`（加 `touchOnlineNow`）
- Modify: `lib/main.dart`（`WuxiaApp` 挂 `AppLifecycleListener`）
- Test: `test/features/seclusion/application/online_timestamp_recorder_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/seclusion/application/online_timestamp_recorder_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

void main() {
  late Directory tempDir;
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_online_ts_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async => await IsarSetup.close());

  test('touchOnlineNow 写入指定时间到 lastOnlineAt', () async {
    await IsarSetup.touchOnlineNow(now: DateTime(2026, 6, 15, 9));
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 9));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/seclusion/application/online_timestamp_recorder_test.dart`
Expected: FAIL — `touchOnlineNow` 未定义。

- [ ] **Step 3: IsarSetup 加 touchOnlineNow**

在 `isar_setup.dart` 加静态方法：

```dart
  /// 写当前在线时间戳到 SaveData.lastOnlineAt（M2 范围 B 离线时长基准）。
  /// 由 app lifecycle detached/hidden 调用；[now] 仅供测试注入。
  static Future<void> touchOnlineNow({DateTime? now}) async {
    final save = await currentSaveData();
    if (save == null) return; // 未 init / 无存档：安全 no-op。
    await instance.writeTxn(() async {
      save.lastOnlineAt = now ?? DateTime.now();
      await instance.saveDatas.put(save);
    });
  }
```

> 类内部用 `instance`(Isar getter) + Task 3 的 `currentSaveData()`，同在 `IsarSetup` 类。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/seclusion/application/online_timestamp_recorder_test.dart`
Expected: PASS

- [ ] **Step 5: main.dart 挂 AppLifecycleListener**

`WuxiaApp` 改 `ConsumerStatefulWidget`（若已是 ConsumerWidget），在 State 加：

```dart
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _recordOnline,
      onInactive: _recordOnline,
      onDetach: _recordOnline,
    );
  }

  void _recordOnline() {
    // fire-and-forget：离开瞬间记时间戳，下次重开算离线时长。
    IsarSetup.touchOnlineNow();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
```

> 若 IsarSetup 未初始化（极早期），`touchOnlineNow` 内 `instance` getter 抛 StateError；给 `_recordOnline` 加 `unawaited(IsarSetup.touchOnlineNow().catchError((_) {}));` 包裹，避免 lifecycle 回调崩溃。需 `import 'dart:async';`（unawaited）。

- [ ] **Step 6: 跑全量回归 + analyze**

Run: `flutter analyze && flutter test`
Expected: analyze 0 issues；全量测试零回归（基线 2214 + 本批新增）。

- [ ] **Step 7: Commit**

```bash
git add lib/data/isar_setup.dart lib/main.dart test/features/seclusion/application/online_timestamp_recorder_test.dart
git commit -m "M2范围B Task5: lastOnlineAt 真写入点(AppLifecycleListener)"
```

---

## Task 6: 归来卡被动变体 + 文案

**Files:**
- Modify: `lib/features/seclusion/presentation/offline_recap_card.dart`（加 `OfflineRecapCard.passive`）
- Modify: `lib/shared/strings.dart`（被动文案）
- Test: `test/features/seclusion/presentation/offline_recap_passive_card_test.dart`

- [ ] **Step 1: strings.dart 加文案**

在 `UiStrings` 的 `offlineRecap*` 段旁加（无中文硬编码进 Dart 逻辑，§5.6）：

```dart
  /// M2 范围 B 被动离线挂机告知卡。
  static const String passiveRecapTitle = '闭关之外，亦有精进';
  static String passiveRecapBody(int hours, int moji, int exp) =>
      '离去约 $hours 时辰。这些日子里你未曾松懈，'
      '行功走架间得磨剑石 $moji、修为 $exp，已收入囊中。';
  static const String passiveRecapDismiss = '甚好';
```

- [ ] **Step 2: 写失败 widget 测试**

```dart
// test/features/seclusion/presentation/offline_recap_passive_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_card.dart';

void main() {
  testWidgets('被动卡展示产量 + 仅一个关闭按钮(无领取)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OfflineRecapCard.passive(
          mojianshi: 2, experience: 250, awayHours: 10, onDismiss: () {}),
      ),
    ));
    expect(find.textContaining('磨剑石'), findsWidgets);
    expect(find.textContaining('甚好'), findsOneWidget);
    // 无「前去收功/领取」按钮（被动自动入包，避 §5.1 登录奖励化）
    expect(find.textContaining('收功'), findsNothing);
    expect(find.textContaining('领取'), findsNothing);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
Expected: FAIL — `OfflineRecapCard.passive` 未定义。

- [ ] **Step 4: 加 passive 命名构造**

`offline_recap_card.dart` 现有主构造接 `OfflineRecap recap`。加一个命名构造 + 内部 mode 分支（保持原构造不变）：

```dart
  /// 范围 B 被动离线挂机「仅告知」变体：无收功按钮，仅展示已入囊产量。
  const OfflineRecapCard.passive({
    super.key,
    required int mojianshi,
    required int experience,
    required double awayHours,
    required VoidCallback onDismiss,
  })  : _passiveMojianshi = mojianshi,
        _passiveExperience = experience,
        _passiveAwayHours = awayHours,
        onGoCollect = null,
        onDismiss = onDismiss,
        recap = null;
```

加字段 `final int? _passiveMojianshi;` 等 + `final OfflineRecap? recap;`（原构造给 recap 赋值，passive 给 null）。`build` 内 `if (recap == null)` 渲染被动布局：标题 `UiStrings.passiveRecapTitle`、正文 `UiStrings.passiveRecapBody(awayHours.floor(), moji, exp)`、单个 `PlaqueButton(UiStrings.passiveRecapDismiss, onPressed: onDismiss)`，复用现有 `WuxiaPaperPanel`/`PlaqueButton` 体例（参照原构造布局）。

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/seclusion/presentation/offline_recap_card.dart lib/shared/strings.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart
git commit -m "M2范围B Task6: 归来卡被动变体 + 文案(无领取按钮守§5.1)"
```

---

## Task 7: balance_simulator 红线复评 + base 校准

**Files:**
- Modify: `data/numbers.yaml`（按 simulator 结果调 base 值）
- Test: `test/tools/balance_simulator_test.dart`（加被动管道断言）或新诊断测

- [ ] **Step 1: 看现有 balance_simulator 测怎么验产出曲线**

Run: `grep -n "passive\|idle\|周目\|产出曲线\|redline\|不进百万" test/tools/balance_simulator_test.dart | head`
读现有极值×周目诊断测结构（CLAUDE.md §5.4 提到 `test/tools/balance_simulator_test.dart` 极值×周目诊断）。

- [ ] **Step 2: 加被动管道产出断言**

在 simulator 诊断测加一项：满 72h 被动产出叠加现有养成路径后，① 不让低境界碾压跨阶内容（参照 numbers.yaml retreat 段 B2 finding「满挂 72h 二流不碾压 Ch1 学徒差 1 阶」同口径）② 经验/磨剑石产量级别合理（被动 ≈ 闭关 25%，可直接断言 `passive_72h_exp ≈ retreat_入门图_72h_exp × 0.25 ± 容差`）。

```dart
test('被动 72h 产出 ≈ 入门闭关图 72h 的 25%(±容差)', () {
  const cfg = /* 读 GameRepository.instance.numbers.passiveIdle */;
  final passive = OfflinePassiveService.compute(
    awayHours: 72, realmTier: RealmTier.xueTu, config: cfg);
  // 入门图 exp_per_hour 100 × 72 × 1.0 = 7200，25% = 1800
  expect(passive.experience, closeTo(1800, 200));
});
```

- [ ] **Step 3: 跑 simulator + 校准 base**

Run: `flutter test test/tools/balance_simulator_test.dart`
若被动产出过高（碾压跨阶 / 破坏曲线）→ 下调 `data/numbers.yaml` `passive_idle.base_*`，重跑直至：① 25% 锚定成立 ② 不触 §5.4 红线 ③ 闭关仍明显最优。

- [ ] **Step 4: 全量回归 + analyze**

Run: `flutter analyze && flutter test`
Expected: analyze 0 issues；全量零回归。

- [ ] **Step 5: Commit**

```bash
git add data/numbers.yaml test/tools/balance_simulator_test.dart
git commit -m "[balance] M2范围B Task7: 被动产出 balance_simulator 复评 + base 校准"
```

---

## 收尾（全 Task 完成后）

- [ ] 全量 `flutter analyze`（0 issues）+ `flutter test`（零回归，测数从 2214 净增 ≈ Task1-7 新增）
- [ ] 更新 `PROGRESS.md` 顶段（续12：M2 范围 B 闭环）
- [ ] 合 main 前确认：spec §2 九决策全落实、§5.1 守线（无领取按钮/无每日刷新）、§5.5 兑现（真离线时长结算）
- [ ] **真机验收待办**（bg 无法跑 GUI）：关游戏→重开→被动卡展示 + 数值入包；lifecycle detached 写 lastOnlineAt 实效。派 Codex 或用户本机实测（memory `feedback_visual_acceptance_two_workflows`）。
- [ ] 用 `superpowers:finishing-a-development-branch` 决定合并方式。
