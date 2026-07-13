# Progression Attribute Playtest Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可复现的 Lv1～Lv490、七类经验入口、四属性职责和玩家成长路径体检，只修硬证据证明的 P0/P1，不在本批调整数值。

**Architecture:** 所有诊断代码留在 `test/`，通过共享合法玩家夹具直接调用真实 `GameRepository`、生产服务与战斗策略；硬契约进入常规全量测试，软指标只写绑定 commit/seed 的 Markdown 与 CSV。现有主线节奏、心魔和塔 Boss 诊断继续作为事实源，新汇总层只复用或抽取其测试支持代码，不复制生产公式。

**Tech Stack:** Flutter Desktop、Dart、flutter_test、Isar Community、YAML、固定种子战斗模拟、Markdown/CSV

---

## 当前恢复点

- 状态：Task 3 已完成；七类经验入口委托、旧等级账零读写与主线/爬塔奖励策略差异已由契约锁定，下一步执行 Task 4。
- 实现分支：`codex/progression-attribute-playtest-implementation`。
- 无修改基线 commit：`0b5d4b234f9630b43dfda9ce9b8ed1d81e3e2bbf`。
- 基线验证：重新生成 Git 忽略的 `g.dart` 后，`flutter analyze --no-pub` 为 `No issues found`；计划指定基线共 41 tests PASS；固定种子心魔观察值为 05=`17/20`、06=`17/20`、07=`13/20`；塔诊断 PASS。以上观察值均绑定 commit `0b5d4b234f9630b43dfda9ce9b8ed1d81e3e2bbf`。
- Task 1 TDD 红灯证据：`flutter test --no-pub test/support/progression_playtest_fixture_test.dart` 退出码 1，报告缺少 `progression_playtest_fixture.dart`，且 `ProgressionPlaytestFixture`、`GrowthStage` 未定义。
- Task 1 质量加固绿灯：同一目标测试 4 tests PASS；`flutter analyze --no-pub` 仍为 `No issues found`；以上结果绑定 commit `29f48d42324a8db8822c050696ef6c3931541f96`。
- Task 2 绿灯：新全路径契约单独运行 4 tests PASS；与 `character_advancement_service_test.dart`、`realm_progress_display_test.dart` 联合运行 32 tests PASS；`flutter analyze --no-pub` 为 `No issues found`；未触发 Task 7，且未修改 `lib/` / `data/`。以上结果绑定 commit `b9c677b5ca1085976315eab11dcd0ef86e4813ba`。
- Task 2 质量加固：心魔锁现在精确守住层位、经验留账和镜像刷新；真实 `RealmDef` 中学徒·精通门槛为 170，学徒·圆熟门槛为 230，锁定积累 340 后解锁 `+1` 的确定余量为 171，因此精确只升 1 层；终境守住 tier/layer、全量经验与终境镜像；逐层 tier/layer/mirror 断言均带 `absoluteLevel` 定位理由。单文件 4 tests PASS，三文件联合 32 tests PASS，`flutter analyze --no-pub` 为 `No issues found`；以上结果绑定 commit `1d6aee30bb9b8c97960adea9c357a9f098fc9872`。
- Task 3 绿灯：两份经验入口契约与七份真实行为测试联合运行 133 tests PASS；旧 `level/levelExp` 在离线和经验丹路径保持不变，闭关与溢出普通挂机经验合并后只委托一次成长服务；`flutter analyze --no-pub` 为 `No issues found`，未触发 Task 7，且未修改 `lib/` / `data/`。以上结果基于 commit `3499d8d730eae6b650d3e8ef46ca2ff5ab15ee22` 及本 Task 3 工作树改动；交付 commit 将在提交后同步为真实值。
- 设计规格：`docs/superpowers/specs/2026-07-13-progression-attribute-playtest-design.md`。
- 下一步：执行 Task 4，建立四属性方向性与职责隔离诊断。
- 强制边界：本计划不改 `numbers.yaml`、schema、save version、属性倍率或发布流程。

---

## 文件结构

### 新建

- `test/support/progression_playtest_fixture.dart`：前中后期合法角色、单属性变体和确定性元数据。
- `test/support/progression_battle_probe.dart`：从既有首通诊断抽出的测试专用玩家构造与战斗采样 API。
- `test/features/cultivation/application/progression_full_path_contract_test.dart`：49 层、490 级、心魔锁和终境封顶硬契约。
- `test/features/cultivation/application/experience_source_consistency_test.dart`：七类经验入口委托与玩法差异契约。
- `test/tools/attribute_role_sensitivity_diagnostic_test.dart`：四属性前中后期方向性及职责隔离诊断。
- `test/tools/progression_playtest_diagnostic_test.dart`：主线三档成长路径软指标采集与统一输出。
- `docs/audit/progression_attribute_playtest_2026-07-13.md`：绑定 commit、环境、种子和结果的人工结论。
- `test/tools/output/progression_attribute_playtest_2026-07-13.csv`：本轮原始场景数据。

### 修改

- `test/tools/readable_first_clear_tempo_diagnostic_test.dart`：改用共享 battle probe，行为与现有断言不变。
- `test/features/cultivation/application/single_experience_account_contract_test.dart`：扩大旧等级账零写入守卫到全部经验来源。
- `PROGRESS.md`：仅在最终门禁完成后记录真实结果。
- 本计划文件：每个任务提交时更新恢复点。

### 条件修改

