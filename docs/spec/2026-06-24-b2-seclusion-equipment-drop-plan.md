# 闭关装备掉落接通 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 闭关命中外层掉落闸后，从地图压一阶 dropTable 加权抽 1 件装备并真入背包。

**Architecture:** `SeclusionMapDef` 加 `dropTable`（复用 `DropEntry`）；`DropService` 加 `rollOneWeighted`（按 dropChance 权重抽 1）；`computeOutputs` 接 `DropService?`（nullable → 不传则零回归）填空块；`completeRetreat` 构造注入 + writeTxn 落库。

**Tech Stack:** Dart / Flutter / Isar；现有 `DropService`/`EquipmentFactory`/`DropEntry` 体系。

**基线：** spec `docs/spec/2026-06-24-b2-seclusion-equipment-drop-design.md`，HEAD `f14eebe8`，saveVer 不变。

---

## 文件结构

| 文件 | 改动 |
|---|---|
| `lib/features/seclusion/domain/seclusion_map_def.dart` | +`dropTable` 字段 + fromYaml 解析 |
| `lib/features/equipment/application/drop_service.dart` | +`rollOneWeighted` 方法 |
| `lib/shared/strings.dart` | +`dropSourceSeclusion` 常量 |
| `lib/features/seclusion/application/seclusion_service.dart` | computeOutputs +`dropService` 参数 / 填空块 / completeRetreat 构造注入 + writeTxn 落库 |
| `data/numbers.yaml` | 5 图 `retreat.maps[].dropTable` 区块 |
| `test/features/seclusion/domain/seclusion_map_def_test.dart` | dropTable 解析测 |
| `test/features/equipment/application/drop_service_roll_one_test.dart` | rollOneWeighted 测（新建）|
| `test/features/seclusion/application/seclusion_drop_test.dart` | 掉落 + 落库 + 锁步红线（新建）|

---

### Task 1: SeclusionMapDef 加 dropTable 字段 + 解析

**Files:**
- Modify: `lib/features/seclusion/domain/seclusion_map_def.dart`
- Test: `test/features/seclusion/domain/seclusion_map_def_test.dart`

- [ ] **Step 1: 写失败测试**（在该测试文件末尾 group 内追加）

```dart
test('fromYaml 解析 dropTable 为 EquipmentDrop 列表，缺省则空表', () {
  final withTable = SeclusionMapDef.fromYaml({
    'map_type': 'shanLin',
    'map_name': '山林',
    'required_realm': 'xueTu',
    'base_outputs': {
      'experience_per_hour': 1.0,
      'mojianshi_per_hour': 1.0,
      'equipment_drop_rate': 1.0,
      'technique_learn_rate': 1.0,
      'internal_force_growth': 1.0,
    },
    'dropTable': [
      {'equipmentDefId': 'weapon_xunchang_tie_jian', 'dropChance': 1.0},
    ],
  });
  expect(withTable.dropTable, hasLength(1));
  expect(
    (withTable.dropTable.first as EquipmentDrop).equipmentDefId,
    'weapon_xunchang_tie_jian',
  );

  final noTable = SeclusionMapDef.fromYaml({
    'map_type': 'shanLin',
    'map_name': '山林',
    'required_realm': 'xueTu',
    'base_outputs': {
      'experience_per_hour': 1.0,
      'mojianshi_per_hour': 1.0,
      'equipment_drop_rate': 1.0,
      'technique_learn_rate': 1.0,
      'internal_force_growth': 1.0,
    },
  });
  expect(noTable.dropTable, isEmpty);
});
```

确保测试文件顶部 import：`import 'package:wuxia_idle/data/defs/drop_entry.dart';`

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/domain/seclusion_map_def_test.dart`
Expected: FAIL（`dropTable` getter 不存在 / 参数缺失）

- [ ] **Step 3: 实现**

`seclusion_map_def.dart` 顶部加 import：

```dart
import '../../../data/defs/drop_entry.dart';
```

字段区（`imagePath` 后）加：

```dart
  /// 闭关掉落表（numbers.yaml `retreat.maps[].dropTable`，B2 接通）。
  /// 压一阶定位：装备 tier 锁地图 requiredRealm 低一阶。缺省空表 = 不掉。
  final List<DropEntry> dropTable;
