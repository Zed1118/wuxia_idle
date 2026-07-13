# Progression and Settlement Convergence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 正式接通中文门派名称、把境界经验阈值统一到 `RealmDef`，并让主线与爬塔复用同一套成长及公共事件结算。

**Architecture:** 采用渐进式兼容：`FactionDef` 完整加载后继续派生旧 `factionAlignments`；`Character.experienceToNextLayer` 保留为 Isar 兼容镜像但退出生产读取；新增 `CombatProgressionSettlementService`，只承接两种玩法真正相同的经验、突破、共鸣与 Boss 首胜事件，首通和掉落策略仍留在各玩法外层。

**Tech Stack:** Flutter Desktop、Dart、Riverpod、Isar Community、YAML、flutter_test

---

## 当前恢复点

- 状态：实现与验证完成，待分支收尾决策。
- 最后完成：Task 8 全量验证、macOS debug 构建和进度文档收口。
- 下一步：按 `finishing-a-development-branch` 流程决定保留、合并或推送分支。
- 已跑验证：基线全量 3878 pass；Task 1 定向 33 pass；Task 2 定向 42 pass；Task 3 定向 31 pass；Task 4 定向 60 pass；Task 5 定向 49 pass；Task 6 联合定向 46 pass；Task 7 联合定向 45 pass；最终定向 151 pass；全量 JSON reporter 非隐藏测试 3897 success / 0 fail；format 1109/0 changed；`flutter analyze --no-pub` 0 issue；macOS debug build 成功。
- 阻塞项：无。

---

## 文件结构

### 新建

- `lib/data/defs/faction_def.dart`：完整门派静态定义与 YAML 解析。
- `lib/features/cultivation/domain/advancement_entry.dart`：跨主线、爬塔、胜利 UI 共享的角色成长结果。
- `lib/features/equipment/domain/resonance_upgrade_notice.dart`：跨玩法共享的共鸣晋阶展示结果。
- `lib/features/battle/application/combat_progression_settlement_service.dart`：公共经验与事件结算。
- `test/data/defs/faction_def_test.dart`：门派定义解析单测。
- `test/data/experience_threshold_production_usage_contract_test.dart`：禁止生产重新读取兼容镜像。
- `test/features/battle/application/combat_progression_settlement_service_test.dart`：公共服务行为与事务回滚测试。
- `test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart`：主线、爬塔接线去重契约。

### 修改

- `lib/data/game_repository.dart`：加载 `factionDefs`，派生 `factionAlignments`。
- `lib/features/jianghu/application/jianghu_providers.dart`：提供门派显示名 provider。
- `lib/features/jianghu/presentation/reputation_panel_screen.dart`：显示中文名。
- `lib/core/domain/character.dart`：把阈值字段标为兼容镜像。
- `lib/features/cultivation/application/character_advancement_service.dart`：使用局部 `RealmDef` 阈值推进。
- `lib/features/character_panel/presentation/character_panel_screen.dart`：移除镜像兜底读取。
- `lib/features/inner_demon/domain/inner_demon_panel.dart`：由调用方传入真实阈值。
- `lib/features/main_menu/application/main_menu_status_summary_provider.dart`：用 `RealmDef` 判断突破提示。
- `lib/features/shop/application/shop_providers.dart`、`shop_service.dart`：动态价格改读 `RealmDef` 并订正文档。
- `lib/features/cultivation/presentation/advancement_summary.dart`：导入共享 `AdvancementEntry`。
- `lib/features/mainline/presentation/stage_victory_dialog.dart`：导入共享 `ResonanceUpgradeNotice`。
- `lib/features/mainline/presentation/stage_entry_flow.dart`：接入公共结算。
- `lib/features/tower/presentation/tower_entry_flow.dart`：接入公共结算。
- 对应现有测试：更新构造参数、provider override 和共享类型 import。

## 必守行为

- 主线只要 `baseExpReward > 0` 就按当前规则发经验，包括重打。
- 爬塔只有 `isFirstClear && baseExpReward > 0` 才发经验。
- 主线秘籍首通门控、主线掉落、爬塔掉落、排行榜同步不进入公共服务。
- 公共服务不开 `writeTxn`；调用方继续持有唯一事务。
- 本批不改 save version，不删除任何 Isar 字段，不调整经验或商店数值。

---

### Task 1: 完整加载门派定义

**Files:**
- Create: `lib/data/defs/faction_def.dart`
- Create: `test/data/defs/faction_def_test.dart`
- Modify: `lib/data/game_repository.dart:118-161,380-396,418-450,573-615`
- Modify: `test/features/sect/faction_territory_validation_test.dart`

- [ ] **Step 1: 写 `FactionDef` 失败测试**

在 `test/data/defs/faction_def_test.dart` 写入：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/faction_def.dart';