- `lib/**`：只有新增硬契约实际失败并被归类为 P0/P1 时才允许修改；先暂停执行，把失败测试、根因和精确修法追加为本计划的新任务，再按 TDD 实施。

---

### Task 1: 冻结基线并建立合法玩家夹具

**Files:**
- Create: `test/support/progression_playtest_fixture.dart`
- Test: `test/support/progression_playtest_fixture_test.dart`
- Modify: `docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md`

- [x] **Step 1: 记录无修改基线**

Run:

```bash
git status -sb
flutter analyze --no-pub
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart
```

Expected: 工作区干净，analyze 为 0，所有指定测试 PASS。把真实通过数和心魔观察值连同 `git rev-parse HEAD` 写入本计划“当前恢复点”，观察值必须附 commit。

- [x] **Step 2: 写夹具失败测试**

Create `test/support/progression_playtest_fixture_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import 'progression_playtest_fixture.dart';
import 'test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('early middle late profiles use real realm definitions', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final early = fixture.createCharacter(GrowthStage.early, id: 101);
    final middle = fixture.createCharacter(GrowthStage.middle, id: 102);
    final late = fixture.createCharacter(GrowthStage.late, id: 103);

    expect(repository.getRealm(early.realmTier, early.realmLayer).absoluteLevel, 4);
    expect(repository.getRealm(middle.realmTier, middle.realmLayer).absoluteLevel, 25);
    expect(repository.getRealm(late.realmTier, late.realmLayer).absoluteLevel, 46);
    expect([early.id, middle.id, late.id], [101, 102, 103]);
  });

  test('attribute variant changes exactly one field and stays legal', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final base = fixture.createCharacter(GrowthStage.middle, id: 201);
    final agile = fixture.createCharacter(
      GrowthStage.middle,
      id: 202,
      raisedAttribute: AttributeKey.agility,
    );

    expect(base.attributes.total, 20);
    expect(agile.attributes.total, 23);
    expect(agile.attributes.constitution, base.attributes.constitution);
    expect(agile.attributes.enlightenment, base.attributes.enlightenment);
    expect(agile.attributes.agility, 8);
    expect(agile.attributes.fortune, base.attributes.fortune);
  });

  test('fixture mirrors the current RealmDef threshold only for compatibility', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final character = fixture.createCharacter(GrowthStage.late, id: 301);
    final realm = repository.getRealm(character.realmTier, character.realmLayer);

    expect(character.experienceToNextLayer, realm.experienceToNext);
    expect(character.internalForceMax, realm.internalForceMax);
  });
}
```

- [x] **Step 3: 运行测试确认失败**

Run:

```bash
flutter test --no-pub test/support/progression_playtest_fixture_test.dart
```

Expected: FAIL，`progression_playtest_fixture.dart`、`ProgressionPlaytestFixture` 和 `GrowthStage` 尚不存在。

- [x] **Step 4: 实现最小夹具**

Create `test/support/progression_playtest_fixture.dart`:

```dart
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

enum GrowthStage { early, middle, late }

final class ProgressionPlaytestFixture {
  const ProgressionPlaytestFixture(this.repository);

  final GameRepository repository;

  Character createCharacter(
    GrowthStage stage, {
    required int id,
    AttributeKey? raisedAttribute,
  }) {
    final (tier, layer) = switch (stage) {
      GrowthStage.early => (RealmTier.xueTu, RealmLayer.jingTong),
      GrowthStage.middle => (RealmTier.yiLiu, RealmLayer.jingTong),
      GrowthStage.late => (RealmTier.wuSheng, RealmLayer.jingTong),
    };
    final realm = repository.getRealm(tier, layer);
    final attributes = Attributes()
      ..constitution = raisedAttribute == AttributeKey.constitution ? 8 : 5
      ..enlightenment = raisedAttribute == AttributeKey.enlightenment ? 8 : 5
      ..agility = raisedAttribute == AttributeKey.agility ? 8 : 5
      ..fortune = raisedAttribute == AttributeKey.fortune ? 8 : 5;
    final character = Character.create(
      name: '体检角色-${stage.name}-$id',
      realmTier: tier,
      realmLayer: layer,
      attributes: attributes,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 7, 13),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: true,
      isActive: true,
      school: TechniqueSchool.gangMeng,
    )..id = id;
    validateCharacter(character);
    return character;
  }

  void validateCharacter(Character character) {
    final realm = repository.getRealm(character.realmTier, character.realmLayer);
    if (character.attributes.total < 16 || character.attributes.total > 24) {
      throw StateError('属性总和 ${character.attributes.total} 不在 [16, 24]');
    }
    if (character.internalForceMax != realm.internalForceMax) {
      throw StateError('角色内力上限未使用真实 RealmDef');
    }
  }
}
```

- [x] **Step 5: 格式化并运行夹具测试**

Run:

```bash
dart format test/support/progression_playtest_fixture.dart test/support/progression_playtest_fixture_test.dart
flutter test --no-pub test/support/progression_playtest_fixture_test.dart
```

Expected: 3 tests PASS。

- [x] **Step 6: 提交**

```bash
git add \
  test/support/progression_playtest_fixture.dart \
  test/support/progression_playtest_fixture_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: add progression playtest fixtures"
```

---

### Task 2: 建立 49 层与 Lv490 全路径硬契约

**Files:**
- Create: `test/features/cultivation/application/progression_full_path_contract_test.dart`
- Use: `test/support/progression_playtest_fixture.dart`