```

构造器加 `this.dropTable = const []`，置于 `this.imagePath` 后。

`fromYaml` return 区加字段（`imagePath:` 行后）：

```dart
      dropTable: (y['dropTable'] as List<dynamic>?)
              ?.map((e) => DropEntry.fromYaml(e as Map<String, dynamic>))
              .toList() ??
          const [],
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/domain/seclusion_map_def_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/seclusion/domain/seclusion_map_def.dart test/features/seclusion/domain/seclusion_map_def_test.dart
git commit -m "feat: SeclusionMapDef 加 dropTable 字段 + 解析(B2 task1)"
```

---

### Task 2: DropService.rollOneWeighted

**Files:**
- Modify: `lib/features/equipment/application/drop_service.dart`
- Test: `test/features/equipment/application/drop_service_roll_one_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

class _ConstRng implements Rng {
  _ConstRng(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
}

void main() {
  EquipmentDef def(String id) => EquipmentDef(
        id: id,
        name: id,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        baseAttackMin: 1,
        baseAttackMax: 1,
        baseHealthMin: 0,
        baseHealthMax: 0,
        baseSpeedMin: 0,
        baseSpeedMax: 0,
        presetLoreIds: const [],
        dropSourceTags: const [],
        iconPath: '',
      );

  DropService svc() => DropService(
        equipmentDefLookup: def,
        defaultObtainedFrom: 'T',
        now: () => DateTime(2026, 6, 24),
      );

  test('空表返回 null', () {
    expect(svc().rollOneWeighted(const [], _ConstRng(0.0)), isNull);
  });

  test('命中按权重抽恰好 1 件（roll=0.0 落第 1 条）', () {
    final table = [
      const EquipmentDrop(equipmentDefId: 'a', dropChance: 1.0),
      const EquipmentDrop(equipmentDefId: 'b', dropChance: 1.0),
    ];
    final eq = svc().rollOneWeighted(table, _ConstRng(0.0));
    expect(eq, isNotNull);
    expect(eq!.defId, 'a');
  });

  test('忽略非 EquipmentDrop 条目', () {
    final table = [
      const ItemDrop(
          inventoryItemDefId: 'item_x', quantityMin: 1, quantityMax: 1,
          dropChance: 1.0),
    ];
    expect(svc().rollOneWeighted(table, _ConstRng(0.0)), isNull);
  });
}
```

> 字段名已对照 `equipment_def.dart` 构造器（id/name/tier/slot/base*Min-Max + presetLoreIds/dropSourceTags/iconPath 必填）、`rng.dart`（Rng 在 `shared/utils/rng.dart`）核实。

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/equipment/application/drop_service_roll_one_test.dart`
Expected: FAIL（`rollOneWeighted` 未定义）

- [ ] **Step 3: 实现**（`drop_service.dart`，`_rollTable` 方法后追加）

```dart
  /// 加权抽 1 件装备（B2 闭关用）：按各 [EquipmentDrop.dropChance] 作相对权重
  /// 选恰好 1 条。表空 / 无 EquipmentDrop / 总权重 ≤ 0 → null。
  /// 与 [_rollTable] 的 EquipmentDrop 分支同样经 [EquipmentFactory.fromDef] 实例化。
  Equipment? rollOneWeighted(List<DropEntry> table, Rng rng) {
    final entries = table.whereType<EquipmentDrop>().toList();
    if (entries.isEmpty) return null;
    final total = entries.fold<double>(0, (s, e) => s + e.dropChance);
    if (total <= 0) return null;
    var roll = rng.nextDouble() * total;
    EquipmentDrop chosen = entries.last; // 浮点兜底
    for (final entry in entries) {
      roll -= entry.dropChance;
      if (roll < 0) {
        chosen = entry;
        break;
      }
    }
    final def = equipmentDefLookup(chosen.equipmentDefId);
    return EquipmentFactory.fromDef(
      def,
      rng: rng,
      obtainedAt: now(),
      obtainedFrom: defaultObtainedFrom,
    );
  }
```

确保文件已 import `EquipmentFactory`（`_rollTable` 已用，通常已在）。

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/equipment/application/drop_service_roll_one_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/equipment/application/drop_service.dart test/features/equipment/application/drop_service_roll_one_test.dart
git commit -m "feat: DropService.rollOneWeighted 加权抽 1 件(B2 task2)"
```

---

### Task 3: numbers.yaml 5 图 dropTable + 锁步红线测

**Files:**
- Modify: `data/numbers.yaml`（`retreat.maps[]`）
- Test: `test/features/seclusion/application/seclusion_drop_test.dart`（新建，红线 group）

- [ ] **Step 1: 写失败红线测**（建文件，含全 fixture + `_ConstRng`，供 Task 4/5 复用）

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 固定 nextDouble 的测试 Rng（驱动外层闸 + 加权抽 1 确定性）。
class _ConstRng implements Rng {
  _ConstRng(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
}

const kSaveDataId = 1;
const kCharId = 10;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_seclusion_drop_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch = Character.create(
      name: 'test_hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 500,
    )..id = kCharId;
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(ch),
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('红线：5 图 dropTable 装备 tier == 压一阶目标 tier（守 §5.3 锁步）', () {
    const expected = <RetreatMapType, EquipmentTier>{
      RetreatMapType.shanLin: EquipmentTier.xunChang, // xueTu 边界压不动
      RetreatMapType.guJianZhong: EquipmentTier.xunChang, // sanLiu→压
      RetreatMapType.cangJingGe: EquipmentTier.xunChang,
      RetreatMapType.xuanYaPuBu: EquipmentTier.xiangYang, // erLiu→压
      RetreatMapType.duanYaJueBi: EquipmentTier.zhongQi, // zongShi→压
    };
    for (final m in GameRepository.instance.seclusionMaps) {
      expect(m.dropTable, isNotEmpty, reason: '${m.mapType} 应有 dropTable');
      for (final entry in m.dropTable.whereType<EquipmentDrop>()) {
        final def = GameRepository.instance.getEquipment(entry.equipmentDefId);
        expect(def.tier, expected[m.mapType],
            reason: '${m.mapType} 的 ${entry.equipmentDefId} tier 越界');
      }
    }
  });
}
```

> 注：getter `seclusionMaps` / `getEquipment` / `numbers.retreat` 已对照 `seclusion_service_test.dart` 既有体例核实。

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/application/seclusion_drop_test.dart`
Expected: FAIL（dropTable 为空 / 未配）

- [ ] **Step 3: 配 numbers.yaml**（`retreat.maps[]` 各 map 的 `base_outputs` 同级加 `dropTable`）

按 spec §3 填（每图 3 条 weapon/armor/accessory，`dropChance: 1.0`）：

```yaml
    # 山林 shanLin（寻常货·边界）
      dropTable:
        - equipmentDefId: weapon_xunchang_tie_jian
          dropChance: 1.0
        - equipmentDefId: armor_xunchang_bu_yi
          dropChance: 1.0
        - equipmentDefId: accessory_xunchang_yu_pei
          dropChance: 1.0
    # 古剑冢 guJianZhong（寻常货）
      dropTable:
        - equipmentDefId: weapon_xunchang_zhe_dao
          dropChance: 1.0
        - equipmentDefId: armor_xunchang_duan_gua
          dropChance: 1.0
        - equipmentDefId: accessory_xunchang_tong_ling
          dropChance: 1.0
    # 藏经阁 cangJingGe（寻常货）
      dropTable:
        - equipmentDefId: weapon_xunchang_ruan_bian
          dropChance: 1.0
        - equipmentDefId: armor_xunchang_mian_jia
          dropChance: 1.0
        - equipmentDefId: accessory_xunchang_yao_nang
          dropChance: 1.0
    # 悬崖瀑布 xuanYaPuBu（像样货）
      dropTable:
        - equipmentDefId: weapon_xiangyang_gang_dao
          dropChance: 1.0
        - equipmentDefId: armor_xiangyang_pi_jia
          dropChance: 1.0
        - equipmentDefId: accessory_xiangyang_yin_jie
          dropChance: 1.0
    # 断崖绝壁 duanYaJueBi（重器）
      dropTable:
        - equipmentDefId: weapon_zhongqi_po_zhen_chui
          dropChance: 1.0
        - equipmentDefId: armor_zhongqi_yin_lin_jia
          dropChance: 1.0
        - equipmentDefId: accessory_zhongqi_qing_yu_huan
          dropChance: 1.0
```

> 缩进对齐各 map 的 `base_outputs` 层级（正向定位 `- map_type:` 块逐个填，勿照搬上面缩进，以文件实际为准）。

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/application/seclusion_drop_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add data/numbers.yaml test/features/seclusion/application/seclusion_drop_test.dart
git commit -m "feat: 5 图闭关 dropTable 配置 + 锁步红线测(B2 task3)"
```

---

### Task 4: computeOutputs 接 DropService + 填空块 + strings 常量

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/seclusion/application/seclusion_service.dart`（computeOutputs :177 签名 + 空块 :255-259）
- Test: `test/features/seclusion/application/seclusion_drop_test.dart`（同 Task 3 文件，新 group）

- [ ] **Step 1: 写失败测试**（追加到 `seclusion_drop_test.dart` main() 内，复用 Task 3 的 `_ConstRng`）

```dart
  RetreatSession shanLinSession(int id) => RetreatSession()
    ..id = id
    ..saveDataId = kSaveDataId
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime(2026, 5, 11, 10, 0)
    ..status = RetreatStatus.active
    ..actualRewards = [];

