# 终局机制型 Boss 批次2「爬塔应用」Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让批次1 的「脆弱窗口」底座在真实爬塔 yaml 上生效——floor25/30 配 vulnerability，floor30 叠「护法墙 taunt」（修 no-op），并用自动战斗诊断硬闸证真触发。

**Architecture:** 三步：① 放宽 `EnemyDef` 跨字段校验，让靠 `chargeCounter` 相位开窗（无顶层 chargeSkillId）的真实塔 Boss 能配 vulnerability；② floor25（绝顶剑魔，无护法）+ floor30（九霄魔尊，有护法墙）配 `vulnerability` yaml；③ 模块 A：给 `battle_ai.dart` 三个目标选择器 + aoe 分支加「被存活护法保护的 Boss 从目标池排除」（taunt 语义，复用现有 `guardianDefIds`/`guardianWardMult` 存活判定，**零新 def 字段**），把护法结界减伤从「自动战斗 no-op」升级为「护法活着 Boss 不可选」。诊断走真实 yaml 消费 + `BattleEngine.runToEnd` 全自动对照。

**Tech Stack:** Dart/Flutter, Isar, YAML 配置, `flutter test`（并发）, TDD。

**批次1 已就绪（勿重做）：** `BossVulnerabilityDef`（`lib/data/defs/boss_vulnerability_def.dart`）、`EnemyDef.vulnerability`、`BattleCharacter.vulnerabilityMult`、伤害闸 `vulnerabilityMultOf` × `wardMultOf`（`default_ground_strategy.dart`）、`StageBattleSetup` plumbing 全部生效。本批只加 yaml 消费 + taunt AI + 诊断。

**核心约束（memory，违反即返工）：**
- `ward_noop`：护法减伤在自动战斗是 no-op（AI 先清低血护法）→ 模块 A 必须做真 taunt/不可选，诊断须证「护法全灭前 Boss 不被选中」。
- `boss_phase_needs_hp`：Boss 血不够会被 alpha strike 秒穿使窗口/相位失效 → 诊断读 avgTicks，秒杀型（≈1-3）说明窗口没生效。floor25/30 血已够（15000/42000）。
- `boss_balance_crosstier`：软门槛须测 under-gear 跨 1-2 阶。
- `battle_determinism_test_via_notifier` / `strategy_immutable_vs_ui_tick`：诊断走 `BattleEngine.runToEnd` + 固定 `Random(seed)`，多 seed 统计，非直接 `strategy.tick`。
- `stages_yaml_edit_direction`：改 towers.yaml 从 `- floorIndex:` / `- id:` 正向定位，不从 isBoss 反搜。

**测试节奏（CLAUDE v1.29）：** 本批是**跨切面改动**（改核心 AI 目标选择器 + yaml 配置），Task 3/末批跑全量并发 `flutter test --no-pub`；其余 Task targeted + `flutter analyze`。

---

## File Structure

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/data/defs/stage_def.dart` | `EnemyDef.fromYaml` 跨字段校验 | Modify（放宽校验，Task 1） |
| `lib/features/battle/domain/damage_calculator.dart` | 伤害 debug 标签 | Modify（标签订正，Task 1） |
| `lib/features/battle/domain/strategy/default_ground_strategy.dart` | `vulnerabilityMultOf` docstring | Modify（补 chargeCounter 路径注释，Task 1） |
| `test/data/enemy_def_vulnerability_validation_test.dart` | 校验红绿双验 | Create（Task 1） |
| `data/towers.yaml` | floor25/30 Boss 配置 | Modify（Task 2 floor25 / Task 4 floor30） |
| `test/data/tower_vulnerability_config_test.dart` | 真实 yaml 加载守卫 | Create（Task 2/4） |
| `lib/features/battle/domain/battle_ai.dart` | 目标选择器 taunt 排除 | Modify（Task 3 模块 A） |
| `test/features/battle/battle_ai_guardian_taunt_test.dart` | taunt 单元测 + drift 守卫 | Create（Task 3） |
| `test/tools/floor30_soft_gate_diagnostic_test.dart` | floor30 taunt + vuln 诊断 | Modify（Task 5） |
| `test/tools/vulnerability_window_diagnostic_test.dart` | floor25 真 yaml 消费诊断 | Modify（Task 5） |

---

## Task 1: 放宽校验 + 收口 batch-1 遗留标签/注释

**批次1 最终审查浮出的 3 待办一次做全。**

**Files:**
- Modify: `lib/data/defs/stage_def.dart`（`EnemyDef.fromYaml`，约 282-328 行）
- Modify: `lib/features/battle/domain/damage_calculator.dart:290`
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`（`vulnerabilityMultOf` docstring，约 926-929 行）
- Create: `test/data/enemy_def_vulnerability_validation_test.dart`