- [x] **Step 1: 写全路径契约**

Create `test/features/cultivation/application/progression_full_path_contract_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';

import '../../../support/progression_playtest_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
  });

  test('49 real layers expose exactly Lv1 through Lv490', () {
    final realms = [...repository.realms]
      ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
    expect(realms.length, 49);

    final levels = <int>[];
    for (final realm in realms) {
      for (var segment = 0; segment < 10; segment++) {
        final experience = segment == 9
            ? realm.experienceToNext - 1
            : (realm.experienceToNext * segment + 9) ~/ 10;
        levels.add(
          RealmProgressDisplay.fromSnapshot(
            absoluteRealmLevel: realm.absoluteLevel,
            experience: experience,
            experienceToNext: realm.experienceToNext,
            hasNextRealmLayer: realm.absoluteLevel < 49,
          ).level,
        );
      }
    }

    expect(levels, List<int>.generate(490, (index) => index + 1));
  });

  test('every real layer advances to the next RealmDef and refreshes its mirror', () {
    final realms = [...repository.realms]
      ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
    for (var index = 0; index < realms.length - 1; index++) {
      final current = realms[index];
      final next = realms[index + 1];
      final character = fixture.createCharacter(GrowthStage.early, id: 1000 + index)
        ..realmTier = current.tier
        ..realmLayer = current.layer
        ..internalForceMax = current.internalForceMax
        ..experienceToNextLayer = 999999;

      final result = CharacterAdvancementService.applyExperience(
        character,
        current.experienceToNext,
        realmLookup: repository.getRealm,
      );

      expect(result.layersGained, 1, reason: 'absolute=${current.absoluteLevel}');
      expect(character.realmTier, next.tier);
      expect(character.realmLayer, next.layer);
      expect(character.experienceToNextLayer, next.experienceToNext);
    }
  });

  test('locked overflow remains at level ten then advances after unlock', () {
    final character = fixture.createCharacter(GrowthStage.early, id: 2001);
    final current = repository.getRealm(character.realmTier, character.realmLayer);

    final locked = CharacterAdvancementService.applyExperience(
      character,
      current.experienceToNext * 2,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => true,
    );
    expect(locked.layersGained, 0);
    expect(locked.progressChange.after.level, current.absoluteLevel * 10);
    expect(locked.progressChange.after.isWaitingForBreakthrough, isTrue);

    final unlocked = CharacterAdvancementService.applyExperience(
      character,
      1,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => false,
    );
    expect(unlocked.layersGained, greaterThan(0));
  });

  test('terminal realm reaches Lv490 and never creates layer 50', () {
    final terminal = repository.getRealm(
      RealmTier.wuSheng,
      RealmLayer.dengFeng,
    );
    final character = fixture.createCharacter(GrowthStage.late, id: 3001)
      ..realmTier = terminal.tier
      ..realmLayer = terminal.layer
      ..experience = 0
      ..experienceToNextLayer = 0
      ..internalForceMax = terminal.internalForceMax;

    final result = CharacterAdvancementService.applyExperience(
      character,
      terminal.experienceToNext * 2,
      realmLookup: repository.getRealm,
    );

    expect(result.layersGained, 0);
    expect(result.progressChange.after.level, 490);
    expect(result.progressChange.after.didReachPeak, isTrue);
    expect(CharacterAdvancementService.nextLayer(
      character.realmTier,
      character.realmLayer,
    ), isNull);
  });
}
```

- [x] **Step 2: 运行契约测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/progression_full_path_contract_test.dart
```

Expected: 若 PASS，确认当前生产逻辑满足完整契约；若 FAIL，保留失败输出并进入 Task 7 硬门禁，不立即改生产代码。

- [x] **Step 3: 联合既有境界测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart
```

Expected: all PASS。

- [x] **Step 4: 提交硬契约**

```bash
git add \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: cover the full Lv490 progression path"
```

---

### Task 3: 锁定七类经验入口与玩法差异

**Files:**
- Create: `test/features/cultivation/application/experience_source_consistency_test.dart`
- Modify: `test/features/cultivation/application/single_experience_account_contract_test.dart`
- Verify existing behavior tests listed below

- [x] **Step 1: 写入口委托与策略契约**

Create `test/features/cultivation/application/experience_source_consistency_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all seven experience entrances delegate to the single experience account', () async {
    const combatPaths = {
      'mainline': 'lib/features/mainline/presentation/stage_entry_flow.dart',
      'tower': 'lib/features/tower/presentation/tower_entry_flow.dart',
    };
    for (final entry in combatPaths.entries) {
      final source = await File(entry.value).readAsString();
      expect(source, contains('CombatProgressionSettlementService'));
      expect(source, contains('settlement.applyExperience'));
      expect(source, isNot(contains('.levelExp =')), reason: entry.key);
      expect(source, isNot(contains('LevelService')), reason: entry.key);
    }

    const directPaths = {
      'retreat': 'lib/features/seclusion/application/seclusion_service.dart',
      'offline': 'lib/features/seclusion/application/offline_passive_service.dart',
      'item': 'lib/features/inventory/application/item_use_service.dart',
    };
    for (final entry in directPaths.entries) {
      final source = await File(entry.value).readAsString();
      expect(
        source,
        contains('CharacterAdvancementService.applyExperience'),
        reason: '${entry.key} 未委托唯一成长服务',
      );
      expect(source, isNot(contains('.levelExp =')), reason: entry.key);
      expect(source, isNot(contains('LevelService')), reason: entry.key);
    }
  });

  test('mainline replay and tower first-clear policies remain intentionally different', () async {
    final mainline = await File(
      'lib/features/mainline/presentation/stage_entry_flow.dart',
    ).readAsString();
    final tower = await File(
      'lib/features/tower/presentation/tower_entry_flow.dart',
    ).readAsString();

    expect(mainline, contains('experienceReward: stage.baseExpReward'));
    expect(
      tower,
      contains('experienceReward: isFirstClear ? floor.baseExpReward : 0'),
    );
  });

  test('retreat and passive sources combine before one advancement call', () async {
    final source = await File(
      'lib/features/seclusion/application/seclusion_service.dart',
    ).readAsString();
    expect(
      source,
      contains('outputs.experiencePoints + settlement.passive.experience'),
    );
  });
}
```