void main() {
  test('fromYaml parses complete faction definition', () {
    final def = FactionDef.fromYaml({
      'id': 'shaolin',
      'name': '少林寺',
      'alignment': 'orthodox',
      'npc_ids': ['shaolin_abbot'],
    });

    expect(def.id, 'shaolin');
    expect(def.name, '少林寺');
    expect(def.alignment, 'orthodox');
    expect(def.npcIds, ['shaolin_abbot']);
  });

  test('fromYaml rejects blank id or name', () {
    expect(
      () => FactionDef.fromYaml({
        'id': '',
        'name': '无名',
        'alignment': 'neutral',
        'npc_ids': const [],
      }),
      throwsStateError,
    );
    expect(
      () => FactionDef.fromYaml({
        'id': 'unknown',
        'name': '   ',
        'alignment': 'neutral',
        'npc_ids': const [],
      }),
      throwsStateError,
    );
  });

  test('fromYaml defaults missing npc_ids to empty', () {
    final def = FactionDef.fromYaml({
      'id': 'wudang',
      'name': '武当派',
      'alignment': 'orthodox',
    });
    expect(def.npcIds, isEmpty);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
flutter test --no-pub test/data/defs/faction_def_test.dart
```

Expected: FAIL，提示 `faction_def.dart` 或 `FactionDef` 不存在。

- [ ] **Step 3: 实现 `FactionDef`**

新建 `lib/data/defs/faction_def.dart`：

```dart
class FactionDef {
  final String id;
  final String name;
  final String alignment;
  final List<String> npcIds;

  const FactionDef({
    required this.id,
    required this.name,
    required this.alignment,
    required this.npcIds,
  });

  factory FactionDef.fromYaml(Map<String, dynamic> yaml) {
    final id = (yaml['id'] as String? ?? '').trim();
    final name = (yaml['name'] as String? ?? '').trim();
    if (id.isEmpty) throw StateError('faction id 不可为空');
    if (name.isEmpty) throw StateError('faction $id name 不可为空');
    return FactionDef(
      id: id,
      name: name,
      alignment: yaml['alignment'] as String,
      npcIds: List<String>.unmodifiable(
        ((yaml['npc_ids'] as List?) ?? const []).cast<String>(),
      ),
    );
  }
}
```

- [ ] **Step 4: 运行解析测试确认通过**

Run:

```bash
flutter test --no-pub test/data/defs/faction_def_test.dart
```

Expected: 3 tests PASS。

- [ ] **Step 5: 给 Repository 加生产加载失败测试**

在 `test/features/sect/faction_territory_validation_test.dart` 增加：

```dart
test('真实 factions 加载完整定义并派生旧 alignment map', () async {
  final repo = await GameRepository.loadAllDefs(loader: realLoad);
  expect(repo.factionDefs, hasLength(6));
  expect(repo.factionDefs['shaolin']?.name, '少林寺');
  expect(repo.factionDefs['shaolin']?.npcIds, isEmpty);
  expect(repo.factionAlignments['shaolin'], 'orthodox');
});

test('factions.yaml 重复 id → 启动失败', () async {
  Future<String> duplicateLoader(String path) {
    if (path == 'data/factions.yaml') {
      return Future.value('''
factions:
  - {id: same, name: "甲", alignment: neutral, npc_ids: []}
  - {id: same, name: "乙", alignment: neutral, npc_ids: []}
''');
    }
    return realLoad(path);
  }

  await expectLater(
    GameRepository.loadAllDefs(loader: duplicateLoader),
    throwsA(isA<FormatException>()),
  );
});
```

为本文件增加 `tearDown(GameRepository.resetForTest);`，防止测试间全局实例串扰。

- [ ] **Step 6: 修改 `GameRepository`**

导入 `FactionDef`，新增字段和构造参数：

```dart
final Map<String, FactionDef> factionDefs;
final Map<String, String> factionAlignments;
```

把原始门派加载块替换为：

```dart
final factionDefs = await _loadOptionalAsset(
  load,
  'data/factions.yaml',
  (raw) {
    final factionsRaw = parseYamlMap(raw);
    return _parseDefMap(
      (factionsRaw['factions'] as List?) ?? const [],
      FactionDef.fromYaml,
      idOf: (def) => def.id,
    );
  },
  fallback: const <String, FactionDef>{},
);
final factionAlignments = <String, String>{
  for (final def in factionDefs.values) def.id: def.alignment,
};
```

构造 `GameRepository._` 时同时传入 `factionDefs` 和 `factionAlignments`。现有 `_validateFactionTerritoryReferences` 保持接收 `factionAlignments`，避免扩大本任务。

- [ ] **Step 7: 运行门派与 Repository 测试**

Run:

```bash
flutter test --no-pub \
  test/data/defs/faction_def_test.dart \
  test/features/sect/faction_territory_validation_test.dart \
  test/features/jianghu/jianghu_r5_test.dart
```

Expected: all PASS；真实门派数为6，敌对阵营结果不变。

- [ ] **Step 8: 提交**

```bash
git add \
  lib/data/defs/faction_def.dart \
  lib/data/game_repository.dart \
  test/data/defs/faction_def_test.dart \
  test/features/sect/faction_territory_validation_test.dart
git commit -m "feat: load complete faction definitions"
```

---

### Task 2: 声望页面显示中文门派名

**Files:**
- Modify: `lib/features/jianghu/application/jianghu_providers.dart`
- Modify: `lib/features/jianghu/presentation/reputation_panel_screen.dart:13-18,70-85,96-130`
- Modify: `test/features/jianghu/reputation_panel_screen_test.dart`

- [ ] **Step 1: 写中文名和未知 ID 回退的失败测试**

在 `reputation_panel_screen_test.dart` 导入 `GameRepository` 与 `../../support/test_data.dart`，加入：

```dart
setUpAll(loadTestGameRepository);
tearDownAll(GameRepository.resetForTest);
```

新增纯 provider 测试：

```dart
test('factionDisplayNameProvider uses config name and falls back to id', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  expect(container.read(factionDisplayNameProvider('shaolin')), '少林寺');
  expect(
    container.read(factionDisplayNameProvider('future_faction')),
    'future_faction',
  );
});
```

把现有 R4.2 改为真实渲染断言。ProviderScope 中继续 override `reputationsForCurrentPlayerProvider`，另加：

```dart
reputationTierProvider(50).overrideWithValue('zongShi'),
reputationTierProvider(-30).overrideWithValue('sanLiu'),
reputationTierProvider(-80).overrideWithValue('xueTu'),
```

断言找到“少林寺”“武当派”“邪教”，找不到文本 `shaolin`、`wudang`、`jiaoMen`，并找到3个 `ReputationTierChip`。

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
flutter test --no-pub test/features/jianghu/reputation_panel_screen_test.dart
```

Expected: FAIL，提示 `factionDisplayNameProvider` 不存在或仍显示 `shaolin`。

- [ ] **Step 3: 增加显示名 provider**

在 `jianghu_providers.dart` 增加 Flutter Riverpod import，并定义：

```dart
final factionDisplayNameProvider = Provider.family<String, String>((ref, id) {
  final repo = GameRepository.instanceOrNull;
  return repo?.factionDefs[id]?.name ?? id;
});

final reputationTierProvider = Provider.family<String, int>((ref, value) {
  return ref.watch(reputationServiceProvider)?.tierOf(value) ?? 'yiLiu';
});
```

该 provider 不访问 Isar，不异步，不缓存复制门派名称。

- [ ] **Step 4: 修改声望行输入**

删除 `final svc = ref.watch(reputationServiceProvider);`，空态条件只保留 `list.isEmpty`。在 `itemBuilder` 中解析名称和 tier：

```dart
final reputation = list[i];
final factionName = ref.watch(
  factionDisplayNameProvider(reputation.factionId),
);
final tier = ref.watch(reputationTierProvider(reputation.value));
return Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: _ReputationRow(
      reputation: reputation,
      factionName: factionName,
      tier: tier,
    ),
  ),
);
```

把 `_ReputationRow` 改为接收：

```dart
final Reputation reputation;
final String factionName;
final String tier;
```

名称位置渲染 `factionName`，不再渲染 `reputation.factionId`。

- [ ] **Step 5: 运行声望相关测试**

Run:

```bash
flutter test --no-pub \
  test/features/jianghu/reputation_panel_screen_test.dart \
  test/features/jianghu/reputation_service_test.dart \
  test/features/jianghu/jianghu_r5_test.dart
```

Expected: all PASS；中文名显示，未知 ID 回退。

- [ ] **Step 6: 提交**

```bash
git add \
  lib/features/jianghu/application/jianghu_providers.dart \
  lib/features/jianghu/presentation/reputation_panel_screen.dart \
  test/features/jianghu/reputation_panel_screen_test.dart
git commit -m "fix: render localized faction names in reputation panel"
```

---

### Task 3: 升级服务停止依赖存档镜像阈值

**Files:**
- Modify: `lib/core/domain/character.dart:40-45`
- Modify: `lib/features/cultivation/application/character_advancement_service.dart:65-105`
- Modify: `test/features/cultivation/application/character_advancement_service_test.dart`

- [ ] **Step 1: 写错误镜像仍按 RealmDef 升级的失败测试**

在 `character_advancement_service_test.dart` 增加：

```dart
test('stored threshold mirror never drives advancement', () {
  final character = _mkChar(
    tier: RealmTier.xueTu,
    layer: RealmLayer.qiMeng,
    experience: 40,
    experienceToNextLayer: 999999,
  );

  final result = CharacterAdvancementService.applyExperience(
    character,
    10,
    realmLookup: _lookup,
  );

  expect(result.layersGained, 1);
  expect(character.realmLayer, RealmLayer.ruMen);
  expect(
    character.experienceToNextLayer,
    _lookup(RealmTier.xueTu, RealmLayer.ruMen).experienceToNext,
  );
});

test('corrupt zero mirror does not stop advancement', () {
  final character = _mkChar(
    tier: RealmTier.xueTu,
    layer: RealmLayer.qiMeng,
    experience: 49,
    experienceToNextLayer: 0,
  );

  final result = CharacterAdvancementService.applyExperience(
    character,
    1,
    realmLookup: _lookup,
  );

  expect(result.layersGained, 1);
});
```

- [ ] **Step 2: 运行单测确认至少一项失败**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart
```

Expected: 至少“stored threshold mirror never drives advancement”在旧实现下暴露循环仍读取镜像字段。

- [ ] **Step 3: 改写升级循环**

在 `applyExperience` 中用局部 RealmDef 驱动：

```dart
var currentDef = beforeDef;
ch.experience += delta;
var layersGained = 0;

while (true) {
  final threshold = currentDef.experienceToNext;
  if (threshold <= 0) break;
  if (ch.experience < threshold) break;

  final next = nextLayer(ch.realmTier, ch.realmLayer);
  if (next == null) break;
  if (isLayerLocked != null && isLayerLocked(next.tier, next.layer)) {
    break;
  }

  ch.experience -= threshold;
  ch.realmTier = next.tier;
  ch.realmLayer = next.layer;
  currentDef = realmLookup(next.tier, next.layer);
  ch.internalForceMax = currentDef.internalForceMax;
  layersGained++;
}

ch.experienceToNextLayer = currentDef.experienceToNext;
```

删除循环中所有对 `ch.experienceToNextLayer` 的条件判断和扣减。`delta <= 0` 的既有 no-op 行为保持不变。

把 `Character.experienceToNextLayer` 注释改成：

```dart
/// Legacy Isar compatibility mirror of RealmDef.experienceToNext.
/// Production decisions must derive the threshold from realmTier + realmLayer.
/// Keep synchronized after creation/advancement until a future schema cleanup.
int experienceToNextLayer = 100;
```

- [ ] **Step 4: 运行成长全套测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/balance/inner_demon_r5_redline_test.dart
```

Expected: all PASS；Lv490 和心魔锁断言不变。

- [ ] **Step 5: 提交**

```bash
git add \
  lib/core/domain/character.dart \
  lib/features/cultivation/application/character_advancement_service.dart \
  test/features/cultivation/application/character_advancement_service_test.dart
git commit -m "refactor: derive advancement thresholds from realm definitions"
```

---

### Task 4: 迁移所有生产阈值消费者并加契约

**Files:**
- Create: `test/data/experience_threshold_production_usage_contract_test.dart`
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart:554-580,945-960`
- Modify: `lib/features/inner_demon/domain/inner_demon_panel.dart:35-65`
- Modify: `lib/features/main_menu/application/main_menu_status_summary_provider.dart:42-60,132-145`
- Modify: `lib/features/shop/application/shop_providers.dart:45-60`
- Modify: `lib/features/shop/application/shop_service.dart:30-40`
- Modify: `test/features/inner_demon/domain/inner_demon_panel_test.dart`
- Modify: `test/features/main_menu/main_menu_status_summary_test.dart`
- Modify: `test/features/shop/shop_providers_test.dart`
- Modify: `test/features/character_panel/presentation/character_panel_screen_test.dart`

- [ ] **Step 1: 写生产零读取契约并确认失败**

新建 `test/data/experience_threshold_production_usage_contract_test.dart`：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production consumers never read the legacy threshold mirror', () async {
    const allowed = <String>{
      'lib/core/domain/character.dart',
      'lib/features/cultivation/application/character_advancement_service.dart',
      'lib/features/debug/application/phase2_seed_service.dart',
      'lib/features/onboarding/application/master_builder.dart',
      'lib/features/recruitment/application/recruitment_service.dart',
      'lib/features/sect/presentation/sect_recruit_handler.dart',
    };

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path;
      if (allowed.contains(path)) continue;
      final source = await file.readAsString();
      expect(
        source,
        isNot(contains('experienceToNextLayer')),
        reason: '$path must derive the threshold from RealmDef',
      );
    }
  });
}
```

Run:

```bash
flutter test --no-pub test/data/experience_threshold_production_usage_contract_test.dart
```

Expected: FAIL，列出角色面板、心魔、主菜单和商店旧读取方。

- [ ] **Step 2: 改造心魔纯解析接口**

把 `resolveInnerDemonPanel` 增加必填参数：

```dart
required int experienceToNext,
```

并把判断改为：

```dart
final expFull =
    experienceToNext > 0 && character.experience >= experienceToNext;
```

角色面板调用时传：

```dart
final realmDef = GameRepository.instance.getRealm(
  character.realmTier,
  character.realmLayer,
);
final data = resolveInnerDemonPanel(
  character: character,
  experienceToNext: realmDef.experienceToNext,
  progress: progress,
  innerDemonDef: innerDemonDef,
);
```

所有 `inner_demon_panel_test.dart` 调用显式传入测试阈值，不再通过修改角色镜像控制状态。

- [ ] **Step 3: 改造主菜单突破判断**

把 helper 签名改为：

```dart
MainMenuStatusSummaryItem? _breakthroughItem(
  List<Character> characters,
  int Function(Character character) thresholdFor,
)
```

循环内使用：

```dart
final threshold = thresholdFor(character);
if (threshold <= 0 || character.experience < threshold) continue;
```

provider 调用：

```dart
final repository = GameRepository.instance;
final breakthroughItem = _breakthroughItem(
  characters,
  (character) => repository
      .getRealm(character.realmTier, character.realmLayer)
      .experienceToNext,
);
```

- [ ] **Step 4: 改造商店动态阈值**

`founderEtlProvider` 找到 founder 后返回：

```dart
final realm = GameRepository.instance.getRealm(c.realmTier, c.realmLayer);
return realm.experienceToNext;
```

把 `shop_service.dart` 文档中的来源改为 `RealmDef.experienceToNext`。函数参数名 `founderEtl` 保持不变，避免无意义 API 改名。

在 `shop_providers_test.dart` 增加一个 founder 镜像写成 `999999` 的用例，断言 provider 返回真实 `RealmDef.experienceToNext`。

- [ ] **Step 5: 移除角色面板镜像兜底**

把进度卡参数改为：

```dart
experienceToNext: realmDef?.experienceToNext ?? 1,
```

生产启动时 Repository 必然已加载；`1` 只保护不加载 Repository 的 isolated widget fixture，不从旧镜像恢复业务判断。

- [ ] **Step 6: 运行契约和所有消费者测试**

Run:

```bash
flutter test --no-pub \
  test/data/experience_threshold_production_usage_contract_test.dart \
  test/features/inner_demon/domain/inner_demon_panel_test.dart \
  test/features/main_menu/main_menu_status_summary_test.dart \
  test/features/shop/shop_providers_test.dart \
  test/features/shop/shop_screen_test.dart \
  test/features/character_panel/presentation/character_panel_screen_test.dart
```

Expected: all PASS；契约只允许兼容写入白名单。

- [ ] **Step 7: 提交**

```bash
git add \
  lib/features/character_panel/presentation/character_panel_screen.dart \
  lib/features/inner_demon/domain/inner_demon_panel.dart \
  lib/features/main_menu/application/main_menu_status_summary_provider.dart \
  lib/features/shop/application/shop_providers.dart \
  lib/features/shop/application/shop_service.dart \
  test/data/experience_threshold_production_usage_contract_test.dart \
  test/features/inner_demon/domain/inner_demon_panel_test.dart \
  test/features/main_menu/main_menu_status_summary_test.dart \
  test/features/shop/shop_providers_test.dart \
  test/features/character_panel/presentation/character_panel_screen_test.dart
git commit -m "refactor: use realm definitions for progression thresholds"
```

---

### Task 5: 把跨玩法结算结果移出 presentation

**Files:**
- Create: `lib/features/cultivation/domain/advancement_entry.dart`
- Create: `lib/features/equipment/domain/resonance_upgrade_notice.dart`
- Modify: `lib/features/cultivation/presentation/advancement_summary.dart`
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Modify: `test/features/cultivation/presentation/advancement_summary_test.dart`
- Modify: `test/features/mainline/presentation/stage_victory_dialog_test.dart`

- [ ] **Step 1: 新建共享结果类型**

`lib/features/cultivation/domain/advancement_entry.dart`：

```dart
import '../application/character_advancement_service.dart';

class AdvancementEntry {
  final int characterId;
  final String chName;
  final AdvancementResult result;

  const AdvancementEntry({
    required this.characterId,
    required this.chName,
    required this.result,
  });
}
```

`lib/features/equipment/domain/resonance_upgrade_notice.dart`：

```dart
import '../../../core/domain/enums.dart';

class ResonanceUpgradeNotice {
  final String equipmentName;
  final ResonanceStage newStage;

  const ResonanceUpgradeNotice({
    required this.equipmentName,
    required this.newStage,
  });

  @override
  String toString() =>
      'ResonanceUpgradeNotice($equipmentName → ${newStage.name})';
}
```

`characterId` 是本次必须加入的稳定关联键，公共事件不得继续按可能重复的角色名反查角色。

- [ ] **Step 2: 替换类型定义和 imports**

- 从 `advancement_summary.dart` 删除内联 `AdvancementEntry`，导入 domain 文件。
- 从 `stage_victory_dialog.dart` 删除内联 `ResonanceUpgradeNotice`，导入 equipment domain 文件。
- 主线、爬塔、debug 和测试改为导入新文件。
- 所有 `AdvancementEntry` 构造补 `characterId`；测试 fixture 使用固定非零 ID。

- [ ] **Step 3: 运行展示回归测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/presentation/advancement_summary_test.dart \
  test/features/mainline/presentation/stage_victory_dialog_test.dart \
  test/features/tower/presentation/tower_victory_content_test.dart
```

Expected: all PASS；本步零行为变化。

- [ ] **Step 4: 提交**

```bash
git add \
  lib/features/cultivation/domain/advancement_entry.dart \
  lib/features/equipment/domain/resonance_upgrade_notice.dart \
  lib/features/cultivation/presentation/advancement_summary.dart \
  lib/features/mainline/presentation/stage_victory_dialog.dart \
  lib/features/mainline/presentation/stage_entry_flow.dart \
  lib/features/tower/presentation/tower_entry_flow.dart \
  lib/features/debug/presentation/visual_route_host.dart \
  test/features/cultivation/presentation/advancement_summary_test.dart \
  test/features/mainline/presentation/stage_victory_dialog_test.dart
git commit -m "refactor: move shared settlement results out of presentation"
```

---

### Task 6: 建立公共成长与事件结算服务

**Files:**
- Create: `lib/features/battle/application/combat_progression_settlement_service.dart`
- Create: `test/features/battle/application/combat_progression_settlement_service_test.dart`

- [ ] **Step 1: 写纯经验结算失败测试**

`combat_progression_settlement_service_test.dart` 使用以下统一 fixture：

```dart
late Directory tempDir;
late GameRepository repository;

setUpAll(() async {
  await initializeTestIsarCore();
  repository = await loadTestGameRepository();
});

setUp(() async {
  tempDir = await Directory.systemTemp.createTemp(
    'wuxia_progression_settlement_',
  );
  await IsarSetup.init(directory: tempDir, inspector: false);
});

tearDown(() async {
  await IsarSetup.close();
  if (await tempDir.exists()) await tempDir.delete(recursive: true);
});

tearDownAll(GameRepository.resetForTest);

Character makeCharacter({required int id, required String name}) {
  final realm = repository.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
  return Character.create(
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 7, 13),
    internalForce: realm.internalForceMax,
    internalForceMax: realm.internalForceMax,
    experienceToNextLayer: realm.experienceToNext,
  )..id = id;
}
```

导入 `dart:io`、Isar、Character/Attributes/enums、GameRepository/IsarSetup、公共服务及 `test/support` 两个 helper。然后写入：

```dart
test('applyExperience rewards every character and keeps stable ids', () {
  final characters = [
    makeCharacter(id: 1, name: '同名'),
    makeCharacter(id: 2, name: '同名'),
    makeCharacter(id: 3, name: '三徒'),
  ];
  final service = CombatProgressionSettlementService(repository);

  final entries = service.applyExperience(
    characters: characters,
    experienceReward: 100,
    clearedStageIds: const {},
  );

  expect(entries.map((entry) => entry.characterId), [1, 2, 3]);
  expect(entries.every((entry) => entry.result.experienceGained == 100), isTrue);
});

test('zero reward returns no entries and mutates no experience', () {
  final character = makeCharacter(id: 1, name: '祖师');
  final before = character.experience;
  final service = CombatProgressionSettlementService(repository);

  final entries = service.applyExperience(
    characters: [character],
    experienceReward: 0,
    clearedStageIds: const {},
  );

  expect(entries, isEmpty);
  expect(character.experience, before);
});
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
flutter test --no-pub \
  test/features/battle/application/combat_progression_settlement_service_test.dart
```

Expected: FAIL，公共服务尚不存在。

- [ ] **Step 3: 实现经验结算与 Boss 上下文**

新文件先定义：

```dart
class BossVictoryEventContext {
  final String stageId;
  final String stageName;
  final String bossName;
  final List<Equipment> warbornEquipment;

  const BossVictoryEventContext({
    required this.stageId,
    required this.stageName,
    required this.bossName,
    required this.warbornEquipment,
  });
}
```

服务构造与经验方法：

```dart
class CombatProgressionSettlementService {
  final GameRepository repository;

  const CombatProgressionSettlementService(this.repository);

  List<AdvancementEntry> applyExperience({
    required List<Character> characters,
    required int experienceReward,
    required Set<String> clearedStageIds,
  }) {
    if (experienceReward <= 0) return const [];
    final innerDemonDef = repository.numbers.innerDemon;
    return [
      for (final character in characters)
        AdvancementEntry(
          characterId: character.id,
          chName: character.name,
          result: CharacterAdvancementService.applyExperience(
            character,
            experienceReward,
            realmLookup: repository.getRealm,
            isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
              nextTier: tier,
              nextLayer: layer,
              innerDemonDef: innerDemonDef,
              clearedStageIds: clearedStageIds,
            ),
          ),
        ),
    ];
  }
}
```

- [ ] **Step 4: 写公共事件与事务回滚失败测试**

使用 `initializeTestIsarCore`、临时目录和 `IsarSetup.init`。在同一个 `writeTxn` 中调用事件方法后主动抛错：

```dart
test('caller transaction rollback leaves no partial progression events', () async {
  final isar = IsarSetup.instance;
  final service = CombatProgressionSettlementService(repository);
  final founder = makeCharacter(id: 1, name: '祖师');
  final entries = service.applyExperience(
    characters: [founder],
    experienceReward: 100,
    clearedStageIds: const {},
  );

  await expectLater(
    isar.writeTxn(() async {
      await isar.characters.put(founder);
      await service.recordCommonEvents(
        isar: isar,
        characters: [founder],
        equipmentsByCharacter: const {},
        resonanceUpgradedEquipmentIds: const [],
        advancements: entries,
        founderId: founder.id,
        bossVictory: null,
      );
      throw StateError('rollback probe');
    }),
    throwsStateError,
  );

  expect(await isar.gameEvents.where().count(), 0);
  expect(await isar.characters.get(founder.id), isNull);
});
```

加入同名角色事件测试：

```dart
test('same-name characters are routed by characterId', () async {
  final isar = IsarSetup.instance;
  final first = makeCharacter(id: 1, name: '同名');
  final second = makeCharacter(id: 2, name: '同名');
  final service = CombatProgressionSettlementService(repository);
  final entries = service.applyExperience(
    characters: [first, second],
    experienceReward: repository
        .getRealm(RealmTier.xueTu, RealmLayer.qiMeng)
        .experienceToNext,
    clearedStageIds: const {},
  );

  await isar.writeTxn(() async {
    await isar.characters.putAll([first, second]);
    await service.recordCommonEvents(
      isar: isar,
      characters: [first, second],
      equipmentsByCharacter: const {},
      resonanceUpgradedEquipmentIds: const [],
      advancements: entries,
      founderId: null,
      bossVictory: null,
    );
  });

  final events = await isar.gameEvents.where().findAll();
  expect(events.map((event) => event.relatedCharacterId).toSet(), {1, 2});
});
```

- [ ] **Step 5: 实现公共事件方法**

在服务中增加：

```dart
Future<List<ResonanceUpgradeNotice>> recordCommonEvents({
  required Isar isar,
  required List<Character> characters,
  required Map<int, List<Equipment>> equipmentsByCharacter,
  required Iterable<int> resonanceUpgradedEquipmentIds,
  required List<AdvancementEntry> advancements,
  required int? founderId,
  required BossVictoryEventContext? bossVictory,
}) async {
  final events = GameEventService(isar);
  final tutorial = TutorialService(isar);
  final charactersById = {for (final character in characters) character.id: character};
  final equipmentById = {
    for (final equipment in equipmentsByCharacter.values.expand((list) => list))
      equipment.id: equipment,
  };
  final notices = <ResonanceUpgradeNotice>[];

  for (final equipmentId in resonanceUpgradedEquipmentIds) {
    final equipment = equipmentById[equipmentId];
    if (equipment == null) continue;
    final def = repository.getEquipment(equipment.defId);
    final stage = equipment.resonanceStage(repository.numbers);
    await events.recordResonanceUpgraded(
      characterId: equipment.ownerCharacterId ?? founderId ?? 0,
      equipmentId: equipment.id,
      equipmentName: def.name,
      newStage: stage.index + 1,
    );
    notices.add(
      ResonanceUpgradeNotice(equipmentName: def.name, newStage: stage),
    );
  }

  for (final entry in advancements.where((entry) => entry.result.didAdvance)) {
    final character = charactersById[entry.characterId];
    if (character == null) {
      throw StateError('advancement character ${entry.characterId} 不存在');
    }
    await events.recordRealmBreakthrough(
      character: character,
      result: entry.result,
    );
    if (founderId != null && character.id == founderId) {
      await tutorial.advanceForRealmBreakthrough(entry.result.tierAfter);
    }
  }

  if (founderId != null && bossVictory != null) {
    await events.recordBossDefeated(
      characterId: founderId,
      stageId: bossVictory.stageId,
      stageName: bossVictory.stageName,
      bossName: bossVictory.bossName,
      warbornEquipment: bossVictory.warbornEquipment,
    );
  }

  return List.unmodifiable(notices);
}
```

该方法不得包含 `writeTxn`。

- [ ] **Step 6: 运行公共服务测试**

Run:

```bash
flutter test --no-pub \
  test/features/battle/application/combat_progression_settlement_service_test.dart