- [ ] **Step 1: 写失败测试（红绿双验校验放宽）**

`test/data/enemy_def_vulnerability_validation_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

void main() {
  // 最小合法 EnemyDef yaml map 构造器（按 EnemyDef.fromYaml 必需字段）。
  Map<String, dynamic> baseEnemy({
    String? chargeSkillId,
    List<Map<String, dynamic>>? bossPhases,
    Map<String, dynamic>? vulnerability,
  }) => {
        'id': 'test_boss',
        'name': '测试 Boss',
        'realmTier': 'jueDing',
        'realmLayer': 'dengFeng',
        'school': 'lingQiao',
        'baseHp': 15000,
        'baseAttack': 2000,
        'baseSpeed': 200,
        'skillIds': <String>['skill_a'],
        'iconPath': 'assets/enemies/test.png',
        'isBoss': true,
        if (chargeSkillId != null) 'chargeSkillId': chargeSkillId,
        if (bossPhases != null) 'bossPhases': bossPhases,
        if (vulnerability != null) 'vulnerability': vulnerability,
      };

  group('EnemyDef vulnerability 跨字段校验（放宽后）', () {
    test('vulnerability + 顶层 chargeSkillId → 合法', () {
      final def = EnemyDef.fromYaml(baseEnemy(
        chargeSkillId: 'skill_a',
        vulnerability: {'outOfWindowDamageMult': 0.10},
      ));
      expect(def.vulnerability?.outOfWindowDamageMult, 0.10);
    });

    test('vulnerability + bossPhases 含 chargeCounter 相位（无顶层 chargeSkillId）→ 合法', () {
      final def = EnemyDef.fromYaml(baseEnemy(
        bossPhases: [
          {'hpThresholdPct': 1.0},
          {'hpThresholdPct': 0.7, 'onEnterMechanic': 'chargeCounter'},
        ],
        vulnerability: {'outOfWindowDamageMult': 0.10},
      ));
      expect(def.vulnerability?.outOfWindowDamageMult, 0.10);
    });

    test('vulnerability 但既无 chargeSkillId 也无 chargeCounter 相位 → StateError', () {
      expect(
        () => EnemyDef.fromYaml(baseEnemy(
          bossPhases: [
            {'hpThresholdPct': 1.0},
            {'hpThresholdPct': 0.7}, // 无 onEnterMechanic
          ],
          vulnerability: {'outOfWindowDamageMult': 0.10},
        )),
        throwsA(isA<StateError>()),
      );
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/enemy_def_vulnerability_validation_test.dart`
Expected: 第 2 个 test FAIL（当前校验只认 chargeSkillId，chargeCounter 相位形态会抛 StateError）。

- [ ] **Step 3: 放宽校验实现**

`stage_def.dart` `EnemyDef.fromYaml`——把 `bossPhases` 解析上提到校验前，改跨字段校验：