- [x] **Step 2: 扩大旧等级账守卫**

In `test/features/cultivation/application/single_experience_account_contract_test.dart`, replace both path loops with one list that also covers the shared settlement service:

```dart
const productionExperiencePaths = [
  'lib/features/mainline/presentation/stage_entry_flow.dart',
  'lib/features/tower/presentation/tower_entry_flow.dart',
  'lib/features/battle/application/combat_progression_settlement_service.dart',
  'lib/features/seclusion/application/seclusion_service.dart',
  'lib/features/seclusion/application/offline_passive_service.dart',
  'lib/features/inventory/application/item_use_service.dart',
];

test('all production experience paths ignore the legacy level account', () async {
  for (final path in productionExperiencePaths) {
    final source = await File(path).readAsString();
    expect(source, isNot(contains('LevelService')), reason: path);
    expect(source, isNot(contains('LevelConfig')), reason: path);
    expect(source, isNot(contains('.levelExp =')), reason: path);
    expect(source, isNot(contains('numbers.level')), reason: path);
  }
});
```

- [x] **Step 3: 运行新契约与真实持久化入口测试**

Run:

```bash
flutter test --no-pub \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/features/battle/application/combat_progression_settlement_service_test.dart \
  test/features/seclusion/application/offline_passive_settle_test.dart \
  test/features/seclusion/application/seclusion_service_test.dart \
  test/features/inventory/item_use_service_test.dart \
  test/features/mainline/presentation/stage_victory_dialog_test.dart \
  test/features/tower/presentation/tower_victory_content_test.dart \
  test/features/seclusion/presentation/retreat_result_screen_test.dart
```

Expected: all PASS；离线和经验丹行为测试继续证明旧 `level/levelExp` 不变，闭关服务测试继续证明合并经验只结算一次。

- [x] **Step 4: 提交**

```bash
git add \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: lock progression experience source policies"
```

---

### Task 4: 建立四属性方向性与职责隔离诊断

**Files:**
- Create: `test/tools/attribute_role_sensitivity_diagnostic_test.dart`
- Use: `test/support/progression_playtest_fixture.dart`

- [ ] **Step 1: 写属性诊断**

Create `test/tools/attribute_role_sensitivity_diagnostic_test.dart`:

