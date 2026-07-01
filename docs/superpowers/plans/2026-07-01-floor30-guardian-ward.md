# floor30 护法结界终局战 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给爬塔 floor30 主 Boss 加「护法结界」——护法存活时主 Boss 减伤，护法全灭后减伤解除，形成 on-level 稳过、欠配队会败的软门槛 + 终局仪式感。

**Architecture:** 承伤管线末端加一个 ward 乘子（与现有 schoolDamageTakenMult 同层）。ward 由纯函数据「主 Boss 的 guardianDefIds 中是否有护法存活」计算。护法存活判定依赖新增的 `BattleCharacter.enemyDefId`（现敌人 characterId 是槽位负数无法回溯源 id）。配置走 towers.yaml 新字段 `guardianWard`，加载期 fail-fast 校验。仅 floor30 用，他关零回归。

**Tech Stack:** Flutter / Dart / Isar；战斗纯 Dart 域层；yaml 配置；`flutter test --no-pub -j1`。

**关键约束（红线）：** Boss HP ≤60000（42000 不动）｜招式倍率 ≤8000｜在线=离线（结界纯战斗内、不碰 settle）｜三系锁死（realmTier 不改）｜中文进 UiStrings/narratives｜不硬编码数值。

**spec：** `docs/superpowers/specs/2026-07-01-floor30-guardian-ward-design.md`

---

## File Structure

- `lib/data/defs/stage_def.dart` — 新增 `GuardianWardDef` 值类 + `EnemyDef.guardianWard` 字段与解析。
- `lib/data/game_repository.dart` — 新增 `_enforceGuardianWardReferences` fail-fast 校验 + 调用点。
- `lib/features/battle/domain/battle_state.dart` — `BattleCharacter` 新增 `enemyDefId` / `guardianWardMult` / `guardianDefIds` 字段 + copyWith。
- `lib/features/battle/application/stage_battle_setup.dart` — `_enemyToBattle` 透传新字段。
- `lib/features/battle/domain/damage_calculator.dart` — `calculateResolved` 新增 `defenderWardMult` 入参并末端相乘。
- `lib/features/battle/domain/strategy/default_ground_strategy.dart` — 新增纯函数 `wardMultOf` + 调用点透传。
- `data/towers.yaml` — floor30 主 Boss 加 `guardianWard` 块 + 护法 HP 校准。
- `lib/shared/strings.dart` — 结界/破界题字文案。
- `lib/features/battle/presentation/*` — 结界护罩 + 破界演出（复用现有基建）。
- 测试：`test/data/`、`test/features/battle/`、`test/features/tower/`。

---

## Task 1: GuardianWardDef schema + EnemyDef 解析 + 加载校验

**Files:**
- Modify: `lib/data/defs/stage_def.dart:197-282`（EnemyDef 类 + fromYaml）
- Modify: `lib/data/game_repository.dart:428-430`（调用点）+ 新增校验函数
- Test: `test/data/guardian_ward_schema_test.dart`（新建）

- [ ] **Step 1: 写失败测试（解析 + 校验）**

`test/data/guardian_ward_schema_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

void main() {
  group('GuardianWardDef', () {
    test('EnemyDef.fromYaml 解析 guardianWard', () {
      final e = EnemyDef.fromYaml({
        'id': 'boss', 'name': 'B', 'realmTier': 'zongShi', 'realmLayer': 'dengFeng',
        'school': 'yinRou', 'baseHp': 42000, 'baseAttack': 2800, 'baseSpeed': 245,
        'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': true,
        'guardianWard': {
          'damageTakenMult': 0.15,
          'guardianIds': ['g_a', 'g_b'],
        },
      });
      expect(e.guardianWard, isNotNull);
      expect(e.guardianWard!.damageTakenMult, 0.15);
      expect(e.guardianWard!.guardianIds, ['g_a', 'g_b']);
    });

    test('无 guardianWard → null（零回归）', () {
      final e = EnemyDef.fromYaml({
        'id': 'x', 'name': 'X', 'realmTier': 'xueTu', 'realmLayer': 'qiMeng',
        'school': 'gangMeng', 'baseHp': 100, 'baseAttack': 10, 'baseSpeed': 100,
        'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': false,
      });
      expect(e.guardianWard, isNull);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/data/guardian_ward_schema_test.dart`