```dart
  factory EnemyDef.fromYaml(Map<String, dynamic> y) {
    final chargeSkillId = y['chargeSkillId'] as String?;
    final bossPhases = y['bossPhases'] == null
        ? null
        : BossPhaseDef.parseList(y['bossPhases'] as List);
    final vulnerability = y['vulnerability'] == null
        ? null
        : BossVulnerabilityDef.fromYaml(
            Map<String, dynamic>.from(y['vulnerability'] as Map),
          );
    // 脆弱窗口需有开窗途径:顶层 chargeSkillId(蓄招技 CD 周期开窗)或 bossPhases
    // 含 chargeCounter 相位(进阶跌破阈值时进蓄力态开窗)。二者皆无 → 永不开窗无解。
    final hasChargePhase = bossPhases
            ?.any((p) => p.onEnterMechanic == BossPhaseMechanic.chargeCounter) ??
        false;
    if (vulnerability != null && chargeSkillId == null && !hasChargePhase) {
      throw StateError(
        'EnemyDef ${y['id']}: 配 vulnerability 必须有开窗途径'
        '（顶层 chargeSkillId 或 bossPhases 含 onEnterMechanic: chargeCounter），'
        '否则脆弱窗口永不开 = 永久免疫无解',
      );
    }
    return EnemyDef(
      id: y['id'] as String,
      name: y['name'] as String,
      realmTier: RealmTier.values.byName(y['realmTier'] as String),
      realmLayer: RealmLayer.values.byName(y['realmLayer'] as String),
      school: TechniqueSchool.values.byName(y['school'] as String),
      baseHp: (y['baseHp'] as num).toInt(),
      baseAttack: (y['baseAttack'] as num).toInt(),
      baseSpeed: (y['baseSpeed'] as num).toInt(),
      skillIds: List<String>.from(
        (y['skillIds'] as List? ?? const []).map((e) => e as String),
      ),
      iconPath: y['iconPath'] as String,
      isBoss: y['isBoss'] as bool? ?? false,
      chargeSkillId: chargeSkillId,
      bossPhases: bossPhases,
      cycleBossPhases: _parseCycleBossPhases(y['cycleBossPhases'] as Map?),
      schoolDamageTakenMult: y['schoolDamageTakenMult'] == null
          ? null
          : (y['schoolDamageTakenMult'] as Map).map(
              (k, v) => MapEntry(
                TechniqueSchool.values.byName(k as String),
                (v as num).toDouble(),
              ),
            ),
      guardianWard: y['guardianWard'] == null
          ? null
          : GuardianWardDef.fromYaml(
              Map<String, dynamic>.from(y['guardianWard'] as Map),
            ),
      vulnerability: vulnerability,
    );
  }
```

> 注：`bossPhases` 由 inline（原 `return` 里）上提为局部变量并在 `return` 中引用；`BossPhaseMechanic` 已随 `BossPhaseDef` 一并可用（同 `boss_phase_def.dart`，stage_def.dart 已 import 该文件用 `BossPhaseDef.parseList`）。若 analyze 报 `BossPhaseMechanic` 未定义，在文件头补 `import 'boss_phase_def.dart';`（大概率已存在）。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/enemy_def_vulnerability_validation_test.dart`
Expected: 3 tests PASS。

- [ ] **Step 5: 收口 debug 标签（batch-1 待办 #2）**

`damage_calculator.dart:290`，`defenderWardMult` 现承载 `wardMultOf * vulnerabilityMultOf`，标签 `(护法结界)` 会误标 vulnerability。改通用标签：

```dart
        '${defenderWardMult != 1.0 ? ' * ${_fmt(defenderWardMult)}(防御乘子)' : ''}'
```

- [ ] **Step 6: 收口 vulnerabilityMultOf docstring（batch-1 待办 #3）**

`default_ground_strategy.dart` `vulnerabilityMultOf` 的 docstring（约 926-929 行），补 chargeCounter 相位开窗路径。把「窗口靠 chargeSkillId 的技能 CD 周期复发(§3.2)」一行改为：

```dart
  /// 窗口复发靠现成机制:顶层 chargeSkillId 的技能 CD(§3.2),或 bossPhases 的
  /// chargeCounter 相位(跌破 hpThreshold 进蓄力态,floor25/30 用此路径)。此处只读状态不改状态。