```dart
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import '../support/progression_playtest_fixture.dart';
import '../support/test_data.dart';

void recordAttributeObservation(
  GrowthStage stage,
  String metric,
  num baseline,
  num raised,
) {
  print([
    'attribute_role',
    stage.name,
    metric,
    baseline,
    raised,
  ].join(','));
}

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;
  late AttributeEffectPolicy policy;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
    policy = AttributeEffectPolicy(repository.numbers.attributeEffects);
  });

  for (final stage in GrowthStage.values) {
    test('${stage.name}: constitution shortens new heavy injury duration', () {
      final base = fixture.createCharacter(stage, id: 100 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 200 + stage.index,
        raisedAttribute: AttributeKey.constitution,
      );
      final hoursBase = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: base.attributes.constitution,
      );
      final hoursRaised = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: raised.attributes.constitution,
      );
      recordAttributeObservation(
        stage,
        'constitution_heavy_injury_hours',
        hoursBase,
        hoursRaised,
      );
      expect(hoursRaised, lessThan(hoursBase));
    });

    test('${stage.name}: enlightenment improves all three growth entrances', () {
      final base = fixture.createCharacter(stage, id: 300 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 400 + stage.index,
        raisedAttribute: AttributeKey.enlightenment,
      );
      final usageBase = policy.effectiveUsageCount(
        rawUses: 100,
        enlightenment: base.attributes.enlightenment,
      );
      final usageRaised = policy.effectiveUsageCount(
        rawUses: 100,
        enlightenment: raised.attributes.enlightenment,
      );
      final progressBase = policy.effectiveProgressDelta(
        rawBefore: 20,
        rawDelta: 50,
        enlightenment: base.attributes.enlightenment,
      );
      final progressRaised = policy.effectiveProgressDelta(
        rawBefore: 20,
        rawDelta: 50,
        enlightenment: raised.attributes.enlightenment,
      );
      final encounterBase = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.enlightenment,
        attributes: base.attributes,
      );
      final encounterRaised = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.enlightenment,
        attributes: raised.attributes,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_effective_usage',
        usageBase,
        usageRaised,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_progress_delta',
        progressBase,
        progressRaised,
      );
      recordAttributeObservation(
        stage,
        'enlightenment_encounter_probability',
        encounterBase,
        encounterRaised,
      );
      expect(usageRaised, greaterThan(usageBase));
      expect(progressRaised, greaterThan(progressBase));
      expect(encounterRaised, greaterThan(encounterBase));
    });

    test('${stage.name}: agility raises speed/evasion but never critical rate', () {
      final base = fixture.createCharacter(stage, id: 500 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 600 + stage.index,
        raisedAttribute: AttributeKey.agility,
      );
      final tier = RealmUtils.techniqueTierCapOf(base.realmTier);
      final def = repository.techniqueDefs.values.firstWhere(
        (value) => value.tier == tier && value.school == TechniqueSchool.gangMeng,
      );
      Technique techniqueFor(int id) => Technique.create(
        defId: def.id,
        ownerCharacterId: id,
        tier: def.tier,
        school: def.school,
        role: TechniqueRole.main,
        learnedAt: DateTime.utc(2026, 7, 13),
        cultivationLayer: CultivationLayer.zhongCheng,
      );

      final speedBase = CharacterDerivedStats.speed(
        base,
        const [],
        techniqueFor(base.id),
        repository.numbers,
      );
      final speedRaised = CharacterDerivedStats.speed(
        raised,
        const [],
        techniqueFor(raised.id),
        repository.numbers,
      );
      final evasionBase =
          CharacterDerivedStats.evasionRate(base, repository.numbers);
      final evasionRaised =
          CharacterDerivedStats.evasionRate(raised, repository.numbers);
      final criticalBase =
          CharacterDerivedStats.criticalRate(base, repository.numbers);
      final criticalRaised =
          CharacterDerivedStats.criticalRate(raised, repository.numbers);
      recordAttributeObservation(
        stage,
        'agility_speed',
        speedBase,
        speedRaised,
      );
      recordAttributeObservation(
        stage,
        'agility_evasion_rate',
        evasionBase,
        evasionRaised,
      );
      recordAttributeObservation(
        stage,
        'agility_critical_rate',
        criticalBase,
        criticalRaised,
      );
      expect(speedRaised, greaterThan(speedBase));
      expect(evasionRaised, greaterThan(evasionBase));
      expect(criticalRaised, criticalBase);
    });

    test('${stage.name}: fortune changes fortune encounters but not combat stats', () {
      final base = fixture.createCharacter(stage, id: 700 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 800 + stage.index,
        raisedAttribute: AttributeKey.fortune,
      );
      final encounterBase = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.fortune,
        attributes: base.attributes,
      );
      final encounterRaised = policy.encounterProbability(
        base: 0.2,
        source: EncounterProbabilitySource.fortune,
        attributes: raised.attributes,
      );
      final hpBase =
          CharacterDerivedStats.maxHp(base, const [], repository.numbers);
      final hpRaised =
          CharacterDerivedStats.maxHp(raised, const [], repository.numbers);
      final evasionBase =
          CharacterDerivedStats.evasionRate(base, repository.numbers);
      final evasionRaised =
          CharacterDerivedStats.evasionRate(raised, repository.numbers);
      final criticalBase =
          CharacterDerivedStats.criticalRate(base, repository.numbers);
      final criticalRaised =
          CharacterDerivedStats.criticalRate(raised, repository.numbers);
      recordAttributeObservation(
        stage,
        'fortune_encounter_probability',
        encounterBase,
        encounterRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_max_hp',
        hpBase,
        hpRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_evasion_rate',
        evasionBase,
        evasionRaised,
      );
      recordAttributeObservation(
        stage,
        'fortune_critical_rate',
        criticalBase,
        criticalRaised,
      );
      expect(encounterRaised, greaterThan(encounterBase));
      expect(hpRaised, hpBase);
      expect(evasionRaised, evasionBase);
      expect(criticalRaised, criticalBase);
    });
  }
}
```

- [ ] **Step 2: 运行属性诊断**

Run:

```bash
flutter test --no-pub test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: 12 tests PASS。任何失败都进入 Task 7 硬门禁；不因“提升幅度看起来小”修改倍率。

- [ ] **Step 3: 联合既有属性入口测试**

Run:

```bash
flutter test --no-pub \
  test/core/domain/attribute_effect_policy_test.dart \
  test/features/injury/application/injury_service_test.dart \
  test/features/cultivation/application/cultivation_service_test.dart \
  test/features/cultivation/application/insight_exchange_service_test.dart \
  test/features/encounter/application/encounter_service_test.dart \
  test/features/encounter/presentation/encounter_dialog_test.dart \
  test/features/battle/damage_calculator_proficiency_wire_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: all PASS。

- [ ] **Step 4: 提交**

```bash
git add \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: diagnose attribute role sensitivity"
```

---

### Task 5: 抽取测试专用战斗采样 API

**Files:**
- Create: `test/support/progression_battle_probe.dart`
- Modify: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`
- Test: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`

- [ ] **Step 1: 先运行既有首通诊断保存行为基线**

Run:

```bash
flutter test --no-pub test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

Expected: PASS；保存最终摘要中的总 run 数、平均展示动作行和 `stage_06_05` floor 数据。

- [ ] **Step 2: 创建共享类型和 API**

Create `test/support/progression_battle_probe.dart` with these public declarations:

```dart
import 'dart:math';

import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

enum ProgressionBuildProfile { undergeared, standard, nearMax }

final class ProgressionBattleObservation {
  const ProgressionBattleObservation({
    required this.stageId,
    required this.profile,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.playerHpStart,
    required this.playerHpEnd,
    required this.playerQiStart,
    required this.playerQiEnd,
    required this.actionRows,
  });