  test('computeOutputs：闸命中 + dropService → 1 件压一阶(山林 xunChang)', () {
    final now = DateTime(2026, 5, 11, 14, 0); // start + 4h
    final dropSvc = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.dropSourceSeclusion,
      now: () => now,
    );
    final out = SeclusionService.computeOutputs(
      session: shanLinSession(50),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
      dropService: dropSvc,
      rng: _ConstRng(0.0), // 0.0 < equipProb(1.0×0.1) → 命中；抽第 1 条
    );
    expect(out.equipmentDrops, hasLength(1));
    expect(out.equipmentDrops.first.tier, EquipmentTier.xunChang);
    expect(out.equipmentDrops.first.obtainedFrom, UiStrings.dropSourceSeclusion);
  });

  test('computeOutputs：不传 dropService → equipDrops 恒空(零回归)', () {
    final now = DateTime(2026, 5, 11, 14, 0);
    final out = SeclusionService.computeOutputs(
      session: shanLinSession(51),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
      rng: _ConstRng(0.0),
    );
    expect(out.equipmentDrops, isEmpty);
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/application/seclusion_drop_test.dart`
Expected: FAIL（`dropService` 参数不存在）

- [ ] **Step 3a: 加 strings 常量**（`strings.dart`，`dropSourceAscensionReward` 行后）

```dart
  // B2 闭关掉落来历（DropService.defaultObtainedFrom）。
  static const String dropSourceSeclusion = '闭关所得';
```

- [ ] **Step 3b: computeOutputs 加参数**（`seclusion_service.dart:177` named 参数区，`Rng? rng,` 前）

```dart
    DropService? dropService,
```

文件顶部确保 import：`import '../../equipment/application/drop_service.dart';`

- [ ] **Step 3c: 填空块**（`:255-259` 现有空 `if` 块整体替换）

```dart
    final effectiveRng = rng ?? DefaultRng();
    final equipRoll = effectiveRng.nextDouble();
    final equipProb = def.equipmentDropRate * config.baseEquipDropProbability;
    final equipDrops = <Equipment>[];
    if (dropService != null && equipRoll < equipProb) {
      final eq = dropService.rollOneWeighted(def.dropTable, effectiveRng);
      if (eq != null) equipDrops.add(eq);
    }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/application/seclusion_drop_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/shared/strings.dart lib/features/seclusion/application/seclusion_service.dart test/features/seclusion/application/seclusion_drop_test.dart
git commit -m "feat: computeOutputs 接 DropService 填闭关掉落空块 + dropSourceSeclusion(B2 task4)"
```

---

### Task 5: completeRetreat 注入构造 + writeTxn 落库

**Files:**
- Modify: `lib/features/seclusion/application/seclusion_service.dart`（调用点 :311 + writeTxn :327+）
- Test: `test/features/seclusion/application/seclusion_drop_test.dart`（新 group，Isar 集成）

- [ ] **Step 1: 写失败测试**（追加到 `seclusion_drop_test.dart`，Isar 集成；`completeRetreat` 内部走 `GameRepository.isLoaded` 分支自建 DropService，不需注 rng）

```dart
  test('completeRetreat：收功后掉落装备真入 isar.equipments + obtainedFrom 闭关', () async {
    final start = DateTime(2026, 5, 11, 10, 0);
    final completeAt = start.add(const Duration(hours: 4));
    // 写一条 active 山林 session（完成时长 4h）
    final session = RetreatSession()
      ..id = 60
      ..saveDataId = kSaveDataId
      ..mapType = RetreatMapType.shanLin
      ..durationHours = 4
      ..startedAt = start
      ..status = RetreatStatus.active
      ..actualRewards = [];
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.retreatSessions.put(session),
    );

    // 山林 equipProb = 1.0 × 0.1 = 0.1。completeRetreat 默认 rng = DefaultRng()，
    // 命中非确定。注入说明：completeRetreat 暴露可选 rng 参数（既有签名已有
    // `Rng? rng`，见 :311 调用透传），测试传 _ConstRng(0.0) 强制命中。
    await SeclusionService(isar: IsarSetup.instance).completeRetreat(
      session: session,
      characterId: kCharId,
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: completeAt,
      rng: _ConstRng(0.0),
    );

    final eqs = await IsarSetup.instance.equipments.where().findAll();
    expect(eqs, hasLength(1));
    expect(eqs.first.tier, EquipmentTier.xunChang);
    expect(eqs.first.obtainedFrom, UiStrings.dropSourceSeclusion);
  });
```

> `completeRetreat` 既有签名已含 `Rng? rng`（透传给 computeOutputs）；Isar 集成测须 `GameRepository.isLoaded == true`（setUpAll 已 loadAllDefs），否则 :311 的 `isLoaded ?` 分支返回 null 不掉。

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/application/seclusion_drop_test.dart`
Expected: FAIL（equipments 空 / dropService 未注入）

- [ ] **Step 3a: 调用点注入**（`seclusion_service.dart:311` `computeOutputs(` 调用，`rng: rng,` 行后加）

```dart
      dropService: GameRepository.isLoaded
          ? DropService(
              equipmentDefLookup: GameRepository.instance.getEquipment,
              defaultObtainedFrom: UiStrings.dropSourceSeclusion,
              now: () => now,
            )
          : null,
```

确保 import：`import '../../../shared/strings.dart';`、`import '../../../data/game_repository.dart';`（多半已在）。

- [ ] **Step 3b: writeTxn 落库**（`:327` writeTxn 内，silver 块 `}` 后 / session 更新前插入）

```dart
      // 1c. 写闭关掉落装备 → isar.equipments（B2 接通）。
      for (final eq in outputs.equipmentDrops) {
        await isar.equipments.put(eq);
      }
```

- [ ] **Step 4: 跑测试确认通过 + 全量回归**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/seclusion/`
Expected: PASS（含既有闭关测全绿，零回归）

- [ ] **Step 5: 提交**

```bash
git add lib/features/seclusion/application/seclusion_service.dart test/features/seclusion/application/seclusion_drop_test.dart
git commit -m "feat: completeRetreat 注入 DropService + writeTxn 落库闭关装备(B2 task5)"
```

---

### Task 6: 全量回归 + analyze + 审计标 resolved

**Files:**
- Modify: `docs/audit/full_system_audit_2026-06-24.md`（B2 标 resolved）

- [ ] **Step 1: 全量测试**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test`
Expected: 全绿，仅新增测，0 回归（对照基线 2876+1skip，新增本批测数）

- [ ] **Step 2: analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze`
Expected: `No issues found!`（0 error/warning）

- [ ] **Step 3: 审计标 resolved**

`docs/audit/full_system_audit_2026-06-24.md` 的 `### B2` 标题后加 `— ✅ resolved 2026-06-24（接通 · commit <sha> · spec/plan docs/spec/2026-06-24-b2-seclusion-equipment-drop-*）`；分级汇总表 B 行计数 -1 或注接通。

- [ ] **Step 4: 提交**

```bash
git add docs/audit/full_system_audit_2026-06-24.md
git commit -m "docs: B2 闭关装备掉落标 resolved"
```

---

## 完成定义

- [ ] 闭关收功 10~15% 概率掉 1 件压一阶装备，真入 `isar.equipments`、`obtainedFrom == 闭关所得`。
- [ ] 5 图 dropTable tier 守 §5.3 锁步（红线测保护）。
- [ ] 零 saveVer / 零产出数值变更 / dropService 不传则恒空（既有测全绿）。
- [ ] `flutter test` 全绿 + `flutter analyze` 0 issue。
- [ ] 审计 B2 标 resolved。