```

- [ ] **Step 7: analyze + 提交**

```bash
flutter analyze lib/ test/   # Expected: No issues
git add -A
git commit -m "[schema] 放宽 vulnerability 校验含 chargeCounter 相位 + 收口 batch-1 标签/docstring"
```

---

## Task 2: floor25 绝顶剑魔配 vulnerability

**floor25 有 `bossPhases` chargeCounter 相位（0.70/0.50）、无护法、无顶层 chargeSkillId。批次1 诊断已用 copyWith 注入 0.10 证满配 20/20 胜、ticks 2.66×。本 Task 把它写进 yaml。**

**Files:**
- Modify: `data/towers.yaml`（floor25，`enemy_tower_boss_25`）
- Create: `test/data/tower_vulnerability_config_test.dart`

- [ ] **Step 1: 写失败测试（真实 yaml 加载守卫）**

`test/data/tower_vulnerability_config_test.dart`：

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('floor25 绝顶剑魔配 vulnerability 0.10 且靠 chargeCounter 相位（无 StateError）', () {
    final floor = repo.getTowerFloor(25);
    final boss = floor.enemyTeam.firstWhere((e) => e.id == 'enemy_tower_boss_25');
    expect(boss.vulnerability, isNotNull,
        reason: 'floor25 应配 vulnerability');
    expect(boss.vulnerability!.outOfWindowDamageMult, 0.10);
    expect(boss.chargeSkillId, isNull,
        reason: 'floor25 靠相位开窗，不应有顶层 chargeSkillId');
    expect(
      boss.bossPhases?.any((p) => p.onEnterMechanic != null),
      isTrue,
      reason: 'floor25 需有 chargeCounter 相位提供开窗途径',
    );
  });
}
```

> `GameRepository.getTowerFloor` / `TowerFloorDef.enemyTeam` / `EnemyDef.id` 均现成（诊断测已用）。若 `getTowerFloor` 签名不同，照 `floor30_soft_gate_diagnostic_test.dart:_` 的 `repo.getTowerFloor(30)` 用法对齐。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/tower_vulnerability_config_test.dart`
Expected: FAIL（`boss.vulnerability` 为 null，yaml 未配）。

- [ ] **Step 3: floor25 yaml 加 vulnerability**

`data/towers.yaml`，从 `- floorIndex: 25` 正向定位到 `- id: enemy_tower_boss_25`，在其 `isBoss: true` 与 `schoolDamageTakenMult:` 之间（或 `bossPhases:` 之前的同缩进层）加：

```yaml
        vulnerability:
          outOfWindowDamageMult: 0.10   # 机制型:窗口外(未蓄招/未踉跄)仅受 10% 伤;
                                        # 窗口靠 bossPhases chargeCounter 相位(0.70/0.50)开。
                                        # 批次1 诊断(copyWith 0.10)验:满配20/20胜·ticks 2.66×。
```

> 缩进对齐 floor25 enemy 现有字段（Phase0 实测该 enemy 字段缩进 8 空格，`vulnerability:` 顶格 8 空格、`outOfWindowDamageMult:` 10 空格）。加在 enemy map 内任意位置皆可（yaml 无序），推荐紧邻 `bossPhases:` 上方语义聚合。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/tower_vulnerability_config_test.dart`
Expected: PASS。

- [ ] **Step 5: analyze + 提交**

```bash
flutter analyze lib/ test/   # Expected: No issues
git add -A
git commit -m "[balance] floor25 绝顶剑魔配脆弱窗口 vulnerability 0.10（靠相位开窗）"
```

---

## Task 3: 模块 A —— 护法墙 taunt（修 no-op，改核心 AI）

**给目标选择器加「被存活护法保护的 Boss 从目标池排除」。复用现有 `guardianDefIds`/`enemyDefId`（floor30 Boss 已从 guardianWard 灌入），零新 def 字段。护法全灭 → Boss 进池 + 脆弱窗口接管。taunt 优先于脆弱窗口。**

**Files:**
- Modify: `lib/features/battle/domain/battle_ai.dart`
- Create: `test/features/battle/battle_ai_guardian_taunt_test.dart`

- [ ] **Step 1: 写失败测试（taunt 排除 + 护法灭后恢复 + drift 守卫）**

`test/features/battle/battle_ai_guardian_taunt_test.dart`。**先 grep 现有 battle_ai 测试的造 BattleCharacter helper** 复用（`grep -rln "BattleCharacter(" test/features/battle/ | head`，找一个构造存活敌队的样板，如 `battle_ai_*_test.dart`），镜像它造：一个带 `guardianDefIds:['g1']` + `guardianWardMult:0.15` 的 Boss（enemyDefId:'boss'）+ 一个护法（enemyDefId:'g1'）+ 一个攻击者。断言：