  final String stageId;
  final ProgressionBuildProfile profile;
  final int seed;
  final BattleResult result;
  final int ticks;
  final int playerHpStart;
  final int playerHpEnd;
  final int playerQiStart;
  final int playerQiEnd;
  final int actionRows;
}

ProgressionBattleObservation probeMainlineStage({
  required GameRepository repository,
  required StageDef stage,
  required ProgressionBuildProfile profile,
  required int seed,
}) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      buildProgressionPlayer(
        repository: repository,
        tier: stage.requiredRealm,
        slot: slot,
        isFounder: slot == 0,
        profile: profile,
      ),
  ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repository.numbers,
    maxTicks: 240,
    rng: Random(seed),
  );
  int sumHp(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentHp);
  int sumQi(List<BattleCharacter> team) =>
      team.fold(0, (sum, character) => sum + character.currentQi);
  return ProgressionBattleObservation(
    stageId: stage.id,
    profile: profile,
    seed: seed,
    result: terminal.result,
    ticks: terminal.tick,
    playerHpStart: sumHp(initial.leftTeam),
    playerHpEnd: sumHp(terminal.leftTeam),
    playerQiStart: sumQi(initial.leftTeam),
    playerQiEnd: sumQi(terminal.leftTeam),
    actionRows: terminal.actionLog.length,
  );
}
```

Add the complete player builder below. It preserves the existing undergeared/nearMax values and adds only the standard midpoint profile:

```dart
BattleCharacter buildProgressionPlayer({
  required GameRepository repository,
  required RealmTier tier,
  required int slot,
  required bool isFounder,
  required ProgressionBuildProfile profile,
}) {
  const school = TechniqueSchool.gangMeng;
  final numbers = repository.numbers;
  final realm = repository.getRealm(tier, RealmLayer.huaJing);
  final (enhanceRatio, battleCount, cultivationLayer, attributeValue, buff) =
      switch (profile) {
        ProgressionBuildProfile.undergeared =>
          (0.0, 0, CultivationLayer.zhongCheng, 5, false),
        ProgressionBuildProfile.standard =>
          (0.25, 150, CultivationLayer.zhongCheng, 5, false),
        ProgressionBuildProfile.nearMax =>
          (0.5, 400, CultivationLayer.daCheng, 6, true),
      };
  final enhanceLevel = (realm.absoluteLevel * enhanceRatio).round();

  final equipmentTier = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final slotType in const [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final EquipmentDef def = repository.equipmentDefs.values.firstWhere(
      (value) => value.tier == equipmentTier && value.slot == slotType,
      orElse: () => throw StateError(
        'progression_probe: 无 ${equipmentTier.name}/${slotType.name} 装备',
      ),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime.utc(2026, 7, 13),
        obtainedFrom: 'progression_playtest',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
        forgingSlots: const <ForgingSlot>[],
      ),
    );
  }

  final techniqueTier = RealmUtils.techniqueTierCapOf(tier);
  final TechniqueDef techniqueDef = repository.techniqueDefs.values.firstWhere(
    (value) => value.tier == techniqueTier && value.school == school,
    orElse: () => throw StateError(
      'progression_probe: 无 ${techniqueTier.name}/${school.name} 心法',
    ),
  );
  final ownerId = 7000 + slot;
  final mainTechnique = Technique.create(
    defId: techniqueDef.id,
    ownerCharacterId: ownerId,
    tier: techniqueDef.tier,
    school: techniqueDef.school,
    role: TechniqueRole.main,
    learnedAt: DateTime.utc(2026, 7, 13),
    cultivationLayer: cultivationLayer,
  );
  final attributes = Attributes()
    ..constitution = attributeValue
    ..enlightenment = 5
    ..agility = attributeValue
    ..fortune = 5;
  final character = Character.create(
    name: isFounder ? '成长体检祖师' : '成长体检弟子$slot',
    realmTier: tier,
    realmLayer: RealmLayer.huaJing,
    attributes: attributes,
    rarity: RarityTier.biaoZhun,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime.utc(2026, 7, 13),
    internalForce: realm.internalForceMax,
    internalForceMax: realm.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = ownerId;
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTechnique,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: buff,
  );
}
```

- [ ] **Step 3: 改既有首通诊断使用共享 API**

In `test/tools/readable_first_clear_tempo_diagnostic_test.dart`:

- import `../support/progression_battle_probe.dart`;
- keep `_TempoRun.fromBattle` and all existing action-log assertions unchanged;
- delete only the now-duplicated local `_buildPlayer` function and profile enum;
- apply these exact type and call-site replacements:

```dart
const readableProfiles = [
  ProgressionBuildProfile.undergeared,
  ProgressionBuildProfile.nearMax,
];

// _TempoRun field and constructor parameter
final ProgressionBuildProfile profile;

// _simulate signature
_TempoRun _simulate(
  StageDef stage,
  GameRepository repository,
  ProgressionBuildProfile profile,
  int seed,
) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      buildProgressionPlayer(
        repository: repository,
        tier: stage.requiredRealm,
        slot: slot,
        isFounder: slot == 0,
        profile: profile,
      ),
  ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repository.numbers,
    maxTicks: _maxTicks,
    rng: Random(seed),
  );
  return _TempoRun.fromBattle(
    stage: stage,
    profile: profile,
    seed: seed,
    initial: initial,
    terminal: terminal,
  );
}
```

Replace `_TempoProfile.values` loops with `readableProfiles`, `_TempoProfile.floor`
with `ProgressionBuildProfile.undergeared`, and `_TempoProfile.ceiling` with
`ProgressionBuildProfile.nearMax`.

- [ ] **Step 4: 运行格式与等价性回归**

Run:

```bash
dart format \
  test/support/progression_battle_probe.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart
flutter test --no-pub test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

Expected: PASS，run 数和 Task 5 Step 1 保存的关键摘要相同；若不相同，恢复到语义等价后再继续。

- [ ] **Step 5: 提交**

```bash
git add \
  test/support/progression_battle_probe.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: share progression battle probes"
```

---

### Task 6: 生成统一成长路径 CSV 与诊断报告

**Files:**
- Create: `test/tools/progression_playtest_diagnostic_test.dart`
- Create: `test/tools/output/progression_attribute_playtest_2026-07-13.csv`
- Create: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Use: `test/support/progression_battle_probe.dart`

- [ ] **Step 1: 写受控规模成长诊断**

Create `test/tools/progression_playtest_diagnostic_test.dart`:

```dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seedCount = 20;
const _csvPath =
    'test/tools/output/progression_attribute_playtest_2026-07-13.csv';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'progression playtest: 30 mainline × 3 profiles × 20 seeds',
    () {
      final stages = repository.stageDefs.values
          .where((stage) =>
              stage.stageType == StageType.mainline &&
              stage.enemyTeam.isNotEmpty)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final rows = <ProgressionBattleObservation>[];
      for (final stage in stages) {
        for (final profile in ProgressionBuildProfile.values) {
          for (var seed = 0; seed < _seedCount; seed++) {
            rows.add(probeMainlineStage(
              repository: repository,
              stage: stage,
              profile: profile,
              seed: seed,
            ));
          }
        }
      }

      expect(stages.length, 30);
      expect(rows.length, 30 * 3 * _seedCount);
      expect(rows.every((row) => row.ticks < 240), isTrue,
          reason: '诊断样本不得撞 maxTicks');

      final buffer = StringBuffer()
        ..writeln(
          'stage_id,profile,seed,result,ticks,player_hp_start,'
          'player_hp_end,player_qi_start,player_qi_end,action_rows',
        );
      for (final row in rows) {
        buffer.writeln([
          row.stageId,
          row.profile.name,
          row.seed,
          row.result.name,
          row.ticks,
          row.playerHpStart,
          row.playerHpEnd,
          row.playerQiStart,
          row.playerQiEnd,
          row.actionRows,
        ].join(','));
      }
      File(_csvPath).writeAsStringSync(buffer.toString());
      print('progression playtest wrote ${rows.length} rows to $_csvPath');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
```

- [ ] **Step 2: 运行诊断并核对 CSV**

Run:

```bash
flutter test --no-pub test/tools/progression_playtest_diagnostic_test.dart
wc -l test/tools/output/progression_attribute_playtest_2026-07-13.csv
head -n 2 test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

Expected: test PASS；CSV 为 1801 行（表头 + 1800 个场景）。

- [ ] **Step 3: 运行心魔、塔和经验专项形成同 commit 证据**

Run:

```bash
git rev-parse HEAD
flutter --version
flutter test --no-pub \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart
```

Expected: all PASS。记录当前心魔 05/06/07、塔 25/30、Lv490 和属性诊断的真实输出。

- [ ] **Step 4: 写审计报告**

Create `docs/audit/progression_attribute_playtest_2026-07-13.md`，内容必须按以下固定顺序填写本轮真实值，不引用旧 `PROGRESS.md` 数字：

```markdown
# 成长路径与四属性体感体检 · 2026-07-13

## 运行元数据

- commit：本轮 `git rev-parse HEAD`
- Flutter：本轮 `flutter --version`
- 战斗种子：0～19
- 主线矩阵：30 关 × 3 配置 × 20 seed
- 生产代码修改：是或否，并列出 `lib/` 文件

## 硬契约结论

- Lv1～Lv490 / 49 层：通过或失败，并列失败测试
- 七类经验入口：通过或失败，并列失败测试
- 心魔锁与终境：通过或失败，并列失败测试
- 四属性职责：通过或失败，并列失败测试

## 软观察

- 主线：分别汇总 undergeared / standard / nearMax 胜率、节拍、剩余血量与真气
- 心魔：记录 05/06/07 当前 commit 的固定种子观察值
- 通天塔：记录 25/30 层及前驱层当前 commit 的观察值
- 四属性：逐项记录前/中/后期 baseline 与 raised 原始值，不只写“通过”

## 问题分级

- P0：只列硬契约证明的问题；无则写“无”
- P1：只列确定性职责/显示/落库错误；无则写“无”
- P2：列数值候选及复现配置，不在本批修改
- 观察项：列单个临界种子或主观手感

## 第一批处置

- 已修 P0/P1 及对应测试；无则明确“零生产代码修改”
- 第二批候选：逐项说明为什么可能调整、不调整会怎样
```

- [ ] **Step 5: 校验报告引用与 CSV 卫生**

Run:

```bash
git diff --check
rg -n "T[B]D|T[O]DO|待[补]|旧[报]告" \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

Expected: `git diff --check` 无输出，`rg` 无命中。

- [ ] **Step 6: 提交诊断证据**