Expected: FAIL（`guardianWard` getter 不存在，编译错误）

- [ ] **Step 3: 实装 GuardianWardDef + EnemyDef 字段与解析**

`lib/data/defs/stage_def.dart` 在 EnemyDef 类**之前**加值类：
```dart
/// 护法结界配置(仅爬塔终局 Boss 用)。护法存活时主 Boss 承伤 ×damageTakenMult;
/// guardianIds 全部阵亡 → 结界破,承伤恢复 ×1.0。见 spec 2026-07-01-floor30-guardian-ward。
class GuardianWardDef {
  final double damageTakenMult;      // 结界期间主 Boss 承伤乘子, ∈ (0, 1]
  final List<String> guardianIds;    // 护法敌人 id(须在本 floor enemyTeam 存在)

  const GuardianWardDef({
    required this.damageTakenMult,
    required this.guardianIds,
  });

  factory GuardianWardDef.fromYaml(Map<String, dynamic> y) => GuardianWardDef(
        damageTakenMult: (y['damageTakenMult'] as num).toDouble(),
        guardianIds: ((y['guardianIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
      );
}
```
在 `EnemyDef` 字段区（约 213 行 `schoolDamageTakenMult` 附近）加：
```dart
  final GuardianWardDef? guardianWard;
```
在构造函数参数列表加 `this.guardianWard,`（可选，无 required）。
在 `EnemyDef.fromYaml`（253-282）return 里加：
```dart
        guardianWard: y['guardianWard'] == null
            ? null
            : GuardianWardDef.fromYaml(
                Map<String, dynamic>.from(y['guardianWard'] as Map)),
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test --no-pub test/data/guardian_ward_schema_test.dart`
Expected: PASS（2 tests）

- [ ] **Step 5: 加加载期 fail-fast 校验（悬空/越界）**

先在测试文件加校验用例（同源 `enforceGuardianWardReferences` 静态方法，仿 `enforceDropTableReferences` 可独立测的范式）：
```dart
  group('enforceGuardianWardReferences', () {
    EnemyDef boss(List<String> gids) => EnemyDef.fromYaml({
          'id': 'boss', 'name': 'B', 'realmTier': 'zongShi', 'realmLayer': 'dengFeng',
          'school': 'yinRou', 'baseHp': 42000, 'baseAttack': 2800, 'baseSpeed': 245,
          'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': true,
          'guardianWard': {'damageTakenMult': 0.15, 'guardianIds': gids},
        });
    EnemyDef minion(String id) => EnemyDef.fromYaml({
          'id': id, 'name': id, 'realmTier': 'zongShi', 'realmLayer': 'jingTong',
          'school': 'gangMeng', 'baseHp': 4000, 'baseAttack': 700, 'baseSpeed': 220,
          'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': false,
        });

    test('guardianIds 全在 team → 不抛', () {
      GameRepository.enforceGuardianWardReferences(
          [boss(['g_a']), minion('g_a')]);
    });
    test('guardianIds 悬空 → 抛 StateError(含坏 id)', () {
      expect(() => GameRepository.enforceGuardianWardReferences([boss(['ghost'])]),
          throwsA(isA<StateError>()));
    });
    test('damageTakenMult 越界(>1) → 抛', () {
      final b = EnemyDef.fromYaml({
        'id': 'boss', 'name': 'B', 'realmTier': 'zongShi', 'realmLayer': 'dengFeng',
        'school': 'yinRou', 'baseHp': 42000, 'baseAttack': 2800, 'baseSpeed': 245,
        'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': true,
        'guardianWard': {'damageTakenMult': 1.5, 'guardianIds': <String>['g']},
      });
      expect(() => GameRepository.enforceGuardianWardReferences([b, minion('g')]),
          throwsA(isA<StateError>()));
    });
  });
```
（测试顶部加 `import 'package:wuxia_idle/data/game_repository.dart';`）