```dart
// 伪结构——用现有 battle_ai 测试的 BattleCharacter/BattleState 造队 helper 填充。
// 关键断言（不依赖具体 helper 名）：
//
// 公开入口: BattleAI.decide(actor, state, n) → (SkillDef skill, List<int> targetIds)
//   —— record, targetIds 是 .$2。n = NumbersConfig（现场测试常有 helper 造，
//   或 GameRepository.loadAllDefs().numbers；grep 现有 battle_ai 测试拿 NumbersConfig）。
// 用单体技(非 aoe)actor 触发 _pickTargetId 路径。
//
// test('护法存活时 Boss 不被单体目标选择器选中（taunt）', () {
//   造 state: 攻击者(左) vs [Boss(guardianDefIds:['g1'], hp 低), 护法 g1(hp 高, 存活)](右)
//   // 注意:让 Boss hp < 护法 hp,若无 taunt,_pickTargetId 本会选 Boss(血最低)。
//   final (_, targetIds) = BattleAI.decide(attacker, state, n);
//   expect(targetIds, isNot(contains(bossCharacterId)));       // Boss 被排除
//   expect(targetIds, contains(g1CharacterId));                // 选中护法
// });
//
// test('护法全灭后 Boss 恢复可选', () {
//   同上但 g1.isAlive=false（currentHp:0）
//   final (_, targetIds) = BattleAI.decide(attacker, state, n);
//   expect(targetIds, contains(bossCharacterId));              // Boss 进池
// });
//
// test('drift 守卫:isGuardedBoss 与 wardMultOf 存活判定口径一致', () {
//   // 护法存活 → isGuardedBoss==true 且 wardMultOf<1.0;
//   // 护法全灭 → isGuardedBoss==false 且 wardMultOf==1.0。
//   expect(BattleAI.isGuardedBoss(boss, aliveState),
//          DefaultGroundStrategy.wardMultOf(boss, aliveState) < 1.0);
//   expect(BattleAI.isGuardedBoss(boss, deadGuardianState),
//          DefaultGroundStrategy.wardMultOf(boss, deadGuardianState) < 1.0);
// });
```

> **实装细则：** `BattleAI` 的公开决策入口名 + 返回类型（含 targetIds 的结构）现场 grep `battle_ai.dart` 的 `static` 公开方法确认（Phase0 见 `decideAction`/aoe 分支返回 `(skill, targetIds)` 记录）。断言核心「Boss 被排除 / 护法灭后恢复 / drift 一致」不可删。`wardMultOf` 在 `DefaultGroundStrategy`（import `strategy/default_ground_strategy.dart`）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/battle_ai_guardian_taunt_test.dart`
Expected: FAIL（`isGuardedBoss` 未定义 / Boss 未被排除）。

- [ ] **Step 3: 实现 taunt helper + 四处目标选择器排除**

`battle_ai.dart` 加 helper（放在目标选择器附近）：

```dart
  /// 护法墙 taunt(floor30 模块 A):候选敌为被护法保护的 Boss —— guardianDefIds 非空
  /// 且同队有护法(enemyDefId ∈ guardianDefIds)存活 —— 返 true,应从目标池排除。
  /// 护法全灭 → false,Boss 进池。镜像 DefaultGroundStrategy.wardMultOf 的护法存活判定
  /// (drift 守卫见 battle_ai_guardian_taunt_test)。taunt 优先于脆弱窗口:护法活着
  /// Boss 打不到,无论其是否蓄招。
  static bool isGuardedBoss(BattleCharacter candidate, BattleState state) {
    if (candidate.guardianDefIds.isEmpty) return false;
    final team = candidate.teamSide == 1 ? state.rightTeam : state.leftTeam;
    return team.any((c) =>
        c.isAlive &&
        c.enemyDefId != null &&
        candidate.guardianDefIds.contains(c.enemyDefId));
  }