```bash
git add \
  test/tools/progression_playtest_diagnostic_test.dart \
  test/tools/output/progression_attribute_playtest_2026-07-13.csv \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "test: record progression and attribute playtest evidence"
```

---

### Task 7: P0/P1 证据门禁

**Files:**
- Inspect: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Modify conditionally: this plan and the exact failing production/test files

- [ ] **Step 1: 审核硬失败列表**

Run:

```bash
rg -n "^## 问题分级|^- P0|^- P1" \
  docs/audit/progression_attribute_playtest_2026-07-13.md
git diff --name-only $(git merge-base HEAD main)..HEAD | sort
```

Expected: 问题分级与实际失败测试一致，不能把 P2 或单 seed 观察升级成 P1。

- [ ] **Step 2A: 无 P0/P1 时关闭生产修改门禁**

If P0/P1 都为“无”，run:

```bash
git diff --name-only $(git merge-base HEAD main)..HEAD -- 'lib/**' 'data/**'
```

Expected: 无输出。把报告“第一批处置”写为“零生产代码修改”，继续 Task 8。

- [ ] **Step 2B: 存在 P0/P1 时暂停并具体化修复任务**

If any hard contract fails:

1. 不修改 `lib/` 或 `data/`；
2. 在本计划 Task 7 后追加一个独立任务，标题使用失败行为，例如“修复心魔锁可被离线经验绕过”；
3. 新任务必须列出失败测试、精确生产文件、红绿命令、最小实现代码和独立提交；
4. 若修复需要 `numbers.yaml`、schema、save version 或改变三个以上系统规则，停止并请求用户确认；
5. 追加任务后重新执行 `writing-plans` 自检，再按 TDD 实施。

Expected: 未具体化修复任务前保持零生产修改；不允许用通用“修一下”步骤越过门禁。

- [ ] **Step 3: 提交门禁结论**

若报告因门禁审核有文字修正：

```bash
git add \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "docs: classify progression audit findings"
```

若无文字变化，不创建空提交。

---

### Task 8: 全量门禁、macOS 复验与收尾

**Files:**
- Modify: `PROGRESS.md`
- Modify: `docs/audit/progression_attribute_playtest_2026-07-13.md`
- Modify: `docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md`

- [ ] **Step 1: 格式检查与静态分析**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
git diff --check
```

Expected: formatter 0 changed，analyze `No issues found!`，diff check 无输出。

- [ ] **Step 2: 运行本批定向门禁**

Run:

```bash
flutter test --no-pub \
  test/support/progression_playtest_fixture_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/features/cultivation/application/single_experience_account_contract_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart \
  test/tools/progression_playtest_diagnostic_test.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart
```

Expected: all PASS，记录真实非隐藏测试数。

- [ ] **Step 3: 运行全量测试并提取真实计数**

Run:

```bash
set -o pipefail
flutter test --no-pub --reporter json 2>/dev/null \
  | jq -r 'select(.type == "testDone" and .hidden == false) | .result' \
  | sort | uniq -c
```

Expected: 仅一行 `<实际数量> success`，无 failure/error。不可把 hidden load events 计入 pass 数。

- [ ] **Step 4: macOS Debug 构建**

Run:

```bash
flutter build macos --debug
```

Expected: `✓ Built build/macos/Build/Products/Debug/wuxia_idle.app`。第三方 warning 单独记录，不把 warning 写成 build failure。

- [ ] **Step 5: 四画面双视口复验**

用既有 debug visual route/harness 复验：

- 前期角色档案；
- 心魔锁定与经验溢出；
- 战后经验/Lv/突破反馈；
- Lv490 角色档案。

每个画面检查 1280×720 和 1440×900，验收标准：无 overflow/exception、等级与境界一致、心魔等待说明可见、Lv490 无虚假进度。截图路径和结果写入审计报告；本步不改 UI，发现布局问题按 P1 证据门禁新增具体任务。

- [ ] **Step 6: 更新进度文档**

在 `PROGRESS.md` 顶部新增一条，必须区分：

- 已完成：硬契约、诊断矩阵和报告；
- 已验证：format/analyze/定向/全量/build/双视口真实结果；
- 已知风险：P2 和观察项；
- 下批建议：只引用审计报告中的第二批候选；
- 明确是否零生产代码修改，且本批无 `numbers.yaml`/schema/save version 变化。

- [ ] **Step 7: 最终自检与 READY 提交**

Run:

```bash
git diff --check
git status -sb
git log --oneline -10
```

Expected: 仅本步报告/计划/PROGRESS 待提交，历史为小切片提交。

```bash
git add \
  PROGRESS.md \
  docs/audit/progression_attribute_playtest_2026-07-13.md \
  docs/superpowers/plans/2026-07-13-progression-attribute-playtest.md
git commit -m "[READY] docs: close progression attribute playtest audit"
```

Expected: worktree clean，tip 前缀为 `[READY]`。合并和推送属于后续显式授权，不在本计划自动执行。

---

## 自检清单

- 设计规格的 Lv490、七入口、四属性、成长路径、报告、门禁和真机复验均有对应任务。
- 生产代码默认零修改；P0/P1 未具体化前不能越过 Task 7。
- 软观察不写精确永久断言，所有数字绑定 commit 和 seed。
- 夹具只构造合法样本，不复制生产经验、属性或战斗公式。
- 不包含发布准备、Windows、数值调整、schema/save version 或 rejected registry 方向。