`lib/data/game_repository.dart` 加静态方法（仿 484-507 范式，一个 floor 的 enemyTeam 传入）：
```dart
  /// 护法结界引用校验:主 Boss guardianIds 须在同 floor enemyTeam 存在,
  /// damageTakenMult ∈ (0,1], guardianIds 非空。缺失/越界 fail-fast(spec §5)。
  static void enforceGuardianWardReferences(List<EnemyDef> enemyTeam) {
    final ids = enemyTeam.map((e) => e.id).toSet();
    for (final e in enemyTeam) {
      final w = e.guardianWard;
      if (w == null) continue;
      if (w.guardianIds.isEmpty) {
        throw StateError('敌人 ${e.id} guardianWard.guardianIds 为空');
      }
      if (w.damageTakenMult <= 0 || w.damageTakenMult > 1) {
        throw StateError(
            '敌人 ${e.id} guardianWard.damageTakenMult=${w.damageTakenMult} 越界(须 ∈ (0,1])');
      }
      for (final gid in w.guardianIds) {
        if (!ids.contains(gid)) {
          throw StateError('敌人 ${e.id} guardianWard 引用 $gid 不在本 floor enemyTeam');
        }
      }
    }
  }
```
在 `loadAllDefs` 校验区（428-430 附近，`_enforceRedLines()` 之后）遍历爬塔各 floor 调用：
```dart
    for (final floor in repo.towerDef.floors) {
      GameRepository.enforceGuardianWardReferences(floor.enemyTeam);
    }
```
（若 towerDef 访问路径不同，按现有 tower floors 访问方式对齐；grep `towerDef` / `TowerFloorDef` 确认 getter。）

- [ ] **Step 6: 跑测试确认全绿**

Run: `flutter test --no-pub test/data/guardian_ward_schema_test.dart`
Expected: PASS（5 tests）

- [ ] **Step 7: analyze + commit**

Run: `flutter analyze lib/ test/`（Expected: 0）
```bash
git add lib/data/defs/stage_def.dart lib/data/game_repository.dart test/data/guardian_ward_schema_test.dart
git commit -m "[schema] EnemyDef 加 guardianWard 护法结界配置 + 加载校验"
```

---

## Task 2: BattleCharacter 源 def id + ward 字段 + assembly 透传

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart:104-274`（字段）+ `:519` 附近（copyWith）
- Modify: `lib/features/battle/application/stage_battle_setup.dart:486-514`（_enemyToBattle）
- Test: `test/features/battle/guardian_ward_assembly_test.dart`（新建）

- [ ] **Step 1: 写失败测试（assembly 透传）**

`test/features/battle/guardian_ward_assembly_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

void main() {
  test('_enemyToBattle 透传 enemyDefId + ward 字段', () {
    final boss = EnemyDef.fromYaml({
      'id': 'enemy_boss', 'name': 'B', 'realmTier': 'zongShi', 'realmLayer': 'dengFeng',
      'school': 'yinRou', 'baseHp': 42000, 'baseAttack': 2800, 'baseSpeed': 245,
      'skillIds': <String>[], 'iconPath': 'x.png', 'isBoss': true,
      'guardianWard': {'damageTakenMult': 0.15, 'guardianIds': ['g_a']},
    });
    final bc = StageBattleSetup.debugEnemyToBattle(enemy: boss, slotIndex: 0);
    expect(bc.enemyDefId, 'enemy_boss');
    expect(bc.guardianWardMult, 0.15);
    expect(bc.guardianDefIds, ['g_a']);
  });
}
```
（若 `_enemyToBattle` 私有不可直测，加一个 `@visibleForTesting static BattleCharacter debugEnemyToBattle(...)` 薄封装转调，或用现有 buildTeamsForTower 公开路径断言 rightTeam[0] 字段。优先薄封装。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/battle/guardian_ward_assembly_test.dart`
Expected: FAIL（`enemyDefId` getter 不存在）

