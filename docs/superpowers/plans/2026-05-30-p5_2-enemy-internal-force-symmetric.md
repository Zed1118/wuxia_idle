# P5.2 敌人内力按境界对称化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把敌人内力从扁平常量 1000 改为按境界查表对称化（RealmDef.internalForceMax × 全局系数，满开局），让进阶 Boss 招牌大招能放。

**Architecture:** 纯查表，不动 EnemyDef schema（已有 realmTier+realmLayer）。缩放计算抽成纯函数 `StageBattleSetup.resolveEnemyInternalForce` 便于单测；`_enemyToBattle` 查 `GameRepository.getRealm` 拿 internalForceMax 再过纯函数，clamp ≤ 红线 15000。`enemy_defaults.internal_force:1000` 替换为 `internal_force_scale:1.0`（平衡旋钮）。实装后跑 balance_simulator 验难度曲线。

**Tech Stack:** Flutter / Dart, Isar, YAML 数值, flutter_test。

**执行约束（bg session）:** Edit/Write 工具可能被 isolation guard 拦——若拦则改用 Bash `python3 -c` 精确替换（`assert old in s` + 写回）或 heredoc，每改一处 `git diff` 核验。未 EnterWorktree（避 fresh worktree libisar.dylib + build_runner 摩擦），直写 main。

**关键事实锚点（Phase 0 实测，行号）:**
- `lib/data/numbers_config.dart:1101` `EnemyDefaults` 类（字段 `internalForce/criticalRate/evasionRate`），仅 2 caller。
- `lib/features/battle/application/stage_battle_setup.dart:275-296` `_enemyToBattle`（292-293 取 `enemyDefaults.internalForce`）；`buildEnemyTeam`（:71 公开 static）。
- `GameRepository.getRealm(RealmTier,RealmLayer)`（`game_repository.dart:1314`）→ `RealmDef.internalForceMax`。
- redLines 访问：`GameRepository.instance.numbers.combat.redLines.internalForceMax`（=15000）。
- 锚点：stage_01_01 敌人 xueTu/qiMeng→500；stage_06_05「西凉霸主」wuSheng/qiMeng→13000；「西凉三弟子·刚猛」zongShi/dengFeng→12500。
- 大招：`getSkill('skill_yinrou_chuanshuo_ult').internalForceCost` = 1600。
- 测试 pattern：`test/features/battle/application/stage_battle_setup_test.dart`（setUpAll 跑 `GameRepository.loadAllDefs`，buildEnemyTeam 无需 Isar）。
- enum：`RealmTier.{xueTu,sanLiu,erLiu,yiLiu,jueDing,zongShi,wuSheng}` / `RealmLayer.{qiMeng..dengFeng}` / `TechniqueSchool.{gangMeng,lingQiao,yinRou}`。

---

## Task 1: 抽 `resolveEnemyInternalForce` 纯函数（additive，不破编译）

**Files:**
- Modify: `lib/features/battle/application/stage_battle_setup.dart`（加 static 方法）
- Test: `test/features/battle/application/stage_battle_setup_test.dart`（追加 group）

- [ ] **Step 1: Write the failing tests**

在 `stage_battle_setup_test.dart` 的 `void main(){...}` 内末尾追加（import `package:flutter/foundation.dart` 不需，方法用 `@visibleForTesting` 但 public 可直调）：

```dart
group('P5.2 resolveEnemyInternalForce 纯函数', () {
  test('scale 1.0 直通 RealmDef 值', () {
    expect(
      StageBattleSetup.resolveEnemyInternalForce(13000, 1.0, 15000),
      13000,
    );
  });
  test('scale 0.5 折半', () {
    expect(
      StageBattleSetup.resolveEnemyInternalForce(13000, 0.5, 15000),
      6500,
    );
  });
  test('scale 2.0 越红线 → clamp 15000', () {
    expect(
      StageBattleSetup.resolveEnemyInternalForce(15000, 2.0, 15000),
      15000,
    );
  });
  test('低境界学徒 500 × 1.0 = 500', () {
    expect(
      StageBattleSetup.resolveEnemyInternalForce(500, 1.0, 15000),
      500,
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "resolveEnemyInternalForce"`
Expected: 编译失败 `method 'resolveEnemyInternalForce' isn't defined`。