```

在四处目标遍历里加排除（`isAlive` 判定旁加 `isGuardedBoss` 跳过）：

`_pickTargetId`（约 163 行循环内，`if (!e.isAlive) continue;` 之后）：
```dart
      if (!e.isAlive) continue;
      if (isGuardedBoss(e, state)) continue; // taunt:护法活着 Boss 不可选
```

`_pickFocusTargetId`（约 189 行）：
```dart
      if (!e.isAlive || e.staggerTicksRemaining <= 0) continue;
      if (isGuardedBoss(e, state)) continue; // taunt 优先于脆弱窗口
```

`_pickControlTargetId`（约 205 行）：
```dart
      if (!e.isAlive || e.chargingSkill == null) continue;
      if (isGuardedBoss(e, state)) continue; // taunt 优先
```

aoe 分支（约 45 行 filter）：
```dart
      final targets = enemyTeam
          .where((e) => e.isAlive && !isGuardedBoss(e, state)) // taunt:群体技也不越护法打 Boss
          .toList()
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
```

> **安全性：** 被保护的 Boss 要求护法存活；护法本身不被保护（无 guardianDefIds）→ 池中永有护法可选，`_pickTargetId` 的 `best==null` throw 不触发。护法全灭 → `isGuardedBoss` 返 false → Boss 进池。已验逻辑闭环。

- [ ] **Step 4: 跑测试确认通过 + battle 回归**

Run: `flutter test test/features/battle/battle_ai_guardian_taunt_test.dart test/features/battle/`
Expected: 新测 PASS + 全 `test/features/battle/` 绿（改的是核心 AI，必跑全 battle 测防回归；无护法的敌队 `guardianDefIds` 为空 `[]` → `isGuardedBoss` 恒 false → 零行为变化）。

- [ ] **Step 5: analyze + 提交**

```bash
flutter analyze lib/ test/   # Expected: No issues
git add -A
git commit -m "feat: 护法墙 taunt——存活护法保护的 Boss 从目标池排除（修自动战斗 no-op）"
```

---

## Task 4: floor30 九霄魔尊配 vulnerability

**floor30 有护法墙（左使9000/右使8500）+ chargeCounter 相位（0.90/0.50）+ 42000 血。Task 3 后护法期 Boss 不可选，护法灭后靠脆弱窗口打完残局。vuln 起点 0.20（比 floor25 宽松：叠了护法血墙 + 高血量，避三层无解，Task 5 诊断校准）。**

**Files:**
- Modify: `data/towers.yaml`（floor30，`enemy_tower_boss_30`）
- Modify: `test/data/tower_vulnerability_config_test.dart`（加 floor30 断言）

- [ ] **Step 1: 加失败测试（floor30 加载守卫）**

在 `test/data/tower_vulnerability_config_test.dart` 追加 test：

```dart
  test('floor30 九霄魔尊配 vulnerability 且靠 chargeCounter 相位 + 护法墙', () {
    final floor = repo.getTowerFloor(30);
    final boss = floor.enemyTeam.firstWhere((e) => e.id == 'enemy_tower_boss_30');
    expect(boss.vulnerability, isNotNull);
    expect(boss.vulnerability!.outOfWindowDamageMult, 0.20);
    expect(boss.chargeSkillId, isNull);
    expect(boss.guardianWard, isNotNull, reason: 'floor30 保留护法墙');
    expect(
      boss.bossPhases?.any((p) => p.onEnterMechanic != null),
      isTrue,
    );
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/tower_vulnerability_config_test.dart`
Expected: 新 test FAIL（floor30 `vulnerability` 为 null）。

- [ ] **Step 3: floor30 yaml 加 vulnerability**

`data/towers.yaml`，从 `- floorIndex: 30` 正向定位到 `- id: enemy_tower_boss_30`，加（缩进对齐，保留现有 `guardianWard`/`bossPhases` 不动）：

```yaml
        vulnerability:
          outOfWindowDamageMult: 0.20   # 机制型:护法墙(taunt)破后靠脆弱窗口打残局。
                                        # 窗口靠 bossPhases chargeCounter 相位(0.90/0.50)。
                                        # 起点 0.20(比 floor25 宽:叠护法血墙+42000血),诊断校准。
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/tower_vulnerability_config_test.dart`
Expected: 全 PASS（floor25 + floor30）。

- [ ] **Step 5: analyze + 提交**

```bash
flutter analyze lib/ test/   # Expected: No issues
git add -A
git commit -m "[balance] floor30 九霄魔尊配脆弱窗口 vulnerability 0.20（叠护法墙 taunt）"
```

---

## Task 5: 诊断硬闸（真实 yaml 消费 · 本批核心验收）

**证真实 yaml 配置下：① floor25 脆弱窗口真生效（非首击秒穿，满配可胜）② floor30 护法墙 taunt 在自动战斗真排除 Boss（避 ward no-op）+ 护法灭后 vuln 接管 ③ 两 floor 软门槛（under-gear 有败率）。数值在此校准。**

**Files:**
- Modify: `test/tools/vulnerability_window_diagnostic_test.dart`（floor25 从 copyWith 注入改「验真实 yaml 已配 0.10」）
- Modify: `test/tools/floor30_soft_gate_diagnostic_test.dart`（加 taunt 排除 + vuln 生效断言）

- [ ] **Step 1: floor25 诊断改真实 yaml 消费**

`vulnerability_window_diagnostic_test.dart` 现用 `.copyWith(vulnerabilityMult:0.1)` 注入。Task 2 后 floor25 yaml 已配，改为：
- 保留 A/B 对照结构，但断言 A（真实 floor25，现已带 vuln）与「人工去掉 vuln」的 B 对照——即把注入方向反转：baseline = 真实 yaml（有 vuln），对照组 = `.copyWith(vulnerabilityMult: null)`（关闭机制）。
- 加一个断言：真实加载的 floor25 Boss BattleCharacter `vulnerabilityMult == 0.10`（证 plumbing 端到端灌入，非仅内存注入）。

```dart
  test('D. 真实 yaml floor25 Boss 端到端灌入 vulnerabilityMult=0.10', () {
    // 用 StageBattleSetup 从真实 floor25 建战斗初态,取 Boss BattleCharacter。
    // 照本文件现有 setup helper 造队;断言 boss.vulnerabilityMult == 0.10。
    // （证 EnemyDef.vulnerability → StageBattleSetup → BattleCharacter 全链路,
    //   不再是测试内 copyWith 注入。）
  });
```

> 现有 A/B/C 三断言（ticks 拉长 / 减伤真触发 / under-gear 软门槛）保留，把「B=copyWith 注入 0.1」调整为「A=真实 yaml 有 vuln，对照=copyWith 关闭」，方向断言不变（有 vuln 的 ticks > 无 vuln）。

- [ ] **Step 2: floor30 诊断加 taunt + vuln 断言**

`floor30_soft_gate_diagnostic_test.dart` 已有 onLevel/underGear × 30 seed 跑法 + `wardBreakTick`（护法全灭 tick）。加断言：

```dart
  test('floor30 护法墙 taunt 真生效:护法全灭前 Boss 未受伤（避 ward no-op）', () {
    // 跑 onLevel 一个固定 seed 的 runToEnd,逐 tick 或末态检查:
    //   在 wardBreakTick 之前,Boss(enemy_tower_boss_30) currentHp 保持满血 baseHp
    //   （taunt 排除 → 从不被选中）。wardBreakTick 之后才开始掉血。
    // 关键:证 taunt 让减伤在自动战斗真咬合(旧 guardianWard 减伤是 no-op)。
  });

  test('floor30 满配仍必胜（护法墙+脆弱窗口不构成无解）', () {
    // onLevel × 全 seed:winRate == 100%。若 <100% → 放宽 vuln mult(0.20→0.25)
    //   或降护法/Boss 参数,守 boss<60000 红线。
  });

  test('floor30 under-gear 跨阶软门槛（有可观败率）', () {
    // underGear × 全 seed:winRate < 100%（如 <= 85%）。守 boss_balance_crosstier。
  });
```

> **taunt 生效的可观测量：** floor30 Boss `enemyDefId=='enemy_tower_boss_30'`，护法 `enemy_tower_30_cultist_a/b`。诊断逐 tick 记录 Boss `currentHp`；断言「首个 Boss 掉血的 tick >= wardBreakTick」（护法未全灭前 Boss 满血）。若 `runToEnd` 无逐 tick 钩子，用 `BattleEngine` 单步 `advance` 循环采样（照 `battle_advance_one_action_test.dart:90-107` 的 `notifier.advance` 骨架）或复用本文件已有的 `wardBreakTick` 采集逻辑扩展记 `bossFirstDamageTick`。

- [ ] **Step 3: 跑诊断，按实测校准阈值**

Run: `flutter test test/tools/vulnerability_window_diagnostic_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart`
Expected: 全绿。**若 floor30 satisfy 不了「满配 100% 胜」**（vuln 0.20 + 护法墙 + 42000 血可能超时 `_maxTicks=300`）：
1. 先看 avgTicks——若接近 300 = 超时卡死 → vuln 放宽到 0.25 或 0.30（改 Task 4 yaml + 本测期望值），重跑。
2. 若护法灭后 Boss 血仍打不动 = 窗口太窄 → 确认 chargeCounter 相位在护法灭后仍触发（Boss 满血 42000，护法灭后从满血开打，90% 阈值很快触发首窗）。
3. 记录最终实测值（meanTicks / winRate / bossFirstDamageTick）写进测试注释 OBSERVED 行 + PROGRESS。

- [ ] **Step 4: 提交**

```bash
git add test/tools/vulnerability_window_diagnostic_test.dart test/tools/floor30_soft_gate_diagnostic_test.dart
git commit -m "test: floor25/30 脆弱窗口+护法墙 taunt 真实 yaml 诊断硬闸（自动战斗真触发+软门槛）"
```

---

## Task 6: 批末全量回归 + 文档收口

**Files:**
- Modify: `PROGRESS.md`（顶段加 batch-2 条）
- Modify: `docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch2-tower-application.md`（本文件恢复点）
- Modify（若诊断阈值涉及）: 无红线注释需改（本批不改硬红线，vulnerability 是机制非数值膨胀；§5.4 例外条款留批次5 文档批）

- [ ] **Step 1: 全量并发测试（跨切面改动，批末必跑）**

Run: `flutter test --no-pub`
Expected: 基线 3621 + 本批新测（校验 3 + config 2 + taunt 3 + 诊断新增）passed / 1 skipped / 0 fail。记录实测数字（禁转抄）。

- [ ] **Step 2: analyze 全量**

Run: `flutter analyze lib/ test/`
Expected: No issues。

- [ ] **Step 3: 更新 PROGRESS.md 顶段**

在 PROGRESS「当前阶段」顶部加 batch-2 条（区分四态：已完成/已验证/已知风险/下批建议），引 spec/plan，记诊断实测值。

- [ ] **Step 4: 更新本 plan 恢复点**

标注批次2 完成，记提交序 + 实测验证数字，下一步指向批次3（心魔）/批次4（周目）/批次5（红线文档）。

- [ ] **Step 5: 提交**

```bash
git add PROGRESS.md docs/superpowers/plans/2026-07-03-endgame-mechanic-boss-batch2-tower-application.md
git commit -m "docs: batch-2 爬塔应用收口（PROGRESS + plan 恢复点）"
```

---

## 恢复点（Resume Point）

- **状态：** 未开始（plan 已写，待执行）。
- **下一步：** Task 1（放宽校验 + 收口 batch-1 遗留标签/docstring）。
- **环境：** worktree `endgame-boss-batch2-tower`（branch `worktree-endgame-boss-batch2-tower`，base=origin/main af4db5a2），dylib + pub get + build_runner 已预热。
- **阻塞项：** 无。
- **视觉验收（批末，可 defer 到合并前）：** floor30 护法墙 + 脆弱窗口的减伤反馈题字真机目检（非本批 TDD 范围，主窗口合并前统一安排）。

## 批次2 后续（不在本 plan）

- 批次3：心魔应用（相位开窗 + 终关模块 B 限时生存，改 isFinished 回归面大，可 defer）。
- 批次4：终局周目 `cycleBossPhases` 收窄窗口。
- 批次5：GDD §5.4 + CLAUDE §5.4 加机制型 Boss 例外条款（纯文档，需用户确认措辞）。