- [ ] **Step 3: BattleCharacter 加字段**

`lib/features/battle/domain/battle_state.dart` 在 BattleCharacter 字段区（`schoolDamageTakenMult` 第 219 行附近）加：
```dart
  /// 敌人源 def id(仅敌方填充;玩家方 null)。护法结界据此判定护法存活。
  final String? enemyDefId;
  /// 护法结界:本单位(主 Boss)承伤乘子;null=非结界单位。
  final double? guardianWardMult;
  /// 护法结界:守护本单位的护法 def id 集(空=无结界)。
  final List<String> guardianDefIds;
```
构造函数加：`this.enemyDefId, this.guardianWardMult, this.guardianDefIds = const [],`
copyWith（约 519 行）加对应可选参数与透传：
```dart
    String? enemyDefId,
    double? guardianWardMult,
    List<String>? guardianDefIds,
```
```dart
      enemyDefId: enemyDefId ?? this.enemyDefId,
      guardianWardMult: guardianWardMult ?? this.guardianWardMult,
      guardianDefIds: guardianDefIds ?? this.guardianDefIds,
```
（注意 copyWith 无法把非空重置为 null——本机制不需要重置,copyWith 只用于 hp/存活更新,ward 字段随单位不变,OK。）

- [ ] **Step 4: _enemyToBattle 透传**

`lib/features/battle/application/stage_battle_setup.dart:514`（`schoolDamageTakenMult: enemy.schoolDamageTakenMult ?? const {},` 那行后）加：
```dart
      enemyDefId: enemy.id,
      guardianWardMult: enemy.guardianWard?.damageTakenMult,
      guardianDefIds: enemy.guardianWard?.guardianIds ?? const [],
```
若需薄测试封装，在 StageBattleSetup 加：
```dart
  @visibleForTesting
  static BattleCharacter debugEnemyToBattle({
    required EnemyDef enemy, required int slotIndex, int cycleIndex = 1,
  }) => _enemyToBattle(enemy: enemy, slotIndex: slotIndex, cycleIndex: cycleIndex, isTower: true);
```
（`import 'package:flutter/foundation.dart';` 若未引入。）

- [ ] **Step 5: 跑测试确认通过 + analyze**

Run: `flutter test --no-pub test/features/battle/guardian_ward_assembly_test.dart`（Expected: PASS）
Run: `flutter analyze lib/ test/`（Expected: 0）

- [ ] **Step 6: commit**

```bash
git add lib/features/battle/domain/battle_state.dart lib/features/battle/application/stage_battle_setup.dart test/features/battle/guardian_ward_assembly_test.dart
git commit -m "feat: BattleCharacter 加 enemyDefId + 护法结界字段并 assembly 透传"
```

---

## Task 3: 承伤管线 ward 减伤接入

**Files:**
- Modify: `lib/features/battle/domain/damage_calculator.dart:100-138`（入参）+ `:223`（相乘）
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart:834-870`（wardMultOf + 调用点）
- Test: `test/features/battle/guardian_ward_damage_test.dart`（新建）

- [ ] **Step 1: 写失败测试（wardMultOf 纯函数）**

`test/features/battle/guardian_ward_damage_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

BattleCharacter enemy({required int slot, required bool alive, String? defId,
    double? wardMult, List<String> guards = const []}) {
  // 用最小构造:按 BattleCharacter 必填字段填占位(参现有 battle test helper)。
  // 见 test/support 里既有 enemy 构造 helper,复用之;此处仅示意关键字段。
  return /* 复用 helper 或最小构造 */ throw UnimplementedError();
}