- [ ] **Step 3: Write minimal implementation**

在 `lib/features/battle/application/stage_battle_setup.dart` 类内（紧邻 `buildEnemyTeam` 之后或 `_enemyToBattle` 之前）加：

```dart
  /// P5.2 敌人内力对称化：按境界 internalForceMax × 全局 scale，clamp ≤ 红线。
  /// 抽纯函数便于单测 scale/clamp，不依赖 GameRepository 单例。
  @visibleForTesting
  static int resolveEnemyInternalForce(
    int realmInternalForceMax,
    double scale,
    int redLineCap,
  ) {
    final scaled = (realmInternalForceMax * scale).round();
    return scaled.clamp(0, redLineCap);
  }
```

（文件首行已 `import 'package:flutter/foundation.dart' show visibleForTesting;`，无需新 import。）

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "resolveEnemyInternalForce"`
Expected: 4 测 PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/application/stage_battle_setup.dart test/features/battle/application/stage_battle_setup_test.dart
git commit -m "[balance] P5.2 抽 resolveEnemyInternalForce 纯函数(内力对称化 helper)"
```

---

## Task 2: 配置层字段改名 + 范围校验（`internal_force` → `internal_force_scale`）

**Files:**
- Modify: `data/numbers.yaml`（enemy_defaults 段 :96-99）
- Modify: `lib/data/numbers_config.dart:1101-1119`（EnemyDefaults 类）
- Test: `test/features/battle/application/stage_battle_setup_test.dart`（追加 fromYaml 校验测）

- [ ] **Step 1: Write the failing tests**

追加 group（import 顶部加 `import 'package:wuxia_idle/data/numbers_config.dart';`）：

```dart
group('P5.2 EnemyDefaults.fromYaml scale 校验', () {
  Map<String, dynamic> y(double scale) => {
        'internal_force_scale': scale,
        'critical_rate': 0.05,
        'evasion_rate': 0.05,
      };
  test('scale 1.0 正常解析', () {
    expect(EnemyDefaults.fromYaml(y(1.0)).internalForceScale, 1.0);
  });
  test('scale 0 → throw', () {
    expect(() => EnemyDefaults.fromYaml(y(0)), throwsArgumentError);
  });
  test('scale 负 → throw', () {
    expect(() => EnemyDefaults.fromYaml(y(-0.5)), throwsArgumentError);
  });
  test('scale > 2 → throw', () {
    expect(() => EnemyDefaults.fromYaml(y(2.5)), throwsArgumentError);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "EnemyDefaults.fromYaml"`
Expected: 编译失败 `internalForceScale` getter 不存在 + `internal_force_scale` 解析 null。

- [ ] **Step 3a: 改 EnemyDefaults 类**

`lib/data/numbers_config.dart` 把 `EnemyDefaults` 整类替换为：

```dart
class EnemyDefaults {
  final double internalForceScale;
  final double criticalRate;
  final double evasionRate;

  const EnemyDefaults({
    required this.internalForceScale,
    required this.criticalRate,
    required this.evasionRate,
  });

  factory EnemyDefaults.fromYaml(Map<String, dynamic> y) {
    final scale = (y['internal_force_scale'] as num).toDouble();
    if (scale <= 0 || scale > 2) {
      throw ArgumentError.value(
        scale,
        'internal_force_scale',
        '敌人内力 scale 必须 ∈ (0, 2]',
      );
    }
    return EnemyDefaults(
      internalForceScale: scale,
      criticalRate: (y['critical_rate'] as num).toDouble(),
      evasionRate: (y['evasion_rate'] as num).toDouble(),
    );
  }
}
```

- [ ] **Step 3b: 改 numbers.yaml**

`data/numbers.yaml` enemy_defaults 段把 `internal_force: 1000` 行替换为（同时更新上方注释末句）：

```yaml
  enemy_defaults:
    internal_force_scale: 1.0        # 敌人内力 = 同境界 RealmDef.internal_force_max × 此系数（P5.2 对称化平衡旋钮，∈(0,2]，clamp≤15000）
    critical_rate: 0.05              # 基础暴击率
    evasion_rate: 0.05               # 基础闪避率
```