```

Expected: 经验、同名角色、心魔锁、公共事件和回滚用例全部 PASS。

- [ ] **Step 7: 提交**

```bash
git add \
  lib/features/battle/application/combat_progression_settlement_service.dart \
  test/features/battle/application/combat_progression_settlement_service_test.dart
git commit -m "feat: add shared combat progression settlement"
```

---

### Task 7: 主线和爬塔接入公共服务

**Files:**
- Create: `test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:840-1000`
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart:495-595`
- Modify: `test/features/mainline/presentation/stage_entry_flow_test.dart`
- Modify: `test/features/tower/presentation/tower_entry_flow_test.dart`

- [ ] **Step 1: 写去重接线契约并确认失败**

新建契约测试：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mainline and tower delegate common progression settlement', () async {
    for (final path in [
      'lib/features/mainline/presentation/stage_entry_flow.dart',
      'lib/features/tower/presentation/tower_entry_flow.dart',
    ]) {
      final source = await File(path).readAsString();
      expect(source, contains('CombatProgressionSettlementService'));
      expect(source, isNot(contains('CharacterAdvancementService.applyExperience')));
      expect(source, isNot(contains('recordRealmBreakthrough')));
      expect(source, isNot(contains('recordResonanceUpgraded')));
    }
  });

  test('shared settlement never owns a transaction', () async {
    final source = await File(
      'lib/features/battle/application/combat_progression_settlement_service.dart',
    ).readAsString();
    expect(source, isNot(contains('writeTxn')));
  });
}
```

Run:

```bash
flutter test --no-pub \
  test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart
```

Expected: FAIL，两种流程仍含直接调用。

- [ ] **Step 2: 主线接入经验方法**

读取 `MainlineProgress` 后创建：

```dart
final settlement = CombatProgressionSettlementService(
  GameRepository.instance,
);
final advancements = settlement.applyExperience(
  characters: characters,
  experienceReward: stage.baseExpReward,
  clearedStageIds: clearedSet,
);
```

删除原 `CharacterAdvancementService.applyExperience` 循环。主线不把 `isFirstClearStage` 传入经验条件，因此重打行为保持不变。

- [ ] **Step 3: 主线事务内接入公共事件**

保留主线专属 `recordEquipmentObtained` 循环。其后调用：

```dart
final resonanceUpgrades = await settlement.recordCommonEvents(
  isar: isar,
  characters: characters,
  equipmentsByCharacter: equipsByCh,
  resonanceUpgradedEquipmentIds: result.resonanceUpgradedEquipmentIds,
  advancements: advancements,
  founderId: founderId,
  bossVictory: stage.isBossStage && isFirstClearStage
      ? BossVictoryEventContext(
          stageId: stage.id,
          stageName: stage.name,
          bossName: stage.enemyTeam.isNotEmpty
              ? stage.enemyTeam.last.name
              : stage.name,
          warbornEquipment: founderId == null
              ? const []
              : equipsByCh[founderId] ?? const [],
        )
      : null,
);
```

因为 `resonanceUpgrades` 在事务外还要返回，先声明：

```dart
var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
```

再在事务内赋值。删除旧共鸣、突破、教程和 Boss 首胜循环。

- [ ] **Step 4: 爬塔接入经验方法**

```dart
final settlement = CombatProgressionSettlementService(
  GameRepository.instance,
);
final advancements = settlement.applyExperience(
  characters: characters,
  experienceReward: isFirstClear ? floor.baseExpReward : 0,
  clearedStageIds: clearedSet,
);
```

`isFirstClear` 必须只在调用参数处决定奖励，不进入公共服务。

- [ ] **Step 5: 爬塔事务内接入公共事件**

```dart
var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
await isar.writeTxn(() async {
  await isar.characters.putAll(characters);
  for (final list in techsByCh.values) {
    if (list.isNotEmpty) await isar.techniques.putAll(list);
  }
  for (final list in equipsByCh.values) {
    if (list.isNotEmpty) await isar.equipments.putAll(list);
  }

  resonanceUpgrades = await settlement.recordCommonEvents(
    isar: isar,
    characters: characters,
    equipmentsByCharacter: equipsByCh,
    resonanceUpgradedEquipmentIds:
        battleResult.resonanceUpgradedEquipmentIds,
    advancements: advancements,
    founderId: founderId,
    bossVictory: floor.isBoss && isFirstClear
        ? BossVictoryEventContext(
            stageId: 'tower_floor_${floor.floorIndex}',
            stageName: UiStrings.towerFloorLabel(floor.floorIndex),
            bossName: floor.enemyTeam.isNotEmpty
                ? floor.enemyTeam.last.name
                : UiStrings.towerFloorLabel(floor.floorIndex),
            warbornEquipment: founderId == null
                ? const []
                : equipsByCh[founderId] ?? const [],
          )
        : null,
  );
});
```

爬塔 `_persistDrops`、装备获得事件和排行榜同步保持原位。

- [ ] **Step 6: 增加玩法差异回归断言**

在现有 flow 测试中加入四个带真 Isar 角色读取的测试：

- 主线重复胜利仍获得 `baseExpReward`。
- 爬塔 `isFirstClear: false` 时经验不变。
- 爬塔 `isFirstClear: true` 时三名 active 角色均获得经验。
- 两种玩法遇到心魔锁时均保留溢出经验。

测试应读取结算后 Character，而不是只断言流程没有抛错。

- [ ] **Step 7: 运行接线和玩法回归测试**

Run:

```bash
flutter test --no-pub \
  test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart \
  test/features/battle/application/combat_progression_settlement_service_test.dart \
  test/features/mainline/presentation/stage_entry_flow_test.dart \
  test/features/tower/presentation/tower_entry_flow_test.dart \
  test/data/scroll_firstclear_gate_test.dart \
  test/data/scroll_drop_test.dart \
  test/features/event/application/game_event_service_test.dart