void main() {
  test('护法存活 → wardMult 生效', () {
    final boss = enemy(slot: 0, alive: true, defId: 'boss', wardMult: 0.15, guards: ['g']);
    final g = enemy(slot: 1, alive: true, defId: 'g');
    final state = /* BattleState with rightTeam=[boss,g] */ throw UnimplementedError();
    expect(DefaultGroundStrategy.wardMultOf(boss, state), 0.15);
  });
  test('护法全灭 → 1.0', () {
    final boss = enemy(slot: 0, alive: true, defId: 'boss', wardMult: 0.15, guards: ['g']);
    final g = enemy(slot: 1, alive: false, defId: 'g');
    final state = /* rightTeam=[boss,g] */ throw UnimplementedError();
    expect(DefaultGroundStrategy.wardMultOf(boss, state), 1.0);
  });
  test('非结界单位 → 1.0', () {
    final e = enemy(slot: 0, alive: true, defId: 'x');
    final state = /* rightTeam=[e] */ throw UnimplementedError();
    expect(DefaultGroundStrategy.wardMultOf(e, state), 1.0);
  });
}
```
**实装前先做**：grep `test/support` / 现有 battle 测试里 BattleCharacter/BattleState 的构造 helper（如 `test/features/battle/.../*_test.dart` 里的 fixtures），复用之替换上面 `throw UnimplementedError()` 占位，得到可编译测试。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/battle/guardian_ward_damage_test.dart`
Expected: FAIL（`wardMultOf` 未定义）

- [ ] **Step 3: 实装 wardMultOf**

`lib/features/battle/domain/strategy/default_ground_strategy.dart`（`weaknessMultOf` 第 870 行附近）加：
```dart
  /// 护法结界:defender 为结界单位(guardianWardMult != null)且其 guardianDefIds 中
  /// 有护法在同队存活 → 返回 wardMult(减伤);否则 1.0。纯函数无 side effect。
  static double wardMultOf(BattleCharacter defender, BattleState state) {
    final mult = defender.guardianWardMult;
    if (mult == null || defender.guardianDefIds.isEmpty) return 1.0;
    final team = defender.teamSide == 1 ? state.rightTeam : state.leftTeam;
    final anyGuardianAlive = team.any((c) =>
        c.isAlive &&
        c.enemyDefId != null &&
        defender.guardianDefIds.contains(c.enemyDefId));
    return anyGuardianAlive ? mult : 1.0;
  }
```

- [ ] **Step 4: damage_calculator 加入参 + 相乘**

`lib/features/battle/domain/damage_calculator.dart` 在 `calculateResolved` 入参（`defenderSchoolDamageMult = 1.0,` 后）加：
```dart
    double defenderWardMult = 1.0,
```
第 223 行 raw 相乘链末尾加一乘子：
```dart
    defenderSchoolDamageMult *
    defenderWardMult;
```

- [ ] **Step 5: strategy 调用点透传**

`default_ground_strategy.dart` 第 859 行（`defenderSchoolDamageMult: weaknessMultOf(attacker, defender),`）后加：
```dart
      defenderWardMult: wardMultOf(defender, preState),
```
（用与该结算同一份状态快照——若该段用 `preState`/`state` 变量名，对齐；本文件结算基于 `preState` 行动前快照，见 435 行注释。）

- [ ] **Step 6: 补一个「减伤真实作用于伤害」的集成断言**

在测试文件加：护法存活时 calculateResolved 输出 × 0.15 ≈ 全伤 × 0.15（同参两次调用，一次 wardMult=1.0 一次 0.15，比值 ≈ 0.15，允许取整误差）。用现有 damage_calculator 测的调用范式（grep `calculateResolved(` 在 test/ 找样板参数）。

- [ ] **Step 7: 跑测试 + analyze**

Run: `flutter test --no-pub test/features/battle/guardian_ward_damage_test.dart`（Expected: PASS）
Run: `flutter analyze lib/ test/`（Expected: 0）

- [ ] **Step 8: commit**

```bash
git add lib/features/battle/domain/damage_calculator.dart lib/features/battle/domain/strategy/default_ground_strategy.dart test/features/battle/guardian_ward_damage_test.dart
git commit -m "feat: 承伤管线接入护法结界减伤(wardMultOf 纯函数末端相乘)"
```

---

## Task 4: towers.yaml floor30 结界配置 + 护法 HP 校准初值

**Files:**
- Modify: `data/towers.yaml`（floor30 主 Boss 加 guardianWard；护法 HP 提值初值）
- Test: `test/features/tower/floor30_guardian_ward_config_test.dart`（新建）

- [ ] **Step 1: 写失败测试（floor30 加载出结界配置）**

`test/features/tower/floor30_guardian_ward_config_test.dart`：加载真 towers.yaml，断言 floor30 主 Boss `guardianWard != null`、guardianIds = 两护法 id、护法 HP ≥ 初值下界；断言其他 floor 主 Boss guardianWard=null。参现有 `test/features/tower/domain/tower_floor_def_test.dart` 的加载范式（复用其 loader）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test --no-pub test/features/tower/floor30_guardian_ward_config_test.dart`
Expected: FAIL

- [ ] **Step 3: 改 towers.yaml floor30**

在 `enemy_tower_boss_30`（`data/towers.yaml:1275` 附近，`isBoss: true` 后、`schoolDamageTakenMult` 附近）加：
```yaml
        guardianWard:
          damageTakenMult: 0.15          # 结界减伤 85%(初值,Task 5 诊断校准)
          guardianIds:
            - enemy_tower_30_cultist_a
            - enemy_tower_30_cultist_b
```
护法提血初值（`enemy_tower_30_cultist_a` baseHp 4200→9000 / `enemy_tower_30_cultist_b` 4000→8500，初值，Task 5 校准）。加注释：`# [balance] 护法结界:提血使 burst 掉护法成软门槛,Task 5 诊断校准`。

- [ ] **Step 4: 跑测试 + 加载校验（Task 1 的 loadAllDefs 校验此时对真数据生效）**

Run: `flutter test --no-pub test/features/tower/floor30_guardian_ward_config_test.dart test/data/guardian_ward_schema_test.dart`
Expected: PASS

- [ ] **Step 5: commit**

```bash
git add data/towers.yaml test/features/tower/floor30_guardian_ward_config_test.dart
git commit -m "[balance] floor30 主 Boss 加护法结界配置 + 护法提血初值"
```

---

## Task 5: 软门槛确定性战斗测 + 诊断校准

**Files:**
- Modify: `test/tools/`（复用 `tower_boss_feel_diagnostic` 相关工具）
- Test: `test/features/tower/floor30_soft_gate_battle_test.dart`（新建，确定性 seed）

- [ ] **Step 1: 写 on-level 稳过 / 欠配会败的确定性战斗测**

参 memory `feedback_battle_determinism_test`（ProviderContainer + 永久 listener + `notifier.advance`，非 strategy.tick）+ `feedback_debug_battle_seed_real_power`（seed 真满配、实测 leftWin）。两 case：
- on-level 宗师满配队 vs floor30（含结界）→ 跑到 end → `leftWin == true`（破界后杀 Boss）。
- 欠配队（-1 阶 绝顶 / 低强化）vs floor30 → `leftWin == false`（burst 不动护法被耗死）。
先 grep 现有 `test/features/tower/*battle*` / `balance_simulator` 测拿队伍构造 + 跑战斗到结束的范式，复用。

- [ ] **Step 2: 跑测试**

Run: `flutter test --no-pub test/features/tower/floor30_soft_gate_battle_test.dart`
Expected: 初次可能不满足边界（欠配队仍胜 or on-level 队反被卡）。

- [ ] **Step 3: 诊断校准循环（[balance]）**

用 `tower_boss_feel_diagnostic`（现成，只读模拟，2 profile×N seed）跑 floor30，看 on-level 破界时机 + 胜率、欠配胜率。据结果调 `data/towers.yaml`：`guardianWard.damageTakenMult`（结界越强→越难破）、护法 HP（越高→burst 门槛越高）、（可选）护法施压技强度。目标：on-level 100% 胜、欠配 <100%。**Boss HP 42000 不动**。每次调值重跑 Step 1 测 + 诊断，迭代到边界达标。

- [ ] **Step 4: 边界达标后固化测试断言**

把校准后的稳定 seed 场景写死进 Step 1 测（确定性），使软门槛成为回归红线。

- [ ] **Step 5: commit**

```bash
git add data/towers.yaml test/features/tower/floor30_soft_gate_battle_test.dart
git commit -m "[balance] floor30 护法结界软门槛校准 + 确定性战斗回归测"
```

---

## Task 6: 表现层——结界护罩 + 题字 + 破界演出

**Files:**
- Modify: `lib/shared/strings.dart`（题字文案）
- Modify: `lib/features/battle/presentation/*`（护罩 overlay + 破界 flash；复用 screen_flash / 状态标签 / 题字层）
- Test: `test/features/battle/guardian_ward_presentation_test.dart`（widget test）

- [ ] **Step 1: 加题字文案（UiStrings）**

`lib/shared/strings.dart` 加：`guardianWardActive`（"护法结界·刀枪不入"）、`guardianWardBroken`（"结界破！"）。**不散写中文**，全进 UiStrings。

- [ ] **Step 2: 写 widget 失败测试**

结界期间主 Boss 单位显护罩标记 + 题字；护法全灭那帧显「结界破」题字 + flash。参现有相位题字 / 蓄力环 widget 测范式（grep `bossPhase_desperate` / 题字层 widget 测）。先 grep 定位现有相位题字渲染组件，护罩复用其模式。

- [ ] **Step 3: 实装护罩 overlay + 破界演出**

在战斗单位渲染层（BattleCharacter → CharacterAvatar 链）据 `guardianWardMult != null && 结界仍在`（可从 BattleState 派生同 `wardMultOf` 逻辑，presentation 只读不改结算）显护罩描边 + 题字。破界=护法存活数由 >0 变 0 的那帧触发 `screen_flash` + 「结界破」题字（复用现有相位转阶段题字机制）。**纯表现层,零碰 BattleState 结算字段**。

- [ ] **Step 4: 跑 widget 测 + analyze**

Run: `flutter test --no-pub test/features/battle/guardian_ward_presentation_test.dart`（Expected: PASS）
Run: `flutter analyze lib/ test/`（Expected: 0）

- [ ] **Step 5: commit**

```bash
git add lib/shared/strings.dart lib/features/battle/presentation/ test/features/battle/guardian_ward_presentation_test.dart
git commit -m "feat: 护法结界表现层(护罩+题字+破界演出,纯表现层)"
```

---

## Task 7: 红线守护测 + 全量回归

**Files:**
- Test: `test/features/tower/floor30_guardian_ward_redline_test.dart`（新建）

- [ ] **Step 1: 写红线守护测**

断言：floor30 主 Boss `baseHp == 42000` 且 `≤ 60000`（结界不涨血红线）；仅 floor30 主 Boss guardianWard != null，其他 floor 全 null（零回归范围）；护法 realmTier 未越三系锁死（zongShi）；施压技倍率 ≤8000（若加了新施压技，走 `_enforceEncounterSkillRedLines`——grep 确认覆盖）。

- [ ] **Step 2: 跑该测 + analyze**

Run: `flutter test --no-pub test/features/tower/floor30_guardian_ward_redline_test.dart`（Expected: PASS）
Run: `flutter analyze lib/ test/`（Expected: 0）

- [ ] **Step 3: 全量回归**

Run: `flutter test --no-pub -j1`
Expected: All tests passed（基线 3530 + 本批新测，0 fail）

- [ ] **Step 4: commit**

```bash
git add test/features/tower/floor30_guardian_ward_redline_test.dart
git commit -m "test: 护法结界红线守护测(HP 不涨/仅 floor30/三系锁死) + 全量回归"
```

---

## 已知范围 / 非目标

- ward 只减免走 `calculateResolved` 的主伤害;yinRou 内伤(per-tick 固定)不受结界减免——量小,接受(spec §8 风险②相关,如需可后续扩)。
- 仅 floor30;20/10 major Boss 不推广(用户拍板范围)。
- 具体 balance 数值(damageTakenMult / 护法 HP)由 Task 5 诊断校准定,本计划给初值。