并把段顶注释第 3 行 `# 当前为纯抽取...留根因A 重平衡批。` 改为 `# P5.2 起按境界查表对称化（internal_force_scale × RealmDef.internal_force_max）。`

- [ ] **Step 3c: wire `_enemyToBattle`（消除编译断裂）**

`lib/features/battle/application/stage_battle_setup.dart` `_enemyToBattle` 内，`final enemyDefaults = ...` 行之后插入查表，并把 292-293 两行的 `enemyDefaults.internalForce` 改用新值：

```dart
    final enemyDefaults = GameRepository.instance.numbers.combat.enemyDefaults;
    final realm = GameRepository.instance.getRealm(
      enemy.realmTier,
      enemy.realmLayer,
    );
    final enemyIf = resolveEnemyInternalForce(
      realm.internalForceMax,
      enemyDefaults.internalForceScale,
      GameRepository.instance.numbers.combat.redLines.internalForceMax,
    );
```

然后：
```dart
      maxInternalForce: enemyIf,
      currentInternalForce: enemyIf,
```

并更新 `_enemyToBattle` 上方 doc 注释那条 `maxInternalForce / currentInternalForce ... 取 numbers.yaml combat.enemy_defaults` → 改为 `按境界查表 RealmDef.internalForceMax × enemy_defaults.internal_force_scale（P5.2 对称化），满开局`。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart`
Expected: fromYaml 校验 4 测 PASS + 原有测全绿（敌人字段映射测可能断言旧 1000 → 见 Step 5 修）。

- [ ] **Step 5: 修可能断言旧 1000 的回归测**

Run: `grep -n "1000\|internalForce" test/features/battle/application/stage_battle_setup_test.dart`
若有断言敌人 `maxInternalForce == 1000` 的旧测，改为期望对称化值（按该测用的 stage 敌人境界查锚点表，如 stage_01_01→500）。无则跳过。

- [ ] **Step 6: 跑 numbers loader 回归（改 yaml 必跑）**

Run: `flutter test test/ --plain-name "numbers" && flutter test test/features/battle/application/stage_battle_setup_test.dart`
Expected: 全绿。

- [ ] **Step 7: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart lib/features/battle/application/stage_battle_setup.dart test/features/battle/application/stage_battle_setup_test.dart
git commit -m "[schema] P5.2 敌人内力按境界对称化:internal_force→scale 查表 + _enemyToBattle wire"
```

---

## Task 3: 对称化集成测 + Boss 能放大招语义守护

**Files:**
- Test: `test/features/battle/application/stage_battle_setup_test.dart`（追加 group）

- [ ] **Step 1: Write the tests（实装已就绪，应直接 GREEN，作回归守护）**

```dart
group('P5.2 敌人内力对称化集成', () {
  test('学徒敌人 stage_01_01 内力 = 500 (满开局)', () {
    final stage = GameRepository.instance.getStage('stage_01_01');
    final enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
    expect(enemies.first.maxInternalForce, 500);
    expect(enemies.first.currentInternalForce, 500);
  });
  test('武圣 Boss 西凉霸主内力 = 13000', () {
    final stage = GameRepository.instance.getStage('stage_06_05');
    final boss = StageBattleSetup.buildEnemyTeam(stage.enemyTeam)
        .firstWhere((e) => e.name == '西凉霸主');
    expect(boss.maxInternalForce, 13000);
    expect(boss.currentInternalForce, 13000);
  });
  test('武圣 Boss 内力足够放阴柔传说大招 (cost 1600)', () {
    final stage = GameRepository.instance.getStage('stage_06_05');
    final boss = StageBattleSetup.buildEnemyTeam(stage.enemyTeam)
        .firstWhere((e) => e.name == '西凉霸主');
    final ult = GameRepository.instance.getSkill('skill_yinrou_chuanshuo_ult');
    expect(ult.internalForceCost, 1600);
    expect(boss.currentInternalForce,
        greaterThanOrEqualTo(ult.internalForceCost));
  });
});
```

- [ ] **Step 2: Run**

Run: `flutter test test/features/battle/application/stage_battle_setup_test.dart --plain-name "对称化集成"`
Expected: 3 测 PASS。若「西凉霸主」名不符，先 `grep -n "name:" data/stages.yaml | sed -n` 在 stage_06_05 段核对真名。

- [ ] **Step 3: Commit**