```

Expected: all PASS；接线契约证明两种玩法已无直接公共结算实现。

- [ ] **Step 8: 提交**

```bash
git add \
  lib/features/mainline/presentation/stage_entry_flow.dart \
  lib/features/tower/presentation/tower_entry_flow.dart \
  test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart \
  test/features/mainline/presentation/stage_entry_flow_test.dart \
  test/features/tower/presentation/tower_entry_flow_test.dart
git commit -m "refactor: share mainline and tower progression settlement"
```

---

### Task 8: 全量验证、文档收口与推送前检查

**Files:**
- Modify: `PROGRESS.md`
- Modify only if contract wording changed: `CLAUDE.md`

- [x] **Step 1: 格式化修改文件**

Run:

```bash
dart format \
  lib/data/defs/faction_def.dart \
  lib/data/game_repository.dart \
  lib/features/jianghu/application/jianghu_providers.dart \
  lib/features/jianghu/presentation/reputation_panel_screen.dart \
  lib/core/domain/character.dart \
  lib/features/cultivation/application/character_advancement_service.dart \
  lib/features/character_panel/presentation/character_panel_screen.dart \
  lib/features/inner_demon/domain/inner_demon_panel.dart \
  lib/features/main_menu/application/main_menu_status_summary_provider.dart \
  lib/features/shop/application/shop_providers.dart \
  lib/features/shop/application/shop_service.dart \
  lib/features/cultivation/domain/advancement_entry.dart \
  lib/features/equipment/domain/resonance_upgrade_notice.dart \
  lib/features/cultivation/presentation/advancement_summary.dart \
  lib/features/mainline/presentation/stage_victory_dialog.dart \
  lib/features/battle/application/combat_progression_settlement_service.dart \
  lib/features/mainline/presentation/stage_entry_flow.dart \
  lib/features/tower/presentation/tower_entry_flow.dart \
  test/data/defs/faction_def_test.dart \
  test/data/experience_threshold_production_usage_contract_test.dart \
  test/features/battle/application/combat_progression_settlement_service_test.dart \
  test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart
```

Expected: formatter completes without error。

- [x] **Step 2: 静态检查**

Run:

```bash
flutter analyze --no-pub
```

Expected: `No issues found!`

- [x] **Step 3: 运行本批定向测试**

Run:

```bash
flutter test --no-pub \
  test/data/defs/faction_def_test.dart \
  test/features/sect/faction_territory_validation_test.dart \
  test/features/jianghu \
  test/data/experience_threshold_production_usage_contract_test.dart \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/inner_demon/domain/inner_demon_panel_test.dart \
  test/features/main_menu/main_menu_status_summary_test.dart \
  test/features/shop \
  test/features/battle/application/combat_progression_settlement_service_test.dart \
  test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart \
  test/features/mainline/presentation/stage_entry_flow_test.dart \
  test/features/tower/presentation/tower_entry_flow_test.dart
```

Expected: all PASS。

- [x] **Step 4: 全量测试**

Run:

```bash
flutter test --no-pub
```

Expected: 0 failed；记录终端真实 pass 数，不预填固定数字。

- [x] **Step 5: macOS debug 构建**

Run:

```bash
flutter build macos --debug
```

Expected: build succeeds，产物位于 `build/macos/Build/Products/Debug/`。

- [x] **Step 6: 更新进度文档**

在 `PROGRESS.md` 顶部新增本批条目，只写真实执行结果：

- 门派显示名正式接线；
- 经验阈值的生产单一真相源；
- 主线/爬塔公共成长结算；
- analyze、定向测试、全量测试和 build 的真实结果；
- 明确 `experienceToNextLayer` 仍是兼容镜像，未做 schema migration。

若 `CLAUDE.md` 已明确 Lv1～Lv490 与存档兼容规则且无冲突，不修改它。

- [x] **Step 7: 文档与工作区检查**

Run:

```bash
git diff --check
git status -sb
git log --oneline -8
```

Expected: 无行尾错误；仅 `PROGRESS.md` 等本步文档待提交；提交历史为本计划的小切片。

- [x] **Step 8: 提交验证证据**

```bash
git add PROGRESS.md CLAUDE.md
git commit -m "docs: record progression settlement convergence"
```

若 `CLAUDE.md` 未变化，不把它传给 `git add`。

- [ ] **Step 9: 推送前最终确认**

Run:

```bash
git status -sb
git rev-list --left-right --count origin/main...main
```

Expected: 工作区干净；`main` 只领先本批已审阅提交。推送属于外部可见操作，执行时按用户当前授权决定，不在计划编写阶段自动推送。

---

## 自检清单

- 门派名称不在 Dart 重复硬编码。
- `factionAlignments` 继续兼容既有敌对阵营逻辑。
- 生产阈值读取全部来自 `RealmDef`。
- Isar schema 和 save version 均未改变。
- 公共服务不持有 Riverpod `Ref`，不开事务。
- `AdvancementEntry` 通过 `characterId` 关联角色，不再按名称反查。
- 主线重打经验、爬塔首通经验规则均被测试钉死。
- 掉落、秘籍、排行榜和图鉴仍留在玩法 Adapter。
- 全量测试数字只记录实际结果。