```bash
git add test/features/battle/application/stage_battle_setup_test.dart
git commit -m "[balance] P5.2 敌人内力对称化集成测 + Boss 能放大招语义守护"
```

---

## Task 4: 全量回归 + analyze

- [ ] **Step 1: 全量测**

Run: `flutter test 2>&1 | tail -20`
Expected: 全绿，测数 ≥ baseline 1581 + 新增 ~11（4 helper + 4 校验 + 3 集成）。记录实际测数。

- [ ] **Step 2: analyze**

Run: `flutter analyze 2>&1 | tail -5`
Expected: `No issues found!`（0）。

- [ ] **Step 3: 若有 fail/issue，修到全绿再继续（不跳过）**

注意 memory `feedback_layered_bugs`：长链路 fail 不要修一步就报完成。

---

## Task 5: balance_simulator 复跑 + 难度验收（数值平衡核心）

**Files:**
- Run: `test/tools/balance_simulator_test.dart`
- 对比 baseline: `test/tools/output/balance_summary_2026-05-29.md`
- 可能 Modify: `data/numbers.yaml`（仅当 sim 显示过强需下调 scale）

- [ ] **Step 1: 复跑 sim**

Run: `flutter test test/tools/balance_simulator_test.dart 2>&1 | tail -30`
产出 csv 到 `test/tools/output/balance_simulation_*.csv`。

- [ ] **Step 2: 读新 csv + 对比 baseline**

Read 新 csv 与 `balance_summary_2026-05-29.md`，重点看 Ch5-Ch6 stage（尤其 stage_06_05）的 floor / ceiling / on-level 三 bracket：
- floor 玩家对 Ch6 Boss 是否被**首回合秒杀**（playerHpEnd=0 且 ticks 极小）。
- ceiling 是否仍普遍胜（对称化目的是难度上升但不应让 floor 崩盘）。

- [ ] **Step 3: 决策（判断题，记录到 closeout）**

- **若 floor 不崩盘**（Boss 放大招但玩家仍有 3-4 招架空间）→ 保持 scale=1.0，记录「对称化达标，floor 健康」。
- **若 floor 崩盘**（首回合秒杀）→ 两选一并记录理由：
  - ① `internal_force_scale` 下调（如 0.7-0.85）整体降敌人内力预算，重跑 sim 收敛。
  - ② 针对 stage_06_xx 调敌人 realmLayer 降一档 或 把传说大招 cost 抬高 / 占位招式 cost 调整。
  - 优先 ①（单旋钮、可逆、不碰 stage 配置）。

- [ ] **Step 4: 若调了 scale，重跑 Task 4 全量 + 本 Task sim 直到收敛，Commit**

```bash
git add data/numbers.yaml test/tools/output/
git commit -m "[balance] P5.2 sim 复跑 + scale 调校至 floor 健康(scale=<值>)"
```

---

## Task 6: 收尾 — PROGRESS + spec/plan 归档 commit

**Files:**
- Modify: `PROGRESS.md`（当前阶段段追加一条 P5.2 实装条目）
- 已存在: spec/plan（docs/superpowers/）

- [ ] **Step 1: 更新 PROGRESS.md**

在「当前阶段」段顶追加一条（控制总行 ≤100，必要时归档旧条）：实装摘要 + commit sha + 测数 + sim 决议（scale 值 + floor 健康判定）。

- [ ] **Step 2: Commit + push**

```bash
git add PROGRESS.md docs/superpowers/
git commit -m "docs: PROGRESS 记 P5.2 敌人内力对称化实装 + spec/plan 归档"
git push origin main
```

- [ ] **Step 3: 报告 result**

报告：实装文件、测数 baseline→新值、analyze 0、sim 决议（scale=? / floor 健康?）、Boss 大招能放验证。

---

## 验收标准（对齐 spec）

1. flutter test 全绿（≥1581 + ~11 新增）。
2. flutter analyze 0。
3. balance_simulator 复跑产出新数据，floor 玩家不被进阶 Boss 首回合秒杀（或记录 scale 下调决议）。
4. 武圣 Boss currentInternalForce ≥ 传说大招 cost 1600（语义测守护）。
5. 红线 ≤15000 不破（clamp + scale∈(0,2] 校验）。
